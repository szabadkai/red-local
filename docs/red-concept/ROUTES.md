# Prototype routes and validation

The movement simulation is independent of render frame rate and runs at 120 Hz.
The tests drive the same World class used by the browser, with ordinary movement,
jump, card selection and confirmation. They do not teleport the player to finish
levels. Each successful route asserts completion with one attempt.

## 1. The first clearing

Walk right toward the short stone step. Jump onto it. From the right side of the
step, play Feather and keep moving right to land on the high island. Jump near
the golden keepsake to collect it. Walk near the island's right edge, then jump
the final gap and walk to the lantern. Only Feather is required.

## 2. The broken crossing

Route A: approach the first edge. Jump right and play Step near the top of the
jump. Keep moving right to land across the gap, then walk to the lantern. With a
well-timed dash, the keepsake is on this route.

Route B: from near the left edge, aim Briar in the middle of the gap, a little
above the starting floor. Jump to it, move toward its right edge, and jump to the
far bank. Feather and Step remain unused. A Feather-assisted jump can pursue the
keepsake if you miss it on the simple route.

## 3. The lantern keeper

Jump from the first island to the little stone post. Play Feather from the post
and steer right; the high keepsake is on the ascent/upper arc. Land on the central
island. Jump from its right edge and play Step while high enough to clear the red
wisp. Land on the final island and reach the lantern.

Alternative: after reaching the central island with Feather, grow a Briar in the
middle of the last gap slightly above the central island's top. Jump onto the
Briar, then jump to the far bank, passing above the wisp. Step is not needed.

## Automated verification

The test suite covers selection/cancel without consumption, exact-once spending,
invalid Briar placement, complete simulation freeze while planning, whole-room
retry, dash/solid collision, one-way platform collision, room 1 completion plus
treasure, and two complete routes each for rooms 2 and 3. The build includes a
strict TypeScript check.

## Browser verification

The preview was opened in Chrome. Rendering, card selection, planning state,
invalid Briar rejection, valid pointer placement, card consumption, cosmetic
form change, and reset restoration were checked through the UI. Further checks
are recorded below as completed. The cloud browser advances animation frames
infrequently during timed key holds, so its movement timing is not suitable for
certifying full manual playthroughs. End-to-end route reachability is verified by
the deterministic simulation tests, rather than claimed as human playtesting.

Additional browser checks: all three chapter buttons load their room; Step
selection and Escape cancel preserve the hand; the help dialog opens and closes;
the transformation checkbox disables cosmetic switching while a played Feather
is still consumed; R restores the hand. No application-origin console errors
were observed. The final layout was inspected at the available desktop viewport.
