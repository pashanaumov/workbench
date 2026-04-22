import { resolve } from 'node:path';
import { createInterface } from 'node:readline';
import { parseArgs } from 'node:util';
import { Chunker, createEmbedder, Indexer, resolveConfig, VectorStore } from '@workbench/core';

async function confirm(question: string): Promise<boolean> {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase() === 'y');
    });
  });
}

export async function clearCmd(rawArgs: string[]): Promise<void> {
  const { values } = parseArgs({
    args: rawArgs,
    options: {
      yes: { type: 'boolean', short: 'y', default: false },
    },
    allowPositionals: false,
    strict: true,
  });

  const projectPath = resolve(process.cwd());
  const config = await resolveConfig(projectPath);

  if (!values.yes) {
    const ok = await confirm(`Clear index for ${projectPath}? [y/N] `);
    if (!ok) {
      console.log('Aborted.');
      return;
    }
  }

  const embedder = createEmbedder(config);
  const vectorStore = new VectorStore(config);
  const chunker = new Chunker(config);
  const indexer = new Indexer(config, embedder, vectorStore, chunker);

  try {
    await indexer.clear(projectPath);
  } catch (err) {
    const msg = (err as Error).message ?? String(err);
    if (msg.includes('ENOENT') || msg.includes('not found') || msg.includes('No such')) {
      console.log('No index found — nothing to clear.');
      return;
    }
    throw err;
  }

  console.log('✓ Index cleared');
}
