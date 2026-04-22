import { resolve } from 'node:path';
import { parseArgs } from 'node:util';
import type { IndexProgress, WorkbenchConfig } from '@workbench/core';
import {
  Chunker,
  checkSetupStatus,
  createEmbedder,
  Indexer,
  resolveConfig,
  setup,
  VectorStore,
} from '@workbench/core';
import { createIndexBars, SetupSpinner } from '../ui/progress.js';

export async function indexCmd(rawArgs: string[]): Promise<void> {
  const { values, positionals } = parseArgs({
    args: rawArgs,
    options: {
      force: { type: 'boolean', short: 'f', default: false },
      embedder: { type: 'string' },
    },
    allowPositionals: true,
    strict: true,
  });

  const projectPath = resolve(positionals[0] ?? process.cwd());

  const cliFlags: Partial<WorkbenchConfig> = {};
  if (values.embedder) {
    if (!['openai', 'transformers', 'ollama'].includes(values.embedder)) {
      console.error(
        `wb: unknown embedder '${values.embedder}' (choose: openai, transformers, ollama)`,
      );
      process.exit(1);
    }
    cliFlags.embedder = values.embedder as WorkbenchConfig['embedder'];
  }

  const config = await resolveConfig(projectPath, cliFlags);

  // First-run setup if needed
  const setupStatus = await checkSetupStatus(config);
  const needsSetup =
    (config.embedder === 'transformers' && !setupStatus.modelReady) ||
    setupStatus.grammarsMissing.length > 0;

  if (needsSetup) {
    console.log('Running first-time setup...');
    const spinner = new SetupSpinner();
    await setup({
      config,
      onProgress: (p) => spinner.onProgress(p),
      onTip: (msg) => {
        spinner.finalize();
        console.log(msg);
      },
    });
    spinner.finalize();
  } else if (config.embedder === 'transformers' && !values.embedder) {
    // Tip for users who haven't explicitly set an embedder
    console.log(
      '  Tip: 5-20x faster with OpenAI — set OPENAI_API_KEY or add "embedder": "openai" to .workbench.json',
    );
  }

  const embedder = createEmbedder(config);
  const vectorStore = new VectorStore(config);
  const chunker = new Chunker(config);
  const indexer = new Indexer(config, embedder, vectorStore, chunker);

  const bars = createIndexBars();
  const startTime = Date.now();

  const result = await indexer.index(
    projectPath,
    (progress: IndexProgress) => {
      if (progress.phase === 'scan') {
        bars.updateScan(progress.filesDone, Math.max(progress.filesTotal, 1));
      } else if (progress.phase === 'embed' || progress.phase === 'store') {
        bars.updateScan(progress.filesTotal, progress.filesTotal); // scan complete
        bars.updateEmbed(progress.chunksDone, Math.max(progress.chunksTotal, 1));
      } else if (progress.phase === 'done') {
        bars.updateScan(progress.filesTotal, progress.filesTotal);
        bars.updateEmbed(progress.chunksTotal, progress.chunksTotal);
      }
    },
    values.force,
  );

  bars.stop();

  const durationSec = Math.round((Date.now() - startTime) / 1000);
  const chunksFormatted = result.chunksIndexed.toLocaleString();
  console.log(
    `\n✓ Indexed ${result.filesIndexed} files (${chunksFormatted} chunks) in ${durationSec}s`,
  );
  console.log(`  ${result.filesUnchanged} files unchanged, ${result.errors.length} errors`);

  if (result.errors.length > 0) {
    console.error('\nErrors:');
    for (const { file, error } of result.errors) {
      console.error(`  ${file}: ${error}`);
    }
  }
}
