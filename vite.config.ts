import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: { port: 1420, strictPort: true },
  envPrefix: ["VITE_", "TAURI_ENV_"],
  build: {
    outDir: process.env.QUOTA_FLOAT_FRONTEND_DIST ?? "dist",
    rollupOptions: { input: "index.html" },
  },
  test: { exclude: ["node_modules/**", "dist/**", "release/**", "outputs/**", "src-tauri/target/**", "scripts/release-contract.test.mjs"] },
});
