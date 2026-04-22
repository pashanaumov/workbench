# Workbench Indexer — Testing & Usage Guide

A local, fully offline codebase indexer that gives Claude Code (and any MCP-compatible agent)
**semantic + keyword hybrid search** over your repo.  
No cloud. No running server. Embeddings stay on disk in `~/.workbench/<project-hash>/`.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)  
2. [Installation](#2-installation)  
3. [First Run (Setup)](#3-first-run-setup)  
4. [CLI Reference](#4-cli-reference)  
5. [MCP Server — Claude Code Integration](#5-mcp-server--claude-code-integration)  
6. [Monitoring & Observability](#6-monitoring--observability)  
7. [Configuration](#7-configuration)  
8. [Benchmarking & Token-Savings Validation](#8-benchmarking--token-savings-validation)  
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

| Requirement | Minimum | Notes |
|---|---|---|
| Node.js | 22 | Uses `--experimental-strip-types` |
| pnpm | 9+ | `npm i -g pnpm` |
| Disk space | ~500 MB | ONNX model (~154 MB) + LanceDB index |
| RAM | 2 GB | For ONNX inference during indexing |

No GPU required — the quantised ONNX model runs on CPU.

---

## 2. Installation

### From the repo (development)

```bash
git clone https://github.com/pashanaumov/workbench
cd workbench
pnpm install
pnpm run build          # compiles all three packages
```

Add the `bin/` directory to your `PATH` so the `wb` command is available:

```bash
export PATH="$PWD/bin:$PATH"   # add to ~/.zshrc or ~/.bashrc for persistence
wb --help
```

### Verify the build

```bash
wb status               # should say "No index found" (that's fine)
wb index --help         # shows usage
```

---

## 3. First Run (Setup)

The first `wb index` run automatically downloads:

- **jina-embeddings-v2-base-code** ONNX model (~154 MB) → `~/.workbench/models/`  
- **tree-sitter grammar WASMs** for TypeScript, JavaScript, Python, Rust, Go, Java, C, C++, Ruby (~2 MB total) → `~/.workbench/grammars/`

Downloads happen once; subsequent runs skip them.

```bash
wb index /path/to/your/project
```

You'll see two progress bars: one for the download, one for chunk embedding.

**Speed expectations** (transformers/CPU, jina-embeddings-v2-base-code):

| Repo size | Files | Chunks | Time |
|---|---|---|---|
| Small (e.g. a single package) | ~50 | ~200 | 5–15 s |
| Medium (e.g. this workbench repo) | ~300 | ~1 500 | 60–120 s |
| Large (e.g. 10 kloc TypeScript) | ~800 | ~4 000 | 300–600 s |

Switch to OpenAI embeddings for 5–20× faster indexing:

```bash
export OPENAI_API_KEY=sk-...
wb index /path/to/project --embedder openai
```

---

## 4. CLI Reference

### `wb index [path] [--force] [--embedder <name>]`

Index (or incrementally update) a project.

```bash
wb index                          # index current directory
wb index ~/projects/my-app        # index a specific path
wb index --force                  # re-index all files (ignore cached manifest)
wb index --embedder openai        # use OpenAI instead of local model
wb index --embedder ollama        # use Ollama (must be running locally)
```

Incremental behaviour: only files whose **mtime or size** changed since last
run are re-embedded. A 300-file repo with 5 changed files re-indexes in under 2 s.

---

### `wb search <query> [--top N]`

Run a hybrid (semantic + keyword) search.

```bash
wb search "jwt token validation"
wb search "sql connection pooling" --top 10
wb search "react useEffect cleanup"
```

Output format per result:

```
── src/auth/token.ts:42-68 ──────────────────────────────────────
src/auth/token.ts > validateJwtToken
score: 0.847

export function validateJwtToken(token: string): JwtPayload {
  ...
}
```

`score` is the RRF-fused relevance score (higher = more relevant).

---

### `wb status`

Show index health for the current directory.

```bash
wb status
```

Example output:

```
Index status for: /Users/you/projects/my-app
  Provider:     transformers (jina-embeddings-v2-base-code)
  Last indexed: 3 minutes ago
  Files:        312
  Chunks:       1 847
  Index path:   ~/.workbench/a3f9c12e04b1/
```

---

### `wb clear`

Delete the index for the current project (keeps the downloaded model/grammars).

```bash
wb clear
```

---

## 5. MCP Server — Claude Code Integration

The MCP server exposes four tools to Claude Code:

| Tool | Description |
|---|---|
| `index_codebase` | Index (or re-index) the project |
| `search_code` | Semantic + keyword hybrid search |
| `get_indexing_status` | Check if indexed, last run time |
| `clear_index` | Delete the stored index |

### Setup

1. **Build the packages** (if not already done):
   ```bash
   pnpm install && pnpm run build
   ```

2. **Register the MCP server** in your Claude Code config  
   (`~/.config/claude/claude_desktop_config.json` on macOS):

   ```json
   {
     "mcpServers": {
       "workbench-indexer": {
         "command": "node",
         "args": ["/absolute/path/to/workbench/packages/mcp/dist/index.js"],
         "env": {
           "WORKBENCH_PROJECT_PATH": "/absolute/path/to/your/project"
         }
       }
     }
   }
   ```

   Omit `WORKBENCH_PROJECT_PATH` to let the server auto-detect the project root by
   walking up from `process.cwd()` until it finds a `.git` directory.

3. **Restart Claude Code** — the `workbench-indexer` tools will appear.

4. **First use**: ask Claude Code to run `index_codebase`. This triggers the same
   first-run setup as the CLI.

### OpenAI embeddings via MCP

Set `OPENAI_API_KEY` in the env block, then ask Claude to
`index_codebase` with `{"force": false}` — or add to `.workbench.json`:

```json
{ "embedder": "openai" }
```

---

## 6. Monitoring & Observability

### Stats file

After every successful `wb index` run a `stats.json` is written to the index directory:

```bash
cat ~/.workbench/$(wb status | grep 'Index path' | awk '{print $NF}')/stats.json
```

```json
{
  "lastIndexedAt": "2026-04-22T17:42:23.290Z",
  "chunkCount": 1847
}
```

`wb status` reads this file and formats it as "N minutes ago".

### Index directory layout

```
~/.workbench/<12-char-sha256-of-project-path>/
├── chunks.lance/          # LanceDB table (vector + FTS)
│   ├── _versions/
│   └── data-*.lance
├── manifest.json          # per-file mtime + size + sha256 cache
└── stats.json             # last-indexed timestamp + chunk count
```

### Verbose indexer output

Set `WB_DEBUG=1` to pipe stderr from the indexer to your terminal — useful to see
per-file warnings (e.g. token-limit truncation, missing grammar fallback):

```bash
WB_DEBUG=1 wb index --force 2>&1 | head -50
```

Warnings to watch for:

| Warning | Meaning |
|---|---|
| `[chunker] WARNING: grammar not found for 'X'` | Grammar WASM missing; file chunked by sliding window |
| `[chunker] WARNING: chunk exceeds token limit` | Chunk truncated to 512 tokens |

### Incremental update latency

Monitor how quickly the indexer catches file changes:

```bash
time wb index .          # second run — should be <2 s for unchanged repos
touch src/some-file.ts
time wb index .          # re-indexes only that one file
```

---

## 7. Configuration

Create `.workbench.json` in your project root (or `~/.workbench/config.json` for global
defaults):

```json
{
  "embedder": "transformers",
  "chunkMaxLines": 50,
  "chunkMaxTokens": 512,
  "chunkStrategy": "function",
  "concurrency": 10,
  "searchTopK": 5,
  "ignorePatterns": ["fixtures/", "*.generated.ts"],
  "watchEnabled": false
}
```

Priority order (highest wins): CLI flags → `.workbench.json` → `~/.workbench/config.json` → built-in defaults.

`ignorePatterns` is **additive** — patterns from all layers are merged (never replaced).

### Embedder options

| Value | Speed | Cost | Notes |
|---|---|---|---|
| `transformers` | ~87 chunks/s (CPU) | Free | Default; jina-embeddings-v2-base-code, 768 dims |
| `openai` | ~2 000 chunks/s | $0.02/1M tokens | Requires `OPENAI_API_KEY`; `text-embedding-3-small` |
| `ollama` | Depends on model | Free | Requires Ollama running at `http://localhost:11434` |

---

## 8. Benchmarking & Token-Savings Validation

Run the benchmark script to measure search quality and quantify token savings:

```bash
node --experimental-strip-types scripts/benchmark.ts [project-path] [--queries queries.json]
```

Or use the defaults (queries the current repo):

```bash
pnpm run bench          # runs benchmark on the workbench repo itself
```

### What the benchmark measures

1. **Search quality** — precision@3: does a relevant file appear in the top 3 results?
2. **Token savings** — compares tokens served by the indexer against two baselines:
   - *Whole-file baseline*: reading the single most-relevant file in full
   - *Whole-repo baseline*: reading every source file (simulating a grep-all approach)

### Understanding token savings

Without the indexer, an LLM agent typically has two options when asked about code:

| Strategy | Token cost | Problem |
|---|---|---|
| `read_file` on a guessed file | 1 file × avg_file_tokens | Wrong file → wasted tokens |
| Scan all files | all_files × avg_file_tokens | Extremely expensive |

With the indexer, the agent gets:

```
search_code("jwt token validation") → top-5 chunks × avg_chunk_tokens
```

A chunk is typically 20–80 lines (a function or sliding window), versus a file that may
be 200–1 000 lines. Across a medium-sized repo the savings are typically **85–97%**.

### Validating savings manually

```bash
# Step 1: index your project
wb index /path/to/project

# Step 2: run a search and note the returned chunks
wb search "database connection pool" --top 5

# Step 3: count tokens in the returned body text (approx: chars ÷ 4)
wb search "database connection pool" --top 5 \
  | awk '/^score:/{next} /^──/{next} {chars += length($0)} END {print "chunk chars:", chars, "≈ tokens:", int(chars/4)}'

# Step 4: compare to the full file
wc -c src/db/pool.ts   # file size in bytes ≈ tokens * 4

# Step 5: compare to the whole repo
find src -name '*.ts' | xargs wc -c | tail -1   # total bytes
```

The benchmark script automates steps 2–5 across a set of representative queries and
prints a summary table.

---

## 9. Troubleshooting

### `Error: Workbench indexer not built`

```bash
pnpm install && pnpm run build
```

### `wb index` shows no progress / hangs on "Running first-time setup"

First-time model download is ~154 MB. Check network:

```bash
curl -I https://huggingface.co/jinaai/jina-embeddings-v2-base-code/resolve/main/onnx/model_quantized.onnx
```

If behind a corporate proxy, set `HTTPS_PROXY`.

### `No index found. Run wb index first.`

The LanceDB table doesn't exist yet. Run `wb index <project-path>`.

### Slow search (>3 s)

LanceDB's Rust binary has a ~100 ms cold-start. The first search in a session is slower;
subsequent searches are fast (<50 ms). This is normal.

### `grammar not found for 'X'` warnings

The grammar WASM for language X wasn't downloaded. Re-run setup:

```bash
wb index --force       # re-runs setup check and downloads missing grammars
```

Or download manually:

```bash
curl -L "https://github.com/tree-sitter/tree-sitter-X/releases/latest/download/tree-sitter-X.wasm" \
  -o ~/.workbench/grammars/tree-sitter-X.wasm
```

### OpenAI embedder: `Authentication error`

```bash
echo $OPENAI_API_KEY   # must be set
wb index --embedder openai
```

### Ollama embedder: `fetch failed`

Ensure Ollama is running and the model is pulled:

```bash
ollama serve &
ollama pull nomic-embed-text
wb index --embedder ollama
```

If your model has different dimensions than the default 768, set in `.workbench.json`:

```json
{ "embedder": "ollama", "ollamaModel": "mxbai-embed-large", "ollamaDimensions": 1024 }
```

### Clearing a corrupt index

```bash
wb clear                                   # removes LanceDB table + manifest
# or manually:
rm -rf ~/.workbench/<project-hash>/
```
