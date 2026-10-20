/**
 * Movie 04 – Gårdsplanen (the yard). Hub between garage (03), junkyard (02 via garage) and driving (05).
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, Sym, sym, PropList } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir, ScreenObject, inside, type ScreenReport } from "../game/dir.ts";
import { G, random, pick } from "../game/runtime.ts";
import { DrawCarBH, drawCar } from "../game/drawcar.ts";
import { kickPartSound, performMission } from "../game/shared.ts";
import { worldChooser } from "./m_misc.ts";
import type { SpriteAnimBH } from "./common.ts";
import { setCursor } from "./common.ts";

const symName = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");

// ------------------------------------------------------------------ gDir
export class YardDir extends GameDir {
  carOnYard = false;
  gCurrentSound = "";
  parts!: YardPartsCommon;
  constructor(m: Movie) {
    super(m);
    this.spriteList = { CarStart: 19, DoorStart: 10, fDialog: 107, JunkStart: 61, drag: 100, mailBox: 13, giftSprite: 60,
      addresNote: 105, mulleInCar: 38, mulleStand: 59, Buffa: 58, carClick: 101 };
    this.carOnYard = G.mulle.user!.toYardThroughDoor === 0;
    this.parts = new YardPartsCommon(this);
  }
  /** Sprite setup from Dir.new – applied once frame 1's sprites exist. */
  setupSprites() {
    const m = this.movie;
    const u = G.mulle.user!;
    m.sprite(this.sp("fDialog")).setLoc(320, 240);
    const set = (name: string, member: string) => { const s = m.sprite(this.sp(name)); m.setMemberByName(s, member); s.puppet = true; };
    if (this.carOnYard) {
      m.sprite(this.sp("carClick")).setLoc(50, 15);
      set("mulleStand", "Dummy"); set("Buffa", "Dummy");
      const chassis = m.sprite(this.sp("CarStart") + u.car.chassisSPOffset); m.setMemberByName(chassis, "20b001v1"); chassis.puppet = true;
    } else {
      m.sprite(this.sp("carClick")).setLoc(-400, -400);
      set("mulleInCar", "Dummy");
      const chassis = m.sprite(this.sp("CarStart") + u.car.chassisSPOffset); m.setMemberByName(chassis, "Dummy"); chassis.puppet = true;
    }
  }
  /** The Mulle sprite currently on screen (standing or in the car). */
  mulleName() { return this.carOnYard ? "mulleInCar" : "mulleStand"; }
}

const dir = () => G.dir as YardDir;

// ------------------------------------------------------------------ movie script
export const yardMovie = (): MovieScript & { cuePassed(m: Movie, ch: number, nr: number, name: string): void } => ({
  prepareMovie(m) { G.dir = new YardDir(m); },
  startMovie(m) {
    const d = dir();
    d.setupSprites();
    G.sound.stopAllEffects(); G.sound.stopBG();
    if (G.mulle.loadIndicator === 0) G.sound.play("02e010v0", "BG");
    const u = G.mulle.user!;
    u.car.updateProperties();
    if (d.carOnYard) {
      d.send("mulleInCar", "activate", 1); d.send("mulleInCar", "init");
      d.send("mulleStand", "activate", 0); d.send("Buffa", "activate", 0);
      d.send("CarStart", "drawCar");
    } else {
      d.send("mulleStand", "activate", 1); d.send("mulleStand", "init");
      d.send("Buffa", "activate", 1); d.send("Buffa", "init");
      d.send("mulleInCar", "activate", 0);
    }
    d.send("JunkStart", "drawJunk");
    d.send("mulleInCar", "setMulleSpeak");
    // postal parts become gifts
    G.mulle.calcCurrentlyAvailable("Postal");
    for (const id of G.mulle.getCurrentlyAvailable("Postal")) u.gifts.push([id]);
    if (u.gifts.length) {
      d.send(d.mulleName(), "MakeMulleSpeak", "Package");
      const gift = m.sprite(d.sp("giftSprite")); m.setMemberByName(gift, "04b004v0"); gift.setLoc(180, 410); gift.puppet = true;
    } else if (G.mulle.junkPiles.figgeBeenHere) {
      d.send(d.mulleName(), "MakeMulleSpeak", "FiggeRemark");
      G.mulle.junkPiles.figgeBeenHere = 0;
    }
    G.mulle.checkMissions();
    if (G.mulle.currentMission && u.missionIsComing === 1 && symName(G.mulle.currentMission.type).toLowerCase() === "mail")
      d.send("mailBox", "showMail", 1);
  },
  cuePassed(m, ch, nr, name) {
    const d = dir(); if (!d) return;
    d.send(d.mulleName(), "spritecuePassed", ch, nr, name);
    if (name.toLowerCase() === "tonextframe") m.goFrame(m.frame + 1);
  },
});

// ------------------------------------------------------------------ frame scripts
/** Main loop frame: runs gDir, handles the world-selection window result, holds frame. */
class YardLoop extends Behavior {
  exitFrame() { dir()?.loop(); this.movie.goFrame(this.movie.frame); }
}
const goMovie = (id: string) => class extends Behavior { exitFrame() { void G.engine.goMovie(id, 1); } };
const goFrame = (f: number | string) => class extends Behavior { exitFrame() { this.movie.goFrame(f); } };

// ------------------------------------------------------------------ doors
/** Shared logic of DoorBH / CarPortBH / MailBH: highlight while hovered. */
abstract class HoverDoor extends Behavior implements Behavior {
  doortracking = false;
  activeClick = true;
  locked = false;
  screenObject!: ScreenObject;
  trackRect = { left: 0, top: 0, right: 0, bottom: 0 };
  beginSprite() {
    this.trackRect = this.sprite.rect;
    this.screenObject = new ScreenObject(dir(), this, this.trackRect, 0);
    dir().addScreenObject(this.screenObject);
  }
  activateClick(s: boolean) { this.activeClick = !!s; }
  get mediaName() { return this.p<string>("mediaName", ""); }
  get goToType() { return symName(this.p("goToType", sym("marker"))).toLowerCase(); }
  protected open(sound: string, prio: "EFFECT" | "OPEFFECT", cursor: string) {
    this.doortracking = true;
    G.sound.play(sound, prio);
    this.movie.offsetMember(this.sprite, +1); this.sprite.puppet = true;
    setCursor(cursor);
  }
  protected closeIfLeft(sound: string, prio: "EFFECT" | "OPEFFECT") {
    const { x, y } = this.movie.engine.mouse;
    // trackRect is captured from the closed door graphic at beginSprite
    if (this.doortracking && !inside(x, y, this.trackRect)) {
      this.movie.offsetMember(this.sprite, -1);
      G.sound.play(sound, prio);
      setCursor("C_Standard");
      this.doortracking = false;
    }
  }
  protected navigate() {
    if (this.goToType === "marker") this.movie.goFrame(this.mediaName);
    else void G.engine.goMovie(this.mediaName, 1);
  }
  abstract report(o: ScreenObject, what: ScreenReport): void;
}

/** DoorBH – the small garage door (into the workshop, 03). */
class DoorBH extends HoverDoor {
  beginSprite() { super.beginSprite(); this.locked = dir().carOnYard; }
  mouseEnter() { if (!this.locked && this.activeClick && !this.doortracking) this.open("02e016v0", "EFFECT", dir().parts.tracking ? "c_MoveRight" : "C_Right"); }
  prepareFrame() { if (!this.locked) this.closeIfLeft("02e015v0", "EFFECT"); }
  report(_o: ScreenObject, what: ScreenReport) {
    if (this.locked || what !== "clicked") return;
    G.mulle.user!.toYardThroughDoor = 1;
    G.mulle.whereFrom = "04";
    this.navigate();
  }
}

/** CarPortBH – the big doors: drive the car into the garage, or go in to build one. */
class CarPortBH extends HoverDoor {
  alwaysOpen = false;
  beginSprite() {
    super.beginSprite();
    if (dir().carOnYard) { this.alwaysOpen = true; this.movie.offsetMember(this.sprite, +1); this.sprite.puppet = true; }
  }
  mouseEnter() { if (!this.locked && this.activeClick && !this.doortracking && !this.alwaysOpen) this.open("02e016v0", "OPEFFECT", dir().parts.tracking ? "c_MoveRight" : "C_Right"); }
  prepareFrame() { if (!this.locked && !this.alwaysOpen) this.closeIfLeft("02e015v0", "OPEFFECT"); }
  report(_o: ScreenObject, what: ScreenReport) {
    if (this.locked || !this.activeClick) return;
    if (this.alwaysOpen) {
      if (what === "over") { this.doortracking = true; setCursor(this.movie.engine.mouse.down ? "c_MoveRight" : "C_Right"); }
      else if (what === "NotOver") { this.doortracking = false; setCursor("C_Standard"); }
    }
    const u = G.mulle.user!;
    u.toYardThroughDoor = 0;
    if (what !== "clicked") return;
    if (dir().carOnYard) {
      this.activeClick = false;
      G.mulle.whereFrom = "04_car";
      this.navigate();
    } else {
      G.mulle.whereFrom = "04_nocar";
      this.movie.goFrame("noCar");
    }
  }
}

/** MailBH – the mailbox: shows a letter when a mail mission has arrived. */
class MailBH extends HoverDoor {
  missionIsOn = false;
  mouseEnter() { if (!this.locked && !this.missionIsOn && this.activeClick && !this.doortracking) this.open("04e009v0", "EFFECT", "c_click"); }
  prepareFrame() { if (!this.locked && !this.missionIsOn) this.closeIfLeft("04e010v0", "EFFECT"); }
  showMail() { this.movie.setMemberByName(this.sprite, "02b005v0"); this.sprite.puppet = true; this.missionIsOn = true; }
  mouseUp() {
    if (!this.activeClick || this.locked || !this.missionIsOn) return;
    this.movie.sendAll("activateClick", 0);
    dir().send(dir().mulleName(), "MakeMulleSpeak", "Mail");
    this.missionIsOn = false;
  }
  report(_o: ScreenObject, what: ScreenReport) {
    if (!this.activeClick || this.locked || what !== "clicked" || this.missionIsOn) return;
    const mulle = this.movie.sprite(dir().sp(dir().mulleName()));
    if (symName(mulle.send("getMode")).toLowerCase() === "wait") dir().send(dir().mulleName(), "MakeMulleSpeak", "noMail");
  }
}

// ------------------------------------------------------------------ Mulle & Buffa
/** Common base for Mulle in the yard: talking with lip-sync through SpriteAnimBH. */
abstract class MulleTalker extends Behavior {
  mode = "Wait";
  frozenAction = "";
  intoMail = false;
  currentAnimChart = "";
  activeClick = true;
  get anim(): SpriteAnimBH { return this.sprite.behaviors.find(b => (b as any).type === "SpriteAnim") as SpriteAnimBH; }
  getMode() { return this.mode; }
  activate(s: boolean) { this.activeClick = !!s; }
  loop() {
    if (this.movie.frame === 2) { dir().deleteLoopObject(this); this.MakeMulleSpeak(this.frozenAction); }
  }
  /** On frame 1 the request is deferred one frame (sounds aren't ready yet in the original). */
  MakeMulleSpeak(action: string | Sym) {
    action = symName(action);
    if (this.movie.frame === 1) { this.frozenAction = action; dir().addLoopObject(this); return; }
    this.speak(action);
  }
  protected abstract speak(action: string): void;
  protected soundFor(action: string): string | undefined {
    switch (action) {
      case "shopFull": return pick(["04d016v0", "04d017v0", "04d018v0"]);
      case "Package": return pick(["04d013v0", "04d014v0", "04d015v0"]);
      case "FiggeRemark": return "04d021v0";
      case "noMail": return "04d001v0";
      case "Mail": this.intoMail = true; return "04d020v0";
    }
  }
  protected finishTalk(normalChart: string) {
    if (this.intoMail) { this.intoMail = false; performMission(this.movie); }
    if (this.currentAnimChart === "TalkToMe") this.sprite.send("setAnimChart", normalChart);
    this.anim.setAnimNormal();
  }
}

/** MulleyardBH – Mulle standing in the yard. */
class MulleyardBH extends MulleTalker {
  beginSprite() { this.currentAnimChart = "Mulle"; this.anim?.setAnimNormal(); }
  protected speak(action: string) {
    this.anim.playAnimSound("");
    const snd = this.soundFor(action);
    if (action !== "shopFull" || random(2) === 2) { this.currentAnimChart = "TalkToMe"; this.sprite.send("setAnimChart", "TalkToMe"); }
    this.mode = "Talk";
    if (snd) this.anim.makeAnimSpeech(snd);
    this.sprite.send("setAnimAction", this.mode);
  }
  Stopped() {
    if (this.mode === "Talk") this.finishTalk("Mulle");
    this.mode = "Wait";
    this.sprite.send("setAnimAction", this.mode);
  }
}

/** MulleCarBH – Mulle sitting in the car on the yard; knows whether the car can run. */
class MulleCarBH extends MulleTalker {
  noBreaks = 0; noStearing = 0;
  OkToRun = 0;
  startSounds: string[] = [];
  crashSounds: string[] = [];
  beginSprite() { this.currentAnimChart = "MulleCar"; }
  getProperty(p: Sym | string) {
    const k = symName(p);
    if (k === "OkToRun") return this.OkToRun;
    if (k === "CrashState") {
      const r = [...(this.noBreaks ? ["noBrakes"] : []), ...(this.noStearing ? ["NoStearing"] : [])];
      return r.length ? r : 0;
    }
  }
  setMulleSpeak() {
    const car = G.mulle.user!.car;
    this.crashSounds = []; this.startSounds = [];
    if (car.prop("Steering") === 0) { this.crashSounds.push("04d005v0"); this.noStearing = 1; }
    if (car.prop("break") === 0) { this.crashSounds.push("04d006v0"); this.noBreaks = 1; }
    if (car.prop("Pedals") === 0) {
      if (car.prop("acceleration") === 0) this.startSounds.push("04d004v0");
      if (car.prop("EngineType") === 0) this.startSounds.push("04d022v0");
      if (car.prop("ElectricVolume") === 0) this.startSounds.push("04d003v0");
      if (car.prop("FuelVolume") === 0 && car.prop("EngineType") !== 3) this.startSounds.push("04d002v0");
    }
    if (!this.startSounds.length) { this.startSounds.push("04d008v0", "04d009v0", "04d010v0"); this.OkToRun = 1; }
  }
  protected speak(action: string) {
    const refuseWhileTalking = action === "Refuse" && this.mode === "Talk";
    if (!refuseWhileTalking) this.anim.playAnimSound("");
    let snd = this.soundFor(action);
    if (action === "Refuse" && this.mode !== "Talk") snd = pick(this.startSounds);
    this.currentAnimChart = "TalkToMe";
    this.sprite.send("setAnimChart", "MulleCarTalk");
    if (!refuseWhileTalking && snd) {
      this.mode = "Talk";
      this.anim.makeAnimSpeech(snd);
      this.sprite.send("setAnimAction", "Talk");
    }
    dir().gCurrentSound = snd ?? "";
  }
  Stopped() {
    if (this.mode === "Talk") { this.finishTalk("MulleCar"); dir().gCurrentSound = ""; }
    this.mode = "Wait";
    this.sprite.send("setAnimAction", this.mode);
  }
}

/** BuffaYardBH – the dog: wanders, lies down, sleeps; click to wake. */
class BuffaYardBH extends Behavior {
  mode = "Wait";
  activeClick = true;
  okToGoLeft = false;
  activate(s: boolean) { this.activeClick = !!s; }
  private act(m: string) { this.mode = m; this.sprite.send("setAnimAction", m); }
  exitFrame() {
    if (G.mulle.loadIndicator === 0) {
      if (this.activeClick && this.mode === "Wait" && random(100) === 1) this.randomMove(3);
    } else if (!dir().carOnYard && this.mode !== "Sleep" && this.mode !== "GetDown") this.act("GetDown");
  }
  randomMove(max: number) {
    for (;;) {
      const r = random(max);
      if (r === 1 && !this.okToGoLeft) { this.act("WalkRightStart"); return; }
      if (r === 2 && this.okToGoLeft) { this.sprite.send("setAnimLoc", new Point(-330, 0), 1); this.act("WalkLeftStart"); return; }
      if (r === 3) { this.act("GetDown"); return; }
    }
  }
  mouseUp() {
    if (this.mode === "Wait") this.randomMove(3);
    else if (this.mode === "Sleep") this.act("GetUp");
  }
  Stopped() {
    const next: Record<string, () => string> = {
      WalkRightStart: () => "WalkRight",
      WalkRight: () => "WalkRightStop",
      WalkRightStop: () => { this.okToGoLeft = true; this.sprite.send("setAnimLoc", new Point(200, 0), 1); return "Wait"; },
      WalkLeftStart: () => "WalkLeft",
      WalkLeft: () => "WalkLeftStop",
      WalkLeftStop: () => { this.okToGoLeft = false; this.sprite.send("setAnimLoc", new Point(140, 0), 1); return "Wait"; },
      GetDown: () => "Sleep",
      Sleep: () => random(30) === 1 ? "GetUp" : "Sleep",
    };
    this.act(next[this.mode]?.() ?? "Wait");
  }
}

// ------------------------------------------------------------------ car on the yard
/** carClickBH – click the car to drive off (05) – or crash if brakes/steering are missing. */
class CarClickBH extends Behavior {
  activeClick = true;
  engineSnd = 0;
  okToLeave = false;
  activateClick(s: boolean) { this.activeClick = !!s; }
  mouseEnter() { if (this.activeClick && dir().carOnYard) setCursor("c_click"); }
  mouseLeave() { if (this.activeClick && dir().carOnYard) setCursor("C_Standard"); }
  loop() {
    if (G.sound.finished(this.engineSnd)) { dir().deleteLoopObject(this); G.sound.play("04e002v0", "EFFECT"); this.goOut(); }
  }
  private mulle() { return this.movie.sprite(dir().sp("mulleInCar")).behaviors.find(b => b instanceof MulleCarBH) as MulleCarBH; }
  mouseUp() {
    if (!this.activeClick || !dir().carOnYard) return;
    G.mulle.whereFrom = "04";
    const mc = this.mulle();
    if (mc.OkToRun) {
      if (!mc.crashSounds.length && G.mulle.worlds.length > 1) {
        // more than one world (extra material): choose where to drive in a small window
        this.checkNrOfBuiltCars();
        dir().activate(false);
        worldChooser.onChoose = id => {
          G.engine.closeWindow();
          if (id) { G.mulle.activeWorld = id; this.okToLeave = true; this.kickEngine(); }
          else dir().activate(true);
        };
        void G.engine.openWindow("18", 109, 90, 422, 300);
        dir().send("mulleInCar", "setAnimAction", sym("Still"));
        return;
      }
      if (!mc.crashSounds.length) { this.okToLeave = true; this.checkNrOfBuiltCars(); }
      this.kickEngine();
      dir().send("mulleInCar", "setAnimAction", sym("Still"));
    } else dir().send("mulleInCar", "MakeMulleSpeak", "Refuse");
  }
  private checkNrOfBuiltCars() {
    const u = G.mulle.user!, car = u.car;
    if (car.enterParts.join() !== car.parts.join()) { u.nrOfBuiltCars++; u.figgeIsComing = 1; u.missionIsComing = 1; }
    car.enterParts = [...car.parts];
  }
  private kickEngine() {
    dir().activate(false);
    const engines = ["05e074v0", "05e067v0", "05e025v0", "05e004v0", "05e011v0", "05e053v0", "05e018v0", "05e060v0", "05e032v0"];
    const t = G.mulle.user!.car.prop("EngineType");
    this.engineSnd = t >= 1 && t <= 9 ? G.sound.play(engines[t - 1], "EFFECT") : 0;
    if (this.okToLeave) { this.okToLeave = false; this.movie.goFrame("05"); }
    else dir().addLoopObject(this);
  }
  private goOut() {
    const c = this.mulle().crashSounds;
    if (c.length === 2) this.movie.goFrame(random(2) === 1 ? "fence" : "offroad");
    else if (c[0] === "04d005v0") this.movie.goFrame("offroad");
    else if (c[0] === "04d006v0") this.movie.goFrame("fence");
  }
}

// ------------------------------------------------------------------ gifts
/** packageBH – the parcel: click to read the address note. */
class PackageBH extends Behavior {
  activeClick = true; currentSound = 0;
  activateClick(s: boolean) { this.activeClick = !!s; }
  mouseEnter() { if (this.activeClick) setCursor("c_click"); }
  mouseLeave() { if (this.activeClick) setCursor("C_Standard"); }
  loop() { if (G.sound.finished(this.currentSound)) { dir().deleteLoopObject(this); dir().gCurrentSound = ""; } }
  mouseDown() {
    if (!this.activeClick || dir().gCurrentSound !== "" || !this.sprite.member || this.sprite.member.info.name.toLowerCase() === "dummy") return;
    const note = this.movie.sprite(dir().sp("addresNote"));
    this.movie.setMemberByName(note, "04b006v0"); note.setLoc(320, 240); note.puppet = true;
    G.sound.stopAllEffects();
    this.currentSound = G.sound.play("04d023v0", "EFFECT");
    dir().gCurrentSound = "04d023v0";
    this.movie.sendAll("activateClick", 0);
    dir().addLoopObject(this);
  }
}

/** noteBH – click the note away: the gift parts are unpacked onto the yard. */
class NoteBH extends Behavior {
  mouseDown() {
    if (this.sprite.member?.info.name.toLowerCase() !== "04b006v0" || dir().gCurrentSound === "04d023v0") return;
    const u = G.mulle.user!;
    this.movie.setMemberByName(this.sprite, "Dummy");
    this.movie.sendAll("activateClick", 1);
    for (const g of u.gifts) if (Array.isArray(g)) u.addJunkPart("yard", g[0] as number);
    u.gifts = [];
    dir().send("JunkStart", "drawJunk");
    this.movie.setMemberByName(this.movie.sprite(dir().sp("giftSprite")), "Dummy");
  }
}

// ------------------------------------------------------------------ parts lying on the yard
const YARD_SLOTS = 20;

/** DrawJunkBH – lays out the parts lying on the yard into sprites 61.. */
class DrawJunkBH extends Behavior {
  drawJunk() {
    const first = this.spriteNum - 1;
    const yard = G.mulle.user!.getJunk("yard");
    // parts unknown to the current databases (extra material turned off) stay saved but are not shown
    const ids = (yard.keys() as number[]).filter(id => G.mulle.parts.get(id));
    for (let n = 1; n <= YARD_SLOTS; n++) {
      const s = this.movie.sprite(first + n);
      if (n <= ids.length) s.send("setPart", ids[n - 1], yard.get(ids[n - 1]));
      else { s.send("setPart", 0); s.setLoc(-200, -200); this.movie.setMember(s, null); }
    }
  }
}

/** FloorPartBH – a part on the ground: falls into place, can be picked up. */
class FloorPartBH extends Behavior {
  partId = 0; isFalling = false; velV = 0; velH = 0; activeClick = true;
  beginSprite() { this.sprite.pixelHit = true; }
  activateClick(s: boolean) { this.activeClick = !!s; }
  private yardRect() { return G.mulle.junkPiles.rects.yard[0]; }
  setPart(id: number, loc?: Point) {
    this.isFalling = false;
    const s = this.sprite; s.puppet = true;
    if (!id) { this.partId = 0; this.movie.setMemberByName(s, "Dummy"); return; }
    this.partId = id;
    const part = G.mulle.parts.get(id)!;
    this.movie.setMemberByName(s, part.junkView);
    const h = s.member?.info.h ?? 0;
    let x = loc?.x ?? 400, y = loc?.y ?? 420;
    if (x < 290) this.velH = 20; else if (x > 640) x = 640;
    const halfH = Math.trunc(h / 2);
    const floorV = 460 - halfH;
    const r = this.yardRect();
    if (y < r.top || x < 290) { this.isFalling = true; this.velV = 0; }
    else if (y > floorV + 2 * halfH) y = floorV + 2 * halfH;
    s.setLoc(x, y);
    G.mulle.user!.setJunkPartProp(sym("yard"), id, new Point(x, y));
  }
  mouseDown() { if (this.activeClick && this.partId && this.sprite.member) dir().parts.grabbedPart(this.partId); }
  exitFrame() {
    if (!this.isFalling) return;
    const s = this.sprite, r = this.yardRect();
    if (s.locV >= r.top) {
      if (s.locH < 290) s.locH += this.velH;
      else if (s.locH > r.right) s.locH = r.right;
      else {
        this.velV = 0; this.isFalling = false;
        kickPartSound(this.partId, "InternalGround");
        G.mulle.user!.setJunkPartProp(sym("yard"), this.partId, new Point(s.locH, s.locV));
      }
    } else {
      if (this.velV < 30) this.velV += 8;
      s.locV += this.velV;
      if (s.locH < 290) s.locH += this.velH;
    }
  }
  forcePart() {
    if (!this.isFalling) return;
    const p = G.mulle.junkPiles.setPartPosition(sym("yard"), this.partId);
    kickPartSound(this.partId, "InternalGround");
    this.sprite.setLoc(p.x, p.y);
    G.mulle.user!.setJunkPartProp(sym("yard"), this.partId, p);
  }
}

/** The yard's PartsCommon: picking parts up from the ground and dropping them. */
class YardPartsCommon {
  tracking = false;
  constructor(private d: YardDir) {}
  grabbedPart(id: number) {
    this.tracking = true;
    const m = this.d.movie;
    m.sendAll("forcePart");
    G.mulle.user!.removeJunkPart(sym("yard"), id);
    this.d.send("JunkStart", "drawJunk");
    this.d.send("drag", "startDrag", id);
  }
  letGoOfPart(id: number, where: Point | Sym, dropLoc?: Point) {
    const u = G.mulle.user!, jp = G.mulle.junkPiles;
    if (where instanceof Sym) {
      // dropped on the garage door -> goes to the workshop floor (unless full)
      if (jp.checkFull(sym("shopFloor"))) {
        this.d.send(this.d.mulleName(), "MakeMulleSpeak", "shopFull");
        u.addJunkPart("yard", id, dropLoc ?? new Point(400, 420));
      } else {
        kickPartSound(id, "ExternalGround");
        u.addJunkPart("shopFloor", id);
        setCursor("C_Right");
      }
    } else {
      const r = jp.rects.yard[0];
      if (inside(where.x, where.y, r)) kickPartSound(id, "InternalGround");
      if (where.y > r.bottom) { u.addJunkPart("yard", id); kickPartSound(id, "InternalGround"); }
      else u.addJunkPart("yard", id, where);
    }
    this.d.send("JunkStart", "drawJunk");
    this.tracking = false;
  }
}

/** DragPartBH – the part currently carried by the mouse. */
class DragPartBH extends Behavior {
  active = false; dragging = false; partId = 0;
  beginSprite() { this.sprite.noHit = true; }
  private screenObject: ScreenObject | null = null;
  isDragging() { return this.dragging; }
  startDrag(id: number) {
    this.dragging = true; this.active = true; this.partId = id;
    const part = G.mulle.parts.get(id)!;
    this.movie.setMemberByName(this.sprite, part.junkView); this.sprite.puppet = true;
    this.sprite.ink = 36;
    // catch-all screen object with top priority that reports the release
    const d = dir();
    this.screenObject = new ScreenObject(d, this, { left: -1000, top: -1000, right: 2000, bottom: 2000 }, "ClosedHand");
    d.addScreenObject(this.screenObject, 1);
    this.screenObject.checkDown(320, 240);
    this.exitFrame();
  }
  exitFrame() { if (this.active) { const m = this.movie.engine.mouse; this.sprite.setLoc(m.x | 0, m.y | 0); } }
  report(_o: ScreenObject, what: ScreenReport) {
    if (what !== "clicked" || !this.active) return;
    this.dragging = false; this.active = false;
    if (this.screenObject) { dir().deleteScreenObject(this.screenObject); this.screenObject = null; }
    this.movie.setMemberByName(this.sprite, "Dummy");
    // over one of the two garage doors that lead inside?
    let overDoor = false;
    const first = dir().sp("DoorStart");
    for (const n of [first, first + 1]) {
      const b = this.movie.sprite(n).behaviors.find(x => x instanceof HoverDoor) as HoverDoor | undefined;
      if (b?.doortracking && ["03", "garage"].includes(b.mediaName.toLowerCase())) overDoor = true;
    }
    const m = this.movie.engine.mouse, loc = new Point(m.x | 0, m.y | 0);
    if (overDoor) dir().parts.letGoOfPart(this.partId, sym("ToShopFloor"), loc);
    else dir().parts.letGoOfPart(this.partId, loc);
  }
}

// ------------------------------------------------------------------ registration
export function registerYard(engine: Engine) {
  engine.registerMovie("04", yardMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`04:${n}`, c);
  B(15, YardLoop);
  B(9, goFrame(2));     // "giftstuff" – unused marker, back to the loop
  B(3, goMovie("03")); B(7, goMovie("03")); B(38, goMovie("03")); B(45, goMovie("03"));
  B(2, goMovie("05")); B(32, goMovie("12")); B(6, goMovie("08"));
  B(4, goFrame(2)); B(94, goFrame("done"));
  B(8, Behavior);       // yardBH: only declares a property
  B(19, DoorBH); B(20, CarPortBH); B(46, MailBH);
  B(31, MulleyardBH); B(33, MulleCarBH); B(28, BuffaYardBH);
  B(36, CarClickBH); B(23, PackageBH); B(24, NoteBH);
  B(21, DrawJunkBH); B(22, FloorPartBH); B(11, DragPartBH);
  registerBehavior("DrawCar", DrawCarBH);
  void drawCar; void PropList;
}
