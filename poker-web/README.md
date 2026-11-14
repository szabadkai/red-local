# RED — The Gambler's Clearing

Standalone browser successor to the Godot poker prototype. No dependencies or
external runtime services; sprites, audio, and font are bundled locally.

Play on GitHub Pages: https://szabadkai.github.io/red-local/poker/

The repository's Pages workflow tests and builds both games on pushes to `main`.
`Scripts/prepare-pages.mjs` adds this build under `/poker/`, alongside the original
game at the site root. All asset and module URLs are relative to this directory.
For development, use the local server below. The earlier Sites-hosted copy is
separate and is not updated by this workflow.

```sh
npm run dev       # http://127.0.0.1:4310/
npm test
npm run build    # deployable dist/
```

## Story campaign

The five clearings now carry the [Red Riding Hood script](../docs/STORY_SCRIPT.md).
Mother sends Red with a basket and Grandmother's cards. Meet the stranger, Pip,
Rowan, and Sister Wren before confronting the Wolf in Grandmother's bedroom.

| Clearing | Encounter |
| --- | --- |
| Lantern Wood | Briar Hart: committed charges and rising roots |
| The Huntsman's Bridge | Tollkeeper: chain sweeps, hook slams, and moving mill platforms |
| Moss Cavern | Rowan: a guarded duel, followed by a returning axe |
| Ruined Chapel | Bell Widow: falling silk and low sound rings |
| Thorn House | Wolf: bites and leaps; a playable rescue inside him; a final garden fight |

Twenty dialogue scenes use the repository's supporting-character sprites,
portraits, staged scenery, captions, and a paused simulation. Enter/Space/E
advances; Skip scene or holding Escape skips with the same progression outcome.
The finale ends with a playable walk home alongside Grandmother. Existing routes,
including the bridge's lower passage, remain intact.

Each boss, the swallowed rooms, and the garden have retry checkpoints. R restores
full health and a normal fresh hand at the current encounter. Continue restores
saved dialogue at its current line or restarts the saved encounter. On a trail,
reload/retry begins that clearing again. Saves use `red.poker.story.v3`; older
journeys migrate by clearing name. A saved completed journey can replay the final
encounter. Practice never writes story progress.

Every boss can be beaten with ordinary movement and sword attacks. Rowan's guard
blocks damage and draw credit until he recovers. Rare hands and Dark Red still
provide their normal benefits. The Explore / practice selector offers all five
bosses independently, alongside the existing card and enemy practices.

Character artwork reuses the dungeon atlas and `Assets/doc.png`. Missing large
creatures and scene props are drawn on the native pixel grid. See
[story asset sources](assets/story/README.md). Dialogue is captioned, without
recorded voice acting. The campaign uses compact arenas and staged in-engine
scenes; its timing and difficulty still need a full human playthrough.

Implementation: `story.mjs` owns progression and saves; `story-data.mjs` contains
dialogue and room layouts; `bosses.mjs` implements tells, attacks, and hazards;
`story-art.mjs` renders characters and sets. The underlying combat simulation
remains shared with existing card, movement, and enemy tests.

Run `npm test` and `npm run build` here. The 75 tests cover the existing routes and
mechanics plus story transitions, skip equivalence, validated saves, boss retries,
rescue-room reachability, hazard evasion, and defeating all six boss encounters
with a deterministic player using normal sword/movement inputs. The campaign
transition test uses direct damage to isolate progression; the boss playthrough
tests do not modify health or damage. These checks do not replace a full human
balance playthrough. Have a second developer review before merging.

For local visual review, open `tests/story-review.html` from the dev server. It
uses practice state, can open every cutscene, and records an 18-second Hart fight
using scripted keyboard inputs and the actual game canvas. It and the separate
`tests/story-art-preview.html` are excluded from the release build.

[Scripted Hart gameplay capture](../docs/poker-prototype/story-hart-demo.mp4) ·
[Chapel scene](../docs/poker-prototype/story-chapel.jpg) ·
[Cottage scene](../docs/poker-prototype/story-cottage.jpg).
The recording uses normal keyboard events; it is a combat sample, not a full
campaign playthrough. Browser QA checked dialogue advancement and skipping,
exact-line reload/Continue, practice selection, pause/resume, death/retry,
and the opening, cottage, chapel, and rescue-room layouts.

## Play

A/D or arrows move. Hold Space for a higher jump; release for a short hop.
Shift dashes; hold J for sword attacks; K plays the best poker combination.
S or Down drops through raised platforms. P/Escape pauses. R retries the current clearing.
New journey in the menu starts from Lantern Wood.
Keyboard controls only; no touch control buttons or gamepad implementation yet.
The card dock, health, settings and pause/help menus stay inside one 16:9 viewport.

Cross five authored clearings: Lantern Wood, Broken Crossing, Moss Cavern, Ruined Chapel, and Thorn House.
Each is 4800 units long, in four sections closed off by briar gates. A gate opens once every foe
before it has fallen and restores one heart; foes behind a closed gate stay dormant and cannot be hit.
Collect three embers in each, clear the last section, and reach its lantern. Retrying after a death
returns to the last opened gate with the earlier sections still cleared. Checkpoint posts preserve your
position after pits (falling costs a heart). Movement uses fixed 60 Hz updates,
120 ms coyote time, a 140 ms jump buffer, variable jump height, ground/air
acceleration, and a brief invulnerable dash. Blur or hiding the tab pauses and
clears input. Progress saves at clearing entrances in this browser. Continue restarts that
clearing with five hearts and five fresh cards. Existing v1 saves migrate by destination; new saves use stable clearing IDs.
Practice never overwrites journey progress. Unavailable browser storage is
reported; there is no cross-device sync or mid-clearing save.

Five unique cards are dealt initially. Three landed sword swings drop one
face-down card near the enemy. Touch it to pause combat and reveal two choices.
World cards render behind enemy sprites so they cannot obscure a combat pose.
Click a choice or press 1/2 to take that exact card; the other is discarded and
combat resumes. Escape leaves the pickup and both choices intact. Step away and
return to reopen it. Uncollected pickups keep their own distinct card pairs.
If your hand is full, the chosen card is saved; click a slot or press 1–5 to
replace it. Use that saved card before collecting another pickup. K consumes
only the matching combination, keeps kickers, and automatically fills a slot
with the saved card. Spent cards reshuffle. Poker never earns draw credit.

Pairs are heavy bolts; two pair explodes; trips and straights pierce. Flushes and
higher activate six seconds of Dark Red with double sword damage and faster
movement. Full house fires both ways; four of a kind bursts around Red; straight
flush combines burst and wave. Practice deals reset into a flat testing arena;
Retry clearing leaves practice and restores the saved clearing. They never silently alter a normal run.
The Card drop practice starts with a pair and offers a third seven versus an
ace of spades, demonstrating immediate trips versus building toward a flush.

Scouts use the smaller teal 19-pixel body from the dungeon sheet (the old 26-pixel orc is reserved for brutes). Player, living enemies, and corpses use the same shared native-pixel scale. Scouts patrol until aware of Red, chase, leap to reachable higher ledges, then
telegraph a committed lunge. A separate four-frame idle loop plays during patrol pauses. Brutes telegraph a wider slam and can also traverse reachable platforms.
Both expose recovery time and can be interrupted by hits. Brutes can be jumped
over; scouts can be dodged behind. A platform graph plans multi-hop routes, including climbing, same-height gaps,
and dropping through one-way ledges. Every transfer obeys measured jump reach;
unreachable surfaces do not cause teleportation.

In the story journey, each clearing's three embers unlock a dedicated boss room. Defeating the boss advances the story. Keepsakes and their upgrades remain removed.

Three additional characters use their own idle and movement frames from the dungeon sheet: Goblin Runner (fast committed lunge, 10 HP), Lantern Mage (0.8-second tell followed by a fixed aimed shot, 18 HP), and Iron Guard (0.85-second slam tell and long recovery, 42 HP). Shots can be jumped, dashed through, or cut with a sword; parries earn no draw credit. All three use the same platform-routing graph as scouts. The practice menu offers isolated fights plus direct exploration of the two new environments.

The environment reuses the generated forest and stone from the earlier Red web
prototype. Generated
paintings are reduced once and then drawn into the same 480×270 raster as the
sprites. Scenery reduction uses nearest-neighbor sampling, a 20-color palette,
hard alpha edges and removal of isolated texture flecks; it does not blur or
dither. Original
terrain, foliage and character animation remain in use.
Moss Cavern and Ruined Chapel now use generated panoramic backgrounds, eight transparent modular props, and readable stone material, all prepared at the shared logical pixel pitch. Four independently scrolling depths replace the repetitive small columns. Terrain variants share exact edges, and panoramas wrap horizontally; `tests/material-preview.html` verifies the final runtime pixels and shows repeat grids. Source files and full generation prompts are in `assets/concept/ART_NOTES.md`.
Warm trail lanterns mark checkpoints; banners, mushrooms, falling leaves and
separate stone treatments distinguish the route. Thorn House has a new generated
background. Separate distant scenery, woodland silhouettes, transparent oak
canopy and foreground foliage scroll at distinct rates; Motion Off freezes the
background planes. See assets/concept/ART_NOTES.md for prompts and provenance. The original forest music and
dark ambience return through Sound On, and stop when paused or away.

## Storybook cast

Enemies and townsfolk use the Little Red Riding Hood roster from the Aseprite project
(`assets/cast/<name>_sheet.png`: 32×32 cells, rows idle/run/attack/special/hit/death).
`cast.mjs` keeps each behaviour (scout, brute, runner, mage, guard) and dresses it per clearing:
wolves, hunters and boars in Lantern Wood; stag, witch and crows on the bridge; ravens, mushrooms and
wisps in the cavern; brambles, trees and the ghost hunter in the chapel; the wolf in disguise at Thorn House.
Windups play the attack row (mages the special row), hits flash, and corpses play the death row.
Bowmen (rogue hunter, ghost hunter) use the ranged behaviour: they draw on the attack row and loose arrows.
Mother, the woodcutter and Grandmother stand at the start of the first two clearings and by the hearth,
and speak a line when Red is near. Hitboxes and balance are unchanged.

Story bosses (Briar Hart, Tollkeeper, Bell Widow) use 48×48 sheets in `assets/bosses/`; the Wolf is the roster's
own `big_bad_wolf` sheet. The boss sheets are drawn with
the same roster generator (`lrrh_sprites/boss_gen/` in the Aseprite project). The attack row plays each
boss's main pattern, the special row its phase-two pattern, timed from the tell and strike durations.
The Huntsman's Bridge (`bridge-art.mjs`) places the concept pieces (chapel tower, oaks, arch span, crypt,
mossy bough) at one shared scale on the collision surfaces and reduces them once onto the 2-unit pixel grid;
collision surfaces are unchanged.
Boss hits use body boxes measured from the art (`BOSS_BODY` in bosses.mjs) for the sword, bolts and blasts;
the Tollkeeper's chain sweep is drawn and only hurts where its tip has passed. Add `?hitboxes` to the URL to see them.

## Files and checks

- `model.mjs`: deterministic movement, level, poker, combat, and card lifecycle.
- `enemies.mjs`: enemy state transitions and limited ledge-jump decisions.
- `game.mjs`: rendering, sprite animation, audio, input, moving cards and DOM HUD.
- `environment.mjs`: native-scale terrain tiles, cliff recesses, foliage and the home entrance.
- `scenery.mjs`: shared-raster generated art, atmosphere, trail lanterns and gates.
- `journey.mjs`: five clearing definitions and migrated browser persistence.
- `art.mjs`: pixel-grid snapping, anatomical sprite pivots, enemy frames and cast silhouettes.
- `animation.mjs`: character clip priority, contact/recovery timing, blink and air poses.
- `style.css`: responsive in-viewport HUD and pixel hearts.
- `tests/`: 53 tests, including a complete no-enemy route through all
  three embers to the lantern, deck conservation, movement timing, transformation,
  elevated attacks, and enemy states. The route test verifies geometry, not combat
  balance. Real browser inspection confirmed asset loading, pause/resume, hand
  consumption, and flush transformation without console errors. Draft checks
  cover frozen simulation, Escape/reopening, exact-card reserves, overlapping
  pickups, safe drop placement, and conservation of all 52 unique cards.
  Browser QA also verified Escape/reopening and choosing the seven, saving it,
  then replacing slot five to make three of a kind, with no console errors.
  Journey tests complete all five routes without upgrades or falls and exercise
  direct progression/retry, legacy migration, and malformed or blocked storage.
  These route tests remove enemies; they establish reachability, not combat balance.
  Earlier browser checks cover the opening climb/ember/combat,
  save/continue, card-choice Escape/reopening, and a visual parallax pan.
  A full human playthrough and balance pass across all five clearings remain useful.

The model is independent of rendering, so tests exercise the actual game rules.
Read-only `window.__POKER_STATE__` exposes diagnostics in the browser.

The original browser campaign and Godot prototype are retained in the parent
repository. This folder has its own build, tests and private Sites deployment.

## Credits

Original project character, card, tileset and forest art is reused under its
existing terms; see `assets/ASSET_RIGHTS.md`. Audio credits are in
`assets/AUDIO_CREDITS.md`. Silkscreen by The Silkscreen Project Authors is bundled
under SIL Open Font License 1.1 (`assets/FONT_LICENSE.txt`):
https://github.com/googlefonts/silkscreen

The world and moving card art share a 480×270 raster, enlarged without smoothing.
Character and enemy sprites use their native pixel scale without stretching.
Sword damage lands on the contact pose. Dark Red attack pivots account for the
eight-pixel left margin and six transparent rows below the feet. Both forms use
the original dash frames. Jump/fall clips hold their final pose; idle blinks are
spaced out. Entering Dark Red uses the Light-to-Dark clip; expiry uses the
Dark-to-Light clip and FX. Moving, jumping, dashing or attacking interrupts the
body morph while its FX finishes. A sword swing keeps its initial facing, form
and damage through expiry; refreshing active Dark Red does not replay the morph.
`tests/animation-preview.html` checks both transformation directions and a live
sequence of movement/attack poses with the same animation selector as the game.
Casts have chunky ink-edged silhouettes and cream cores. Animated comic starbursts
and WHAM / KRAK / K.O. markers emphasize heavy hits. Poker hits add 2–5 frames
(33–83 ms) of hit stop and a short, decaying camera shake. Feedback triggers once
per played hand on contact, including multi-target and twin-wave attacks. The
HUD stays still, pending input survives the freeze, and Motion Off disables shake.
Enemy slams use physical dust.
Collectible embers have a larger ink-outlined gold orb, a steady white core, and
a four-pose sparkle/bob animation at six frames per second. Motion Off holds a
static pose; pickup positions and collection radius are unchanged.

Terrain reuses `Assets/tiles.png`; the home reuses the original gothic tileset,
with a timber porch, sign, lantern and three ember sockets. Its doorway lights
when all embers are collected. Ground gaps have dark recessed rock faces and
broken rope ends. Lantern Wood keeps its small plants and mushrooms, with no
repeated oval bushes on the trail or below the ground line. In other clearings,
foreground bushes stay over solid ground so they never bridge a chasm.
The world framing exposes more cliff depth below the grass.
All source art renders at 2x world scale (1 source pixel per raster pixel).
The opening clearing retains its geometry and pickup positions. Its lantern now
leads onward; the home entrance completes the third clearing.
`tests/environment-preview.html` provides local art checks for the chasm and
both home states; it is excluded from the deployed build.
Transformation and magic bursts retain the original frame animation assets.

`tests/journey-preview.html` reviews all five scenes and provides a camera-pan
control for checking independent depth planes. It is excluded from deployment.
Screen captures are in `../docs/poker-prototype/`: `journey-play.mp4` and
`parallax-pan.mp4`, plus historical stills. The keepsake screen is no longer part of the game.

## Enemy and environment expansion QA

Run `npm test` and `npm run build` from this folder: 53 tests pass, including
five complete routes with enemies removed, new enemy tells/routing, hostile-shot
collision/parrying/pause, and old-save migration. Combat balance across a full
five-stage run still needs human playtesting.

Browser smoke check: open the local game, select Goblin runner in Explore / practice,
press Practice, approach with D, attack with J, jump with Space and play K.
Pause with P; repeat with Lantern mage and Iron guard. Choose Explore Moss Cavern
or Explore Ruined Chapel for the authored encounters. No console warnings or
errors appeared during these checks. `../docs/poker-prototype/runner-combat.mp4`
is a short 3-fps sampled browser capture; `moss-cavern.jpg` and
`ruined-chapel.jpg` show the two environments in the game viewport.


The environment-v2 pass was checked in the browser with both Explore options,
including movement, jumping, combat, pause/resume, and Motion Off. The material
fixture checks 81 terrain variant pairs per theme in both directions and both
panorama edges after quantization. New screenshots: `moss-cavern-v2.jpg`,
`ruined-chapel-v2.jpg`, `character-scale-v2.jpg`; sampled traversal clip:
`environment-v2-play.mp4`, all under `../docs/poker-prototype/`.
