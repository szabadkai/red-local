# Campaign release validation — 2026-11-07

## Implemented

- Twelve authored rooms, three visual chapters, moving rafts, crumbling ledges,
  twelve keepsakes, story completion, and an all-keepsake epilogue line.
- Stable room IDs, compatible recovery of earlier journey saves, Continue,
  sequential unlocks, a chapter journal, best card counts, and browser-local preferences.
- Contextual first-room guidance, three optional hints per room, paused dialogs,
  keyboard menu navigation, and a safe landing beyond the lantern counts as an exit.
- Standard gamepad mapping and menu navigation, separate music/effects volume,
  reduced decorative motion, larger text, and a 70% gentle-pace option.
- Different atmosphere for each chapter; the house chapter uses the existing
  dark ambience track. Existing licensed assets and credits are retained.

## Verification

- `npm test`: 45 tests pass. Production TypeScript and Vite build pass.
- Automated tests cover every room's exit and keepsake in one attempt, plus
  alternate routes in eight rooms. Campaign route tests do not teleport players.
- Tests additionally cover exact-once card use, invalid placement, planning
  freeze, reset, platform carrying/collapse, saved progress, malformed/blocked
  storage, control remapping, and controller press/release/disconnect behavior.
- Strict TypeScript check and Vite production build are required before release.
- Browser interaction: reached every room's exit using ordinary keyboard input
  over the development session. Collected keepsakes manually in eleven rooms;
  Millpond's keepsake and raft alternative are covered by simulation tests.
- Verified the final narrative, chapter transition, replay, chapter journal,
  saved completion after reload, Continue, staged hints, and persistence of
  reduced-motion, gentle-pace, and larger-text settings. Test preferences restored.
- No application errors appeared in the inspected browser console.
- Checked a normal desktop view and document overflow at 568px width; the page
  reported equal content and viewport widths. Keyboard/controller remains the
  target; touch controls are not implemented.

## Limits and follow-up quality checks

- A physical controller was not available. Mapping behavior has automated tests,
  but hardware-specific browser/controller combinations still need a playtest.
- No independent unfamiliar-player study, Firefox/Safari matrix, or measured
  reference-laptop performance benchmark was performed. The original 45–75 minute
  duration was a planning target, not a measured claim for this compact campaign.
- The Phaser bundle still triggers Vite's chunk-size advisory. Build succeeds.
- Purchased-asset license records were not present; see `../ASSET_INVENTORY.md`.
  No new third-party asset packs were added.

Screenshot: [campaign ending](campaign-ending.png).
