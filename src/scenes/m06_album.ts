/**
 * Movie 06 – the car album ("Spara bil" / "Hämta bil"). Twelve slots: save the current car and name it,
 * or fetch a saved car (its parts are pulled back out of the junk piles).
 * The original's disk export (movie 13 file dialog) is replaced by a browser download / file upload.
 */
import { Behavior, registerBehavior } from "../engine/behavior.ts";
import { Point, PropList, lingoValue, toLingo } from "../engine/lingo.ts";
import type { Movie, MovieScript } from "../engine/movie.ts";
import type { Engine } from "../engine/engine.ts";
import { GameDir, ScreenObject, type ScreenReport } from "../game/dir.ts";
import { G } from "../game/runtime.ts";
import { drawCar } from "../game/drawcar.ts";
import { Car } from "../game/car.ts";
import { setCursor } from "./common.ts";

const MEDALS: Record<number, string> = { 1: "00n004v0", 2: "00n005v0", 3: "00n006v0", 4: "00n007v0", 5: "00n010v0", 6: "00n009v0" };

class AlbumDir extends GameDir {
  mode: "save" | "load";
  chosenSlot = 0;
  slotOccupied = false;
  changedName = false;
  carPasted = false;
  currentCarSlot = 0;
  firstFree = 1;
  doNextFrame: "" | "jump" | "activateScreen" = "";
  private intro: { loop(): void } | null = null;

  constructor(m: Movie) {
    super(m);
    this.spriteList = { CarStart: 2, MedalsStart: 59, SmallCarStart: 75, PhotoBG: 74, loadCar: 74, YesButton: 111,
      NoButton: 112, EnterName: 65, SlotStart: 46, Flerp: 45, InsertCar: 68, Dialogue: 114, DialogueButton: 113, GoBack: 66 };
    this.mode = m.frameLabel === "load" ? "load" : "save";
    const u = G.mulle.user!;
    if (this.mode === "save") {
      G.mulle.whereFrom = "06";
      G.sound.play("06e002v0", "OPEFFECT"); G.sound.play("06d001v0", "EFFECT");
    } else {
      G.mulle.whereFrom = "07";
      G.sound.play(u.saves.some(Boolean) ? "07d001v0" : "07d003v0", "EFFECT");
    }
  }

  get nameText() { return this.movie.getText("SavedCarName"); }
  set nameText(v: string) { this.movie.setText("SavedCarName", v); }

  start() {
    this.findFirstFree();
    setCursor("C_Standard");
    this.slotSprite(this.firstFree).send("clicked");
    if (this.mode === "save") this.startIntro();
  }

  slotSprite(n: number) { return this.movie.sprite(this.sp("SlotStart") + n - 1); }

  /** The small photo of the current car sliding into place (IntroScript). */
  private startIntro() {
    const m = this.movie, d = this;
    const bg = m.sprite(this.sp("PhotoBG"));
    m.setMemberByName(bg, "06b014v0"); bg.puppet = true;
    const loc = new Point(67, 401);
    let step = 1;
    this.intro = {
      loop() {
        if (d.carPasted) { d.deleteLoopObject(this); return; }
        drawCar(m, d.sp("SmallCarStart"), new Point(loc.x - 25, loc.y + 15), G.mulle.user!.car, 0.5);
        bg.setLoc(loc.x, loc.y);
        if (++step > 8) d.deleteLoopObject(this);
      },
    };
    this.intro.loop();
    this.addLoopObject(this.intro);
  }

  choseSlot(slot: number, occupied: boolean) {
    this.saveIfNecessary();
    this.chosenSlot = slot; this.slotOccupied = occupied;
    const m = this.movie;
    if (this.mode === "load") { const s = m.sprite(this.sp("loadCar")); m.setMemberByName(s, occupied ? "07b004v0" : "Dummy"); s.puppet = true; }
    m.setMemberByName(m.sprite(this.sp("YesButton")), "Dummy");
    m.setMemberByName(m.sprite(this.sp("NoButton")), "Dummy");
    this.changedName = false;
  }

  saveIfNecessary() {
    if (!this.changedName) return;
    const u = G.mulle.user!;
    u.changeCarName(this.chosenSlot, this.nameText);
    if (this.chosenSlot === this.currentCarSlot) u.car.name = this.nameText;
    this.findFirstFree();
    G.mulle.save();
  }

  /** Mark occupied slots; in save mode pick the first empty slot (or a new one, max 12). */
  findFirstFree() {
    const saves = G.mulle.user!.saves;
    this.firstFree = 0;
    saves.forEach((car, i) => {
      if (car) { const s = this.slotSprite(i + 1); this.movie.setMember(s, this.movie.memberInLib(this.movie.member("06n002v0")!, this.movie.memberNum("06n002v0") + i)); s.puppet = true; }
      else if (!this.firstFree) this.firstFree = i + 1;
    });
    if (this.mode === "save") { if (!this.firstFree) this.firstFree = saves.length < 12 ? saves.length + 1 : 1; }
    else this.firstFree = 1;
  }

  /** Put the current car into the chosen slot and let the player name it. */
  prepareEnterName() {
    const m = this.movie, u = G.mulle.user!;
    this.carPasted = true;
    this.currentCarSlot = this.chosenSlot;
    this.send("InsertCar", "activate", 0);
    for (let n = 0; n < 35; n++) { m.setMemberByName(m.sprite(this.sp("CarStart") + n), "Dummy"); m.setMemberByName(m.sprite(this.sp("SmallCarStart") + n), "Dummy"); }
    m.setMemberByName(m.sprite(this.sp("PhotoBG")), "Dummy");
    G.sound.stopAllEffects();
    G.sound.play("06e001v0", "EFFECT"); G.sound.play("06d002v0", "EFFECT");
    G.engine.startTransition(1, 500); // puppetTransition(1, 2, 5, 0): wipe right, 2/4 s
    drawCar(m, this.sp("CarStart"), new Point(282, 220), u.car);
    u.car.name = "";
    u.saveCar(this.chosenSlot);
    this.nameText = "";
    this.findFirstFree();
    this.slotSprite(this.chosenSlot).send("clicked");
    this.editName();
    G.mulle.save();
  }

  /** Name entry for the chosen (occupied) slot. */
  editName() {
    if (this.mode !== "save" || !this.slotOccupied) { this.movie.engine.editField(null); return; }
    this.movie.engine.editField(this.sp("EnterName"), this.nameText, v => { this.nameText = v; this.changedName = true; });
  }

  /** Fetch a car: the current car is scrapped, the saved one rebuilt from the junk piles. */
  loadCar(list?: PropList) {
    const u = G.mulle.user!;
    if (!list) { if (!this.slotOccupied) return; const s = u.getSavedCar(this.chosenSlot); if (!s) return; list = s; }
    u.trashCar();
    u.car.fromList(list);
    // the saved car's parts are taken back out of whichever junk pile they lie in
    for (const id of u.car.parts) {
      if (id <= 1) continue;
      const master = G.mulle.parts.get(id)?.master || id;
      if ([...u.junk.values()].some(p => p instanceof PropList && p.has(master))) u.removeJunkPart(0, master);
    }
    this.doNextFrame = "jump";
    G.mulle.save();
  }

  replaceAsk() { new ReplaceDialog(this); }

  activateScreen(on: boolean) {
    for (let n = 1; n <= 12; n++) this.slotSprite(n).send("activate", on ? 1 : 0);
    if (!on || (this.mode === "save" && !this.carPasted)) { this.send("InsertCar", "activate", on ? 1 : 0); this.send("PhotoBG", "activate", on ? 1 : 0); }
    this.send("DialogueButton", "activate", on ? 1 : 0);
    this.send("GoBack", "activate", on ? 1 : 0);
  }

  kill() {
    this.saveIfNecessary();
    this.movie.engine.editField(null);
    this.nameText = " ";
    G.mulle.save();
    G.sound.play("06e003v0", "EFFECT");
    super.kill();
  }
}
const dir = () => G.dir as AlbumDir;

/** "Do you want to replace the car in this slot?" yes/no. */
class ReplaceDialog {
  private objs: ScreenObject[] = [];
  constructor(private d: AlbumDir) {
    const m = d.movie;
    G.sound.play("06d004v0", "EFFECT");
    const s = m.sprite(d.sp("Dialogue"));
    m.setMemberByName(s, "06b015v0"); s.setLoc(528, 437); s.puppet = true;
    for (const r of [{ left: 469, top: 433, right: 524, bottom: 464 }, { left: 530, top: 432, right: 585, bottom: 463 }]) {
      const o = new ScreenObject(d, this, r); d.addScreenObject(o); this.objs.push(o);
    }
  }
  report(o: ScreenObject, what: ScreenReport) {
    if (what !== "clicked") return;
    const yes = this.objs.indexOf(o) === 0;
    this.d.movie.setMemberByName(this.d.movie.sprite(this.d.sp("Dialogue")), "Dummy");
    for (const x of this.objs) this.d.deleteScreenObject(x);
    this.objs = [];
    if (yes) this.d.prepareEnterName();
  }
}

export const albumMovie = (): MovieScript => ({
  prepareMovie(m) { G.dir = new AlbumDir(m); },
  startMovie() { dir().start(); },
  stopMovie() { dir()?.kill(); },
});

// ------------------------------------------------------------------ frame scripts
class AlbumLoop extends Behavior {
  exitFrame() {
    const d = dir(); if (!d) return;
    d.loop();
    if (d.doNextFrame === "jump") { d.doNextFrame = ""; this.movie.goFrame("Leave"); }
    else { if (d.doNextFrame === "activateScreen") { d.doNextFrame = ""; d.activateScreen(true); } this.movie.goFrame(this.movie.frame); }
  }
}
class BackToWorkshop extends Behavior { exitFrame() { void G.engine.goMovie("03", 1); } }

// ------------------------------------------------------------------ slots
/** ShowSavedCarBH – one album slot; clicking shows the saved car, its name and medals. */
class ShowSavedCarBH extends Behavior {
  active = true;
  get saveNr() { return this.p("SaveNr", 1); }
  beginSprite() {
    const r = this.sprite.rect, e = 12;
    dir().addScreenObject(new ScreenObject(dir(), this, { left: r.left - e, top: r.top - e, right: r.right + e, bottom: r.bottom + e }, "normal"));
  }
  activate(v: number | boolean) { this.active = !!v; }
  report(_o: ScreenObject, what: ScreenReport) { if (what === "clicked") this.clicked(); }
  clicked() {
    if (!this.active) return;
    const d = dir(), m = this.movie, u = G.mulle.user!;
    const car = u.getSavedCar(this.saveNr);
    if (this.saveNr !== d.chosenSlot) G.sound.play("06e003v0", "OPEFFECT");
    d.choseSlot(this.saveNr, !!car);
    this.eraseCar();
    if (car) {
      (car.get<number[]>("medals") ?? []).forEach(id => {
        const s = m.sprite(d.sp("MedalsStart") + id - 1);
        if (MEDALS[id]) { m.setMemberByName(s, MEDALS[id]); s.setLoc(570, 65 + 62 * (id - 1)); s.puppet = true; }
      });
      d.nameText = car.get<string>("name") ?? "";
      const show = new Car(G.mulle.parts, G.mulle.chassis); show.fromList(new PropList().set("parts", car.get("parts") ?? []));
      drawCar(m, d.sp("CarStart"), new Point(282, 220), show);
    } else d.nameText = " ";
    d.editName();
    const flerp = m.sprite(d.sp("Flerp"));
    m.setMember(flerp, m.memberInLib(m.member("06n003v0")!, m.memberNum("06n003v0") + this.saveNr - 1)); flerp.puppet = true;
  }
  private eraseCar() {
    const d = dir(), m = this.movie;
    for (let n = 0; n < 35; n++) m.setMemberByName(m.sprite(d.sp("CarStart") + n), "Dummy");
    for (let n = 0; n < 6; n++) m.setMemberByName(m.sprite(d.sp("MedalsStart") + n), "Dummy");
  }
}

/** PasteCarBH – the photo of the current car: click to put it in the chosen slot. */
class PasteCarBH extends Behavior {
  active = true;
  activate(v: number | boolean) { this.active = !!v; }
  mouseUp() { if (!this.active) return; if (dir().slotOccupied) dir().replaceAsk(); else dir().prepareEnterName(); }
}
class LoadCarBH extends Behavior { mouseUp() { dir().loadCar(); } }

/** GoBackBH – back to the workshop. */
class GoBackBH extends Behavior {
  active = true;
  activate(v: number | boolean) { this.active = !!v; }
  mouseUp() {
    if (!this.active) return;
    G.sound.play("SndMouseClick", "OPEFFECT");
    if (dir().mode === "save") dir().saveIfNecessary();
    this.movie.goFrame("Leave");
  }
}

/** DeleteSavedBH – yes/no buttons. */
class DeleteSavedBH extends Behavior {
  mouseUp() {
    if (this.p("YesNo", 1)) dir().prepareEnterName();
    const m = this.movie;
    m.setMemberByName(m.sprite(dir().sp("YesButton")), "Dummy");
    m.setMemberByName(m.sprite(dir().sp("NoButton")), "Dummy");
  }
}

/**
 * LoadSaveCarBH – the disk button. Originally saved/loaded car files on disk via a dialog;
 * here: save mode downloads the chosen car as a file, load mode opens a file picker.
 */
class LoadSaveCarBH extends Behavior {
  active = true; rolling = 0; sndId = 0;
  activate(v: number | boolean) { this.active = !!v; }
  mouseEnter() { this.rolling = 1; }
  mouseLeave() { this.rolling = 0; G.sound.stop(this.sndId); }
  exitFrame() {
    if (!this.rolling) return;
    if (++this.rolling === 15) { G.sound.stopAllEffects(); this.sndId = G.sound.play(dir().mode === "save" ? "06d007v0" : "07d005v0", "EFFECT"); }
  }
  mouseUp() {
    if (!this.active) return;
    G.sound.play("SndMouseClick", "OPEFFECT");
    const d = dir(), u = G.mulle.user!;
    if (d.mode === "save") {
      d.saveIfNecessary();
      const car = d.slotOccupied ? u.getSavedCar(d.chosenSlot) : u.car.toList();
      if (!car) return;
      const name = (car.get<string>("name") || this.movie.getText("06t001v0") || "MinBil").replace(/[\\/:*?"<>|]/g, "");
      const blob = new Blob([toLingo(car)], { type: "text/plain" });
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob); a.download = `${name}.mullebil`; a.click();
      setTimeout(() => URL.revokeObjectURL(a.href), 1000);
    } else {
      const inp = document.createElement("input");
      inp.type = "file"; inp.accept = ".mullebil,.txt";
      inp.onchange = async () => {
        const f = inp.files?.[0]; if (!f) return;
        const l = lingoValue(await f.text());
        if (l instanceof PropList && Array.isArray(l.get("parts"))) d.loadCar(l);
        else alert("Det här är ingen bil-fil.");
      };
      inp.click();
    }
  }
}

// ------------------------------------------------------------------ registration
export function registerAlbum(engine: Engine) {
  engine.registerMovie("06", albumMovie);
  const B = (n: number, c: new () => Behavior) => registerBehavior(`06:${n}`, c);
  B(1, AlbumLoop); B(5, BackToWorkshop);
  B(7, ShowSavedCarBH); B(14, Behavior); B(30, LoadCarBH); B(31, LoadSaveCarBH); B(32, PasteCarBH);
  B(33, Behavior); B(34, GoBackBH); B(36, DeleteSavedBH);
}
