import cliProgress from 'cli-progress';
import ora, { type Ora } from 'ora';

// SetupProgress mirrors the type from @workbench/core/setup (not re-exported at top level)
interface SetupProgress {
  phase: 'model' | 'grammars' | 'done';
  item: string;
  bytesTotal: number;
  bytesDone: number;
  skipped: boolean;
}

// ---------------------------------------------------------------------------
// Setup spinner (ora)
// ---------------------------------------------------------------------------

export class SetupSpinner {
  private spinner: Ora | null = null;
  private currentPhase: string | null = null;

  onProgress(progress: SetupProgress): void {
    if (progress.phase === 'done') {
      this.spinner?.succeed('Setup complete');
      this.spinner = null;
      this.currentPhase = null;
      return;
    }

    if (progress.skipped) return;

    const phaseLabel = progress.phase === 'model' ? 'Downloading model' : 'Downloading grammars';
    const key = `${progress.phase}:${progress.item}`;

    if (this.currentPhase !== key) {
      const sizeHint =
        progress.bytesTotal > 0 ? ` (${(progress.bytesTotal / 1_048_576).toFixed(0)} MB)` : '';
      const text = `${phaseLabel}: ${progress.item}${sizeHint}...`;
      if (this.spinner) {
        this.spinner.succeed();
        this.spinner.text = text;
        this.spinner.start();
      } else {
        this.spinner = ora(text).start();
      }
      this.currentPhase = key;
    } else if (progress.bytesTotal > 0 && this.spinner) {
      const pct = Math.round((progress.bytesDone / progress.bytesTotal) * 100);
      const sizeHint = ` (${(progress.bytesTotal / 1_048_576).toFixed(0)} MB)`;
      this.spinner.text = `${phaseLabel}: ${progress.item}${sizeHint} ${pct}%`;
    }
  }

  finalize(): void {
    this.spinner?.succeed();
    this.spinner = null;
  }
}

// ---------------------------------------------------------------------------
// Index multi-bar (cli-progress)
// ---------------------------------------------------------------------------

export interface IndexBars {
  scanBar: cliProgress.SingleBar;
  embedBar: cliProgress.SingleBar;
  multiBar: cliProgress.MultiBar;
  start(filesTotal: number, chunksTotal: number): void;
  updateScan(done: number, total: number): void;
  updateEmbed(done: number, total: number): void;
  stop(): void;
}

export function createIndexBars(): IndexBars {
  const multiBar = new cliProgress.MultiBar(
    {
      clearOnComplete: false,
      hideCursor: true,
      format: '  {bar} {percentage}% | {value}/{total} | {label}',
    },
    cliProgress.Presets.shades_classic,
  );

  const scanBar = multiBar.create(1, 0, { label: 'files scanned' });
  const embedBar = multiBar.create(1, 0, { label: 'chunks embedded' });

  return {
    scanBar,
    embedBar,
    multiBar,
    start(filesTotal: number, chunksTotal: number) {
      scanBar.setTotal(Math.max(filesTotal, 1));
      embedBar.setTotal(Math.max(chunksTotal, 1));
    },
    updateScan(done: number, total: number) {
      scanBar.setTotal(Math.max(total, 1));
      scanBar.update(done, { label: 'files scanned' });
    },
    updateEmbed(done: number, total: number) {
      embedBar.setTotal(Math.max(total, 1));
      embedBar.update(done, { label: 'chunks embedded' });
    },
    stop() {
      multiBar.stop();
    },
  };
}
