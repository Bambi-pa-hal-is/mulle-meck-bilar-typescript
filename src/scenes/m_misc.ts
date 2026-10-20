/**
 * Smaller movies: LBSTART (publisher logo intro), 08 diploma, 12 quit, 13 load-car dialog, 18 world chooser,
 * UNLOAD (low-memory pile switching).
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, Sym } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir } from "../game/dir.ts";
import { G } from "../game/runtime.ts";
import { setCursor } from "./common.ts";

const S = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");
class Hold extends Behavior { exitFrame() { this.movie.goFrame(this.movie.frame); } }
const goMovie = (id: string, frame: number | string = 1) => class extends Behavior { exitFrame() { void G.engine.goMovie(id, frame); } };

// ================================================================== LBSTART – Levande Böcker logo
const lbstartMovie = (): MovieScript => ({
  startMovie() { setCursor("C_Standard"); },
  mouseUp(m) { m.goFrame("Leave"); },  // a click skips the logo
});
class LBClickSkip extends Behavior { mouseUp() { this.movie.goFrame("Leave"); } }
class LBWaitMusic extends Behavior { exitFrame() { if (this.movie.engine.sound.busy(2)) this.movie.goFrame(this.movie.frame); } }

// ================================================================== 08 – Diploma
class DiplomaDir extends GameDir {
  returnTo = "";
  constructor(m: Movie) {
    super(m);
    this.spriteList = { CarStart: 4, ToBeCaptured: 82, Scroller: 110 };
    const u = G.mulle.user!;
    m.setText("UserName", u.userId);
    m.setText("SavedCarName", u.car.name || " ");
  }
  kill() { this.movie.setText("SavedCarName", " "); this.movie.setText("UserName", " "); super.kill(); }
}
const ddir = () => G.dir as DiplomaDir;

const diplomaMovie = (): MovieScript => ({
  prepareMovie(m) { G.dir = new DiplomaDir(m); },
  startMovie(m) {
    ddir().returnTo = G.mulle.whereFrom.slice(0, 2);
    G.mulle.whereFrom = "08";
    G.sound.stopBG(); G.sound.stopAllEffects();
    setCursor("C_Standard");
    m.setMemberByName(m.sprite(119), "Dummy"); m.setMemberByName(m.sprite(120), "Dummy");
  },
});

const MEDALS = ["00n004v0", "00n005v0", "00n006v0", "00n007v0", "00n010v0", "00n009v0"];
const MEDAL_TEXTS = ["08t001v0", "08t002v0", "08t003v0", "08t004v0", "08t005v0", "08t006v0"];

/** ScrollBH – the diploma is taller than the screen; the arrows scroll it in three steps. */
class DiplomaScrollBH extends Behavior {
  private readonly list: Record<string, number> = { title: 55, Signature: 56, CarName: 59, userName: 57, to: 58, LeftR: 60, RightR: 61 };
  private offsets: Record<string, number> = {};
  private nowAt = 1; private readonly steps = 3; private stepV = 0; private startV = 0;
  private carStart = new Point(0, 0); private medalsStartV = 0; private readonly medalsSP = 63;
  beginSprite() {
    const m = this.movie;
    for (const k of ["CarName", "userName", "to"]) this.offsets[k] = 240 - m.sprite(this.list[k]).locV;
    const chassis = m.sprite(4 + 7);            // "the locV of sprite 4 + 7" = the chassis sprite
    this.carStart = new Point(chassis.locH, 240 - chassis.locV);
    this.stepV = Math.trunc((812 - 300) / this.steps);
    this.startV = 240 + this.nowAt * this.stepV;
    this.medalsStartV = 200 - m.sprite(this.medalsSP).locV;
    const car = G.mulle.user!.car;
    for (let n = 1; n <= 6; n++) {
      const medal = m.sprite(this.medalsSP + n - 1), text = m.sprite(this.medalsSP + n + 5);
      if (car.hasMedal(n)) {
        m.setMemberByName(medal, MEDALS[n - 1]); m.setMemberByName(text, MEDAL_TEXTS[n - 1]);
        medal.locH = 70 + 90 * (n - 1); text.locH = medal.locH - 43;
      } else { m.setMemberByName(medal, "Dummy"); m.setMemberByName(text, "Dummy"); }
      medal.puppet = text.puppet = true;
    }
    this.show();
  }
  ScrollToMid() { this.nowAt = 2; this.show(); }
  scroll(dir: number) {
    if ((dir === -1 && this.nowAt > 1) || (dir === 1 && this.nowAt < this.steps)) { this.nowAt += dir; this.show(); }
  }
  private show() {
    const m = this.movie, v = this.startV - (this.nowAt - 1) * this.stepV;
    for (const [k, ch] of Object.entries(this.list)) { const s = m.sprite(ch); s.locV = v - (this.offsets[k] ?? 0); s.puppet = true; }
    for (let n = 0; n < 6; n++) {
      m.sprite(this.medalsSP + n).locV = v - this.medalsStartV;
      m.sprite(this.medalsSP + n + 6).locV = v - this.medalsStartV + 40;
    }
    m.sprite(4).send("drawCar", undefined, new Point(this.carStart.x, v - this.carStart.y));
  }
}

/** Entry frames labelled with the movie we came from: remember it and show the diploma (frame 1). */
class DiplomaEntry extends Behavior { exitFrame() { ddir().returnTo = this.movie.frameLabel; this.movie.goFrame(1); } }

class DiplomaArrowBH extends Behavior {
  mouseUp() { ddir().send("Scroller", "scroll", S(this.p("direction")).toLowerCase() === "up" ? -1 : 1); }
}

class DiplomaGoBackBH extends Behavior {
  mouseUp() {
    G.sound.play("SndMouseClick", "EFFECT");
    const to = ddir().returnTo || "03";
    if (to === "02") void G.engine.goMovie("02", "j" + G.mulle.user!.myLastPile);
    else void G.engine.goMovie(to, 1);
  }
}

/**
 * PrintBH – the original printed through the PrintOMatic xtra (A4, 20 pt margins): title, player name,
 * "för bilen", car name, a snapshot of the car, medals with captions, signature and frame lines.
 * Here the same layout is built as a page in a new window (positions in points, like the original).
 */
class DiplomaPrintBH extends Behavior {
  mouseUp() {
    G.sound.play("SndMouseClick", "EFFECT");
    ddir().send("Scroller", "ScrollToMid");
    const m = this.movie, area = m.sprite(ddir().sp("ToBeCaptured")).rect;
    // draw now so the snapshot shows the scrolled diploma
    m.draw(m.engine.g);
    const cw = area.right - area.left, ch = area.bottom - area.top;
    const c = document.createElement("canvas"); c.width = cw * 2; c.height = ch * 2;
    const g = c.getContext("2d")!; g.imageSmoothingEnabled = false;
    g.drawImage(m.engine.canvas, area.left, area.top, cw, ch, 0, 0, c.width, c.height);
    const img = (name: string) => { const r = m.member(name); return r?.info.file ? new URL(r.lib.url(r.info), location.href).href : ""; };
    const esc = (t: string) => t.replace(/[&<>"]/g, ch => `&#${ch.charCodeAt(0)};`);
    const font = (name: string) => { const f = m.member(name)?.info.font; return f ? `font:${f.size}pt ${/times/i.test(f.name) ? "'Times New Roman',serif" : "Arial,sans-serif"}` : ""; };
    const at = (x: number, y: number, inner: string, extra = "") => `<div style="position:absolute;left:${x}pt;top:${y}pt;${extra}">${inner}</div>`;
    const u = G.mulle.user!, W = 555, H = 802, sign = 55, corr = 25, bottom = H - sign + 40 - corr;
    let html = at(0, 0, `<img src="${img("Title")}">`);
    html += at(130, 160, esc(u.userId), font("UserName"));
    html += at(130, 200, esc(m.member("08t007v0")?.info.text ?? "för bilen"), font("08t007v0"));
    html += at(130, 220, esc(u.car.name || ""), font("SavedCarName"));
    html += at(50, 272, `<img src="${c.toDataURL()}" style="max-width:490pt;max-height:530pt">`);
    for (let n = 1; n <= 6; n++) if (u.car.hasMedal(n)) {
      const x = 50 + 80 * (n - 1);
      html += at(x, 620, `<img src="${img(MEDALS[n - 1])}">`, "width:80pt;text-align:center");
      html += at(x, 680, esc(m.member(MEDAL_TEXTS[n - 1])?.info.text ?? "").replace("- ", "-<br>"), "width:80pt;text-align:center;font:bold 9pt Arial,sans-serif");
    }
    html += at(195, H - sign - corr, `<img src="${img("08b005v0")}" style="max-width:${W - 295}pt">`);
    const line = (x: number, y: number, w: number, h: number) => at(x, y, "", `width:${w}pt;height:${h}pt;background:#000`);
    html += line(0, 0, 1, bottom) + line(W - 1, 0, 1, bottom) + line(0, bottom, 185, 1) + line(365, bottom, W - 365, 1);
    const w = window.open("", "_blank");
    if (!w) { alert("Tillåt popup-fönster för att skriva ut diplomet."); return; }
    w.document.write(`<!doctype html><meta charset="utf-8"><title>Diplom</title><style>@page{size:A4;margin:20pt}body{margin:0}` +
      `.page{position:relative;width:${W}pt;height:${H}pt;overflow:hidden}img{image-rendering:pixelated}</style>` +
      `<div class="page">${html}</div><script>addEventListener("load",()=>print())<\/script>`);
    w.document.close();
  }
}

// ================================================================== 12 – Quit (slideshow, then end)
let quitDone = false;
const quitMovie = (): MovieScript => ({
  startMovie() { quitDone = false; G.mulle.save(); setCursor("C_Standard"); },
  // click: next picture; double-click: straight to the end
  mouseUp(m) {
    if (quitDone) return;
    const now = performance.now(), dbl = now - lastQuitClick < 450; lastQuitClick = now;
    m.goFrame(dbl ? "Eldmatch" : m.frame + 1);
  },
});
let lastQuitClick = 0;
class QuitSlideSound extends Behavior { exitFrame() { const r = this.movie.member("12e002v0"); if (r) void this.movie.engine.sound.play(2, r); } }
class QuitMarkDone extends Behavior { exitFrame() { quitDone = true; } }
/** The original quits the program; in the browser show a goodbye screen that restarts the game. */
class QuitEnd extends Behavior {
  exitFrame() {
    const e = this.movie.engine;
    e.sound.stopAll();
    G.mulle.save();
    const div = document.createElement("div");
    div.id = "start"; div.textContent = "Hej då! Klicka för att spela igen";
    div.addEventListener("click", () => location.reload());
    document.body.appendChild(div);
    this.movie.stop();
    e.movie = null;
  }
}

// ================================================================== 18 – World chooser (a window over the yard)
/** Callback set by whoever opened the chooser: receives the chosen world id, or "" for cancel. */
export const worldChooser = { onChoose: (_world: string) => {} };

/** WorldScrollBH – one signpost with a sign per world (at the world's SymbolPosition). */
class WorldScrollBH extends Behavior {
  private readonly postSP = 2; private readonly middle = new Point(200, 150);
  beginSprite() {
    G.sound.play("18d001v0", "EFFECT");
    const m = this.movie;
    const post = m.sprite(this.postSP); m.setMemberByName(post, "18b005v0"); post.setLoc(this.middle.x, this.middle.y); post.puppet = true;
    for (let n = 1; n <= 13; n++) if (n !== 7) { const sp = m.sprite(this.postSP + n); m.setMemberByName(sp, "Dummy"); sp.puppet = true; }
    for (const id of G.mulle.worlds) {
      const l = G.mulle.dbValue(`world${id}DB`) as any;
      const pos = l?.get?.("SymbolPosition") ?? 1, symbol = l?.get?.("symbol") ?? "";
      const sp = m.sprite(this.postSP + pos);
      m.setMemberByName(sp, symbol); sp.setLoc(this.middle.x, this.middle.y); sp.puppet = true;
      (sp as any).worldId = id;
    }
    // only one post: no scroll arrows
    for (const a of [17, 18]) m.setMemberByName(m.sprite(a), "Dummy");
  }
}
class WorldChoose extends Behavior { mouseUp() { const id = (this.sprite as any).worldId; if (id) worldChooser.onChoose(id); } }
class WorldCancel extends Behavior { mouseUp() { worldChooser.onChoose(""); } }

// ================================================================== 13 / UNLOAD
// 13 is the original file dialog for car files (replaced by download/upload in the album, movie 06);
// 18 picks between installed worlds (only one world exists). If reached, continue sensibly.
class BackToWorkshop extends Behavior { exitFrame() { void G.engine.goMovie("03", 1); } }
/** UNLOAD: switch junk pile through a reload of the junkyard (low-memory mode). */
class UnloadToPile extends Behavior {
  exitFrame() { const from = G.mulle.whereFrom || "02"; void G.engine.goMovie(from.slice(0, 2), "j" + G.mulle.user!.myLastPile); }
}

// ================================================================== registration
export function registerMisc(engine: Engine) {
  engine.registerMovie("LBSTART", lbstartMovie);
  registerBehavior("LBSTART:1", LBClickSkip); registerBehavior("LBSTART:95", LBWaitMusic);
  registerBehavior("LBSTART:3", goMovie("10")); registerBehavior("LBSTART:7", Behavior); // CatchClick
  registerBehavior("LBSTART:99", Behavior);

  engine.registerMovie("08", diplomaMovie);
  const D = (n: number, c: new () => Behavior) => registerBehavior(`08:${n}`, c);
  D(1, Hold); D(4, DiplomaEntry); D(7, DiplomaScrollBH); D(13, DiplomaArrowBH); D(34, DiplomaGoBackBH); D(38, DiplomaPrintBH);

  engine.registerMovie("12", quitMovie);
  registerBehavior("12:4", QuitSlideSound); registerBehavior("12:9", QuitMarkDone); registerBehavior("12:2", QuitEnd);

  engine.registerMovie("13", () => ({}));
  registerBehavior("13:17", BackToWorkshop);
  engine.registerMovie("18", () => ({ startMovie() { setCursor("C_Standard"); } }));
  registerBehavior("18:15", Hold); registerBehavior("18:17", WorldScrollBH);
  registerBehavior("18:20", WorldChoose); registerBehavior("18:30", WorldCancel); registerBehavior("18:18", Behavior);
  registerBehavior("UNLOAD:1", UnloadToPile); registerBehavior("UNLOAD:3", UnloadToPile);
}
