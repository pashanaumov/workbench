import { resolve } from 'node:path';
import { parseArgs } from 'node:util';
import {
  Chunker,
  createEmbedder,
  Indexer,
  resolveConfig,
  type SearchResult,
  VectorStore,
} from '@workbench/core';

export async function searchCmd(rawArgs: string[]): Promise<void> {
  const { values, positionals } = parseArgs({
    args: rawArgs,
    options: {
      top: { type: 'string', default: '5' },
    },
    allowPositionals: true,
    strict: true,
  });

  const query = positionals.join(' ');
  if (!query.trim()) {
    console.error('workbench search: query is required');
    console.error('Usage: workbench search <query> [--top N]');
    process.exit(1);
  }

  const topK = parseInt(values.top ?? '5', 10);
  if (Number.isNaN(topK) || topK < 1) {
    console.error('workbench search: --top must be a positive integer');
    process.exit(1);
  }

  const projectPath = resolve(process.cwd());
  const config = await resolveConfig(projectPath, { searchTopK: topK });

  const embedder = createEmbedder(config);
  const vectorStore = new VectorStore(config);
  const chunker = new Chunker(config);
  const indexer = new Indexer(config, embedder, vectorStore, chunker);

  let results: SearchResult[];
  try {
    results = await indexer.search(query, topK);
  } catch (err) {
    const msg = (err as Error).message ?? String(err);
    if (msg.includes('ENOENT') || msg.includes('not found') || msg.includes('No such')) {
      console.log('No index found. Run `workbench index` first.');
      return;
    }
    throw err;
  }

  if (results.length === 0) {
    console.log('No results found.');
    return;
  }

  const COLS = process.stdout.columns || 72;

  for (const result of results) {
    const location = `${result.filePath}:${result.startLine}-${result.endLine}`;
    const header = `── ${location} `;
    const pad = COLS - header.length;
    console.log(header + '─'.repeat(Math.max(0, pad)));

    const breadcrumb = result.header ? `${result.filePath} > ${result.header}` : result.filePath;
    console.log(breadcrumb);
    console.log(`score: ${result.score.toFixed(3)}`);
    console.log('');
    console.log(result.body);
    console.log('');
  }
}
