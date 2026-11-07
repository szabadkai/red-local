# Build RED: a small card-powered platforming puzzle

You are working in https://github.com/szabadkai/ridingHood. Implement a polished, playable browser prototype using the existing web game and assets. Do the implementation, run it, and verify it. Do not stop at a design document or scaffolding.

## The game in one sentence

Reach the exit of a short platforming room using normal running and jumping plus a hand of three single-use magical movement cards; find a clever route, pause to aim when necessary, and execute it.

This is a small experiment in movement and resource planning. Prioritize understandable decisions, responsive controls, satisfying movement, and instant retries. The attached concept art establishes visual direction, not a finished game design.

## First inspect the project and references

Read repository instructions and inspect the current implementation before changing it. The repository previously contained a Phaser/TypeScript/Vite browser project in ridingHood-web/ and a separate Godot version. Confirm the current structure and reuse the web project rather than creating a second application. Reuse its character animations, tiles, input, camera, sound, and useful movement code where practical. Keep unrelated work intact. Do not modify the Godot project unless necessary for accessing shared assets.

Open and visually inspect these local PNG files using your image-viewing capability:

- docs/red-concept/references/01-bridge-gameplay.png
- docs/red-concept/references/02-light-dark-cards.png
- docs/red-concept/references/03-transformation.png

Read docs/red-concept/REFERENCE_GUIDE.md. If you cannot actually inspect images, say so and use its descriptions; do not claim to have seen them. All references are concept images, not screenshots of implemented features or production sprite sheets. This prompt overrides conflicting mechanics or text depicted in the images.

## Scope and rules

Build three compact, authored rooms. Each fits in one camera view. On entry, show the exit and supply the exact same three cards every attempt: FEATHER, STEP, BRIAR. There is no random draw, mana, cooldown system, or mid-room replenishment. Playing a card consumes it until a restart or the next room. Normal running and jumping remain unlimited. No basic attack is needed in these rooms.

1. FEATHER — launch Red upward from the ground or in midair, higher than a normal jump. Preserve useful horizontal steering. It is one clear upward impulse, not a complicated flight mode.
2. STEP — dash horizontally in the facing direction. Cover more distance than normal jumping allows. Briefly ignore gravity during the dash, but never pass through solid terrain. It does not grant invulnerability in this prototype.
3. BRIAR — create one temporary-for-the-attempt, one-way platform at an aimed valid position within a clearly shown reach radius. The platform remains until retry or room completion. Give it fixed dimensions. Reject placements inside solid terrain, outside bounds, intersecting Red, or outside reach without consuming the card. No stacking platforms or dragging scenery.

Tune the three abilities together with room geometry. Exact numeric values are implementation decisions: keep them in a central balance configuration and verify actual reach in the running game.

The FEATHER/THREAD/BRIAR art is from an earlier design. STEP intentionally replaces THREAD to simplify the first prototype. Make a suitable dash symbol; do not copy the reference labels blindly.

## Controls and planning

- A/D or left/right: move.
- Space: jump, with coyote time and jump buffering.
- Hold Shift or hold right mouse button: enter planning mode. Stop gameplay simulation, including Red, hazards, timers, and card movement effects. UI and aiming continue. Preserve momentum exactly for resuming.
- 1/2/3 or clicking a card selects it. Selecting a card automatically enters planning mode if needed. Selection never spends it.
- FEATHER shows a launch direction and approximate ascent preview; STEP shows direction and a collision-limited dash preview. Left/right while planning changes STEP's facing. BRIAR follows the pointer with a valid/invalid placement ghost; arrow-key aiming also works when BRIAR is selected.
- Enter or left-click in the world confirms a valid selected action, spends the card once, and resumes gameplay. Require planning controls to be released before they can freeze gameplay again, so a held key cannot immediately re-pause after confirmation.
- Escape cancels selection/planning without spending anything. Releasing the planning hold with no confirmed action resumes without spending.
- R instantly restarts the room. Keep the action under a second and use a short fade only if it improves clarity.

Separate UI input from world input so clicking a card cannot also confirm it. Consumed cards cannot be selected. Show key hints and the selected card's plain-language effect. Use color plus a symbol/label for invalid placement, not color alone.

Keyboard and mouse desktop browsers are the target for this prototype. Do not spend the scope on touch controls, account systems, or gamepad support.

## Room design

Room 1: introduce movement and FEATHER. Normal jumps let the player explore safely; one clearly higher ledge demonstrates the launch. Provide all three cards but guide the eye toward the useful one. Include a visible optional treasure encouraging experimentation.

Room 2: a gap with a landing surface and enough horizontal space to understand STEP. Provide at least two practical solutions, such as a direct dash route and a platform-assisted route. A side alcove contains optional treasure that changes the best use of the hand.

Room 3: combine height, a gap, and one simple visibly telegraphed moving hazard. Allow different card orders and at least two verified routes to the exit. The treasure route should require more deliberate resource use. Keep the hazard easy enough that the puzzle remains the focus.

Author room dimensions from measured jump/dash reach. Do not merely assume a route is possible. Avoid key-and-lock design where each obstacle has only its matching card. Let cards substitute for one another where geometry allows. An ordinary route to the exit may require cards, but optional treasure must never be mandatory.

Falling or touching a lethal hazard resets the entire current attempt, including cards, platforms, hazard phase, treasure, form, and player state. A player who wastes cards can always restart immediately. Use friendly feedback such as 'Try another route' rather than a lengthy death screen.

After a room, show treasure collected and cards used, then offer Next or Retry. After room 3, offer Replay. No score economy, punitive timer, deckbuilding, procedural generation, boss, campaign map, or upgrade system.

## Character transformation

Preserve the existing light/dark character assets and transformation animation. For this prototype only, playing a card also switches the visual form after the ability has been triggered; all three card effects remain identical in either form. State this honestly in help text: 'Your appearance changes; card powers stay the same in this prototype.'

Do not retain the existing darkness meter, damage bonuses, timed drain, or random forced reversion in these rooms. Do not implement six alternate card powers yet. The form switch is visual groundwork for a later experiment, not a second puzzle rule.

Transformation must not freeze a jump or postpone an ability. Inspect the animation: if the full animation would interrupt movement, use a brief nonblocking flash/trail during the action and display the full transformation safely on landing, without taking control away. Ensure the final form is consistent even if landing, restarting, or completion interrupts the effect. Add one development toggle to disable form changes so the base game can be evaluated independently.

## Visual direction

Match the references' atmosphere using real scene elements: small bright-red heroine, purple dark form, deep blue-green forest silhouettes, mossy stone, warm amber windows, restrained ivory magic, and parchment cards with simple botanical borders. Keep clear silhouettes and readable landing surfaces. Background contrast must be lower than platforms and hazards.

Use the existing sprites at consistent pixel scale and disable smoothing. The references are aspirational; preserve the original character identity rather than replacing it with newly drawn approximate characters. Do not use a complete concept image as the game background or fake the game with an image overlay. Do not crop characters, UI, or gameplay terrain out of the concept images and pretend they are usable assets. Build actual interactive geometry and independent UI.

The hand should occupy roughly the bottom 15–20% of the viewport, in a reserved area that does not hide landing surfaces. Make cards readable with a large icon, name, one short effect, and key number. Clear spent state, subtle hover, strong selected state. If using dark card styling after transformation, keep the same labels and effects so players do not infer nonexistent alternate powers.

Prioritize a visually coherent playable scene over decorative density. Use restrained particles, a feather lift trail, a dash streak, and a quick vine-growth effect. Add short available sounds for selection, valid play, denied action, landing, treasure, and completion. Respect browser audio activation; provide mute.

## Implementation and verification

Reuse existing architecture where sensible. Keep ability rules, hand consumption, planning state, room data, and transient room entities clearly separated. Use explicit states instead of scattered flags. Centralize resets so restarting restores every subsystem. Avoid an unnecessary general-purpose card engine.

Implement in this order: one greybox room and movement; the three abilities and deterministic reset; planning and previews; remaining rooms and route validation; visual/audio polish; browser verification. Proceed through all steps autonomously.

Run the repository's existing relevant checks and production build. Add focused tests for card consumption exactly once, invalid BRIAR preserving the card, reset restoring room state, and planning preserving simulation state where the test setup supports it. Do not add tests that only repeat constants.

Use browser interaction if available to actually play all rooms. Verify every required exit route, optional treasure route, both solutions in rooms 2 and 3, midair planning, collision during dash, invalid placements, selecting a spent card, canceling, repeated retries, resizing, and form animation interruptions. Watch for stuck input when focus is lost. Record brief route instructions with card order for reproducibility. If you cannot run browser verification, explicitly report the missing checks rather than claiming playability.

Deliver working source in the existing repository, a concise README section with controls and run/build commands, the verified route notes, and actual screenshots of your implementation if screenshot tools are available. Report what you changed, what checks passed, and any remaining limitations. Do not publish, push, or deploy unless separately requested.
