import axios from "axios";

const baseURL =
  import.meta.env.VITE_BACKEND_URL ?? "http://localhost:3001";

// Warn if using localhost in production (likely misconfiguration)
if (
  import.meta.env.PROD &&
  baseURL.includes("localhost") &&
  !import.meta.env.VITE_BACKEND_URL
) {
  console.warn(
    "[API] VITE_BACKEND_URL not set in production. Using localhost fallback. " +
    "Voice features will not work. Set VITE_BACKEND_URL in Vercel environment variables."
  );
}

/**
 * Shared axios instance for all backend calls. Adds reasonable timeouts and
 * default JSON content type. Auth headers can be injected here later.
 */
export const apiClient = axios.create({
  baseURL,
  timeout: 30_000,
  headers: { "Content-Type": "application/json" },
});

apiClient.interceptors.response.use(
  (r) => r,
  (err) => {
    // Log backend connection errors in all environments (helpful for ngrok debugging)
    if (err?.code === "ERR_NETWORK" || err?.message?.includes("ECONNREFUSED")) {
      console.error(
        `[API] Backend connection failed. Ensure VITE_BACKEND_URL is correct: ${baseURL}`
      );
    }
    if (process.env.NODE_ENV !== "production") {
      console.error("[api]", err?.response?.status, err?.message);
    }
    return Promise.reject(err);
  },
);
