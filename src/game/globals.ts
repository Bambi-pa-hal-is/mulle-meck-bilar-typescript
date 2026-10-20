import { loadCast, type CastLib, type MemberInfo } from "../engine/assets.ts";
import { lingoValue, toLingo, PropList, Point, sym, type Sym } from "../engine/lingo.ts";
import { PartsDB } from "./parts.ts";
import { User, JunkPiles } from "./user.ts";
import type { World } from "./world.ts";

const SAVE_PREFIX = "mullebil.";

export interface Mission { id: number; type: Sym; image: string; sound: string; }

/**
 * gMulleGlobals: game-wide state shared by every movie.
 * Databases come from the "data" (DATA.CST) and "CDdata" (CDDATA.cst) casts.
 */
export class MulleGlobals {
  parts = new PartsDB();
  externalParts = new PropList();       // #Postal / #JunkMan / #Destinations / #Random -> ids
  currentlyAvailable = new PropList();
  missionList: number[] = [];
  worlds: string[] = [];
  maps: number[] = [];
  objects: number[] = [];
  users: string[] = [];
  user: User | null = null;
  junkPiles = new JunkPiles(this);
  chassis = 1;
  newCarName = "Ny bil";
  whereFrom = "00";
  justStarted = 1;
  customCursorActive = 1;
  loadIndicator = 0;
  /** Mission currently being delivered (mail/telephone). */
  currentMission: Mission | null = null;
  kickMission = 0;
  libs: CastLib[] = [];
  /** The driving world (loaded on first drive; random destinations persist while driving). */
  world: World | null = null;

  /** Extra material (Plugins folder): Figge's scrapyard world + extra parts. Chosen on the start screen. */
  extras = false;
  /** Plugin casts loaded when extras are on (searched for part/world/map data and images). */
  pluginLibs: CastLib[] = [];
  /** World selected in the world chooser (movie 18); "" = the first world. */
  activeWorld = "";

  async load(extras = false) {
    this.extras = extras;
    const [data, cd, shared] = await Promise.all([loadCast("DATA"), loadCast("CDDATA"), loadCast("00")]);
    this.libs = [data, cd, shared];
    if (extras) {
      // like xferPluginCasts: every plugin cast in the Plugins folder adds to the databases
      const names = ["PLUGIN", ...Array.from({ length: 10 }, (_, i) => `BIL${i + 1}`)];
      this.pluginLibs = (await Promise.all(names.map(n => loadCast(n).catch(() => null)))).filter((l): l is CastLib => !!l);
      this.libs.push(...this.pluginLibs);
    }
    const v = (name: string) => lingoValue(this.memberInfo(name)?.text);
    this.newCarName = this.memberInfo("00t002v0")?.text ?? "Ny bil";
    // Plugin casts (bil1..10 / Plugin.cst) could extend these lists – see plan phase 4.7.
    const partIds = [...(v("PartsDB") as number[])];
    const ext = v("ExternalPartsDB"); this.externalParts = ext instanceof PropList ? ext : new PropList();
    const listMerge = (base: unknown[], extra: unknown) => { if (Array.isArray(extra)) for (const x of extra) if (!base.includes(x)) base.push(x); };
    const extraLists: Record<string, unknown[]> = { WorldsDB: [], mapsDB: [], ObjectsDB: [], MissionsDB: [] };
    for (const lib of this.pluginLibs) {
      const pv = (name: string) => lingoValue(lib.byName.get(name.toLowerCase())?.text);
      listMerge(partIds, pv("PartsDB"));
      for (const k of Object.keys(extraLists)) listMerge(extraLists[k], pv(k));
      const pe = pv("ExternalPartsDB");
      if (pe instanceof PropList) for (const [cat, ids] of pe.entries) {
        const cur = this.externalParts.get<number[]>(cat as any) ?? [];
        listMerge(cur, ids); this.externalParts.set(cat as any, cur);
      }
    }
    this.parts.load(partIds, [cd, data, ...this.pluginLibs]);
    this.currentlyAvailable = new PropList().set("Postal", []).set("JunkMan", []).set("Destinations", []).set("random", []);
    this.missionList = [...((v("MissionsDB") as number[]) ?? []), ...(extraLists.MissionsDB as number[])];
    this.worlds = [...((v("WorldsDB") as string[]) ?? []), ...(extraLists.WorldsDB as string[])];
    this.maps = [...((v("mapsDB") as number[]) ?? []), ...(extraLists.mapsDB as number[])];
    this.objects = [...((v("ObjectsDB") as number[]) ?? []), ...(extraLists.ObjectsDB as number[])];
    this.users = JSON.parse(localStorage.getItem(SAVE_PREFIX + "users") ?? "[]");
  }

  memberInfo(name: string): MemberInfo | undefined {
    const k = name.toLowerCase();
    for (const lib of this.libs) { const m = lib.byName.get(k); if (m) return m; }
    return undefined;
  }
  dbValue(name: string) { return lingoValue(this.memberInfo(name)?.text); }

  // ------------------------------------------------------------- users
  /** Log in (creating a new profile from UserNewTemplateDB if needed). */
  login(userId: string): "ok" | "error" {
    const saved = localStorage.getItem(SAVE_PREFIX + "user." + userId);
    const u = new User(this);
    if (saved) {
      const l = lingoValue(saved);
      if (l instanceof PropList) { u.fromList(l); this.user = u; u.repairJunk(); }
    } else {
      if (this.users.length >= 6) return "error";
      const t = this.dbValue("UserNewTemplateDB");
      if (t instanceof PropList) u.fromList(t);
      u.userId = userId;
      const junk = this.dbValue("InitialJunkDB");
      if (junk instanceof PropList) u.initJunk(junk);
      this.users.push(userId);
    }
    this.user = u;
    this.save();
    return "ok";
  }

  deleteUser(userId: string) {
    localStorage.removeItem(SAVE_PREFIX + "user." + userId);
    this.users = this.users.filter(u => u !== userId);
    this.save();
  }

  save() {
    localStorage.setItem(SAVE_PREFIX + "users", JSON.stringify(this.users));
    if (this.user) localStorage.setItem(SAVE_PREFIX + "user." + this.user.userId, toLingo(this.user.toList()));
  }

  // ------------------------------------------------------------- external parts
  /** Parts in a category that the user doesn't own anywhere yet. */
  calcCurrentlyAvailable(category: string) {
    const list = this.externalParts.get<number[]>(category);
    if (!Array.isArray(list) || !this.user) return;
    this.currentlyAvailable.set(category, list.filter(id => !this.user!.findPart(id)));
  }
  getCurrentlyAvailable(category: string): number[] { return this.currentlyAvailable.get<number[]>(category) ?? []; }

  // ------------------------------------------------------------- missions
  loadMission(id: number): Mission | null {
    const l = this.dbValue(`mission${id}DB`);
    if (!(l instanceof PropList)) return null;
    return { id: l.get("MissionId"), type: l.get("type"), image: l.get("image") ?? "", sound: l.get("sound") ?? "" };
  }

  /** A new mission is due every second built car (Missions.checkMissions). */
  checkMissions() {
    const u = this.user; if (!u) return;
    if (u.nrOfBuiltCars > 0 && u.nrOfBuiltCars % 2 === 0 && u.missionIsComing === 1 && !this.currentMission) {
      const todo = this.missionList.filter(m => !u.givenMissions.includes(m));
      if (todo.length) { this.kickMission = todo[0]; this.currentMission = this.loadMission(todo[0]); }
    }
  }
}

export const gMulle = new MulleGlobals();
export { Point, sym };
