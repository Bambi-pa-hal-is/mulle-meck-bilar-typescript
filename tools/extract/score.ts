import { DirectorFile } from "./riff.ts";
import { decodeText } from "./stream.ts";

/** One sprite channel's state over a run of frames. */
export interface SpriteSpan {
  ch: number;              // sprite channel number (1-based, like Lingo)
  start: number; end: number; // frames inclusive
  castLib: number; member: number;
  ink: number; trails?: boolean; stretch?: boolean;
  locH: number; locV: number; width: number; height: number;
  fore: number; back: number; blend: number;
  behaviors?: { castLib: number; member: number; params?: string }[];
  iv?: number;             // score interval index – behaviors persist while it is unchanged
}

export interface Score {
  frameCount: number;
  frameScripts: { start: number; end: number; castLib: number; member: number; params?: string }[];
  sprites: SpriteSpan[];
  sounds: { ch: number; start: number; end: number; castLib: number; member: number }[];
  tempo: { frame: number; tempo?: number; wait?: number }[];
  transitions: { frame: number; castLib: number; member: number }[];
}

const MAIN = 6; // channels 0..5: frame script, palette, transition, sound1, sound2, tempo (D6 order)

export function parseScore(f: DirectorFile): Score | null {
  const c = f.first("VWSC");
  if (!c) return null;
  return parseScoreBuffer(f.data(c.id));
}

/** Parse score data – the movie's VWSC chunk, or a film loop's SCVW chunk (same layout). */
export function parseScoreBuffer(d: Buffer): Score {
  const n = d.readUInt32BE(12);
  const offs: number[] = [];
  for (let i = 0; i <= n; i++) offs.push(d.readUInt32BE(24 + i * 4));
  const base = 24 + (n + 1) * 4;
  const E = (i: number) => i < n ? d.subarray(base + offs[i], base + offs[i + 1]) : Buffer.alloc(0);

  // Behaviors attached via interval entries: primary(idx) -> secondary(idx+1) list
  const behaviorsFor = (idx: number) => {
    const s = E(idx + 1); const out: { castLib: number; member: number; params?: string }[] = [];
    for (let p = 0; p + 8 <= s.length; p += 8) {
      const castLib = s.readUInt16BE(p), member = s.readUInt16BE(p + 2), pidx = s.readUInt32BE(p + 4);
      const b: any = { castLib, member };
      if (pidx) { const t = E(pidx); if (t.length) b.params = decodeText(t).replace(/\0+$/, "").trim(); }
      out.push(b);
    }
    return out;
  };

  const fr = E(0);
  const recSize = fr.readUInt16BE(14), nch = fr.readUInt16BE(16);
  const buf = Buffer.alloc(recSize * nch);
  const score: Score = { frameCount: 0, frameScripts: [], sprites: [], sounds: [], tempo: [], transitions: [] };
  const open = new Map<number, { key: string; span: any }>();
  let p = 20, frame = 0;
  const close = (ch: number) => { const o = open.get(ch); if (o) { o.span.end = frame - 1; open.delete(ch); } };

  while (p + 2 <= fr.length) {
    const flen = fr.readUInt16BE(p); if (flen < 2) break;
    const end = p + flen; p += 2;
    // (film loops may end a few bytes short – stop cleanly at the end of the data)
    while (p + 4 <= end && p + 4 <= fr.length) { const l = fr.readUInt16BE(p), o = fr.readUInt16BE(p + 2); p += 4; fr.copy(buf, o, p, Math.min(p + l, fr.length)); p += l; }
    p = Math.max(p, end);
    frame++;
    for (let ch = 0; ch < nch; ch++) {
      const r = buf.subarray(ch * recSize, (ch + 1) * recSize);
      let span: any = null, list: any[] | null = null;
      if (ch === 0) { // frame script
        const castLib = r.readUInt16BE(0), member = r.readUInt16BE(2);
        if (member) { span = { castLib, member }; list = score.frameScripts; const idx = r.readUInt32BE(4); if (idx) { const b = behaviorsFor(idx); if (b[0]?.params) span.params = b[0].params; } }
      } else if (ch === 3 || ch === 4) { // sound channels
        const castLib = r.readUInt16BE(0), member = r.readUInt16BE(2);
        // main channel 4 = sound channel 1, main channel 3 = sound channel 2
        if (member) { span = { ch: ch === 4 ? 1 : 2, castLib, member }; list = score.sounds; }
      } else if (ch === 2) { // transition: castLib u16, member u16 – plays when entering this frame
        const castLib = r.readUInt16BE(0), member = r.readUInt16BE(2);
        if (member) score.transitions.push({ frame, castLib, member });
      } else if (ch === 1) { // tempo: [interval u32][value u16][kind u8] – kind 0xf6 = fps, 0xf7 = wait N seconds
        const value = r.readUInt16BE(4), kind = r[6];
        if (kind === 0xf6 && value) score.tempo.push({ frame, tempo: value });
        else if (kind === 0xf7 && value) score.tempo.push({ frame, wait: value });
      } else if (ch >= MAIN) {
        const type = r[0], inkB = r[1], castLib = r.readUInt16BE(4), member = r.readUInt16BE(6);
        if (type && member) {
          const idx = r.readUInt32BE(8);
          span = {
            ch: ch - MAIN + 1, castLib, member, ink: inkB & 0x3f,
            locV: r.readInt16BE(12), locH: r.readInt16BE(14), height: r.readInt16BE(16), width: r.readInt16BE(18),
            fore: r[2], back: r[3], blend: r[21] === 0xff || r[21] === 0 ? 100 : Math.round(100 - r[21] * 100 / 255),
          };
          if (inkB & 0x40) span.trails = true;
          if (inkB & 0x80) span.stretch = true;
          if (idx) { span.iv = idx; const b = behaviorsFor(idx); if (b.length) span.behaviors = b; }
          list = score.sprites;
        }
      }
      if (list === null) { if (ch !== 1 && ch !== 2) close(ch); continue; }
      const key = JSON.stringify(span);
      const o = open.get(ch);
      if (o && o.key === key) continue;
      close(ch);
      span.start = frame;
      list.push(span);
      open.set(ch, { key, span });
    }
  }
  frame++;
  for (const ch of [...open.keys()]) close(ch);
  score.frameCount = frame - 1;
  return score;
}
