import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// base: change to the sub-folder the app is hosted under on IIS, e.g. "/ialqc/"
export default defineConfig({
  plugins: [react()],
  base: "/",
  server: {
    port: 5173,
    // In development, /api calls are forwarded to the backend, so the page and
    // the API share one address (no CORS setup needed while developing).
    proxy: {
      "/api": { target: "http://localhost:5080", changeOrigin: true },
    },
  },
});
