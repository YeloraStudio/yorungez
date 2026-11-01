import type { SkyCatalog, ObserverContext } from "./types.ts";
import type { SkyFrame } from "./frame-contract.ts";
export interface WorkerPort {
  onmessage: ((event: MessageEvent) => void) | null;
  onerror: ((event: ErrorEvent) => void) | null;
  postMessage(message: unknown): void;
  terminate(): void;
}
// One running job and one replaceable pending context: a slow cold worker cannot
// accumulate live ticks forever. Sequence equality still protects manual changes.
export class SkyWorkerClient {
  private port: WorkerPort | null = null;
  private ready = false;
  private running = false;
  private disposed = false;
  private pending: { context: ObserverContext; sequence: number } | null = null;
  private latest: { context: ObserverContext; sequence: number } | null = null;
  private sequence = 0;
  private timer: ReturnType<typeof setTimeout> | undefined;
  private fallbackMode = false;
  private fallbackBuild: typeof import("./frame.ts").buildFrame | null = null;
  private catalog: SkyCatalog;
  private onFrame: (frame: SkyFrame) => void;
  private onState: (state: "initializing" | "calculating" | "ready" | "error") => void;
  private timeoutMs: number;
  constructor(catalog: SkyCatalog, onFrame: (frame: SkyFrame) => void,
    onState: (state: "initializing" | "calculating" | "ready" | "error") => void,
    factory: () => WorkerPort, timeoutMs = 8000) {
    this.catalog=catalog; this.onFrame=onFrame; this.onState=onState; this.timeoutMs=timeoutMs;
    this.onState("initializing");
    try {
      this.port = factory();
      this.port.onmessage = event => this.receive(event.data);
      this.port.onerror = () => { void this.fallback(); };
      this.port.postMessage({ type: "init", catalog });
      this.arm();
    } catch { void this.fallback(); }
  }
  get busy() { return !this.ready || this.running || this.pending !== null; }
  request(context: ObserverContext) {
    if (this.disposed) return;
    this.latest = this.pending = { context, sequence: ++this.sequence };
    this.flush();
  }
  private arm() { clearTimeout(this.timer); this.timer = setTimeout(() => { void this.fallback(); }, this.timeoutMs); }
  private receive(data: { type: string; frame?: SkyFrame; sequence?: number }) {
    if (this.disposed) return;
    if (data.type === "ready") { clearTimeout(this.timer); this.ready = true; this.flush(); return; }
    if (data.type === "error") { void this.fallback(); return; }
    if (data.type !== "frame" || !data.frame) return;
    clearTimeout(this.timer); this.running = false;
    if (data.frame.sequence === this.sequence) { this.onFrame(data.frame); this.onState("ready"); }
    this.flush();
  }
  private flush() {
    if (this.disposed || !this.ready || this.running || !this.pending) return;
    const request = this.pending; this.pending = null; this.running = true; this.onState("calculating"); this.arm();
    if (this.fallbackBuild) {
      try { this.receive({ type: "frame", frame: this.fallbackBuild(this.catalog, request.context, request.sequence) }); }
      catch { clearTimeout(this.timer); this.running = false; this.onState("error"); }
    } else this.port?.postMessage({ type: "calculate", ...request });
  }
  private async fallback() {
    if (this.disposed) return;
    clearTimeout(this.timer);
    if (this.fallbackMode) { this.running = false; this.ready = false; this.onState("error"); return; }
    this.fallbackMode = true; this.port?.terminate(); this.port = null; this.ready = false; this.running = false;
    this.pending = this.latest;
    this.onState("initializing");
    this.timer = setTimeout(() => { if (!this.disposed && !this.ready) this.onState("error"); }, this.timeoutMs);
    try {
      const module = await import("./frame.ts");
      if (this.disposed) return;
      clearTimeout(this.timer); this.fallbackBuild = module.buildFrame; this.ready = true;
      // Last running context is retained by request() below until its result arrives.
      this.flush();
    } catch { clearTimeout(this.timer); if (!this.disposed) this.onState("error"); }
  }
  dispose() { this.disposed = true; clearTimeout(this.timer); this.port?.terminate(); this.pending = null; }
}
