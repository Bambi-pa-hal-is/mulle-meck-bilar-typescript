import { CastLib, loadCast, loadImage, imageNow, preloadCast, castFolder, cssFont, type MemberRef, type Manifest } from "./assets.ts";
import { Sprite, Ink } from "./sprite.ts";
import { Behavior, findBehavior, safeCall } from "./behavior.ts";
import { lingoValue, PropList } from "./lingo.ts";
import type { Engine } from "./engine.ts";

export interface Span {
  ch: number; start: number; end: number; castLib: number; member: number; ink: number;
  locH: number; locV: number; width: number; height: number; fore: number; back: number; blend: number;
  behaviors?: { castLib: number; member: number; params?: string }[]; iv?: number; stretch?: boolean;
}
export interface ScoreData {
  frameCount: number;
  tempo?: { frame: number; tempo?: number; wait?: number }[];
  transitions?: { frame: number; castLib: number; member: number }[];
  sounds?: { ch: number; start: number; end: number; castLib: number; member: number }[];
  frameScripts: { start: number; end: number; castLib: number; member: number; params?: string }[];
  sprites: Span[];
}

/** Optional per-movie script (the Lingo "movie scripts": startMovie / stopMovie ...). */
export interface MovieScript {
  /** Runs before frame 1's sprites begin (create gDir here). */
  prepareMovie?(m: Movie): void;
  startMovie?(m: Movie): void | Promise<void>;
  stopMovie?(m: Movie): void;
  /** Called every frame after sprites are updated (idle handler). */
  idle?(m: Movie): void;
  /** Movie-script mouse handlers: receive clicks no sprite or frame script handled. */
  mouseDown?(m: Movie): void;
  mouseUp?(m: Movie): void;
}

export const CHANNELS = 120;

/** A loaded Director movie (one of the original .dir files). */
export class Movie {
  libs: CastLib[] = [];
  labels = new Map<string, number>();
  score!: ScoreData;
  sprites: Sprite[] = [];
  frame = 0;
  private nextFrame: number | null = null;
  private frameScript: Behavior | null = null;
  private frameScriptSpan: unknown = null;
  /** Images to preload for snappy playback. */
  ready!: Promise<void>;
  /** Stage position of this movie (non-zero for a movie in a window). */
  origin = { x: 0, y: 0 };
  /** The mouse in this movie's coordinates. */
  get mouse() { const m = this.engine.mouse; return { x: m.x - this.origin.x, y: m.y - this.origin.y, down: m.down }; }
  /** Free-form per-movie state used by the scene implementations. */
  vars: Record<string, any> = {};

  constructor(public engine: Engine, public id: string, public script: MovieScript = {}) {
    for (let i = 0; i <= CHANNELS; i++) this.sprites.push(new Sprite(i));
  }

  async load() {
    const own = await loadCast(this.id);
    const manifest: Manifest = own.manifest;
    const names = manifest.castLibs.length ? manifest.castLibs : ["Internal"];
    this.libs = await Promise.all(names.map((n, i) => i === 0 ? own : loadCast(castFolder(n)).catch(() => own)));
    // plugin casts come after the movie's own libraries (castLib numbers stay unchanged)
    this.libs.push(...this.engine.extraLibs.filter(l => !this.libs.includes(l)));
    for (const l of manifest.labels) this.labels.set(l.name.toLowerCase(), l.frame);
    this.score = await fetch(`${import.meta.env.BASE_URL}assets/${this.id}/score.json`).then(r => r.json()).catch(() => ({ frameCount: 1, frameScripts: [], sprites: [] }));
    // Preload the movie's own cast completely, plus everything the score uses from shared casts.
    const refs = new Set<MemberRef>();
    for (const s of this.score.sprites) { const r = this.memberRef(s.castLib, s.member); if (r?.info.file && r.lib !== own) refs.add(r); }
    const total = refs.size + [...own.byNum.values()].filter(i => i.type === "bitmap" && i.file).length;
    let done = 0; const tick = () => this.engine.onLoadProgress?.(++done, total);
    this.ready = Promise.all([
      preloadCast(own, () => tick()),
      ...[...refs].map(r => loadImage(r).catch(() => null).then(tick)),
    ]).then(() => {});
    await this.ready;
  }

  // ---------------------------------------------------------- members
  memberRef(castLib: number, num: number): MemberRef | null {
    const lib = this.libs[castLib - 1];
    const info = lib?.byNum.get(num);
    return lib && info ? { lib, info } : null;
  }
  /** member("name") / member("name", "castName") */
  member(name: string | number, castName?: string): MemberRef | null {
    if (typeof name === "number") return this.memberRef(1, name);
    const k = name.toLowerCase();
    const libs = castName ? this.libs.filter(l => l.id === castFolder(castName)) : this.libs;
    for (const lib of libs) { const info = lib.byName.get(k); if (info) return { lib, info }; }
    return null;
  }
  text(name: string) { return this.member(name)?.info.text ?? ""; }
  value(name: string) { return lingoValue(this.text(name)); }

  // ---------------------------------------------------------- navigation
  label(name: string) { return this.labels.get(name.toLowerCase()) ?? 0; }
  /** go to frame N / go to frame "label" (takes effect after the current frame). */
  goFrame(f: number | string) {
    const target = typeof f === "string" ? this.label(f) || this.frame : f;
    // In Director `the frame` already reflects a pending `go`, so a later "go to the frame"
    // in the same cycle doesn't cancel an earlier jump elsewhere.
    if (target === this.frame && this.nextFrame !== null && this.nextFrame !== this.frame) return;
    this.nextFrame = target;
    // A `go` from an event handler (outside the frame cycle) wins over the old frame's exitFrame.
    if (!this.inFrameCycle) this.eventJump = true;
  }
  private inFrameCycle = false;
  private eventJump = false;
  /** go(#next): first marker after the current frame. */
  goNextMarker() {
    // like Director: with no later marker the playhead stays where it is
    const next = [...this.labels.values()].filter(f => f > this.frame).sort((a, b) => a - b)[0];
    this.goFrame(next ?? this.frame);
  }
  /** Label of the marker at or before the current frame. */
  get frameLabel() {
    let best = "", bf = 0;
    for (const [n, f] of this.labels) if (f <= this.frame && f >= bf) { best = n; bf = f; }
    return best;
  }

  // ---------------------------------------------------------- sprites
  sprite(n: number) { return this.sprites[n]; }

  setMember(s: Sprite, ref: MemberRef | null) {
    s.member = ref;
    // Director: an unstretched sprite shows a bitmap at the bitmap's own size (drop any box size left by a
    // shape/text/missing member, e.g. 83 frame 155 where Mulle's animation replaced a stale member).
    if (ref?.info.type === "bitmap" && !s.stretch) { s.width = 0; s.height = 0; }
    const seq = s.nextLoad();
    if (!ref || !ref.info.file || ref.info.type !== "bitmap") { s.image = null; return; }
    // Use an already-loaded image right away; otherwise keep showing the old one until the new arrives.
    const ready = imageNow(ref);
    if (ready) { s.image = ready; return; }
    loadImage(ref).then(img => { if (s.isCurrentLoad(seq)) s.image = img; });
  }
  /** set the member of sprite n to member "name" */
  setMemberByName(n: number | Sprite, name: string | number) {
    const s = typeof n === "number" ? this.sprites[n] : n;
    this.setMember(s, typeof name === "number" ? this.memberRef(1, name) : this.member(name));
    s.width = 0; s.height = 0; // natural member size
  }

  /** Member `delta` positions after the sprite's current member in the same cast (memberNum + n). */
  offsetMember(s: Sprite | number, delta: number) {
    const sp = typeof s === "number" ? this.sprites[s] : s;
    const cur = sp.member; if (!cur) return;
    const info = cur.lib.byNum.get(cur.info.num + delta);
    this.setMember(sp, info ? { lib: cur.lib, info } : null);
  }
  /** member(num) relative to a reference member's cast (used by animations: firstFrame + n). */
  memberInLib(ref: MemberRef, num: number): MemberRef | null {
    const info = ref.lib.byNum.get(num);
    return info ? { lib: ref.lib, info } : null;
  }
  /** Global member number like Lingo `the number of member` (cast-local). */
  memberNum(name: string) { return this.member(name)?.info.num ?? -1; }

  private spanAt(ch: number, frame: number): Span | undefined {
    // spans are few per movie; linear scan is fine
    for (const s of this.score.sprites) if (s.ch === ch && frame >= s.start && frame <= s.end) return s;
    return undefined;
  }

  private makeBehaviors(list: Span["behaviors"], sprite: Sprite | null): Behavior[] {
    const out: Behavior[] = [];
    for (const b of list ?? []) {
      const ref = this.memberRef(b.castLib, b.member);
      let Ctor = findBehavior(this.id, b.member, ref?.info.name ?? "", ref?.lib.id ?? "");
      // Some score references point at member numbers that moved since authoring; identify them by their params.
      if ((!Ctor || ref?.info.type !== "script") && /whichCustomCursor/i.test(b.params ?? "")) Ctor = findBehavior("", 0, "CursorBH", "");
      if (!Ctor && ref?.info.type !== "script") continue; // stale score reference (missing or non-script member): Director ignores it
      if (!Ctor) { this.engine.warnOnce(`missing behavior ${ref?.lib.id}:${b.member} "${ref?.info.name}"`); continue; }
      const inst = new Ctor();
      inst.movie = this; if (sprite) inst.sprite = sprite;
      const p = lingoValue(b.params); if (p instanceof PropList) inst.params = p;
      out.push(inst);
    }
    return out;
  }

  /** Apply score data for the current frame to all non-puppet channels. */
  private updateFromScore() {
    // Pass 1: apply score data to every channel; collect channels whose interval changed.
    const begun: Sprite[] = [];
    for (let ch = 1; ch <= CHANNELS; ch++) {
      const s = this.sprites[ch];
      const span = this.spanAt(ch, this.frame);
      const iv = span ? (span.iv ?? span) : null;
      if (iv !== s.interval) {
        const old = s.behaviors; s.behaviors = [];
        for (const b of old) safeCall(b, "endSprite");
        s.interval = iv;
        s.puppet = false;
        if (span) { this.applySpan(s, span); s.behaviors = this.makeBehaviors(span.behaviors, s); begun.push(s); }
        else { this.setMember(s, null); s.span = null; }
      } else if (span && span !== s.span && !s.puppet) this.applySpan(s, span);
      if (!span) s.span = null;
    }
    // Pass 2: beginSprite once all sprites of the frame are in place (Director order).
    for (const s of begun) for (const b of [...s.behaviors]) safeCall(b, "beginSprite");
    this.updateScoreSounds();
    const fs = this.score.frameScripts.find(f => this.frame >= f.start && this.frame <= f.end) ?? null;
    if (fs !== this.frameScriptSpan) {
      this.frameScript?.endSprite?.();
      this.frameScriptSpan = fs;
      this.frameScript = fs ? this.makeBehaviors([fs], null)[0] ?? null : null;
      this.frameScript?.beginSprite?.();
    }
  }

  /** Score sound channels 1 and 2: a sound plays while its span covers the playhead. */
  private soundSpans: (object | null)[] = [null, null, null];
  private updateScoreSounds() {
    for (const ch of [1, 2]) {
      const span = this.score.sounds?.find(x => x.ch === ch && this.frame >= x.start && this.frame <= x.end) ?? null;
      if (span === this.soundSpans[ch]) continue;
      this.soundSpans[ch] = span;
      if (!span) { this.engine.sound.stop(ch); continue; }
      const ref = this.memberRef(span.castLib, span.member);
      if (ref?.info.file) void this.engine.sound.play(ch, ref, !!ref.info.loop);
    }
  }

  private applySpan(s: Sprite, span: Span) {
    s.span = span;
    s.stretch = !!span.stretch;
    const ref = this.memberRef(span.castLib, span.member);
    if (ref !== s.member) this.setMember(s, ref);
    s.locH = span.locH; s.locV = span.locV;
    // Score width/height only matter for stretched sprites; otherwise the member's own size is used.
    const isBitmap = ref?.info.type === "bitmap";
    if (span.stretch || (ref && !isBitmap)) { s.width = span.width; s.height = span.height; } else { s.width = 0; s.height = 0; }
    s.ink = span.ink; s.blend = span.blend; s.fore = span.fore; s.back = span.back; // `visible` is a channel property, kept
  }

  /** Iterate all behaviors (sprites top to bottom, then frame script). */
  *allBehaviors(): Generator<Behavior> {
    for (let ch = 1; ch <= CHANNELS; ch++) yield* this.sprites[ch].behaviors;
    if (this.frameScript) yield this.frameScript;
  }
  /** sendAllSprites(#msg) */
  sendAll(msg: string, ...args: unknown[]) {
    for (let ch = 1; ch <= CHANNELS; ch++) this.sprites[ch].send(msg, ...args);
  }
  private dispatch(msg: "prepareFrame" | "enterFrame" | "exitFrame") {
    for (const b of [...this.allBehaviors()]) safeCall(b, msg);
  }

  // ---------------------------------------------------------- main loop
  started = false;
  async start(frame: number | string = 1) {
    this.frame = typeof frame === "string" ? this.label(frame) || 1 : frame;
    this.script.prepareMovie?.(this);
    this.loopTick++;
    this.updateFromScore();
    this.applyTempo();
    await this.script.startMovie?.(this);
    this.started = true;
    this.dispatch("prepareFrame");
    this.dispatch("enterFrame");
  }

  /** One tick of the playback head. */
  /** Score transition channel: transition member data = [?][chunkSize][type][flags][duration u16 ms]. */
  private playTransition() {
    const t = this.score.transitions?.find(x => x.frame === this.frame); if (!t) return;
    const spec = (this.memberRef(t.castLib, t.member)?.info as any)?.spec as string | undefined;
    if (!spec || spec.length < 12) return;
    this.engine.startTransition(parseInt(spec.substr(4, 2), 16), parseInt(spec.substr(8, 4), 16));
  }

  /** performance.now() until which the playhead waits (tempo channel "wait N seconds"). */
  private waitUntil = 0;
  private applyTempo() {
    const t = this.score.tempo?.find(x => x.frame === this.frame);
    if (!t) return;
    if (t.tempo) this.engine.tempo = t.tempo;
    if (t.wait) this.waitUntil = performance.now() + t.wait * 1000;
  }

  tick() {
    if (!this.started) return;
    if (performance.now() < this.waitUntil && !this.eventJump) return;
    this.inFrameCycle = true;
    try {
      if (!this.eventJump) this.dispatch("exitFrame");
      this.eventJump = false;
      if (this.engine.movie !== this && this.engine.window?.movie !== this) return; // movie switched during exitFrame
      this.advance();
    } finally { this.inFrameCycle = false; }
  }

  private advance() {
    const next = this.nextFrame ?? this.frame + 1;
    this.nextFrame = null;
    const prev = this.frame;
    if (next > this.score.frameCount) { this.frame = this.score.frameCount; }
    else this.frame = next;
    if (this.frame !== prev) this.playTransition();
    this.loopTick++;
    this.updateFromScore();
    this.applyTempo();
    this.dispatch("prepareFrame");
    this.dispatch("enterFrame");
    this.script.idle?.(this);
    this.engine.onFrame?.(this);
  }

  stop() {
    this.script.stopMovie?.(this);
    for (const s of this.sprites) { for (const b of s.behaviors) safeCall(b, "endSprite"); s.behaviors = []; }
    this.frameScript?.endSprite?.();
    this.started = false;
  }

  // ---------------------------------------------------------- input
  /** Topmost sprite under a point (optionally only ones with behaviors). */
  spriteAt(x: number, y: number, withBehaviors = true): Sprite | null {
    for (let ch = CHANNELS; ch >= 1; ch--) {
      const s = this.sprites[ch];
      if (ch === this.engine.cursorSprite || s.noHit) continue;
      if ((!withBehaviors || s.behaviors.length) && s.hitTest(x, y)) return s;
    }
    return null;
  }
  /** rollover(n) */
  rollover(n: number) { const m = this.mouse; return this.sprites[n].hitTest(m.x, m.y); }

  // ---------------------------------------------------------- render
  draw(g: CanvasRenderingContext2D) {
    g.fillStyle = "#fff"; g.fillRect(0, 0, 640, 480);
    for (let ch = 1; ch <= CHANNELS; ch++) {
      const s = this.sprites[ch];
      if (!s.visible || !s.member) continue;
      const info = s.member.info;
      if (info.type === "text" || info.type === "button" || info.type === "richText") { this.drawText(g, s); continue; }
      if (info.type === "shape") { this.drawShape(g, s); continue; }
      if (info.type === "filmLoop") { this.drawFilmLoop(g, s); continue; }
      const img = s.image; if (!img) continue;
      const r = s.rect;
      const w = r.right - r.left, h = r.bottom - r.top;
      if (w <= 0 || h <= 0) continue;
      g.globalAlpha = s.blend / 100;
      if (s.ink === Ink.Copy) { g.fillStyle = "#fff"; g.fillRect(r.left, r.top, w, h); g.drawImage(img.img, r.left, r.top, w, h); }
      else if (s.ink === Ink.Matte) g.drawImage(img.matte(), r.left, r.top, w, h);
      else g.drawImage(img.img, r.left, r.top, w, h);
      g.globalAlpha = 1;
    }
  }

  /** Film loop frame counter: every loop advances one frame per score frame. */
  private loopTick = 0;
  /** Film loops: a small score of their own; castLib 65535 = this movie's cast. */
  private drawFilmLoop(g: CanvasRenderingContext2D, s: Sprite) {
    const loop = (s.member!.info as any).loop as { frameCount: number; sprites: any[]; rect: { left: number; top: number } } | undefined;
    if (!loop || !loop.frameCount) return;
    const f = (this.loopTick % loop.frameCount) + 1, r = s.rect;
    g.globalAlpha = s.blend / 100;
    for (const ls of loop.sprites) {
      if (f < ls.start || f > ls.end) continue;
      const ref = this.memberRef(ls.castLib === 65535 ? 1 : ls.castLib, ls.member); if (!ref) continue;
      const img = imageNow(ref); if (!img) { loadImage(ref).catch(() => null); continue; }
      const x = r.left + ls.locH - (ref.info.regX ?? 0) - loop.rect.left, y = r.top + ls.locV - (ref.info.regY ?? 0) - loop.rect.top;
      const ink = ls.ink & 0x3f;
      if (ink === Ink.Copy) { g.fillStyle = "#fff"; g.fillRect(x, y, img.w, img.h); g.drawImage(img.img, x, y); }
      else if (ink === Ink.Matte) g.drawImage(img.matte(), x, y);
      else g.drawImage(img.img, x, y);
    }
    g.globalAlpha = 1;
  }

  /** Shape members: spec bytes [14] = filled, [15] = line size + 1 (unfilled, 0-px shapes are invisible click areas). */
  private drawShape(g: CanvasRenderingContext2D, s: Sprite) {
    const spec = (s.member!.info as any).spec as string | undefined;
    const b = (i: number) => spec && spec.length >= (i + 1) * 2 ? parseInt(spec.substr(i * 2, 2), 16) : 0;
    const filled = b(14) !== 0, line = Math.max(0, b(15) - 1);
    if (!filled && !line) return;
    if (s.ink === 36 && s.fore === 0) return; // white on background-transparent ink
    const r = s.rect, w = r.right - r.left, h = r.bottom - r.top;
    g.fillStyle = g.strokeStyle = paletteColor(s.fore);
    if (filled) g.fillRect(r.left, r.top, w, h);
    else { g.lineWidth = line; g.strokeRect(r.left + line / 2, r.top + line / 2, w - line, h - line); }
  }

  /** Field text set at runtime (`set the text of member`) overrides cast text. */
  fieldText = new Map<number, string>();
  memberText = new Map<string, string>();
  setText(memberName: string, text: string) { this.memberText.set(memberName.toLowerCase(), text); }
  getText(memberName: string) { return this.memberText.get(memberName.toLowerCase()) ?? this.text(memberName); }
  /** Sprite currently being edited through a DOM input (its text is drawn by the input). */
  editingSprite = 0;
  private drawText(g: CanvasRenderingContext2D, s: Sprite) {
    if (s.num === this.editingSprite) return;
    const info = s.member!.info;
    const txt = this.fieldText.get(s.num) ?? this.memberText.get(info.name.toLowerCase()) ?? info.text ?? "";
    if (!txt) return;
    const f = cssFont(info);
    g.fillStyle = f?.color ?? "#000"; g.font = f?.font ?? this.engine.fieldFont; g.textBaseline = "top";
    const lh = f?.lineHeight ?? this.engine.fieldLineHeight;
    const r = s.rect;
    if (info.align === "center" && info.w) {
      // rich text: word-wrap into the member width, each line centred
      const lines: string[] = [];
      for (const para of txt.split(/\r\n|\r|\n/)) {
        let cur = "";
        for (const w of para.split(" ")) { const t = cur ? cur + " " + w : w; if (cur && g.measureText(t).width > info.w) { lines.push(cur); cur = w; } else cur = t; }
        lines.push(cur);
      }
      g.textAlign = "center";
      lines.forEach((line, i) => g.fillText(line, r.left + info.w! / 2, r.top + i * lh));
      g.textAlign = "left";
      return;
    }
    txt.split("\n").forEach((line, i) => g.fillText(line, r.left + 2, r.top + 2 + i * lh));
  }
}

/** Mac system palette colour for an 8-bit index (0 = white, 255 = black). */
export function paletteColor(i: number) {
  const steps = [0xff, 0xcc, 0x99, 0x66, 0x33, 0x00];
  let rgb: number[];
  if (i < 215) rgb = [steps[Math.floor(i / 36)], steps[Math.floor(i / 6) % 6], steps[i % 6]];
  else if (i === 255) rgb = [0, 0, 0];
  else {
    const ramp = [0xee, 0xdd, 0xbb, 0xaa, 0x88, 0x77, 0x55, 0x44, 0x22, 0x11];
    const k = i - 215, v = ramp[k % 10], band = Math.floor(k / 10);
    rgb = band === 0 ? [v, 0, 0] : band === 1 ? [0, v, 0] : band === 2 ? [0, 0, v] : [v, v, v];
  }
  return `rgb(${rgb.join(",")})`;
}
