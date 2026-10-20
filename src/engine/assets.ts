/**
 * Loads extracted cast data (public/assets/<FILE>/manifest.json) and resolves members.
 * Asset files are produced locally by `npm run extract` from the original game install.
 */
export interface MemberInfo {
  num: number; name: string; type: string;
  file?: string; w?: number; h?: number; regX?: number; regY?: number;
  text?: string; base64?: string; script?: boolean; scriptType?: string;
  loop?: boolean; duration?: number; cues?: { time: number; name: string }[];
  /** Text members: first style run (font name from the movie's font map, px size, style bits, colour). */
  /** Rich text: centred and word-wrapped to w. */
  align?: "center";
  font?: { name: string; size: number; style: number; lineHeight: number; color: [number, number, number] };
}
export interface Manifest {
  file: string; castLibs: string[];
  casts: { name: string; minMember: number; members: MemberInfo[] }[];
  labels: { frame: number; name: string }[];
}

export class CastLib {
  byNum = new Map<number, MemberInfo>();
  byName = new Map<string, MemberInfo>();
  constructor(public id: string, public manifest: Manifest) {
    for (const m of manifest.casts[0]?.members ?? []) {
      this.byNum.set(m.num, m);
      const k = m.name.toLowerCase();
      if (m.name && !this.byName.has(k)) this.byName.set(k, m);
    }
  }
  url(m: MemberInfo) { return `${BASE}${this.id}/${m.file}`; }
}

const BASE = (import.meta as any).env?.BASE_URL + "assets/";
const castCache = new Map<string, Promise<CastLib>>();

/** Map a cast library name from a movie's MCsL to its extracted folder. */
export function castFolder(name: string) { return name.toUpperCase(); }

export function loadCast(id: string): Promise<CastLib> {
  id = id.toUpperCase();
  let p = castCache.get(id);
  if (!p) {
    p = fetch(`${BASE}${id}/manifest.json`).then(r => { if (!r.ok) throw new Error(`cast ${id} missing – run npm run extract`); return r.json(); })
      .then(m => new CastLib(id, m));
    castCache.set(id, p);
  }
  return p;
}

export interface MemberRef { lib: CastLib; info: MemberInfo; }

// ------------------------------------------------------------ images
export interface ImageAsset {
  img: HTMLImageElement | HTMLCanvasElement;
  w: number; h: number; regX: number; regY: number;
  /** Matte version: exterior white transparent, interior white opaque (ink 8). */
  matte(): HTMLCanvasElement;
  /** Alpha mask for hit testing (based on matte). */
  hit(x: number, y: number): boolean;
}

const imgCache = new Map<string, Promise<ImageAsset>>();
const imgReady = new Map<string, ImageAsset>();

export function loadImage(ref: MemberRef): Promise<ImageAsset> {
  const url = ref.lib.url(ref.info);
  let p = imgCache.get(url);
  if (!p) {
    p = new Promise<HTMLImageElement>((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = rej; i.src = url; })
      .then(img => { const a = makeImageAsset(img, ref.info); imgReady.set(url, a); return a; });
    imgCache.set(url, p);
  }
  return p;
}

/** The image if it has already been loaded (lets sprites switch members without a blank frame). */
export function imageNow(ref: MemberRef): ImageAsset | undefined { return imgReady.get(ref.lib.url(ref.info)); }

/** Preload every bitmap of a cast; onProgress(done, total). */
export async function preloadCast(lib: CastLib, onProgress?: (done: number, total: number) => void) {
  const refs = [...lib.byNum.values()].filter(i => i.type === "bitmap" && i.file).map(info => ({ lib, info }));
  let done = 0;
  await Promise.all(refs.map(r => loadImage(r).catch(() => null).then(() => onProgress?.(++done, refs.length))));
}

function makeImageAsset(img: HTMLImageElement, info: MemberInfo): ImageAsset {
  let matteCanvas: HTMLCanvasElement | null = null;
  let mask: Uint8Array | null = null;
  const w = img.width, h = img.height;
  const build = () => {
    const c = document.createElement("canvas"); c.width = w; c.height = h;
    const g = c.getContext("2d", { willReadFrequently: true })!;
    g.drawImage(img, 0, 0);
    const d = g.getImageData(0, 0, w, h);
    // Transparent pixels in the PNG are the original white. Flood fill from the border:
    // reachable ones stay transparent, enclosed ones become opaque white again.
    const outside = new Uint8Array(w * h);
    const stack: number[] = [];
    const push = (i: number) => { if (!outside[i] && d.data[i * 4 + 3] === 0) { outside[i] = 1; stack.push(i); } };
    for (let x = 0; x < w; x++) { push(x); push((h - 1) * w + x); }
    for (let y = 0; y < h; y++) { push(y * w); push(y * w + w - 1); }
    while (stack.length) {
      const i = stack.pop()!; const x = i % w, y = (i / w) | 0;
      if (x > 0) push(i - 1); if (x < w - 1) push(i + 1); if (y > 0) push(i - w); if (y < h - 1) push(i + w);
    }
    mask = new Uint8Array(w * h);
    for (let i = 0; i < w * h; i++) {
      if (!outside[i]) { mask[i] = 1; if (d.data[i * 4 + 3] === 0) { d.data[i * 4] = d.data[i * 4 + 1] = d.data[i * 4 + 2] = 255; d.data[i * 4 + 3] = 255; } }
    }
    g.putImageData(d, 0, 0);
    matteCanvas = c;
  };
  return {
    img, w, h, regX: info.regX ?? 0, regY: info.regY ?? 0,
    matte() { if (!matteCanvas) build(); return matteCanvas!; },
    hit(x, y) { if (!mask) build(); x |= 0; y |= 0; return x >= 0 && y >= 0 && x < w && y < h && mask![y * w + x] === 1; },
  };
}

// ------------------------------------------------------------ sounds
const audioCache = new Map<string, Promise<AudioBuffer>>();
export function loadAudio(ctx: AudioContext, ref: MemberRef): Promise<AudioBuffer> {
  const url = ref.lib.url(ref.info);
  let p = audioCache.get(url);
  if (!p) { p = fetch(url).then(r => r.arrayBuffer()).then(b => ctx.decodeAudioData(b)); audioCache.set(url, p); }
  return p;
}

/** CSS font for a text member, mapping the Mac/Windows font names Director used to web fonts. */
export function cssFont(info: MemberInfo, scale = 1) {
  const f = info.font;
  if (!f) return null;
  const family = /times/i.test(f.name) ? "'Times New Roman', Times, serif"
    : /courier/i.test(f.name) ? "'Courier New', Courier, monospace"
    : /helvetica|arial|geneva|sans/i.test(f.name) ? "Arial, Helvetica, sans-serif" : `'${f.name}', serif`;
  const weight = f.style & 1 ? "bold " : "", italic = f.style & 2 ? "italic " : "";
  return { font: `${italic}${weight}${Math.round(f.size * scale)}px ${family}`, lineHeight: f.lineHeight || Math.round(f.size * 1.2),
    color: `rgb(${f.color.join(",")})` };
}
