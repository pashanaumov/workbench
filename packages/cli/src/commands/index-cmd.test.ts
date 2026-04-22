/**
 * Tests for index-cmd argument parsing and config flow.
 * Run from repo root:
 *   node --experimental-strip-types --experimental-loader ./packages/core/loader.mjs \
 *     --test packages/cli/src/commands/index-cmd.test.ts
 */

import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import { describe, it } from 'node:test';
import { parseArgs } from 'node:util';
import type { WorkbenchConfig } from '@workbench/core';

// ---------------------------------------------------------------------------
// Helpers that mirror index-cmd argument parsing (extracted for unit testing)
// ---------------------------------------------------------------------------

function parseIndexArgs(rawArgs: string[]): {
  force: boolean;
  embedder: string | undefined;
  projectPath: string;
} {
  const { values, positionals } = parseArgs({
    args: rawArgs,
    options: {
      force: { type: 'boolean', short: 'f', default: false },
      embedder: { type: 'string' },
    },
    allowPositionals: true,
    strict: true,
  });

  return {
    force: values.force ?? false,
    embedder: values.embedder,
    projectPath: resolve(positionals[0] ?? process.cwd()),
  };
}

function buildCliFlags(embedder: string | undefined): Partial<WorkbenchConfig> {
  const flags: Partial<WorkbenchConfig> = {};
  if (embedder) {
    flags.embedder = embedder as WorkbenchConfig['embedder'];
  }
  return flags;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('parseIndexArgs', () => {
  it('--force flag parsed correctly', () => {
    const result = parseIndexArgs(['--force']);
    assert.equal(result.force, true);
  });

  it('--force short flag -f parsed correctly', () => {
    const result = parseIndexArgs(['-f']);
    assert.equal(result.force, true);
  });

  it('force defaults to false when not provided', () => {
    const result = parseIndexArgs([]);
    assert.equal(result.force, false);
  });

  it('--embedder openai sets embedder value', () => {
    const result = parseIndexArgs(['--embedder', 'openai']);
    assert.equal(result.embedder, 'openai');
  });

  it('--embedder transformers sets embedder value', () => {
    const result = parseIndexArgs(['--embedder', 'transformers']);
    assert.equal(result.embedder, 'transformers');
  });

  it('--embedder ollama sets embedder value', () => {
    const result = parseIndexArgs(['--embedder', 'ollama']);
    assert.equal(result.embedder, 'ollama');
  });

  it('embedder defaults to undefined when not provided', () => {
    const result = parseIndexArgs([]);
    assert.equal(result.embedder, undefined);
  });

  it('default path is cwd when no path arg', () => {
    const result = parseIndexArgs([]);
    assert.equal(result.projectPath, resolve(process.cwd()));
  });

  it('explicit path is resolved', () => {
    const result = parseIndexArgs(['/tmp/myproject']);
    assert.equal(result.projectPath, '/tmp/myproject');
  });

  it('relative path is resolved to absolute', () => {
    const result = parseIndexArgs(['./myproject']);
    assert.equal(result.projectPath, resolve('./myproject'));
  });

  it('path and flags can be combined', () => {
    const result = parseIndexArgs(['/some/path', '--force', '--embedder', 'openai']);
    assert.equal(result.projectPath, '/some/path');
    assert.equal(result.force, true);
    assert.equal(result.embedder, 'openai');
  });
});

describe('buildCliFlags', () => {
  it('sets embedder in flags when provided', () => {
    const flags = buildCliFlags('openai');
    assert.deepEqual(flags, { embedder: 'openai' });
  });

  it('returns empty object when no embedder provided', () => {
    const flags = buildCliFlags(undefined);
    assert.deepEqual(flags, {});
  });
});

describe('resolveConfig integration', () => {
  it('--embedder openai overrides default embedder', async () => {
    const { resolveConfig } = await import('@workbench/core');
    const flags = buildCliFlags('openai');
    const config = await resolveConfig(process.cwd(), flags);
    assert.equal(config.embedder, 'openai');
  });

  it('--embedder transformers overrides config embedder', async () => {
    const { resolveConfig } = await import('@workbench/core');
    const flags = buildCliFlags('transformers');
    const config = await resolveConfig(process.cwd(), flags);
    assert.equal(config.embedder, 'transformers');
  });

  it('no embedder flag uses default (transformers)', async () => {
    const { resolveConfig } = await import('@workbench/core');
    const config = await resolveConfig(process.cwd(), {});
    assert.equal(config.embedder, 'transformers');
  });
});

describe('checkSetupStatus error handling', () => {
  it('reports missing model and grammars when dirs do not exist', async () => {
    const { checkSetupStatus } = await import('@workbench/core');
    const status = await checkSetupStatus({
      modelsDir: '/nonexistent/models',
      grammarsDir: '/nonexistent/grammars',
      transformersModel: 'jinaai/jina-embeddings-v2-base-code',
    });
    assert.equal(status.modelReady, false);
    assert.ok(status.grammarsMissing.length > 0);
  });

  it('recognizes that setup is needed when dirs do not exist', async () => {
    const { checkSetupStatus } = await import('@workbench/core');
    // Use non-existent paths so no real cached assets are found
    const status = await checkSetupStatus({
      modelsDir: '/nonexistent/models-xyz-999',
      grammarsDir: '/nonexistent/grammars-xyz-999',
      transformersModel: 'jinaai/jina-embeddings-v2-base-code',
    });
    const needsSetup = !status.modelReady || status.grammarsMissing.length > 0;
    assert.equal(needsSetup, true);
  });
});
