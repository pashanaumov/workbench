import { resolve } from 'node:path';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import {
  resolveConfig,
  checkSetupStatus,
  VectorStore,
  createEmbedder,
} from '@workbench/core';
import type { WorkbenchConfig } from '@workbench/core';

function timeAgo(ms: number): string {
  const sec = Math.floor(ms / 1000);
  if (sec < 60) return `${sec} seconds ago`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min} minute${min !== 1 ? 's' : ''} ago`;
  const hr = Math.floor(min / 60);
  return `${hr} hour${hr !== 1 ? 's' : ''} ago`;
}

async function readIndexStats(
  config: WorkbenchConfig,
): Promise<{ fileCount: number; chunkCount: number; lastIndexedAt: number | null } | null> {
  // Read manifest to get file count
  const manifestPath = join(config.indexDir, 'manifest.json');
  let fileCount = 0;
  let lastIndexedAt: number | null = null;

  try {
    const raw = await readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(raw) as Record<string, unknown>;
    fileCount = Object.keys(manifest).length;
  } catch {
    return null; // not yet indexed
  }

  // Read stats file if present
  const statsPath = join(config.indexDir, 'stats.json');
  try {
    const raw = await readFile(statsPath, 'utf-8');
    const stats = JSON.parse(raw) as { lastIndexedAt?: number; chunkCount?: number };
    lastIndexedAt = stats.lastIndexedAt ?? null;
    const storedChunks = stats.chunkCount;
    if (storedChunks !== undefined) {
      return { fileCount, chunkCount: storedChunks, lastIndexedAt };
    }
  } catch {
    // no stats file — fall through to vector store count
  }

  // Fall back to VectorStore count
  let chunkCount = 0;
  try {
    const embedder = createEmbedder(config);
    const store = new VectorStore(config);
    await store.open(embedder.dimensions);
    chunkCount = await store.count();
  } catch {
    // store not yet initialized
  }

  return { fileCount, chunkCount, lastIndexedAt };
}

export async function statusCmd(): Promise<void> {
  const projectPath = resolve(process.cwd());
  const config = await resolveConfig(projectPath);

  const providerLabel = (() => {
    switch (config.embedder) {
      case 'openai': return `openai (${config.openaiModel})`;
      case 'ollama': return `ollama (${config.ollamaModel})`;
      default: return `local (${config.transformersModel.split('/').pop()})`;
    }
  })();

  console.log('Workbench Indexer Status');
  console.log('========================');
  console.log(`Project:  ${projectPath}`);
  console.log(`Index:    ${config.indexDir}`);
  console.log(`Provider: ${providerLabel}`);

  if (config.embedder === 'transformers' && !process.env['OPENAI_API_KEY']) {
    console.log('          Tip: 5-20x faster with OpenAI — set OPENAI_API_KEY');
  }

  console.log('');
  console.log('Index stats:');

  const stats = await readIndexStats(config);
  if (!stats) {
    console.log('  (not yet indexed)');
  } else {
    console.log(`  Files indexed:  ${stats.fileCount}`);
    console.log(`  Chunks:         ${stats.chunkCount.toLocaleString()}`);
    if (stats.lastIndexedAt !== null) {
      console.log(`  Last indexed:   ${timeAgo(Date.now() - stats.lastIndexedAt)}`);
    } else {
      console.log(`  Last indexed:   unknown`);
    }
  }

  console.log('');
  console.log('Setup status:');

  const setupStatus = await checkSetupStatus(config);

  if (config.embedder === 'transformers') {
    const modelName = config.transformersModel.split('/').pop() ?? config.transformersModel;
    const modelIcon = setupStatus.modelReady ? '✓' : '✗';
    console.log(`  ${modelIcon} Model: ${modelName} (${setupStatus.modelReady ? 'ready' : 'not downloaded'})`);
  } else {
    console.log(`  — Model: n/a (using ${config.embedder})`);
  }

  const grammarTotal = 10; // tree-sitter.wasm + 9 languages
  const grammarReady = grammarTotal - setupStatus.grammarsMissing.length;
  const grammarIcon = setupStatus.grammarsMissing.length === 0 ? '✓' : '✗';
  console.log(`  ${grammarIcon} Grammars: ${grammarReady}/${grammarTotal} ready`);
}
