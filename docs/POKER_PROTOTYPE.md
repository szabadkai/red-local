# Poker combat prototype

Open `project.godot` in Godot 4.5+ and choose **Poker Combat Prototype** from the
main menu, or run:

```sh
godot4 --path . Scenes/PokerPrototype.tscn
```

This is an isolated platforming combat prototype. Collect three forest embers
and reach the lantern on the upper-right ledge to complete the clearing. The original Godot game and browser
campaign remain available. No persistent progression or saved deck changes.

## Controls

| Input | Action |
| --- | --- |
| A/D or arrows | Move |
| Space | Jump, with coyote time and a short input buffer |
| S / Down | Drop through a raised platform |
| Hold J | Sword swings, 2 damage (4 in Dark Red), 0.20-second cooldown |
| K | Fire a poker projectile using the strongest available combination |
| 1–5 | Spend a banked draw to replace that card |
| P | Pause/resume |
| M | Toggle decorative card motion |
| N | Mute/unmute sound effects |
| F1 / F2 / F3 | Practice reset with pair / flush / four of a kind |
| R | Fresh run, full health, shuffled deck |
| Escape | Return to original main menu |

## Rules

Start with five cards from a standard, unique 52-card deck. Each three successful
sword swings deal one replacement into an empty slot. A swing can damage multiple
enemies but earns only one hit credit. Misses and poker projectiles earn none.
A full hand banks at most one draw; further hits do not accumulate credit until
it is used. Playing a combination automatically uses that banked draw to fill one
empty slot, or press 1–5 to replace a card while retaining the rest of the hand.

K chooses the strongest combination automatically. Only its contributing cards
are discarded; kickers remain. A high-card attack spends the highest card.
Aces are high, except A-2-3-4-5 straights. No wraparound straights or jokers.
The discarded cards reshuffle when the draw pile empties. Cards are never
permanently destroyed. Losing health does not cost cards.

| Combination | Damage | Effect |
| --- | ---: | --- |
| High card | 6 | Small bolt; spends one card |
| Pair | 14 | Heavy bolt; kills a normal enemy |
| Two pair | 20 | Explosion within 100 pixels of the struck enemy |
| Three of a kind | 26 | Piercing lance |
| Straight | 32 | Piercing beam |
| Flush | 40 | Broad piercing wave + Dark Red |
| Full house | 52 | Dark waves in both directions + Dark Red |
| Four of a kind | 64 | 270-pixel radial burst + Dark Red |
| Straight flush | 90 | Radial burst and piercing wave + Dark Red |

Flushes and higher activate six seconds of Dark Red: double sword damage and
faster movement. The existing transformation sprites and dark FX play for 0.75
seconds while movement and attacks remain available. That opening grants 0.75
seconds of protection; Dark Red is otherwise vulnerable. Repeated qualifying hands
refresh the six-second duration. A restart clears the transformation.

Each piercing projectile hits each enemy at most once. The straight flush burst
and its wave are separate hits. Poker damage still earns no draws. Damage numbers,
expanding blast rings, larger projectiles, and hand banners make payouts visible.
Sound effects reuse the repository's credited audio; N mutes them.

Normal enemies have 14 health; every third spawn is a visibly larger 56-health
brute. Enemies approach, telegraph in red, and strike after a delay. Up to five
can be alive, with new arrivals every 2.2 seconds. Five lost health ends the run.

F1/F2/F3 are explicit practice tools, not normal draws: each resets the arena,
health, and deck, deals the named combination, and puts three targets ahead of
Red. All 52 unique cards remain accounted for. Press K to compare the effects;
press R to return to an ordinary shuffled run. On some Mac keyboards, use Fn+F1,
Fn+F2, or Fn+F3 to send function keys to the game.

## Implementation

- `Scripts/Poker/PokerHand.gd`: pure ranking and contributing-card selection.
- `Scripts/Poker/PokerDeck.gd`: dealing, hit credit, banking, discards, reshuffling.
- `Scripts/Poker/PokerCard.gd`: original card atlas, bobbing/wiggles, combo lift,
  animated deal and departure. No generated art.
- `Scripts/Poker/PokerPrototype.gd`: arena, input, combat, and HUD.
- `Scenes/PokerPrototype.tscn`: standalone entry; temporarily uses a 640×450 canvas
  and restores the previous viewport size and aspect mode when leaving.

Tuning values currently live in these scripts; no new exported properties.
This experiment uses five one-way platforms, a ground floor, and keyboard input. It has no controller
support, deck upgrades, or manual subset selection. Higher poker hands
will be rare with a standard deck; evaluating whether they need more support is a
playtest question, not solved balancing.

## Validation

Godot 4.5.1 on macOS:

```sh
godot4 --headless --path . --editor --import
godot4 --headless --path . --script Tests/test_poker.gd
godot4 --headless --path . --script Tests/test_poker_combat.gd
godot4 --headless --path . --script Tests/test_poker_power.gd
godot4 --headless --path . --script Tests/test_poker_platforms.gd
```

All four suites passed. Power tests also cover piercing without repeat hits,
explosion and radial-burst range, transformation activation/expiry/reset, doubled
sword damage, and unique practice decks. They cover categories and wheel straights, partial/empty hands,
card consumption, draw banking, invalid swaps, 200 reshuffle cycles with card
conservation, sword cooldown/hit credit, projectile damage, damage preserving cards,
pause/restart, viewport restoration, and the menu entry.

[Original scripted gameplay clip](poker-prototype/demo.mp4) and
[rendered preview](poker-prototype/preview.png) were captured from the running scene.
The recording seeds a pair and positions an enemy near Red to demonstrate three
sword hits, banking a draw, playing the pair, and dealing its replacement.
`Tests/capture_poker.gd` reproduces that scripted demonstration, writing its preview
under `/tmp/card-concept/` (create that folder first).

Native keyboard automation timed out, so a complete manual playtest remains
outstanding. Before merging, manually exercise J/K while moving and jumping,
1–5 with a banked draw, death/restart, pause, and Escape/menu re-entry; check the
original game's combat and navigation too. Have a second developer review.

## Power-pass capture

[Power and transformation clip](poker-prototype/powers.mp4) demonstrates an F2
flush followed by an F3 four-of-a-kind burst. [Dark Red preview](poker-prototype/dark-red.png)
shows the timed empowered state. Reproduce with `Tests/capture_poker_power.gd` and
Godot's `--write-movie` option. These are scripted captures, not a claim that manual
combat tuning is finished. Latest changes were not manually keyboard-playtested.

## Platforming and animation pass

Red now uses the existing idle, run, jump, fall, sword, and cast sprite sequences
in both forms, rendered at native pixel proportions. Orcs use their atlas walk
sequence and face the player. Transformation continues to allow movement and attacks.

The authored route is ground → left low ledge → left middle ledge → center upper
ledge → right middle ledge → right upper ledge/lantern. Jump height is about 60
pixels; successive climbing ledges are 52 pixels apart. The route test physically
simulates the entire climb, collects all three embers, and verifies completion.
It also covers dropping through, coyote time, buffered landing jumps, prevention
of extra air jumps, elevated sword range, and animation assets in both forms.

Ledge enemies stay on their ledge, including when knocked back. Swords, projectiles,
and radial attacks account for enemy height. F1/F2/F3 still provide the flat
practice arena; R restores the platforming clearing. Completing the clearing
freezes gameplay and offers restart/menu controls.

[Clearing preview](poker-prototype/platform-clearing.png) and
[scripted traversal clip](poker-prototype/platforms.mp4) show the layout and route.
The traversal capture removes enemies to isolate the jump demonstration; it is
not a manual combat playtest. Reproduce using `Tests/capture_poker_platforms.gd`.
