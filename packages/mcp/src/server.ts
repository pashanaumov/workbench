import type { Indexer, WorkbenchConfig } from '@workbench/core';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';

// ---------------------------------------------------------------------------
// DI interface
// ---------------------------------------------------------------------------

export interface ServerDeps {
  resolveConfig?: (projectPath: string) => Promise<WorkbenchConfig>;
  createIndexer?: (config: WorkbenchConfig) => Indexer | Promise<Indexer>;
  checkSetupStatus?: (
    config: Pick<WorkbenchConfig, 'modelsDir' | 'grammarsDir' | 'transformersModel'>,
  ) => Promise<{ modelReady: boolean; grammarsMissing: string[] }>;
  startWatcher?: (
    projectPath: string,
    indexFn: () => Promise<void>,
    opts: { debounceMs: number },
  ) => void;
}

// ---------------------------------------------------------------------------
// Project root detection
// ---------------------------------------------------------------------------

export async function detectProjectRoot(): Promise<string> {
  const envPath = process.env['WORKBENCH_PROJECT_PATH'];
  if (envPath) return envPath;

  let dir = process.cwd();
  while (true) {
    if (existsSync(join(dir, '.git'))) return dir;
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return process.cwd();
}

// ---------------------------------------------------------------------------
// Default implementations (lazy-loaded to avoid heavy deps at startup)
// ---------------------------------------------------------------------------

async function defaultResolveConfig(projectPath: string): Promise<WorkbenchConfig> {
  const { resolveConfig } = await import('@workbench/core');
  return resolveConfig(projectPath);
}

async function defaultCreateIndexer(config: WorkbenchConfig): Promise<Indexer> {
  const { createEmbedder, Chunker, VectorStore, Indexer: IndexerClass } = await import('@workbench/core');
  const embedder = createEmbedder(config);
  const vectorStore = new VectorStore(config);
  const chunker = new Chunker(config);
  return new IndexerClass(config, embedder, vectorStore, chunker);
}

async function defaultCheckSetupStatus(
  config: Pick<WorkbenchConfig, 'modelsDir' | 'grammarsDir' | 'transformersModel'>,
): Promise<{ modelReady: boolean; grammarsMissing: string[] }> {
  const { checkSetupStatus } = await import('@workbench/core');
  return checkSetupStatus(config);
}

function defaultStartWatcher(
  projectPath: string,
  indexFn: () => Promise<void>,
  opts: { debounceMs: number },
): void {
  import('chokidar').then(({ watch }) => {
    let debounceTimer: NodeJS.Timeout | undefined;
    let indexing = false;

    const watcher = watch(projectPath, {
      ignored: /(^|[/\\])(\.git|node_modules|dist)($|[/\\])/,
      persistent: false,
      ignoreInitial: true,
    });

    watcher.on('all', () => {
      if (debounceTimer) clearTimeout(debounceTimer);
      debounceTimer = setTimeout(async () => {
        if (indexing) return;
        indexing = true;
        try { await indexFn(); } finally { indexing = false; }
      }, opts.debounceMs);
    });
  }).catch(() => {
    // chokidar unavailable — skip watcher
  });
}

// ---------------------------------------------------------------------------
// Server factory
// ---------------------------------------------------------------------------

export function createServer(deps: ServerDeps = {}): Server {
  const {
    resolveConfig = defaultResolveConfig,
    createIndexer = defaultCreateIndexer,
    checkSetupStatus = defaultCheckSetupStatus,
    startWatcher = defaultStartWatcher,
  } = deps;

  const server = new Server(
    { name: 'workbench-indexer', version: '0.1.0' },
    { capabilities: { tools: {} } },
  );

  // Lazy singleton state
  let indexer: Indexer | null = null;
  let currentConfig: WorkbenchConfig | null = null;
  let watcherStarted = false;
  let lastStatus: { filesCount: number; chunksCount: number } | null = null;

  async function getIndexer(projectPath: string): Promise<{ idx: Indexer; cfg: WorkbenchConfig }> {
    if (indexer && currentConfig) return { idx: indexer, cfg: currentConfig };
    currentConfig = await resolveConfig(projectPath);
    indexer = await createIndexer(currentConfig);
    return { idx: indexer, cfg: currentConfig };
  }

  // ------------------------------------------------------------------
  // Tool list
  // ------------------------------------------------------------------

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
      {
        name: 'index_codebase',
        description: 'Index the current codebase for semantic search. Run this before searching.',
        inputSchema: {
          type: 'object' as const,
          properties: {
            path: { type: 'string', description: 'Project root path (defaults to auto-detected)' },
            force: { type: 'boolean', description: 'Re-index all files even if unchanged' },
          },
        },
      },
      {
        name: 'search_code',
        description: 'Search the indexed codebase using semantic + keyword hybrid search.',
        inputSchema: {
          type: 'object' as const,
          required: ['query'],
          properties: {
            query: { type: 'string', description: 'Search query' },
            topK: { type: 'number', description: 'Number of results (default 5)' },
          },
        },
      },
      {
        name: 'clear_index',
        description: 'Clear the search index for the current project.',
        inputSchema: { type: 'object' as const, properties: {} },
      },
      {
        name: 'get_indexing_status',
        description: 'Check whether the codebase has been indexed and when.',
        inputSchema: { type: 'object' as const, properties: {} },
      },
    ],
  }));

  // ------------------------------------------------------------------
  // Tool calls
  // ------------------------------------------------------------------

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args = {} } = request.params;

    try {
      switch (name) {
        case 'index_codebase': {
          const { path: pathArg } = args as { path?: string; force?: boolean };
          const projectPath = pathArg ?? await detectProjectRoot();
          const { idx, cfg } = await getIndexer(projectPath);
          const result = await idx.index(projectPath);
          lastStatus = { filesCount: result.filesIndexed, chunksCount: result.chunksIndexed };

          if (cfg.watchEnabled && !watcherStarted) {
            startWatcher(projectPath, async () => { await idx.index(projectPath); }, { debounceMs: cfg.watchDebounceMs });
            watcherStarted = true;
          }

          return {
            content: [{
              type: 'text' as const,
              text: JSON.stringify({
                filesIndexed: result.filesIndexed,
                chunksIndexed: result.chunksIndexed,
                durationMs: result.durationMs,
                errors: result.errors,
              }),
            }],
          };
        }

        case 'search_code': {
          const { query, topK } = args as { query?: string; topK?: number };
          if (!query) {
            return {
              content: [{ type: 'text' as const, text: JSON.stringify({ error: 'query parameter is required' }) }],
              isError: true,
            };
          }
          const projectPath = await detectProjectRoot();
          const { idx } = await getIndexer(projectPath);
          const results = await idx.search(query, topK);
          return {
            content: [{
              type: 'text' as const,
              text: JSON.stringify(results.map(r => ({
                file: r.filePath,
                startLine: r.startLine,
                endLine: r.endLine,
                content: r.body,
                score: r.score,
                language: r.language,
              }))),
            }],
          };
        }

        case 'clear_index': {
          const projectPath = await detectProjectRoot();
          const { idx } = await getIndexer(projectPath);
          await idx.clear(projectPath);
          indexer = null;
          lastStatus = null;
          watcherStarted = false;
          return {
            content: [{ type: 'text' as const, text: JSON.stringify({ cleared: true }) }],
          };
        }

        case 'get_indexing_status': {
          const projectPath = await detectProjectRoot();
          const cfg = currentConfig ?? await resolveConfig(projectPath);
          const { modelReady, grammarsMissing } = await checkSetupStatus(cfg);
          return {
            content: [{
              type: 'text' as const,
              text: JSON.stringify({
                indexed: lastStatus !== null,
                filesCount: lastStatus?.filesCount ?? 0,
                chunksCount: lastStatus?.chunksCount ?? 0,
                modelReady,
                grammarsMissing,
              }),
            }],
          };
        }

        default:
          return {
            content: [{ type: 'text' as const, text: JSON.stringify({ error: `Unknown tool: ${name}` }) }],
            isError: true,
          };
      }
    } catch (err) {
      return {
        content: [{ type: 'text' as const, text: JSON.stringify({ error: String(err) }) }],
        isError: true,
      };
    }
  });

  return server;
}
