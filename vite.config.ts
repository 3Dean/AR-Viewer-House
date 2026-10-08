import { defineConfig } from 'vite';

export default defineConfig({
  assetsInclude: ['**/*.glb', '**/*.wasm'],
  optimizeDeps: { exclude: ['@zappar/zappar-threejs', '@zappar/zappar'] },
  build: { target: 'es2022' },
});
