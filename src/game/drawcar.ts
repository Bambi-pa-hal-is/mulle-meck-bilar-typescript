import { Behavior } from "../engine/behavior.ts";
import { Point, PropList } from "../engine/lingo.ts";
import type { Movie } from "../engine/movie.ts";
import { Car } from "./car.ts";
import { G } from "./runtime.ts";

/**
 * Draws a car into a block of 35 consecutive sprites starting at `startSP`.
 * Each part goes to the layer(s) given by the snap point it is mounted on.
 */
export function drawCar(m: Movie, startSP: number, origin: Point, car: Car, scale?: number) {
  const parts = G.mulle.parts;
  const chassisSP = car.chassisSPOffset, driverLayer = car.driverLayer;
  // clear the block first so removed parts disappear
  for (let i = 0; i < 35; i++) { if (i === driverLayer || i === driverLayer + 1) continue; m.setMember(m.sprite(startSP + i), null); }
  for (const id of car.parts) {
    const part = parts.get(id); if (!part) continue;
    let layers: number[], snapOff: number[];
    if (Array.isArray(part.requires) && part.requires.length) {
      const info = car.snapInfo(part.requires[0]);
      layers = info?.[0] ?? [chassisSP]; snapOff = info?.[1] ?? [0, 0];
    } else { layers = [chassisSP]; snapOff = [0, 0]; }
    const place = (layer: number, which: 1 | 2) => {
      if (layer < 0) return;
      if (layer > driverLayer - 1) layer += 2; // two sprites reserved for the driver
      const memberName = which === 1 ? part.useView : part.useView2;
      if (!memberName) return;
      const sp = m.sprite(startSP + layer);
      m.setMemberByName(sp, memberName);
      const k = scale ?? 1;
      const x = origin.x + Math.trunc(part.offset.x * k) + Math.trunc(snapOff[0] * k);
      const y = origin.y + Math.trunc(part.offset.y * k) + Math.trunc(snapOff[1] * k);
      if (scale !== undefined && sp.member?.info.w) { sp.width = Math.trunc(sp.member.info.w * k); sp.height = Math.trunc(sp.member.info.h! * k); }
      sp.setLoc(x, y);
      sp.puppet = true;
      sp.send("setPart", id);
    };
    place(layers[0], 1);
    if (layers.length === 2) place(layers[1], 2);
  }
}

/** DrawCar behavior (00 cast): put on the first of the 35 car sprites. */
export class DrawCarBH extends Behavior {
  beginSprite() { if (this.p("ShowDirect", 1)) this.drawCar(); }
  drawCar(startSP?: number, offset?: Point, partsList?: number[], scale?: number) {
    const car = G.mulle.user!.car;
    const sp = startSP ?? this.spriteNum;
    let origin = offset;
    if (this.p("useChassisLoc", 1)) {
      const ch = this.movie.sprite(sp + car.chassisSPOffset);
      origin = new Point(ch.locH, ch.locV);
    }
    origin ??= new Point(this.p("offsetH", 320), this.p("offsetV", 240));
    let drawn = car;
    if (partsList) { drawn = new Car(G.mulle.parts, G.mulle.chassis); drawn.fromList(new PropList().set("parts", partsList)); }
    drawCar(this.movie, sp, origin, drawn, scale);
    // In the workshop, only parts nothing else is mounted on may be picked off the car.
    if (this.movie.id === "03") (G.dir as any)?.parts?.freeOrBindParts?.();
  }
}
