# RED — The Other Side: expansion plan

## Execution status — 2026-11-07

The twelve-room campaign, moving/crumbling platforms, journal, persistence,
hints, story ending, controller mapping, and accessibility settings are implemented.
See [release validation](RELEASE_VALIDATION.md) for evidence and remaining hardware,
cross-browser, unfamiliar-player, and performance checks. The duration below remains
an unmeasured design target; it is not a release claim.


## Product direction

Turn the current three-room prototype into a complete, compact fairy-tale
puzzle-platformer. Red crosses an enchanted forest to relight the lantern at
Grandmother's house. Her three magical cards offer different ways through each
clearing; optional keepsakes reveal fragments of the journey.

Target desktop browsers first, with keyboard/mouse and gamepad. Aim for a
45–75-minute first playthrough, plus optional mastery routes. This is a design
target to validate through playtesting, not a measured duration or schedule.

Preserve the core promise: see the destination, plan a route, spend a small hand
of movement powers, and retry immediately when an idea fails. Keep direct
Feather/Step activation and held Briar aiming as the default controls.

## Current foundation

- Three single-screen rooms; Feather, Step, and Briar available once per attempt.
- Fixed-step simulation, forgiving jump input, optional planning pause, instant reset.
- Optional keepsakes, a moving wisp, alternate tested routes, configurable bindings.
- Cosmetic light/dark transformation and existing character animation assets.
- Seventeen automated tests, a production build, and automatic GitHub Pages deployment.

Full manual playthrough validation remains a release requirement. Existing
simulation route tests establish reachability, not whether unfamiliar players
understand or enjoy the puzzles. Older concept documents describe a superseded
selection/confirmation control scheme; use the current direct controls as baseline.

## Experience pillars

1. **Movement feels dependable.** Input, collision, aiming, and retries remain
   consistent. Effects never obscure a landing or interrupt an action.
2. **Puzzles invite alternatives.** Cards can substitute for each other. Main
   routes are approachable; keepsakes reward deliberate resource use.
3. **The forest tells a small story.** Each chapter changes the atmosphere and
   introduces one environmental rule. Brief visual moments carry the narrative.
4. **Failure encourages another idea.** No lives, lost currency, mandatory
   timers, or long death screens. Hints are optional and progressively specific.

## Campaign: 12 rooms across three chapters

Each chapter follows introduce → explore → combine → demonstrate mastery.
Keep rooms within one camera view for the first release. Every room has one
optional keepsake; collecting all keepsakes adds an epilogue, not access to the ending.

| Chapter | Rooms and learning goals | Environmental rule | Story beat |
| --- | --- | --- | --- |
| I — The Lantern Wood | First Clearing: safe movement and Feather; Broken Crossing: Step or Briar; Briar Garden: deliberate placement; Lantern Keeper: combine all three around a wisp | Clearly telegraphed moving wisps | Find Grandmother's extinguished lantern and follow her trail |
| II — The Drowned Village | Millpond: observe then ride; Bell Tower: vertical routing; Lost Street: choose between upper/lower paths; Ferry Crossing: combine movement timing and cards | Moving platforms with predictable paths | Keepsakes reveal how villagers once guided travelers home |
| III — The Thorn House | Courtyard: learn a collapsing ledge; Glasshouse: plan a sequence; Rooftops: combine earlier rules; Hearth: final multi-route puzzle | Crumbling platforms with visible warning and generous delay | Relight the hearth and bring the trail of lanterns back to life |

These are greybox briefs, not final geometry. Design against measured movement
ranges and verify each route before committing art. Revise or remove any room
whose challenge depends on an unexplained trick or excessive precision.

Chapter goals:

- Chapter I: every card is taught safely before required use; first room needs
  no external explanation. Adapt the existing rooms rather than discard them.
- Chapters II/III: at least two practical exit routes in most rooms. Each
  keepsake meaningfully changes a route or card budget.
- Final room: combines known rules; introduces no new power or surprise mechanic.

## Player journey and progression

- Title screen: New Journey, Continue, Chapters, Settings, Credits.
- A short playable opening establishes the destination and teaches movement.
- Show relevant control prompts in context, reflecting remapped keys or gamepad.
- Room completion offers Next and Retry, showing keepsake and cards used.
- A simple illustrated chapter trail records cleared rooms and keepsakes.
- Save unlocked rooms, keepsakes, settings, and completed ending locally. Version
  and validate saves; recover safely from missing or corrupted data. Explain that
  browser-local progress does not sync across devices.
- Offer replay goals such as fewer cards or alternate routes after completion.
  No mandatory scoring, online leaderboards, or account system.
- Three optional hint levels: observation, useful approach, explicit route.
  Never interrupt attempts with automatic hints.

## Presentation and accessibility

Build one coherent art treatment around the licensed character sprites. Use
consistent pixel scale, restrained background detail, and clear platform edges;
test painted backgrounds against pixel characters before producing more art.
Give each chapter a distinct palette while keeping danger and interactable
surfaces recognizable. UI should leave the entire playable area unobstructed.

Prioritize anticipation and feedback: Briar placement validity, wisp paths,
crumbling-platform warnings, landing effects, spent-card states, and a brief
lantern-lighting completion sequence. Transformation remains nonblocking.

Add chapter ambience, restrained music transitions, clear action sounds, and
separate music/effects controls. Honor muted settings and browser audio activation.
Include reduced motion, screen-shake control, readable text sizing, non-color
hazard cues, keyboard-accessible menus, and gamepad aiming/navigation. Test focus
loss and controller disconnection so neither leaves movement stuck.

Keep optional planning available throughout. Evaluate an assist mode that slows
simulation consistently, including hazards and timers, without changing puzzle
geometry. Validate it before promising it for release.

## Technical work

- Keep the Phaser/TypeScript web project and deterministic simulation. Preserve
  the historical classic mode and Godot project without extending them in this scope.
- Extract room definitions from `model.ts` into typed chapter data with stable IDs.
  Separate room metadata, narrative, hints, and geometry from simulation behavior.
- Extend the current single-hazard shape to typed environmental objects only as
  needed for moving and crumbling platforms. Keep their state inside the simulation.
- Centralize full-attempt reset for cards, platforms, timers, hazards, and effects.
  Planning must freeze every new gameplay system exactly.
- Add versioned persistence independent of transient attempt state. Keep current
  control configuration compatible or migrate it explicitly.
- Extend existing input adapters for controller support; avoid a second game loop.
- Load chapter assets when needed, measure loading/rendering performance, and
  optimize against representative hardware. Do not begin with a generic engine rewrite.
- Keep room routes reproducible in simulation tests and document manual routes.

## Milestones and acceptance gates

| Milestone | Deliverable | Completion gate |
| --- | --- | --- |
| 1. Establish the baseline | Playtest current rooms, prioritize friction, fix input/reset/clarity issues | All existing tests pass; all exits and keepsakes manually completed; focus loss, resize, cancel, and repeated retries checked |
| 2. Finish one representative room | One polished room with final UI, effects, audio, hint flow, completion, and save/resume | At least five unfamiliar players try it; target four of five completing its main route without verbal coaching; record confusion and revise |
| 3. Complete Chapter I | Four rooms, title/continue/chapter flow, contextual tutorial, keepsakes | Every route verified; chapter played continuously; reload preserves progress and bindings; no required unexplained input |
| 4. Complete the campaign in greybox | Twelve rooms, moving/crumbling platforms, narrative outline and ending | Every room has a verified exit/keepsake route; intended alternatives demonstrated; timing and difficulty reviewed with new players |
| 5. Finish presentation and access | Chapter art/audio, story moments, gamepad, accessibility settings | Browser and controller checks pass; hazards readable without color alone; menus work without mouse; effects respect reduced motion |
| 6. Release candidate | Credits, asset records, performance pass, regression and deployment verification | Complete fresh-save and resumed-save playthroughs; no blocking bugs; live deployment and critical assets load correctly |

Do not estimate a release date until milestone 2 establishes the cost of finishing
one room and playtests validate the core experience. After that, estimate the
remaining rooms using actual work and include iteration time.

## Verification strategy

- Automated: preserve current checks; add moving/crumbling platform collision,
  planning freeze, reset restoration, save migration, and controller mapping behavior
  as those systems arrive. Prefer end-to-end simulated routes over constant checks.
- Human playtests: observe without coaching, then ask what the player thought the
  rules were. Record time to first meaningful action, confusing deaths, accidental
  card use, unnecessary retries, and whether alternate routes are discovered.
- Manual release matrix: current Chrome, Firefox, and Safari; keyboard-only,
  mouse aiming, and gamepad; small laptop and larger desktop viewports; cold load,
  refresh, lost focus, muted audio, corrupted save, and controller disconnect.
- Performance: choose and record a reference laptop; target stable 60 fps during
  normal play. Measure initial transfer and time to playable before setting a
  loading budget. The current bundle-size warning is a measurement prompt.
- Deployment: retain tests/build before Pages deployment and smoke-check the
  published `/red-local/` paths, chapter assets, and rights notice.

## Asset handling

Keep the asset-rights notice and original attribution. Build an inventory of asset
packs, creators, original store/source links, and locally held license records.
Do not publish receipts or personal purchase details. Verify separately which
licenses permit distribution in a playable browser build and which permit raw
files in a public source repository; the rights notice itself grants neither.
Resolve any incompatible asset distribution before expanding public asset uploads.

## Deliberately deferred

No combat revival, bosses, procedural generation, random card draws, deckbuilding,
economy, multiplayer, accounts, mobile touch support, or level editor for this
release. Three versatile cards plus authored environmental rules provide the
initial depth without multiplying tutorial and balancing costs.

Keep light/dark form cosmetic in the main campaign. After milestone 2, a separate
two-room experiment may test one clearly explained form-dependent interaction.
Only adopt it if players understand it and it creates new choices worth the
additional complexity; it is not a dependency for this release.

## First implementation batch

1. Manually play and record the current three rooms; list the five largest points
   of confusion or friction before changing movement balance.
2. Extract typed room data with stable IDs while keeping existing routes passing.
3. Add save/continue for cleared rooms and keepsakes, including safe recovery.
4. Polish The First Clearing into the representative finished room: contextual
   controls, clear ability feedback, layered optional hints, and lantern completion.
5. Run the unfamiliar-player test, revise, and then expand Chapter I.

The next implementation milestone is a finished opening experience, not nine
additional rooms built on untested presentation and onboarding.
