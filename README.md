# RED — local prototype

**[Play RED in your browser](https://szabadkai.github.io/red-local/)**

Run `npm run play` to open the included playable build locally. To rebuild from
source, run `npm ci && npm run build` first. Use `npm run dev` for live development.

Pushes to `main` run tests, build the game, and deploy `dist/` to GitHub Pages
through [the Pages workflow](.github/workflows/pages.yml).

**Asset rights:** This repository includes purchased, licensed assets. Public
availability does not grant permission to reuse them. See [Asset rights](ASSET_RIGHTS.md)
and the third-party credits below for applicable terms.

Start with **START_HERE.md** for the new card-platformer and local launchers. The historical action-game documentation below describes `?classic`.

# Dark Riding Hood

A dark-themed action platformer where Little Red Riding Hood battles through a corrupted forest, wielding a dual-form light/dark transformation system. Built with Godot 4.5 (desktop) and Phaser 3 (web).

**[Play in browser](https://szabadkai.github.io/ridingHood/)**

## Gameplay

Fight through 5 levels — from the Dark Forest to The Abyss — defeating orcs and a final boss. A darkness meter fills from combat and pickups; once it crosses the threshold, press **C** to transform into Dark Riding Hood: faster, stronger, but more fragile. The meter drains over time in dark form, forcing you back to light.

### Controls

| Action | Key |
|--------|-----|
| Move | Arrow keys / WASD |
| Jump | Up / W / Space |
| Attack | X |
| Transform | C |
| Dodge (light: roll, dark: dash) | Z |
| Pause | ESC / P |

### Mechanics

- **Light form** — balanced stats, roll dodge
- **Dark form** — 1.5x damage output, dash with i-frames, but takes 1.5x damage and meter drains constantly
- **3-hit combo** — chain attacks with X
- **Coyote time & jump buffering** — forgiving platforming
- **Checkpoints** — respawn mid-level on death
- **Pickups** — food restores health, wolf essence fills the darkness meter

## Levels

1. **Dark Forest** — introductory platforming, 13 enemies
2. **Abandoned Village** — tighter gaps, 16 enemies
3. **Huntsman's Castle** — corridors and walls, 18 enemies
4. **Grandmother's Tower** — vertical focus, 16 enemies
5. **The Abyss** — maximum challenge, 22 enemies + boss arena

## Tech Stack

| | Desktop | Web |
|---|---------|-----|
| Engine | Godot 4.5 | Phaser 3.80.1 |
| Language | GDScript | TypeScript |
| Resolution | 320x180 scaled | 320x180 scaled |
| Build | Godot export | Vite 8 |

## Running the Web Version

```bash
cd ridingHood-web
npm install
npm run dev       # dev server on localhost:3000
npm run build     # production build to dist/
```

## Project Structure

```
ridingHood/
├── Scenes/                  # Godot scenes
├── Scripts/                 # GDScript game logic
├── Assets/                  # Shared art & audio
├── ridingHood-web/
│   ├── src/
│   │   ├── scenes/          # Boot, Preload, MainMenu, Game, UI, Pause, Death, Victory, Overworld
│   │   ├── entities/        # Player, Enemy, Orc, WolfKing, Checkpoint, Pickup
│   │   ├── systems/         # Camera, Sound, Parallax managers
│   │   ├── config/          # Game balance, animations, input
│   │   ├── levels/          # Level tile/enemy/pickup data
│   │   └── utils/           # EventBus, math helpers
│   └── public/assets/       # Sprites, tilemaps, audio
└── project.godot
```

## Credits

### Audio

**Sound Effects** — [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx) (CC0 Public Domain)
Used for attack, enemy, boss, pickup, checkpoint, transform, and UI sounds.

**Player Movement SFX** — [12 Player Movement SFX](https://opengameart.org/content/12-player-movement-sfx) (CC-BY 4.0 / CC-BY 3.0)
Used for jump, land, and player hurt.

**Forest Theme** — [Forest Whisper Theme](https://opengameart.org/content/forest-whisper-theme) by Cleyton Kauffman (CC0)

**Boss Theme** — [Dark Ambience Loop](https://opengameart.org/content/dark-ambience-loop) by Iwan Gabovitch (CC-BY 3.0)

### Art

- Tileset: [0x72 Dungeon Tileset II](https://0x72.itch.io/dungeontileset-ii)
- Custom character animations (Light & Dark forms)
- 6-layer parallax forest backgrounds

## RED — The Other Side prototype

The web entry point now opens a separate three-room card/platforming prototype.
The original action game remains available with `?classic` in the URL. The Godot
project and original action scenes are unchanged.

From the repository root, with Node 22.6+ (Node 24 recommended):

```sh
npm install
npm run dev
npm test
npm run build
```

The build output is `dist/`. For a static host, serve that directory. No account,
API key, backend, or external CDN is required. The prototype uses the original
light/dark player animations, transformation effects, forest layers, and audio.
Do not commit `node_modules`; the previously checked-in platform-specific copy
was removed from tracking and replaced with lockfile-managed dependencies.

### Controls

- A/D or arrows: move. Space: jump.
- X: Feather leap. C: Step dash in your facing direction. Both act immediately.
- Hold V: aim Briar with mouse or arrows; release V to place it. Invalid placement preserves the card.
- Controls & cards: rebind buttons and swap cards between the three action slots. Saved on this browser.
- Hold Shift or right mouse: optional pause. Escape: cancel without spending.
- R: restore the whole current attempt. Chapter buttons allow direct room selection.
- Sound starts muted; the music-note button enables it. Settings contain the cosmetic transformation toggle.

All three abilities remain identical in light and dark form. There is no darkness
meter, combat, random draw, or replenishment within an attempt. Each room has an
optional golden keepsake and a lantern exit. Death restarts immediately.

### Code and verification

- `ridingHood-web/src/prototype/model.ts`: deterministic fixed-step movement,
  collision, abilities, room data and reset state.
- `game.ts`: Phaser rendering, original animation/audio integration, input, previews.
- `ui.ts` and `style.css`: responsive game interface and instructions.
- `ridingHood-web/tests/prototype.test.ts`: state invariants and simulated complete routes.
- `docs/red-concept/ROUTES.md`: reproducible route notes and validation limits.

The browser project remains Phaser/TypeScript/Vite. This local revision adds generated forest, stone, and card artwork. Platforms and character animation remain live game elements. The original concept renders are included as references, not used as flat screenshots of gameplay.
