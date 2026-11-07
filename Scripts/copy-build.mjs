import { cpSync, copyFileSync, rmSync } from 'node:fs';
rmSync('dist', { recursive: true, force: true });
cpSync('ridingHood-web/dist', 'dist', { recursive: true });
copyFileSync('ASSET_RIGHTS.md', 'dist/ASSET_RIGHTS.md');
