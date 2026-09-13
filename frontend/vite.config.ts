import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  // Tailwind as a Vite plugin, not as a PostCSS step: it needs no config file of its own, so the
  // theme lives in src/styles/tokens.css and there is one less file the Docker build has to copy.
  plugins: [react(), tailwindcss()],
  server: {
    port: 5173,
    // The browser never learns the provider's domain (Article I): every call goes to our API,
    // and in development the proxy is what keeps the frontend origin-relative.
    proxy: {
      '/api': { target: 'http://localhost:8000', changeOrigin: true },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    include: ['tests/**/*.test.{ts,tsx}'],
  },
});
