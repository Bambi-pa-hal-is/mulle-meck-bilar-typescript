/**
 * Extracts all assets from the original Director files into public/assets.
 * Usage: npx tsx tools/extract/main.ts [srcRoot]
 *   srcRoot defaults to "../Decompiled DXR CXT"
 */
import { mkdirSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join, basename, extname, resolve } from "node:path";
import { PNG } from "pngjs";
import { DirectorFile, CastMember } from "./riff.ts";
import { Reader, decodeText } from "./stream.ts";
import { parseBitmapSpecific, decodeBitd, macSystemPalette, readClut, RGB } from "./bitmap.ts";
import { decodeMacSnd, toWav, Pcm } from "./sound.ts";
import { parseScore, parseScoreBuffer } from "./score.ts";

const root = resolve(process.argv[2] ?? "../Decompiled DXR CXT");
const outRoot = resolve("public/assets");
const reRoot = resolve("re"); // reverse-engineering dumps (scripts), not shipped
const MAC = macSystemPalette();

function sndH(head: Buffer, data: Buffer): Pcm {
  const rate = head.readUInt32BE(0x2c), bits = head.readUInt32BE(0x44) || 8, channels = head.readUInt32BE(0x4c) || 1;
  const d = Buffer.from(data);
  if (bits === 16) for (let i = 0; i + 1 < d.length; i += 2) { const a = d[i]; d[i] = d[i + 1]; d[i + 1] = a; }
  return { rate, bits, channels, data: d };
}

function cuePoints(b: Buffer) {
  const r = new Reader(b, false);
  const n = r.u32(); const cues: { time: number; name: string }[] = [];
  for (let i = 0; i < n && r.pos + 36 <= b.length; i++) {
    const time = r.u32(); const nm = r.bytes(32);
    cues.push({ time, name: decodeText(nm.subarray(1, 1 + nm[0])) });
  }
  return cues;
}

function labels(f: DirectorFile) {
  const c = f.first("VWLB"); if (!c) return [];
  const r = f.reader(c.id, false);
  const n = r.u16(); const ents: [number, number][] = [];
  for (let i = 0; i < n; i++) ents.push([r.u16(), r.u16()]);
  const len = r.u32(); const base = r.pos; const out: { frame: number; name: string }[] = [];
  // entries are (frame, nameOffset)
  for (let i = 0; i < n; i++) out.push({ frame: ents[i][0], name: decodeText(r.buf.subarray(base + ents[i][1], base + (i + 1 < n ? ents[i + 1][1] : len))) });
  return out;
}

const safe = (s: string) => s.replace(/[^\w\-åäöÅÄÖ]+/g, "_");

function extractFile(path: string, rel: string) {
  const f = new DirectorFile(path);
  const id = basename(path, extname(path)).toUpperCase();
  const out = join(outRoot, id); mkdirSync(out, { recursive: true });
  const reOut = join(reRoot, id); mkdirSync(reOut, { recursive: true });
  const manifest: any = { file: rel, kind: f.kind, castLibs: f.castLibs.map(c => c.name), casts: [], labels: labels(f) };
  const score = parseScore(f);
  if (score) writeFileSync(join(out, "score.json"), JSON.stringify(score));
  const stats: Record<string, number> = {};

  // font map (Fmap): entries [nameOffset u32][platform u16][fontId u16] at 0x24; names (u32 length + chars)
  // follow in the same order as the sorted name offsets
  const fonts = new Map<number, string>();
  const fm = f.first("Fmap");
  if (fm) {
    const d = f.data(fm.id), count = d.readUInt32BE(0x10);
    const entries: [number, number][] = [];
    for (let i = 0; i < count && 0x24 + i * 8 + 8 <= d.length; i++) entries.push([d.readUInt32BE(0x24 + i * 8), d.readUInt16BE(0x24 + i * 8 + 6)]);
    const names: string[] = [];
    for (let p = 0x24 + count * 8; p + 4 < d.length && names.length < count; p++) {
      const len = d.readUInt32BE(p);
      if (len > 0 && len < 40 && p + 4 + len <= d.length) {
        const str = d.toString("latin1", p + 4, p + 4 + len);
        if (/^[A-Za-z][\w ]+$/.test(str)) { names.push(str); p += 3 + len; }
      }
    }
    [...entries].sort((a, b) => a[0] - b[0]).forEach(([, id], i) => { if (names[i]) fonts.set(id, names[i]); });
  }

  // palettes in this file, keyed by member number
  const palettes = new Map<number, RGB[]>();
  for (const cast of f.casts) for (const m of cast.members)
    if (m.type === "palette") { const cl = m.children.get("CLUT")?.[0]; if (cl !== undefined) palettes.set(m.id, readClut(f.data(cl))); }

  for (const [ci, cast] of f.casts.entries()) {
    const members: any[] = [];
    for (const m of cast.members) {
      const e: any = { num: m.id, name: m.name, type: m.type };
      stats[m.type] = (stats[m.type] ?? 0) + 1;
      try { handle(m, e); } catch (err) { e.error = String(err); }
      members.push(e);
    }
    manifest.casts.push({ name: cast.name, index: ci, minMember: cast.minMember, members });
  }

  function handle(m: CastMember, e: any) {
    const prefix = f.casts.length > 1 ? `${m.id}` : `${m.id}`;
    if (m.scriptText) writeFileSync(join(reOut, `${m.id}_${safe(m.name || "noname")}.ls`), m.scriptText);
    if (m.scriptText) e.script = true;
    if (m.type === "script") e.scriptType = { 1: "score", 3: "movie", 7: "parent" }[m.specific.readUInt16BE(0)] ?? m.specific.readUInt16BE(0);
    if (m.type === "bitmap") {
      const info = parseBitmapSpecific(m.specific);
      Object.assign(e, { w: info.width, h: info.height, regX: info.regX, regY: info.regY, bpp: info.bpp });
      if (info.clutId > 0) e.clut = info.clutId;
      const bitd = m.children.get("BITD")?.[0];
      if (bitd === undefined || info.width <= 0 || info.height <= 0) return;
      let pal = MAC;
      if (info.clutId > 0) { pal = palettes.get(info.clutId) ?? MAC; if (!palettes.has(info.clutId)) e.clutMissing = true; }
      const { rgba } = decodeBitd(f.data(bitd), info, pal);
      const png = new PNG({ width: info.width, height: info.height }); rgba.copy(png.data);
      writeFileSync(join(out, `${prefix}.png`), PNG.sync.write(png));
      e.file = `${prefix}.png`;
    } else if (m.type === "sound") {
      let pcm: Pcm | null = null;
      const h = m.children.get("sndH")?.[0], s = m.children.get("sndS")?.[0], sn = m.children.get("snd ")?.[0];
      if (h !== undefined && s !== undefined) pcm = sndH(f.data(h), f.data(s));
      else if (sn !== undefined && f.chunks[sn].len > 0) pcm = decodeMacSnd(f.data(sn));
      e.loop = (m.infoFlags & 0x10) === 0;
      const cu = m.children.get("cupt")?.[0];
      if (cu !== undefined) e.cues = cuePoints(f.data(cu));
      if (pcm) { writeFileSync(join(out, `${prefix}.wav`), toWav(pcm)); e.file = `${prefix}.wav`; e.duration = +(pcm.data.length / (pcm.rate * pcm.channels * pcm.bits / 8)).toFixed(3); }
    } else if (m.type === "richText") {
      // RTE1 = plain text, RTE2 = rendered bitmap (header: width u16, height u16). Drawn as centred, wrapped text.
      const t1 = m.children.get("RTE1")?.[0], t2 = m.children.get("RTE2")?.[0];
      if (t1 !== undefined) e.text = decodeText(f.data(t1));
      if (t2 !== undefined) { const d = f.data(t2); if (d.length >= 4) { e.w = d.readUInt16BE(0); e.h = d.readUInt16BE(2); } }
      e.font = { name: "Arial", size: 12, style: 1, lineHeight: 14, color: [0, 0, 0] };
      e.align = "center";
    } else if (m.type === "text" || m.type === "button") {
      const st = m.children.get("STXT")?.[0];
      if (st !== undefined) {
        const r = f.reader(st, false); const hl = r.u32(), tl = r.u32();
        const raw = r.buf.subarray(hl, hl + tl);
        // first style run: [count u16][start u32][height u16][ascent u16][fontId u16][style u8][pad][size u16][r g b u16]
        const runs = r.buf.subarray(hl + tl);
        if (runs.length >= 20 && runs.readUInt16BE(0) > 0) {
          e.font = { name: fonts.get(runs.readUInt16BE(10)) ?? "", size: runs.readUInt16BE(14), style: runs[12],
            lineHeight: runs.readUInt16BE(6), color: [runs[16], runs[18], runs[20] ?? 0] };
        }
        // Binary data stored in text members (e.g. map topology "30t..."): keep exact bytes
        if (/^30t/.test(m.name) || raw.some(b => b < 9 || (b > 13 && b < 32))) e.base64 = Buffer.from(raw).toString("base64");
        else e.text = decodeText(raw);
      }
    } else if (m.type === "palette") {
      const cl = m.children.get("CLUT")?.[0];
      if (cl !== undefined) e.colors = readClut(f.data(cl)).map(c => (c[0] << 16 | c[1] << 8 | c[2]).toString(16).padStart(6, "0"));
    } else if (m.type === "shape") {
      e.spec = m.specific.toString("hex");
    } else if (m.type === "transition") {
      e.spec = m.specific.toString("hex");
    } else if (m.type === "filmLoop") {
      e.spec = m.specific.toString("hex");
      // a film loop is a small score of its own; its rect (top,left,bottom,right) centre is the reg point
      const sc = m.children.get("SCVW")?.[0];
      if (sc !== undefined && m.specific.length >= 8) {
        const sp = m.specific, top = sp.readInt16BE(0), left = sp.readInt16BE(2), bottom = sp.readInt16BE(4), right = sp.readInt16BE(6);
        const loop = parseScoreBuffer(f.data(sc));
        e.loop = { frameCount: loop.frameCount, sprites: loop.sprites.map(({ behaviors, iv, ...rest }) => rest),
          rect: { top, left, bottom, right } };
        e.w = right - left; e.h = bottom - top; e.regX = Math.trunc(e.w / 2); e.regY = Math.trunc(e.h / 2);
      }
    }
  }

  writeFileSync(join(out, "manifest.json"), JSON.stringify(manifest, null, 1));
  console.log(`${rel}: ${JSON.stringify(stats)} labels=${manifest.labels.length}`);
  return id;
}

const index: string[] = [];
for (const dir of ["MOVIES", "Plugins", "DATA"]) {
  const d = join(root, dir); if (!existsSync(d)) continue;
  for (const name of readdirSync(d)) {
    if (!/\.(dir|cst|cxt|dxr)$/i.test(name)) continue;
    try { index.push(extractFile(join(d, name), `${dir}/${name}`)); }
    catch (err) { console.error(`${dir}/${name}: FAILED`, err); }
  }
}
writeFileSync(join(outRoot, "index.json"), JSON.stringify(index));
