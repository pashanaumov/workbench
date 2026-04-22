export const VERSION = '0.1.0';
export type { Chunk } from './chunker.js';
export { Chunker } from './chunker.js';
export { resolveConfig } from './config-resolver.js';
export type { WorkbenchConfig } from './config-resolver.js';
export { diffManifest, loadManifest, saveManifest } from './manifest.js';
export type { Manifest, ManifestDiff, ManifestEntry } from './manifest.js';
export { VectorStore } from './vector-store.js';
export type { VectorRecord, SearchResult } from './vector-store.js';
export {
  Indexer,
  createEmbedder,
  checkSetupStatus,
  setup,
} from './indexer.js';
export type {
  IndexPhase,
  IndexProgress,
  IndexResult,
  ProgressCallback,
  Embedder,
} from './indexer.js';
