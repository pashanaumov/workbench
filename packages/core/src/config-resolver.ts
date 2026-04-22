import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';

export interface WorkbenchConfig {
  // Indexer paths
  indexDir: string;
  modelsDir: string;
  grammarsDir: string;

  // Embedder
  embedder: 'transformers' | 'openai' | 'ollama';
  openaiApiKey?: string;
  openaiModel: string;
  ollamaBaseUrl: string;
  ollamaModel: string;
  transformersModel: string;

  // Chunker
  chunkMaxLines: number;
  chunkOverlap: number;
  chunkStrategy: 'sliding-window' | 'function';
  chunkMaxTokens: number;

  // Indexer pipeline
  concurrency: number;
  batchSize: number;

  // Search
  searchTopK: number;

  // File watcher
  watchEnabled: boolean;
  watchDebounceMs: number;

  // Ignored paths (merged, not replaced)
  ignorePatterns: string[];
}

const DEFAULT_IGNORE_PATTERNS: string[] = [
  'node_modules', '.git', 'dist', 'build', 'out', '__pycache__',
  '.next', '.nuxt', 'coverage', '*.min.js', '*.d.ts', '*.map',
  '*.lock', '*.snap', '.DS_Store',
];

function projectHash(absPath: string): string {
  return createHash('sha256').update(absPath).digest('hex').slice(0, 12);
}

function buildDefaults(projectPath: string, home: string): WorkbenchConfig {
  const hash = projectHash(resolve(projectPath));
  return {
    indexDir: join(home, '.workbench', hash),
    modelsDir: join(home, '.workbench', 'models'),
    grammarsDir: join(home, '.workbench', 'grammars'),
    embedder: 'transformers',
    openaiModel: 'text-embedding-3-small',
    ollamaBaseUrl: 'http://localhost:11434',
    ollamaModel: 'nomic-embed-text',
    transformersModel: 'jinaai/jina-embeddings-v2-base-code',
    chunkMaxLines: 50,
    chunkOverlap: 0.2,
    chunkStrategy: 'function',
    chunkMaxTokens: 512,
    concurrency: 10,
    batchSize: 32,
    searchTopK: 5,
    watchEnabled: false,
    watchDebounceMs: 2000,
    ignorePatterns: [...DEFAULT_IGNORE_PATTERNS],
  };
}

async function readJsonConfig(filePath: string): Promise<Partial<WorkbenchConfig> | null> {
  try {
    const content = await readFile(filePath, 'utf-8');
    return JSON.parse(content) as Partial<WorkbenchConfig>;
  } catch {
    return null;
  }
}

async function findProjectConfig(startDir: string): Promise<Partial<WorkbenchConfig> | null> {
  let dir = resolve(startDir);
  while (true) {
    const config = await readJsonConfig(join(dir, '.workbench.json'));
    if (config !== null) return config;
    const parent = dirname(dir);
    if (parent === dir) break; // filesystem root
    dir = parent;
  }
  return null;
}

// Strip undefined values so partial spreads don't clobber resolved values.
function defined<T extends object>(obj: Partial<T>): Partial<T> {
  return Object.fromEntries(
    Object.entries(obj).filter(([, v]) => v !== undefined),
  ) as Partial<T>;
}

export async function resolveConfig(
  projectPath: string,
  cliFlags?: Partial<WorkbenchConfig>,
  homeDir?: string,
): Promise<WorkbenchConfig> {
  const home = homeDir ?? homedir();
  const defaults = buildDefaults(projectPath, home);

  const [globalConfig, projectConfig] = await Promise.all([
    readJsonConfig(join(home, '.workbench', 'config.json')),
    findProjectConfig(projectPath),
  ]);

  const flags = cliFlags ? defined(cliFlags) : {};

  // ignorePatterns: union from all layers (never replace, always grow)
  const ignorePatterns = [
    ...new Set([
      ...defaults.ignorePatterns,
      ...(globalConfig?.ignorePatterns ?? []),
      ...(projectConfig?.ignorePatterns ?? []),
      ...(flags.ignorePatterns ?? []),
    ]),
  ];

  const merged: WorkbenchConfig = {
    ...defaults,
    ...(globalConfig ? defined(globalConfig) : {}),
    ...(projectConfig ? defined(projectConfig) : {}),
    ...flags,
    ignorePatterns,
  };

  // openaiApiKey: fall through to env var if not set by any config source
  if (!merged.openaiApiKey) {
    const envKey = process.env['OPENAI_API_KEY'];
    if (envKey) merged.openaiApiKey = envKey;
  }

  return merged;
}
