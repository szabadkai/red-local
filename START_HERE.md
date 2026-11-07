# RED — The Other Side

[Play online](https://szabadkai.github.io/red-local/) or run `npm run play` from
this folder with Node.js installed. The browser opens the included playable build.
Keep the terminal open; Ctrl+C stops the server.

Mac: `bash Play.command`. Windows: run `Play.bat`. These launchers can use Node.js
or Python 3. Linux: `node tools/serve.mjs --open` or `python3 tools/serve.py`.
Do not open `dist/index.html` directly.

## Your journey

Reach the lantern in each of twelve rooms across three chapters. Move with A/D
or arrows; jump with Space. X launches Feather, C dashes with Step. Hold V to aim
Briar with the mouse or arrows, then release to grow a platform. Escape cancels.
Each card can be used once per attempt. R retries with a fresh hand.

Hold Shift or right mouse to pause and plan. Moving rafts and crumbling ledges
pause too. Keepsakes are optional. Use **Need a hint?** for increasingly specific
help, and **Journey** to replay unlocked rooms or inspect your best card counts.

**Continue** resumes from a room start. Progress and settings are stored only in
this browser. They do not sync to another device or between the local and hosted
versions. Sound starts muted; the music-note button enables it.

**Controls & cards** includes rebinding, card slots, audio levels, larger text,
reduced decorative motion, and gentle pace. Standard gamepads use left stick to
move, A to jump, X/B/Y for Feather/Step/Briar, LB to plan, Back to retry, Start for
settings. Both sticks can aim Briar. Touch controls are not included.

## Edit

With Node 22.6+ (24 recommended):

```sh
npm ci
npm run dev
npm test
npm run build
```

The build refreshes `dist/`. Edit `ridingHood-web/src/prototype/`. Room definitions
are in `rooms.ts`; `model.ts` owns simulation state. The legacy action game is
available via `?classic`. Godot files belong to that original game.

Purchased assets are not licensed for reuse: read [ASSET_RIGHTS.md](ASSET_RIGHTS.md).
For validation details and remaining hardware checks, see
[release validation](docs/red-concept/RELEASE_VALIDATION.md).
