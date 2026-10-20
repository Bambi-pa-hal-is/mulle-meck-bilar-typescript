import type { MemberRef, ImageAsset } from "./assets.ts";
import { type Behavior, safeCall } from "./behavior.ts";

export const enum Ink { Copy = 0, Matte = 8, BgTransparent = 36 }

/** A sprite channel (1..120), mirrors Director's sprite properties. */
export class Sprite {
  member: MemberRef | null = null;
  image: ImageAsset | null = null;
  locH = 0; locV = 0;
  width = 0; height = 0;
  /** Score stretch flag: only stretched sprites keep their box size when a bitmap member is swapped in. */
  stretch = false;
  ink = 0;
  blend = 100;
  visible = true;
  /** Puppeted sprites are no longer driven by the score. */
  puppet = false;
  fore = 255; back = 0;
  behaviors: Behavior[] = [];
  /** Score interval currently applied (behaviors live while it is unchanged). */
  interval: unknown = null;
  /** Score span last applied (score data is re-applied only when this changes). */
  span: unknown = null;
  /** Ignored when finding the sprite under the mouse (e.g. the part being dragged). */
  noHit = false;
  /** Hit-test on the bitmap's pixels instead of its rectangle (parts lying around overlap a lot). */
  pixelHit = false;
  /** Bumped on member change so pending async image loads can be discarded. */
  private loadSeq = 0;

  constructor(public readonly num: number) {}

  get loc() { return { x: this.locH, y: this.locV }; }
  setLoc(x: number, y: number) { this.locH = x; this.locV = y; }

  /** Bounding rect in stage coordinates. */
  get rect() {
    const info = this.member?.info;
    // Shapes and text fields have no bitmap: their loc is the top-left corner, size comes from the score.
    if (info && info.type !== "bitmap" && info.type !== "filmLoop") return { left: this.locH, top: this.locV, right: this.locH + this.width, bottom: this.locV + this.height };
    // Use the member metadata so the rect is valid before the image has finished loading.
    const mw = info?.w ?? 0, mh = info?.h ?? 0;
    if (!mw || !mh) return { left: this.locH, top: this.locV, right: this.locH, bottom: this.locV };
    const w = this.width || mw, h = this.height || mh;
    const left = this.locH - (info!.regX ?? 0) * (w / mw), top = this.locV - (info!.regY ?? 0) * (h / mh);
    return { left, top, right: left + w, bottom: top + h };
  }

  /** Point inside the sprite? Like Director, only matte ink tests the actual shape; other inks use the rectangle. */
  hitTest(x: number, y: number) {
    if (!this.visible || !this.member || !["bitmap", "shape", "text", "button"].includes(this.member.info.type)) return false;
    const r = this.rect;
    if (x < r.left || y < r.top || x >= r.right || y >= r.bottom) return false;
    if ((this.ink === Ink.Matte || this.pixelHit) && this.image) {
      const img = this.image;
      return img.hit(((x - r.left) * img.w) / (r.right - r.left), ((y - r.top) * img.h) / (r.bottom - r.top));
    }
    return true;
  }

  nextLoad() { return ++this.loadSeq; }
  isCurrentLoad(n: number) { return n === this.loadSeq; }

  /** Send a message to all behaviors on this sprite (Lingo sendSprite). */
  send(msg: string, ...args: unknown[]): unknown {
    let result: unknown;
    for (const b of this.behaviors) if (typeof (b as any)[msg] === "function") result = safeCall(b, msg, ...args);
    return result;
  }
}
