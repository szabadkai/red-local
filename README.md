# RED — The Other Side

**[Play the game](https://szabadkai.github.io/red-local/)**

A compact, complete browser puzzle-platformer. Carry a lantern home through
12 authored clearings in three chapters: **The Lantern Wood**, **The Drowned
Village**, and **The Thorn House**. Each attempt gives Red three single-use
movement cards. Find a route, collect optional keepsakes, and retry instantly.

## Browser poker platformer

The new standalone poker platformer lives in `poker-web/`. Run `npm run play:poker`
and open the printed local address. It preserves the moving five-card hand,
poker attacks, and timed Dark Red transformation, with a scrolling platforming
level and enemy patrol/chase/lunge/slam behavior. `npm run test:poker` tests its
rules, movement, full level route, and enemy behavior; `npm run build:poker` builds
its independent static site. The campaign below remains unchanged.

## Godot poker combat prototype

A separate combat sandbox restores the moving pixel-card hand: five cards, poker-powered
attacks, and draws earned through sword hits. Open the Godot project and choose
**Poker Combat Prototype**, or run `godot4 --path . Scenes/PokerPrototype.tscn`.
See [controls, rules, and validation](docs/POKER_PROTOTYPE.md).

## Play locally

```sh
npm run play
```

This opens the included build in your browser. Node.js is required. The Mac and
Windows launchers also support Python 3; see [START_HERE.md](START_HERE.md).

## Develop and verify

Node.js 22.6+ (24 recommended):

```sh
npm ci
npm run dev
npm test
npm run build
```

Pushes to `main` test and build the game on Linux, then deploy `dist/` through
[GitHub Actions](.github/workflows/pages.yml). The Vite build uses relative URLs
so the game works under the `/red-local/` GitHub Pages path.

## Controls

| Action | Keyboard / mouse | Standard gamepad |
| --- | --- | --- |
| Move | A / D or left / right arrows | Left stick / D-pad |
| Jump | Space | A |
| Feather: upward launch | X | X |
| Step: forward dash | C | B |
| Briar: aim, then grow a platform | Hold V; mouse / arrows; release V | Hold Y; either stick / D-pad; release Y |
| Pause and plan | Hold Shift / right mouse | Hold LB |
| Retry | R | Back / View |
| Settings | Controls & cards | Start / Menu |

Keyboard bindings and equipped action slots are configurable. In controller menus,
use D-pad to navigate, A to choose, and B to close. Left/right adjusts a focused
slider or selector. Controller button names use the standard Xbox layout.

## A complete small journey

- Moving rafts carry Red; cracked ledges warn before falling. Planning pauses both.
- Twelve optional keepsakes, a story ending, and an extra ending line for finding all twelve.
- Layered, optional hints in every clearing; sequential room unlocks and replay via Journey.
- Local saves for progress, keepsakes, best card counts, sound, and accessibility settings.
- Separate music/effects volume, reduced decorative motion, larger text, and a gentle
  70% simulation-speed option. These do not change puzzle geometry or rewards.
- Transformation is cosmetic. Feather, Step, and Briar work identically in both forms.
- No accounts, purchases, random draws, combat, or lives. Browser-local saves do not
  sync across devices. A reload resumes at a room start with a fresh hand.

The original action game remains available with `?classic`; its Godot source is
also retained. [Historical documentation](docs/CLASSIC_GAME.md) describes that mode.

## Validation

See [campaign routes](docs/red-concept/CAMPAIGN_ROUTES.md) and
[release validation](docs/red-concept/RELEASE_VALIDATION.md) for checks and limits.
Tests exercise the actual fixed-step simulation, including complete routes,
platform behavior, reset, saves, and controller input edges.

## Asset rights

This repository contains purchased, licensed assets. Public availability does
not grant permission to extract or reuse them. See [ASSET_RIGHTS.md](ASSET_RIGHTS.md)
and the [asset inventory](docs/ASSET_INVENTORY.md). Original third-party licenses
continue to apply. No blanket open-source license is granted.

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
- Licensed character animations (Light & Dark forms); purchased assets are not offered for reuse
- 6-layer parallax forest backgrounds


The illustrated forest, stone, and three card images were generated for this
project; see [art notes](docs/red-concept/ART_NOTES.md). Chapter scenery overlays
are code-drawn. No additional purchased asset packs were added for the campaign.
