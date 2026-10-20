# MulleWeb – status & remaining work

_Last updated: 2026-10-07 (evening). See PLAN.md for the overall plan._

## How to run
```
cd C:\Levande\MulleBil\MulleWeb
npm install            # first time only
npm run extract        # regenerates public/assets + re/ from "../Decompiled DXR CXT" (~10 s)
npm run dev            # http://localhost:5173/?movie=04   (movie=03 workshop, frame=label also works)
npx tsc --noEmit       # typecheck
npm run build          # static site in dist/ (includes public/assets, ~114 MB) – for your own use only
npx vite preview       # serve dist/ at http://localhost:4173/ (saves are per origin, so separate from dev)
```
Debug helpers in the browser console: `engine` (movie, sprites, frame) and `G` (game state, `G.mulle.user`).
Save data lives in localStorage (`mullebil.*`); clear it to start a fresh player.

## Done
- **Extractor** (`tools/extract`): bitmaps (pixel-exact, white→alpha), sounds + cue points, texts, labels,
  score (sprite spans, ink, behaviors + params, interval ids), Lingo source dumped to `re/<FILE>/` for reference.
- **Engine** (`src/engine`): Director-like movie/score playback, sprites, inks 0/8/36, rect hit test (mask for matte),
  behaviors registry, sound channels, software cursor, prepareMovie→beginSprite→startMovie order.
- **Game framework** (`src/game`): parts DB, car (snap points, properties), user (junk piles, gifts, missions, saves),
  junk pile placement, gSound, gDir/ScreenObject, SpriteAnimBH (anim charts + lip sync), DrawCar, missions.
- **04 Yard** (`src/scenes/m04_yard.ts`) – playable.
- **03 Workshop** (`src/scenes/m03_garage.ts`) – car building verified (pull part off, drop on floor, snap back).
- **02 Junkyard** (`src/scenes/m02_junkyard.ts`) – verified: pile → door → part on workshop floor; signs switch piles.
- **06 Car album** (`src/scenes/m06_album.ts`) – verified: paste car into slot, name it, fetch it back from load mode.
- **05 Driving** (`src/scenes/m05_driving.ts`, `m05_objects.ts`, `src/game/cardriving.ts`, `world.ts`) – verified:
  arrow-key driving along roads, steering, sliding on obstacles, drive into a destination → leaves (home → yard).
  Not yet clicked through: ferry, racing, cows/goats, gas station, map-edge crossing, out of fuel, mouse steering.
  Note: if a car with no engine reaches 05 the original swaps in a ready-made car (`makeCar("Good")`, also a
  console helper) – my test profile "Spelare" got that car.
- **10 Name screen + intro** (`src/scenes/m10_intro.ts`) – verified: new name → login → intro (cue-driven) →
  workshop. The game starts here; `?movie=XX` still auto-logs in as `?user=` (default "Spelare") for testing.
- Verification pass (scripted, real-time stepping): all 13 destinations pick the right branch and return to
  driving; "Done" and "JustDoIt" scenes play through (Viola 89, Figge 92: dog → extra tank + mission 1);
  yard mail mission (letter arrives, Mulle reads it, letter shown, mission marked given).
  Fixes found: SpriteAnim waitForWhat/doWhat compared case-sensitively (Lingo symbols aren't) – scenes waiting
  for a sound never continued; sound timing now on the wall clock (works even if audio is blocked); parts of
  disabled extra material are kept in the save but hidden; the exhibition (94) can't be skipped (original).
- Fixes from the user's play session (save file):
  * "Progress too fast": cars built counted on every drive (last-driven parts were kept per yard visit);
    now kept on the car (`Car.enterParts`) like the original – only a changed car counts.
  * Parts sliding off screen / duplicated: hidden floor-part slots kept falling and saved -200 positions;
    junk adds now replace instead of duplicating; junkyard glide-back can't end off screen;
    `User.repairJunk()` fixes damaged saves on login.
  * Behavior errors no longer stop the game (`safeCall`, errors listed in `scriptErrors`).
  * Name screen: the name field keeps keyboard focus (clicks on the picture used to steal it); visible caret.
    Starting a new player is as in the original: type the name on the sign, then click Mulle or press Enter.
  * Figge + dog → extra tank is what the data says (object 14: #ExtraTank, mission 1). Figge's car parts
    come from his workshop visits every 3rd built car after you've visited him – those were mistimed by the
    build-counter bug.
- Crash sweep: all destinations 82–94 played in real time with no script errors (exhibition fully through).
- Transitions: score transition channel (main ch 2) + transition members (spec [?][chunk][type][flags][ms]) →
  `engine.startTransition` (wipes, centre-out/edges-in, push as wipe, dissolves as random blocks); album wipe.
- Fonts: text members carry font/size/colour from STXT style runs + the movie's Fmap (`MemberInfo.font`);
  name fields are Times 24 (diploma 36), racing board Arial 20 green. Used for canvas text and the DOM input.
- Cursor: the software cursor sprite now follows the mouse every display frame (not only at the 12 fps tempo).
- **Extra material** (optional; checkbox "Använd extramaterial" on the start screen → `mullebil.extras`):
  plugin casts merged at load (`MulleGlobals.load(extras)`), searchable via `engine.extraLibs`. World chooser
  (18) opens as a window over the yard (`engine.openWindow`) when >1 world; `m66_scrapyard.ts` crane puzzle –
  verified: world 2 drives, puzzle rules, solved → prize part in the yard.
- **LBSTART, 08, 12, 13, 18, UNLOAD** (`src/scenes/m_misc.ts`) – logo intro and diploma verified; the game now
  starts with the logo. Quit slideshow not yet clicked through.
- Timing: score tempo channel decoded (main ch 1: u16 value + kind byte, 0xf6 = fps, 0xf7 = wait N s). The game
  runs at 12 fps (was 15). "go next marker" with no later marker now stays put (Director behaviour).
- Loading: whole movie cast preloaded on movie switch; shared casts 00 + CDDATA preloaded behind the start
  screen ("Laddar… N%"); sprites switch to already-loaded images immediately (no blank frames).
- Intro note: frame 88 of movie 10 (reached after the battery animation) shows the road's-end sunset picture
  with a 13 s wait in the original data – kept as is; revisit if it turns out to be wrong.
- Engine: score sound channels 1/2 now play (main ch 4 = sound 1, ch 3 = sound 2); cue points tracked for all
  channels and also sent to frame scripts' `CuePassed`; cue names compared case-insensitively (Lingo).
- **Destinations 82–94** (`src/scenes/m8x_destinations.ts`) – verified 92 (Figge): correct branch, full
  scene, click skips back to driving. Other places share the same code paths (rules per place).
- Junkyard drag & drop fixed: dragged part ignored for hover (doors open, cursor changes); parts hit-test
  on pixels (`Sprite.pixelHit`). Workshop: unfilled shapes (invisible click areas) are no longer drawn.
- Display: whole-number nearest-neighbour scaling (`?fit=fill` to fill the window instead).
- Extractor: internal cast first-member number from config offset 12 (movies 13, 18, 88, 92 start at 2).
- Sound: loop flag now read from member info flags (bit 0x10 = don't loop) – fixes engine hum & ambience.
- Engine: a pending `go` beats a later "go to the frame" in the same cycle (Director semantics).
- Shared toolbox + menu dialog (ToolBoxBH/FDialogBH): new car / diploma / quit / close.
- Engine: shape/text sprites sized from the score (loc = top-left), DOM text input for editable fields,
  Director event passing (sprite → frame script → movie script `mouseDown/mouseUp`),
  dangling CursorBH score refs resolved by their params.

- Film loops: extracted from the member's SCVW child chunk (same layout as VWSC; `loop` in the manifest) and drawn by `Movie.drawFilmLoop` (one loop frame per score frame, castLib 65535 = own cast). Mulle now bikes in the intro (movie 10, `LillCykelLoop` / `cykel_loop`).

## Remaining work (in suggested order)
All movies are ported. What's left is polish / verification:
1. Verified: workshop phone mission (mission 5), Figge's workshop visit, petrol station refill,
   out of fuel (voice line → back to the garage, drivingInfo cleared so the next drive starts full),
   yard parcel (parcel → address note → part unpacked onto the yard; new users start with no gifts, as in
   UserNewTemplateDB), world chooser from the yard (extras on; the click area is the road at top-left, as in
   the original), quit slideshow (7 s per picture, Eldmatch, goodbye screen), diploma print (rebuilt with the
   PrintOMatic layout: title, names, car snapshot, medals + captions, signature, frame lines; A4 page).
   Medal captions are richText members (RTE1 = text) – now extracted and drawn centred/wrapped.
   Note: the solar panel (part 91) cancels electricity use, so solar cars never run out (original behaviour).
   Also verified: ferry (map 22 at grid 4,4 – needs the ticket from 86; carries the car across), racing
   (map 28 at grid 4,5 – start/finish logic, time format as the original, <15 s = speed medal, one shared
   high-score board like the original CustomRacingDB), cows (part for any horn) and goats (only horn type 5,
   otherwise the car is pushed back), scrapyard intro (timer sync points 320/530/600/800/950 ticks hit on time).
   Object locations (world 1): Cows m7/m15/m23, Goats m5/m18, Ferry m22, Racing m28, WBridge m8, CBridge m27.
   Bridges (WBridge: weight < 20 crosses + medal 6, heavier cars splash; CBridge: drawbridge cycle) checked
   line by line against the original scripts.
   Still to verify by hand: junkyard drag + name typing.
   Test harness idea: step frames with `movie.tick()` + MessageChannel yields (background tabs throttle timers).
2. Scrapyard (66) is reached as in the original scripts: yard car → world signpost → drive to the scrapyard.

## Engine / framework TODOs
- Placeholder: `MemoryControlBH` is registered as an empty behavior in `src/scenes/index.ts`.
- Registry sweep (all movies, every score behavior + frame script): all resolve except movie 13's file-dialog
  behaviors (dialog replaced; its frame script leaves at once). Stale non-script references are skipped silently.

## Notes / gotchas learned
- Testing with Claude-in-Chrome: the game loop uses requestAnimationFrame, which pauses while the tab is in the
  background – take a screenshot (brings the tab forward) before expecting frames to advance.
- External casts (`00.cst`, `CDDATA.cst`, `DATA.CST`) are numbered from 1 (ignore their config chunk).
- Score width/height only apply when the stretch flag is set. An unstretched sprite that gets a bitmap member
  (score or behavior) always shows it at the bitmap's size – stale score spans on missing members (83 f18/f155,
  92 f89-96, 94 f19, 89 ch42) used to leave a box size behind and stretched Mulle/the dog.
- A `go` from a mouse event must beat the frame's `exitFrame` "go to the frame".
- Lingo compares strings and symbols case-insensitively. Never compare a value from game data (behavior params,
  member names, symbol .name, cue names) with `===` – lowercase both sides or compare interned Syms
  (`v === sym("X")`). Bugs from this so far: cue "Cykla", SpriteAnim waitForWhat "Sound", BlinkThing
  waitFrames "Sound" (stalled every destination gift scene, e.g. Salka → Figge).
- Speech cue times are milliseconds; "Loop" cues are ignored.
- `public/assets` and `re/` are generated from your own install and git-ignored – never redistribute them.
