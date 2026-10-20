# MulleWeb – Browser rebuild of "Mulle Meck bygger bilar"

A from-scratch TypeScript re-implementation of the Macromedia Director 6 game,
playable in a browser. Original game assets are **extracted locally from your own
install** (`C:\Levande\MulleBil`) by a build tool; they are not committed or redistributed.

## Source material (input)
| Path | What |
|---|---|
| `../Decompiled DXR CXT/MOVIES/*.dir, *.cst` | Unprotected Director 6 files (RIFX big-endian `.dir`, XFIR little-endian `.cst`) – bitmaps, palettes, sounds, text, score, Lingo bytecode |
| `../Decompiled DXR CXT/Plugins/*` | Figge's scrapyard plugin (66.dir), bil1-10.cst, Plugin.cst |
| `../Decompiled DXR CXT/DATA/DATA.CST` | Default save file (fresh game state) |
| `../Källfiler/GFX, SND` | Pre-extracted PNG/WAV (partial; used for cross-checking) |
| `../Karta.jpg`, `../Handbok/*.pdf` | Map + manual – reference for game rules |

## Architecture
```
MulleWeb/
  tools/extract/      Node+TS: Director file parser -> public/assets
    riff.ts           RIFX/XFIR container, mmap, KEY*, CAS*, CASt
    bitmap.ts         BITD RLE decode, palettes (CLUT + system Mac/Win)
    sound.ts          snd / ediM -> .wav
    score.ts          VWSC / VWLB frame labels & sprite channels
    lingo.ts          Lscr/Lnam/Lctx -> disassembly (logic reference)
    main.ts           Writes PNGs + manifest.json per movie
  public/assets/      (generated, git-ignored)
  src/
    engine/           Stage (640x480 canvas), Sprite, Cast/asset loader,
                      Audio, Input/cursors, SceneManager, Save (localStorage)
    game/             Shared game state: parts inventory, car model, missions
    scenes/           One module per Director movie (02 junkyard, 03 garage, ...)
  index.html
```

## How the work is phased
1. **Extractor** – parse every movie/cast, dump bitmaps (with registration points
   and names), sounds, texts, frame labels, Lingo disassembly. Output `manifest.json`.
2. **Engine core** – canvas stage, cast loader, sprites with reg points, hit
   testing on alpha, cursor handling, audio playback with priority channels.
3. **Game data** – parse part database (CDDATA: part properties, attachment points,
   car-property values), mission/letter data, save format, implement `GameState`.
4. **Scenes, step by step**
   1. 10 Intro → 04 yard (hub, navigation between rooms)
   2. 03 garage: car building – drag parts, snap to attachment points, car stats
   3. 02 junkyard: piles, dragging parts to/from garage
   4. 05 driving: world map tiles, car movement, fuel/properties, destinations
   5. 82–94 destinations (mud, tree, Grunka, Salka, Mia, Gaston, Sture, Viola,
      Doris, Ludde, Figge, Road's end, Exhibition) + missions/medals
   6. 06/13 saved cars & album, 08 diploma, 12 quit, 18 credits
   7. 66 Figge's scrapyard plugin
5. **Polish** – Mulle dialogue/lip-sync animation, transitions, save/load, scaling.

## Status
See bottom of this file – updated as each step is completed.

- [x] Phase 1 extractor – `npm run extract` → public/assets/<FILE>/{manifest.json,score.json,*.png,*.wav}
      (1694 bitmaps pixel-exact vs reference, 599 sounds incl. cue points, texts, labels, score w/ behaviors+params;
      white → alpha 0, engine restores it for ink 0 copy / ink 8 matte). Lingo source dumped to re/ for reference.
- [x] Phase 2 engine – Movie/score playback (prepareMovie→beginSprite→startMovie order, event `go` precedence,
      script changes persist until the score span changes), sprites (reg point, ink 0/8/36, stretch only when flagged,
      rect hit test except matte), behavior registry, Web Audio channels + cue points, software cursor (sprite 115).
- [x] Phase 3 data/framework – Lingo literal parser, PartsDB/Part, Car (snap points, properties), User (junk piles,
      gifts, missions, saves), JunkPiles placement, MulleGlobals (+ localStorage save in Lingo format), gSound
      (BG/EFFECT/OPEFFECT), GameDir/ScreenObject (gDir), SpriteAnimBH (anim charts + lip sync), DrawCar.
- [~] Phase 4 scenes
      - [x] 04 yard: doors/carport/mailbox hover+navigation, Mulle & Buffa animation/speech, mail missions,
            gift parcel, parts on the ground (drag/drop, falling), car on yard + start/crash logic
      - [x] 03 workshop: car building (snap rects per morph variant, show-on-hover, pull parts off, locked
            parts that carry others), floor parts (falling), drop to junkyard door, Mulle comments/descriptions/
            protest, Buffa, Figge's visit, telephone missions, save/fetch shelf buttons, drive-out via big door
      - [x] 02 junkyard: 6 piles + signs, pick/arrange parts (glide back if dropped on the door area), throw
            parts to neighbouring pile via signs, carry to workshop through the door, Mulle musing/describing/
            "pile full", Buffa follows between piles. (Low-memory "unload" mode intentionally not ported.)
      - [x] 06 car album: 12 slots, paste current car + name it (DOM text input over the field), replace dialog,
            fetch a saved car (old car scrapped to piles, parts pulled back out), medals per car; disk export/
            import replaced by a .mullebil file download/upload
      - [x] 05 driving: world grid of 28 maps, topology terrain (hills/mud/holes vs strength/grip/durability),
            16-direction car with original integer physics, sliding along obstacles, map edge crossing, fuel
            (petrol + electric, gas station, out-of-fuel), engine sounds by speed, medals, key demo for new
            players, keyboard (arrows/Shift/Ctrl) + mouse steering, driving menu; world objects: destinations,
            random destinations, cows/goats, ferry, racing track (+hiscores), bridges, hills, stops, teleports
      - [x] destinations 82–94 (one module, a rule per place): mud car, tree, road things, Salka the dog,
            ferry ticket (ladder), lemonade, Sture, Viola/Doris/Ludde, Figge (extra tank), road's end, exhibition
            (rating + medal); parts to the yard, cache items, missions, medals; click skips; back to driving
      - [x] 10 name screen + intro: type a name (Enter / click Mulle), pick from list (double-click), drag a name
            to the bin to delete, max 6 players, Mulle talks/blinks/warns; intro cartoon driven by score sounds +
            cue points; click skips; ends in the workshop. The game now starts here (no auto-login).
      - [x] LBSTART logo intro (start of the game, click skips) → 10; 08 diploma (scrolling certificate with
            name, car, medals; print via browser print window); 12 quit (picture slideshow with waits, click =
            next, double-click = end; ends on a "Hej då" screen); 13/18/UNLOAD minimal (file dialog and world
            chooser are replaced/unused in the browser)
      - [x] Extra material (optional, checkbox on the start screen, saved in localStorage "mullebil.extras"):
            Plugin.cst + bil1–10.cst merged into the databases like the original's xferPluginCasts (2nd world
            "Plug1 Hood", map 66, object 66, parts 601–607/666, more postal parts); world chooser window (18,
            movie-in-a-window) from the yard car; 66 Figge's scrapyard crane puzzle (Hanoi) → wins an extra part
- [ ] Phase 5 polish (next): click-through of everything, transitions, fonts, sounds' edge cases
