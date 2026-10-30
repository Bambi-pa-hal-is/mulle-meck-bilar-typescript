import type { ImageAsset, MemberRef } from "../engine/assets.ts";
import type { Movie } from "../engine/movie.ts";
import type { Sprite } from "../engine/sprite.ts";
import type { Car } from "./car.ts";
import type { PartsDB } from "./parts.ts";

export interface OverworldPart {
  id: number;
  view: string;
  file: string;
  kind: "chassis" | "hood" | "cabin" | "cargo" | "seat" | "wheel" | "track" | "frontBumper" | "rearBumper";
  width?: number;
  height?: number;
  offsetY?: number;
}

const BASE = `${import.meta.env.BASE_URL}assets/overworld-parts/`;
const SIZE = 80;
let catalog: Promise<OverworldPart[]> | undefined;
const images = new Map<string, Promise<HTMLImageElement>>();

function loadCatalog() {
  return catalog ??= fetch(`${BASE}manifest.json`).then(r => {
    if (!r.ok) throw new Error(`Overworld part manifest: ${r.status}`);
    return r.json() as Promise<OverworldPart[]>;
  });
}

function loadPart(file: string) {
  let image = images.get(file);
  if (!image) {
    image = new Promise<HTMLImageElement>((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error(`Overworld part image: ${file}`));
      img.src = BASE + file;
    });
    images.set(file, image);
  }
  return image;
}

/** One composited sprite keeps the original map's under/car/over occlusion ordering. */
export class OverworldCar {
  private frames = new Map<string, ImageAsset>();
  private layers: { part: OverworldPart; kind: OverworldPart["kind"]; image: HTMLImageElement; front: boolean }[] = [];
  private signature = "";
  private revision = 0;
  private ready = false;
  private disposed = false;
  private ref: MemberRef;

  constructor(private movie: Movie, private car: Car, private db: PartsDB) {
    // A local member supplies registration metadata without changing any extracted cast.
    this.ref = { lib: movie.libs[0], info: {
      num: -1, name: "AssembledOverworldCar", type: "bitmap",
      w: SIZE, h: SIZE, regX: SIZE / 2, regY: SIZE / 2,
    } };
    this.refresh();
  }

  private refresh() {
    const signature = this.car.parts.join(",");
    if (signature === this.signature) return;
    this.signature = signature;
    this.ready = false;
    this.frames.clear();
    const revision = ++this.revision;
    void this.load(revision).catch(error => {
      if (!this.disposed && revision === this.revision) console.warn("Using original driving car artwork:", error);
    });
  }

  private async load(revision: number) {
    const entries = await loadCatalog();
    const byView = new Map(entries.map(p => [p.view.toLowerCase(), p]));
    const selected = this.car.parts.flatMap(id => {
      const original = this.db.get(id);
      if (!original) return [];
      const part = byView.get(original.useView.toLowerCase());
      if (!part) return [];
      const snaps = Array.isArray(original.requires) ? original.requires.map(s => s.name) : [];
      const front = snaps.includes("a1");
      // A crate/barrel can share artwork between cabin, hood and cargo morphs.
      // Place the mounted variant by its actual snap points, not the catalog's representative ID.
      let kind = part.kind;
      if (!["chassis", "track", "wheel"].includes(kind)) {
        if (snaps.includes("b1")) kind = "hood";
        else if (snaps.includes("b2")) kind = "cabin";
        else if (snaps.includes("b4")) kind = "cargo";
        else if (snaps.includes("a11")) kind = "seat";
        else if (snaps.includes("a3")) kind = "frontBumper";
        else if (snaps.includes("a18")) kind = "rearBumper";
      }
      return [{ part, kind, front }];
    });
    const layers = await Promise.all(selected.map(async p => ({ ...p, image: await loadPart(p.part.file) })));
    if (this.disposed || revision !== this.revision) return;
    this.layers = layers;
    this.ready = layers.some(p => p.part.kind === "chassis");
  }

  /** Returns false while artwork loads or if unavailable, preserving the original fallback. */
  display(sprite: Sprite, direction: number, inclination: number): boolean {
    if (this.disposed) return false;
    this.refresh();
    if (!this.ready) return false;
    const key = `${direction}:${inclination}`;
    let image = this.frames.get(key);
    if (!image) {
      image = this.compose(direction, inclination);
      this.frames.set(key, image);
    }
    if (sprite.member !== this.ref) this.movie.setMember(sprite, this.ref);
    sprite.image = image;
    sprite.width = sprite.height = 0;
    sprite.ink = 36;
    sprite.puppet = true;
    return true;
  }

  private compose(direction: number, inclination: number): ImageAsset {
    const canvas = document.createElement("canvas");
    // Supersampling makes rotation readable at the game's original 640x480 resolution.
    canvas.width = canvas.height = SIZE * 3;
    const g = canvas.getContext("2d")!;
    g.scale(3, 3);
    g.translate(SIZE / 2, SIZE / 2);
    g.save();
    g.scale(1, 0.70);
    g.rotate(direction * Math.PI / 8);
    g.fillStyle = "rgba(25,22,17,0.22)";
    g.beginPath(); g.ellipse(0, 2, 15, 24, 0, 0, Math.PI * 2); g.fill();
    g.restore();
    g.translate(0, -inclination);
    g.scale(1, 0.72 + Math.max(-2, Math.min(2, inclination)) * 0.05);
    g.rotate(direction * Math.PI / 8);
    const draw = (image: HTMLImageElement, x: number, y: number, w: number, h: number) => {
      g.drawImage(image, x - w / 2, y - h / 2, w, h);
    };
    // Ground parts first, then chassis, body, seat, cabin and cargo.
    for (const kind of ["wheel", "track", "chassis", "hood", "frontBumper", "rearBumper", "seat", "cabin", "cargo"] as const) {
      // Opaque roofs cover the driver; open cabins naturally leave him visible through their alpha.
      if (kind === "cabin") {
        g.fillStyle = "#315e87"; g.fillRect(-3, -1, 6, 5);
        g.fillStyle = "#e6b783"; g.beginPath(); g.arc(0, -2, 2.5, 0, 2 * Math.PI); g.fill();
        g.fillStyle = "#b67035"; g.fillRect(-2.5, -4, 5, 2);
      }
      for (const layer of this.layers.filter(p => p.kind === kind)) {
        const { image, front } = layer;
        const stamp = (x: number, y: number, w: number, h: number) =>
          draw(image, x, layer.part.offsetY ?? y, layer.part.width ?? w, layer.part.height ?? h);
        switch (kind) {
          case "chassis": stamp(0, 0, 18, 37); break;
          case "hood": stamp(0, -12, 23, 16); break;
          case "cabin": stamp(0, 0, 22, 17); break;
          case "cargo": stamp(0, 13, 23, 17); break;
          case "seat": stamp(0, 2, 12, 10); break;
          case "frontBumper": stamp(0, -22, 26, 4); break;
          case "rearBumper": stamp(0, 22, 26, 4); break;
          case "wheel":
            draw(image, -12, front ? -13 : 13, 5.5, 10);
            draw(image, 12, front ? -13 : 13, 5.5, 10);
            break;
          case "track":
            draw(image, -12, 0, 6, 37);
            draw(image, 12, 0, 6, 37);
            break;
        }
      }
    }
    const output = document.createElement("canvas");
    output.width = output.height = SIZE;
    output.getContext("2d")!.drawImage(canvas, 0, 0, SIZE, SIZE);
    return { img: output, w: SIZE, h: SIZE, regX: SIZE / 2, regY: SIZE / 2,
      matte: () => output, hit: () => false };
  }

  dispose() { this.disposed = true; ++this.revision; this.frames.clear(); this.layers = []; }
}
