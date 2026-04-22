#!/usr/bin/env node
import { VERSION } from '@workbench/core';
import { clearCmd } from './commands/clear-cmd.js';
import { indexCmd } from './commands/index-cmd.js';
import { searchCmd } from './commands/search-cmd.js';
import { statusCmd } from './commands/status-cmd.js';

const command = process.argv[2];
const restArgs = process.argv.slice(3);

const COMMANDS = ['index', 'status', 'search', 'clear'] as const;
type Command = (typeof COMMANDS)[number];

function isCommand(s: string): s is Command {
  return (COMMANDS as readonly string[]).includes(s);
}

if (!command || command === '--version' || command === '-v') {
  console.log(`workbench v${VERSION}`);
  process.exit(0);
}

if (command === '--help' || command === '-h') {
  printUsage();
  process.exit(0);
}

if (!isCommand(command)) {
  console.error(`workbench: unknown command '${command}'`);
  console.error('');
  printUsage();
  process.exit(1);
}

try {
  switch (command) {
    case 'index':
      await indexCmd(restArgs);
      break;
    case 'status':
      await statusCmd();
      break;
    case 'search':
      await searchCmd(restArgs);
      break;
    case 'clear':
      await clearCmd(restArgs);
      break;
  }
} catch (err) {
  if ((err as NodeJS.ErrnoException).code === 'ERR_MODULE_NOT_FOUND') {
    console.error(
      'workbench: @workbench/core could not be loaded. Run `pnpm run build` from the repo root first.',
    );
    process.exit(1);
  }
  console.error(`workbench: unexpected error — ${(err as Error).message ?? String(err)}`);
  process.exit(1);
}

function printUsage(): void {
  console.log(`workbench v${VERSION} — Workbench Indexer`);
  console.log('');
  console.log('Usage:');
  console.log('  workbench index [path]            Index the codebase');
  console.log('  workbench index --force           Re-index everything');
  console.log('  workbench index --embedder <e>    Use embedder: openai|transformers|ollama');
  console.log('  workbench status                  Show indexer status');
  console.log('  workbench search <query>          Search the index');
  console.log('  workbench search <query> --top N  Return N results');
  console.log('  workbench clear                   Clear the index');
  console.log('  workbench clear --yes             Skip confirmation');
}
