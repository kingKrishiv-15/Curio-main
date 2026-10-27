import { resolve } from 'node:path';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// One real HTML file per page, so /privacy.html and /delete-account.html
// (linked from the Play Store listing) keep working on any static host.
const page = (name: string) => resolve(__dirname, name);

export default defineConfig({
  plugins: [react()],
  // Relative asset paths work at a custom domain root, a GitHub Pages
  // project path (/Curio-main/) and Vercel alike.
  base: './',
  build: {
    rollupOptions: {
      input: {
        home: page('index.html'),
        privacy: page('privacy.html'),
        deleteAccount: page('delete-account.html'),
        family: page('family.html'),
      },
    },
  },
});
