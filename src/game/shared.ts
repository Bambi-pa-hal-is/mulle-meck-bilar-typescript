/**
 * Logic shared by several movies: part landing sounds and mission delivery (mail / telephone).
 */
import { Sym } from "../engine/lingo.ts";
import type { Movie } from "../engine/movie.ts";
import { G } from "./runtime.ts";

const symName = (v: unknown) => v instanceof Sym ? v.name : String(v ?? "");

/** Thud sound depending on part weight (SharedSound.kickPartSound). */
export function kickPartSound(id: number, where: "InternalGround" | "ExternalGround" | "car") {
  const parts = G.mulle.parts; let part = parts.get(id);
  if (part && !part.props.count && part.isMorphPart()) part = parts.get((part.morphsTo as number[])[0]);
  const w = part?.prop("Weight") ?? 1;
  const idx = w <= 1 ? 0 : w <= 3 ? 1 : 2;
  const table = {
    InternalGround: ["00e001v0", "00e002v0", "00e003v0"],
    ExternalGround: ["00e004v0", "00e005v0", "00e006v0"],
    car: ["03e003v0", "03e003v1", "03e003v2"],
  };
  G.sound.play(table[where][idx], "OPEFFECT");
}

/**
 * Deliver the current mission (Missions.performMission).
 * Mail: the letter is shown full screen in the yard; telephone: the phone in the workshop rings.
 */
export function performMission(m: Movie) {
  const d = G.dir!, g = G.mulle, u = g.user!, mission = g.currentMission;
  d.activate(false);
  u.missionIsComing = 0;
  if (!mission) { d.activate(true); return; }
  const finish = () => { g.currentMission = null; g.kickMission = 0; d.activate(true); };
  if (!u.givenMissions.includes(g.kickMission)) u.givenMissions.push(g.kickMission);

  if (symName(mission.type).toLowerCase() === "telephone") {
    const small = m.sprite(d.sp("TeleSmall")), big = m.sprite(d.sp("TeleBig"));
    const home = { x: small.locH, y: small.locV };
    let snd = G.sound.play("03e001v0", "EFFECT"), state: "shake" | "talk" = "shake", frame = 0;
    d.addLoopObject({
      loop() {
        if (state === "shake") {
          frame++;
          if (!G.sound.finished(snd)) { small.locH += frame % 2 === 0 ? -2 : 2; small.puppet = true; return; }
          small.setLoc(home.x, home.y);
          m.setMemberByName(big, "03b002v0"); big.setLoc(320, 240); big.puppet = true;
          snd = G.sound.play(mission.sound, "EFFECT"); state = "talk";
        } else if (G.sound.finished(snd)) {
          m.setMemberByName(big, "Dummy");
          d.deleteLoopObject(this);
          finish();
        }
      },
    });
    return;
  }

  // Mail
  const note = m.sprite(d.sp("addresNote"));
  m.setMemberByName(note, mission.image); note.setLoc(320, 240); note.puppet = true;
  const snd = G.sound.play(mission.sound, "EFFECT");
  d.addLoopObject({
    loop() {
      if (!G.sound.finished(snd) || !m.engine.mouse.down) return;
      m.setMemberByName(note, "Dummy");
      m.setMemberByName(m.sprite(d.sp("mailBox")), "04n001v0");
      d.deleteLoopObject(this);
      finish();
    },
  });
}
