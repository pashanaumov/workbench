import type { WorkbenchConfig } from './config-resolver.js';
import type { FeatureExtractionPipeline } from '@huggingface/transformers';

export interface Embedder {
  embed(texts: string[]): Promise<number[][]>;
  readonly dimensions: number;
}

// ---------------------------------------------------------------------------
// TransformersEmbedder
// ---------------------------------------------------------------------------

export class TransformersEmbedder implements Embedder {
  private readonly model: string;
  private readonly cacheDir: string;
  private readonly batchSize: number;
  private pipeline: FeatureExtractionPipeline | null = null;

  constructor(config: Pick<WorkbenchConfig, 'transformersModel' | 'modelsDir' | 'batchSize'>) {
    this.model = config.transformersModel;
    this.cacheDir = config.modelsDir;
    this.batchSize = config.batchSize;
  }

  private async getPipeline(): Promise<FeatureExtractionPipeline> {
    if (this.pipeline) return this.pipeline;
    const { pipeline, env } = await import('@huggingface/transformers');
    env.cacheDir = this.cacheDir;
    this.pipeline = await pipeline('feature-extraction', this.model, { dtype: 'q8' });
    return this.pipeline;
  }

  async embed(texts: string[]): Promise<number[][]> {
    const pipe = await this.getPipeline();
    const results: number[][] = [];
    for (let i = 0; i < texts.length; i += this.batchSize) {
      const batch = texts.slice(i, i + this.batchSize);
      const output = await pipe(batch, { pooling: 'mean', normalize: true }) as { data: Float32Array; dims: number[] };
      const [batchSize, dims] = [output.dims[0]!, output.dims[1]!];
      for (let b = 0; b < batchSize; b++) {
        results.push(Array.from(output.data.slice(b * dims, (b + 1) * dims)));
      }
    }
    return results;
  }

  get dimensions(): number {
    return 768;
  }
}

// ---------------------------------------------------------------------------
// OpenAIEmbedder
// ---------------------------------------------------------------------------

type EmbeddingsCreateFn = (opts: { model: string; input: string[] }) => Promise<{ data: Array<{ embedding: number[] }> }>;

export class OpenAIEmbedder implements Embedder {
  private readonly apiKey: string | undefined;
  private readonly model: string;
  private readonly batchSize: number;
  // Allows injection of a mock client in tests
  private readonly createFn: EmbeddingsCreateFn | null;

  constructor(
    config: Pick<WorkbenchConfig, 'openaiApiKey' | 'openaiModel' | 'batchSize'>,
    createFn?: EmbeddingsCreateFn,
  ) {
    this.apiKey = config.openaiApiKey;
    this.model = config.openaiModel;
    this.batchSize = config.batchSize;
    this.createFn = createFn ?? null;
  }

  private async getCreateFn(): Promise<EmbeddingsCreateFn> {
    if (this.createFn) return this.createFn;
    const { default: OpenAI } = await import('openai');
    const client = new OpenAI({ apiKey: this.apiKey });
    return client.embeddings.create.bind(client.embeddings);
  }

  async embed(texts: string[]): Promise<number[][]> {
    const create = await this.getCreateFn();
    const results: number[][] = [];
    for (let i = 0; i < texts.length; i += this.batchSize) {
      const batch = texts.slice(i, i + this.batchSize);
      const response = await create({ model: this.model, input: batch });
      for (const item of response.data) {
        results.push(item.embedding);
      }
    }
    return results;
  }

  get dimensions(): number {
    return 1536;
  }
}

// ---------------------------------------------------------------------------
// OllamaEmbedder
// ---------------------------------------------------------------------------

export class OllamaEmbedder implements Embedder {
  private readonly baseUrl: string;
  private readonly model: string;
  private readonly batchSize: number;
  private _dimensions: number | null = null;

  constructor(config: Pick<WorkbenchConfig, 'ollamaBaseUrl' | 'ollamaModel' | 'batchSize'>) {
    this.baseUrl = config.ollamaBaseUrl;
    this.model = config.ollamaModel;
    this.batchSize = config.batchSize;
  }

  async embed(texts: string[]): Promise<number[][]> {
    const results: number[][] = [];
    for (let i = 0; i < texts.length; i += this.batchSize) {
      const batch = texts.slice(i, i + this.batchSize);
      for (const text of batch) {
        const response = await fetch(`${this.baseUrl}/api/embeddings`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: this.model, prompt: text }),
        });
        const data = await response.json() as { embedding: number[] };
        if (this._dimensions === null) {
          this._dimensions = data.embedding.length;
        }
        results.push(data.embedding);
      }
    }
    return results;
  }

  get dimensions(): number {
    if (this._dimensions === null) {
      throw new Error('OllamaEmbedder: dimensions not yet known — call embed() first');
    }
    return this._dimensions;
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

export function createEmbedder(config: WorkbenchConfig): Embedder {
  switch (config.embedder) {
    case 'openai':
      return new OpenAIEmbedder(config);
    case 'ollama':
      return new OllamaEmbedder(config);
    case 'transformers':
    default:
      return new TransformersEmbedder(config);
  }
}
