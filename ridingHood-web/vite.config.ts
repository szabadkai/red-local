import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(import.meta.dirname, 'src'),
    },
  },
  server: {
    port: 3000,
    open: false,
    allowedHosts: true,
  },
  build: {
    target: 'es2020',
    cssTarget: 'chrome100',
    outDir: 'dist',
  },
});
