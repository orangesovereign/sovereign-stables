import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// base: './' — RedM NUI resolves bundled assets relatively from ui/dist.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    // Single bundle keeps the fxmanifest files{} list trivial (dist/assets/*).
    chunkSizeWarningLimit: 1500,
  },
})
