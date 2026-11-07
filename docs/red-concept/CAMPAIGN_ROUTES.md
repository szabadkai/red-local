# Campaign route notes

All twelve exit-plus-keepsake routes are tested using the same fixed-step World
simulation as the browser. Tests move, jump, and use cards normally; campaign
route tests never teleport Red or alter the room to force success.

| Room | Main route | Keepsake / alternate route |
| --- | --- | --- |
| First clearing | Jump onto the short step; Feather right to the high island; jump from its far edge to the lantern. | Jump for the keepsake on the high island. |
| Broken crossing | Jump from the near edge; Step near the top of the jump; continue to the lantern. | Keepsake sits on the dash route. Briar halfway across provides a tested route that saves Feather and Step. |
| Briar garden | Jump from the bank, Feather right to the middle island, then jump and Step across the final gap. | Jump for the keepsake on the island. Tested alternates: Briar bridges the first gap without Feather, or the last gap without Step. |
| Lantern keeper | Jump onto the stone post; Feather to the island; jump and Step above the wisp. | Keepsake is on the Feather arc. Briar can substitute for Step in the last gap. |
| Millpond | Jump from the bank, Feather right, then Step toward the far bank. | Time the dash to pass the keepsake. Tested alternate: board the raft as it approaches the near bank, ride it right, jump for the keepsake, then Step to the far bank; saves Feather and Briar. |
| Bell tower | Jump onto the short step; walk to its right edge; Feather to the balcony; jump and Step to the exit. | Jump vertically under the keepsake before leaving the balcony. |
| Lost street | Jump from the bank, Feather onto the upper terrace, then jump and Step over the low wisp. | Jump for the keepsake on the terrace. Briar in the last gap is a tested substitute for Step. |
| Last ferry | Jump, Feather from the near bank onto the central pier, then jump and Step across the final gap. | Jump for the keepsake on the pier. A Briar platform in the last gap saves Step. |
| Thorn courtyard | Jump onto the cracked ledge; walk toward its right end; jump to the safe island before it falls; jump and Step to the lantern. | Jump for the keepsake from the safe island. This tested route saves Feather and Briar. |
| Glasshouse | Jump from the bank, then Feather to the high island; jump and Step to the far bank. | Jump vertically for the keepsake; Briar in the final gap saves Step. |
| Moonlit roofs | Jump and Feather onto the high roof; jump and Step over the wisp. | Jump for the keepsake first. Briar above the wisp offers a tested alternate crossing. |
| Hearth | Jump onto the cracked step, then Feather onto the high island; jump and Step to the hearth. | Jump for the final keepsake before leaving the island. |

Feather extends a normal jump: for the longer first gaps, jump before activating
it. Moving platforms follow fixed sinusoidal paths and carry riders horizontally.
Cracked platforms begin their countdown on first landing. Both stop during
planning, hints, and menus; retries restore their initial state.

`campaign.test.ts` contains the exact reproducible timings and Briar positions.
`prototype.test.ts` preserves the original routes and invariants. Timing guides
assume ordinary speed; gentle pace applies the same rules at 70% simulation speed.
