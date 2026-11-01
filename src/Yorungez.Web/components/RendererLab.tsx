"use client";
import { useRef, useState } from "react";
import { buildFrame } from "../lib/sky/frame.ts";
import { projector } from "../lib/sky/projection.ts";
import { createRenderer } from "../lib/sky/renderers.ts";
import type { RendererKind } from "../lib/sky/renderers.ts";
import type { Language, SkyCatalog } from "../lib/sky/types.ts";

export default function RendererLab({ language }: { language: Language }) {
  const host = useRef<HTMLDivElement>(null), [running, setRunning] = useState(false), [result, setResult] = useState<unknown>(null);
  const tr = language === "tr";
  async function run() {
    setRunning(true); setResult(null);
    try {
      const snapshot = await fetch("/api/catalog").then(r => r.json());
      const catalog = snapshot.catalog as SkyCatalog;
      const frame = buildFrame(catalog, { latitude: 41.0082, longitude: 28.9784, elevationMeters: 0, instantUtc: "2026-10-30T20:00:00Z" }, 1);
      const width = Math.round(host.current!.clientWidth), height = Math.round(host.current!.clientHeight), dpr = Math.min(devicePixelRatio || 1, 2);
      const count = catalog.stars.length + 9, points = new Float32Array(count * 2), radii = new Float32Array(count).fill(1.5), colors = Array<string>(count).fill("#d8e7fa");
      const records = [];
      for (const kind of ["canvas", "svg", "webgl"] as RendererKind[]) {
        let renderer: ReturnType<typeof createRenderer> | null = null;
        try {
          renderer = createRenderer(kind); renderer.element.classList.add("star-surface"); host.current!.appendChild(renderer.element);
          const draw = [], intervals = []; let prior = 0;
          for (let i = 0; i < 150; i++) {
            const tick = await new Promise<number>(resolve => requestAnimationFrame(resolve));
            const start = performance.now();
            const project = projector({ azimuth: 160 + i * 0.3, altitude: 30, fieldOfView: 105 }, width, height);
            points.fill(NaN);
            for (let j = 0; j < count; j++) {
              const p = project(frame.vectors[j * 3], frame.vectors[j * 3 + 1], frame.vectors[j * 3 + 2]);
              if (p) { points[j * 2] = p[0]; points[j * 2 + 1] = p[1]; }
            }
            renderer.draw({ points, radii, colors, count, width, height, dpr });
            if (i >= 30) { draw.push(performance.now() - start); intervals.push(tick - prior); }
            prior = tick;
          }
          draw.sort((a,b) => a-b); intervals.sort((a,b) => a-b);
          records.push({ renderer: kind, status: "measured", warmupFrames: 30, measuredFrames: draw.length,
            cpuP50Milliseconds: draw[59], cpuP95Milliseconds: draw[113], frameIntervalP95Milliseconds: intervals[113],
            intervalsOver25ms: intervals.filter(n => n > 25).length });
        } catch (error) { records.push({ renderer: kind, status: "unavailable", reason: error instanceof Error ? error.message : "error" }); }
        finally { renderer?.dispose(); }
      }
      setResult({ schemaVersion: 1, generatedAtUtc: new Date().toISOString(), profile: process.env.NODE_ENV,
        viewport: { width, height, dpr }, catalogVersion: catalog.version, catalogSha256: snapshot.provenance.derivedSha256,
        starsAndPlanets: count, frameCalculationMilliseconds: frame.durationMilliseconds,
        scope: "Browser, fixed synthetic observer, shared CPU projection + star layer only. rAF includes browser scheduling; draw time is CPU submission, not GPU completion. No physical mobile device or production load test.", records });
    } finally { setRunning(false); }
  }
  return <main className="renderer-lab"><a href={`/${language}`}>← yorungez</a><h1>{tr ? "Çizim motoru denemesi" : "Renderer experiment"}</h1>
    <p>{tr ? "Aynı katalog, bakış ve kare sayısı: Canvas 2D, SVG, WebGL. Bu sayfa yalnızca yerel doğrulama içindir." : "Same catalogue, camera and frame count: Canvas 2D, SVG, WebGL. This page is for local validation only."}</p>
    <button className="primary-button" disabled={running} onClick={run}>{running ? tr ? "Ölçülüyor…" : "Measuring…" : tr ? "Denemeyi çalıştır" : "Run experiment"}</button>
    <div ref={host} className="lab-surface" />
    {result !== null && <pre data-testid="benchmark-result">{JSON.stringify(result, null, 2)}</pre>}
  </main>;
}
