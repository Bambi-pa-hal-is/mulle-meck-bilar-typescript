import { Movie, type MovieScript } from "./movie.ts";
import { cssFont } from "./assets.ts";
import { safeCall } from "./behavior.ts";
import { SoundSystem } from "./sound.ts";
import type { Sprite } from "./sprite.ts";

export type MovieFactory = () => MovieScript;

/** Runs one Director movie at a time on a 640x480 canvas. */
export class Engine {
  g: CanvasRenderingContext2D;
  movie: Movie | null = null;
  sound = new SoundSystem();
  mouse = { x: 0, y: 0, down: false, rightDown: false };
  /** Keys currently held (KeyboardEvent.key values, e.g. "ArrowUp", "Shift"). */
  keys = new Set<string>();
  /** keyDown handler for the current movie (Lingo `on keyDown` / keyDownScript). */
  keyDownScript: ((e: KeyboardEvent) => void) | null = null;
  keyUpScript: ((e: KeyboardEvent) => void) | null = null;
  /** frames per second (Director tempo; the game uses 12, set from each movie's tempo channel) */
  tempo = 12;
  /** Extra casts searched (after a movie's own cast libraries) when looking members up by name – plugins. */
  extraLibs: import("./assets.ts").CastLib[] = [];
  /** Asset loading progress for the current movie switch (done, total). */
  onLoadProgress: ((done: number, total: number) => void) | null = null;
  private scripts = new Map<string, MovieFactory>();
  private warned = new Set<string>();
  private switching: Promise<void> | null = null;
  private downSprite: Sprite | null = null;
  private hoverSprite: Sprite | null = null;
  /** Called before every frame render, e.g. for custom cursors / overlays. */
  overlays: ((g: CanvasRenderingContext2D) => void)[] = [];
  /** Font used to render text fields (the original fonts are not extracted). */
  fieldFont = "bold 18px 'Comic Sans MS', 'Trebuchet MS', sans-serif";
  fieldLineHeight = 22;
  private input: HTMLInputElement | null = null;

  /**
   * Make a text field sprite editable with a DOM <input> laid over the canvas.
   * onChange receives every edit; pass null to remove the input.
   */
  editField(spriteNum: number | null, value = "", onChange?: (v: string) => void, maxLength = 20) {
    const m = this.movie;
    this.input?.remove(); this.input = null;
    if (m) m.editingSprite = 0;
    if (spriteNum === null || !m) return;
    const el = document.createElement("input");
    el.value = value; el.maxLength = maxLength;
    Object.assign(el.style, {
      position: "fixed", background: "transparent", border: "none", outline: "none", color: "#000",
      padding: "0", margin: "0", cursor: "text",
    } as CSSStyleDeclaration);
    el.style.caretColor = "#000";
    el.autocomplete = "off"; el.spellcheck = false;
    el.addEventListener("input", () => onChange?.(el.value));
    el.addEventListener("keydown", e => { if (e.key === "Enter") el.blur(); e.stopPropagation(); });
    document.body.appendChild(el);
    m.editingSprite = spriteNum;
    this.input = el;
    this.placeInput();
    setTimeout(() => el.focus(), 0);
  }

  /** Give the keyboard back to the text field (clicks on the canvas would otherwise steal focus). */
  focusInput() { const el = this.input; if (el) setTimeout(() => { el.focus(); el.setSelectionRange(el.value.length, el.value.length); }, 0); }

  /** Keep the text input aligned with its field sprite (canvas may be resized/rescaled). */
  private placeInput() {
    const el = this.input, m = this.movie;
    if (!el || !m || !m.editingSprite) return;
    const r = m.sprite(m.editingSprite).rect;
    const cr = this.canvas.getBoundingClientRect(), k = cr.width / 640;
    const h = Math.max(22, r.bottom - r.top);
    el.style.left = `${cr.left + r.left * k}px`;
    el.style.top = `${cr.top + r.top * k}px`;
    el.style.width = `${Math.max(120, r.right - r.left) * k}px`;
    el.style.height = `${h * k}px`;
    el.style.lineHeight = `${h * k}px`;
    const info = m.sprite(m.editingSprite).member?.info;
    const f = info ? cssFont(info, k) : null;
    el.style.font = f?.font ?? this.fieldFont.replace(/(\d+)px/, (_, n) => `${Math.round(+n * k)}px`);
    if (f) el.style.color = f.color;
  }

  /** Name of the movie we came from (Lingo: the WhereFrom global). */
  previousMovie = "";
  /** Sprite channel used as software cursor (ignored by hit testing). */
  cursorSprite = 115;
  /** Lingo `the mouseDownScript` / `the mouseUpScript` – run before sprite handlers. */
  mouseDownScript: (() => void) | null = null;
  mouseUpScript: (() => void) | null = null;
  /** Called after every frame (sound cue dispatch etc). */
  onFrame: ((m: Movie) => void) | null = null;
  /** Called when a movie is about to be replaced. */
  onMovieChange: ((from: Movie | null, to: string) => void) | null = null;

  constructor(public canvas: HTMLCanvasElement) {
    this.g = canvas.getContext("2d")!;
    this.g.imageSmoothingEnabled = false;
    this.fit(); addEventListener("resize", () => this.fit());
    const pos = (e: PointerEvent) => {
      const r = canvas.getBoundingClientRect();
      this.mouse.x = ((e.clientX - r.left) * 640) / r.width;
      this.mouse.y = ((e.clientY - r.top) * 480) / r.height;
    };
    canvas.addEventListener("pointermove", e => { pos(e); this.updateHover(); });
    canvas.addEventListener("pointerdown", e => {
      pos(e);
      if (e.button === 2) { this.mouse.rightDown = true; return; }
      this.mouse.down = true; this.onDown();
    });
    addEventListener("pointerup", e => {
      pos(e);
      if (e.button === 2) { this.mouse.rightDown = false; return; }
      this.mouse.down = false; this.onUp();
    });
    canvas.addEventListener("contextmenu", e => e.preventDefault());
    addEventListener("keydown", e => {
      if ((e.target as HTMLElement)?.tagName === "INPUT") return;
      if (e.key.startsWith("Arrow") || e.key === " ") e.preventDefault();
      if (!e.repeat) this.keys.add(e.key);
      this.keyDownScript?.(e);
    });
    addEventListener("keyup", e => { this.keys.delete(e.key); this.keyUpScript?.(e); });
    addEventListener("blur", () => { this.keys.clear(); this.mouse.down = this.mouse.rightDown = false; });
  }

  /** "integer" = whole-number nearest-neighbour scaling (crisp, even pixels); "fill" = fill the window. */
  fitMode: "integer" | "fill" = new URLSearchParams(location.search).get("fit") === "fill" ? "fill" : "integer";

  private fit() {
    const max = Math.min(innerWidth / 640, innerHeight / 480);
    const s = this.fitMode === "integer" && max >= 1 ? Math.floor(max) : max;
    this.canvas.style.width = `${640 * s}px`; this.canvas.style.height = `${480 * s}px`;
  }

  warnOnce(msg: string) { if (!this.warned.has(msg)) { this.warned.add(msg); console.warn(msg); } }

  /** Register the TypeScript re-implementation of a movie's movie scripts. */
  registerMovie(id: string, f: MovieFactory) { this.scripts.set(id.toUpperCase(), f); }

  /** go to frame X of movie "id" */
  goMovie(id: string, frame: number | string = 1) {
    const run = async () => {
      if (this.switching) await this.switching;
      id = id.toUpperCase();
      const old = this.movie;
      this.onMovieChange?.(old, id);
      this.closeWindow();
      this.editField(null);
      if (old) { this.previousMovie = old.id; old.stop(); }
      this.mouseDownScript = this.mouseUpScript = null;
      this.keyDownScript = this.keyUpScript = null;
      this.movie = null;
      const m = new Movie(this, id, this.scripts.get(id)?.() ?? {});
      await m.load();
      this.movie = m;
      this.downSprite = this.hoverSprite = null;
      await m.start(frame);
    };
    this.switching = run().finally(() => { this.switching = null; });
    return this.switching;
  }

  // ------------------------------------------------------------ transitions
  /** A running score transition: the old frame is shown over the new one, shrinking by `type`. */
  private transition: { from: HTMLCanvasElement; start: number; dur: number; type: number; order: number[] } | null = null;

  /**
   * Start a Director transition from the frame currently on screen.
   * Types: 1–4 wipes, 5–10 centre-out / edges-in, 11–14 push (shown as wipes), others dissolve.
   */
  startTransition(type: number, durationMs: number) {
    const from = document.createElement("canvas"); from.width = 640; from.height = 480;
    from.getContext("2d")!.drawImage(this.canvas, 0, 0);
    const cells = 32 * 24, order = Array.from({ length: cells }, (_, i) => i);
    for (let i = cells - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [order[i], order[j]] = [order[j], order[i]]; }
    this.transition = { from, start: performance.now(), dur: Math.max(50, durationMs), type, order };
  }

  private drawTransition() {
    const t = this.transition; if (!t) return;
    const p = Math.min(1, (performance.now() - t.start) / t.dur);
    if (p >= 1) { this.transition = null; return; }
    const g = this.g, W = 640, H = 480;
    // region of the OLD frame that is still visible
    const keep = (x: number, y: number, w: number, h: number) => { if (w > 0 && h > 0) g.drawImage(t.from, x, y, w, h, x, y, w, h); };
    const q = 1 - p;
    switch (t.type) {
      case 1: case 12: keep(W * p, 0, W * q, H); break;                    // wipe right
      case 2: case 11: keep(0, 0, W * q, H); break;                        // wipe left
      case 3: case 13: keep(0, H * p, W, H * q); break;                    // wipe down
      case 4: case 14: keep(0, 0, W, H * q); break;                        // wipe up
      case 5: { const w = (W * p) / 2; keep(0, 0, W / 2 - w, H); keep(W / 2 + w, 0, W / 2 - w, H); break; } // centre out, horizontal
      case 6: { const w = (W * q) / 2; keep(W / 2 - w, 0, w * 2, H); break; }                               // edges in, horizontal
      case 7: { const h = (H * p) / 2; keep(0, 0, W, H / 2 - h); keep(0, H / 2 + h, W, H / 2 - h); break; } // centre out, vertical
      case 8: { const h = (H * q) / 2; keep(0, H / 2 - h, W, h * 2); break; }                               // edges in, vertical
      case 9: { // centre out, square: the new frame grows from the middle
        const w = (W * p) / 2, h = (H * p) / 2;
        keep(0, 0, W, H / 2 - h); keep(0, H / 2 + h, W, H / 2 - h); keep(0, H / 2 - h, W / 2 - w, h * 2); keep(W / 2 + w, H / 2 - h, W / 2 - w, h * 2);
        break;
      }
      case 10: { const w = (W * q) / 2, h = (H * q) / 2; keep(W / 2 - w, H / 2 - h, w * 2, h * 2); break; } // edges in, square
      default: { // dissolves: old frame disappears in random 20×20 blocks
        const shown = Math.floor(t.order.length * q);
        for (let i = 0; i < shown; i++) { const c = t.order[i]; keep((c % 32) * 20, Math.floor(c / 32) * 20, 20, 20); }
      }
    }
  }

  // ------------------------------------------------------------ movie in a window (MIAW)
  /** A movie shown in a small window over the stage (e.g. the world chooser); modal for input. */
  window: { movie: Movie; x: number; y: number; w: number; h: number } | null = null;

  async openWindow(id: string, x: number, y: number, w: number, h: number) {
    this.closeWindow();
    const m = new Movie(this, id.toUpperCase(), this.scripts.get(id.toUpperCase())?.() ?? {});
    m.origin = { x, y };
    await m.load();
    this.window = { movie: m, x, y, w, h };
    this.downSprite = this.hoverSprite = null;
    await m.start(1);
  }
  closeWindow() {
    if (!this.window) return;
    this.window.movie.stop();
    this.window = null;
    this.downSprite = this.hoverSprite = null;
  }

  /** The movie receiving input (the window if one is open) and the mouse in its coordinates. */
  private target(): { m: Movie | null; x: number; y: number } {
    const w = this.window;
    if (w) return { m: w.movie, x: this.mouse.x - w.x, y: this.mouse.y - w.y };
    return { m: this.movie, x: this.mouse.x, y: this.mouse.y };
  }

  // ------------------------------------------------------------ input dispatch
  private call(s: Sprite | null, msg: string) {
    if (!s) return;
    for (const b of [...s.behaviors]) safeCall(b, msg);
  }
  private updateHover() {
    const { m, x, y } = this.target(); if (!m) return;
    const s = m.spriteAt(x, y);
    if (s !== this.hoverSprite) { this.call(this.hoverSprite, "mouseLeave"); this.hoverSprite = s; this.call(s, "mouseEnter"); }
  }
  /**
   * Director event passing: sprite behaviors → frame script → movie script.
   * Returns true when something handled the event.
   */
  private dispatchMouse(s: Sprite | null, msg: "mouseDown" | "mouseUp" | "mouseUpOutside") {
    const { m } = this.target(); if (!m) return;
    const has = (o: unknown) => typeof (o as any)?.[msg] === "function";
    if (s && s.behaviors.some(has)) { this.call(s, msg); return; }
    if (msg === "mouseUpOutside") return;
    const frameScripts = [...m.allBehaviors()].filter(b => !b.sprite && has(b));
    if (frameScripts.length) { for (const b of frameScripts) (b as any)[msg](); return; }
    (m.script as any)[msg]?.(m);
  }
  private onDown() {
    const { m, x, y } = this.target(); if (!m) return;
    this.sound.resume();
    if (!this.window) this.mouseDownScript?.();
    const s = m.spriteAt(x, y);
    this.downSprite = s;
    this.dispatchMouse(s, "mouseDown");
  }
  private onUp() {
    const { m, x, y } = this.target(); if (!m) return;
    if (!this.window) this.mouseUpScript?.();
    const s = this.downSprite; this.downSprite = null;
    if (s && !s.hitTest(x, y) && s.behaviors.some(b => typeof (b as any).mouseUpOutside === "function")) this.call(s, "mouseUpOutside");
    else this.dispatchMouse(s, "mouseUp");
  }

  // ------------------------------------------------------------ loop
  private last = 0;
  run() {
    const loop = (t: number) => {
      requestAnimationFrame(loop);
      const m = this.movie;
      if (m && !this.switching && t - this.last >= 1000 / this.tempo) {
        this.last = t;
        m.tick();
        this.window?.movie.tick();
        this.updateHover();
        for (const s of [this.hoverSprite]) if (s) this.call(s, "mouseWithin");
      }
      // the software cursor follows the mouse at display rate (the original OS cursor was never tied to the tempo)
      for (const mv of [this.movie, this.window?.movie]) {
        if (!mv?.started) continue;
        const c = mv.sprite(this.cursorSprite);
        if (c?.behaviors.some(b => typeof (b as any).C_Standard === "function")) { const p = mv.mouse; c.setLoc(p.x | 0, p.y | 0); }
      }
      if (this.movie) this.movie.draw(this.g);
      this.drawTransition();
      const w = this.window;
      if (w) {
        const g = this.g;
        g.save(); g.translate(w.x, w.y); g.beginPath(); g.rect(0, 0, w.w, w.h); g.clip();
        w.movie.draw(g);
        g.restore();
      }
      for (const o of this.overlays) o(this.g);
      this.placeInput();
    };
    requestAnimationFrame(loop);
  }
}
