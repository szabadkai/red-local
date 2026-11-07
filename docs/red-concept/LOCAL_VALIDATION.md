# Local edition validation

- `npm test`: all 17 tests pass. Includes direct activation, held/released placement, invalid placement preservation, configurable slots, saved configuration validation, and complete simulated routes through all three rooms.
- `npm run build`: TypeScript and production build pass. Phaser bundle size advisory remains.
- Node local launcher: verified HTML and all card/forest assets return HTTP 200 on loopback.
- Browser: verified game rendering, X immediately consumes Feather, rebinding action slot 1 to J, assigning Briar to that slot, and preservation after reload. Defaults restored afterwards.
- Browser timing is unsuitable for reliable full manual playthrough here; complete routes were validated in the deterministic simulation. macOS/Windows launcher OS integration has not been executed on those operating systems.
