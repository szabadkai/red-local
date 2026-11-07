import { cpSync, rmSync } from 'node:fs';
rmSync('dist', { recursive: true, force: true });
cpSync('ridingHood-web/dist', 'dist', { recursive: true });
