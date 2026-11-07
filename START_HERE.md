# RED — The Other Side · local edition

Unzip the entire folder first. This contains the playable build, editable source, original character assets, and concept references.

## Play on your Mac

With Node.js installed, run `npm run play` from this folder to open the game.
The hosted game is also available at https://szabadkai.github.io/red-local/.
Purchased assets are not licensed for reuse; see [Asset rights](ASSET_RIGHTS.md).

Open Terminal in the extracted folder, then run:

```sh
bash Play.command
```

The launcher opens the game in your browser at http://127.0.0.1:4250 (or the next free port). Keep the terminal open while playing; Ctrl+C stops it. It uses an installed Node.js or Python 3. No npm install, account, API key, or internet connection is needed to play. Do not open dist/index.html directly.

Windows: run Play.bat with Node.js or Python 3 installed. Linux: run `node tools/serve.mjs --open` or `python3 tools/serve.py`.

## Controls

| Action | Default |
|---|---|
| Move | A / D or left / right arrows |
| Jump | Space |
| Feather leap | X, immediate |
| Step dash | C, immediate, facing direction |
| Briar platform | Hold V, aim with arrows or pointer, release to place |
| Optional planning pause | Hold left Shift or right mouse |
| Cancel aiming | Escape |
| Retry room and restore cards | R |

Use **Controls & cards** to change keys and assign cards to the three action buttons. Conflicting assignments swap, keeping all actions available. Settings persist in this browser at this local address. Invalid Briar placement does not consume the card. Cards are usable once per attempt and reset on retry/death/room change.

## Edit

Node 22.6+ is needed for the tests (Node 24 used for validation).

```sh
npm install
npm run dev
npm test
npm run build
npm start
```

`npm run build` refreshes the prebuilt `dist/` folder used by the launchers. Edit `ridingHood-web/src/prototype/` for the prototype. The old game remains accessible via `?classic`. Godot files belong to that original game, not this new Phaser prototype.

## Art and scope

This revision uses a detailed generated forest backdrop, stone texture, illustrated cards, and the existing animated Red character. The three original concept images are in `docs/red-concept/references/` so a local coding agent can inspect them directly. These are visual targets; the prototype is not a pixel-perfect recreation. In particular, character art is still pixel art, and light/dark transformation is cosmetic rather than a second set of card mechanics. No gamepad mapping yet.

The three rooms remain a short mechanics prototype with optional keepsakes, not a full game. Room routes and state behavior are checked by automated tests; see `docs/red-concept/ROUTES.md`. Historical prompts and screenshots in that folder describe the earlier revision; this document and current source define the direct-action controls.
