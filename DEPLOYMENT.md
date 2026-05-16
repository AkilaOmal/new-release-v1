# Deployment Guide: Vercel + ngrok

This guide explains how to deploy the blindVision app with Vercel (frontend) and ngrok (backend).

## Prerequisites

- Vercel account and CLI installed
- ngrok account and CLI installed
- API keys: ElevenLabs, Gemini, Google Maps/ORS

## Backend Setup (ngrok)

### 1. Create `.env` file in `server/` directory

```bash
cd server
cp ../.env.example .env  # if available, or create manually
```

Configure with your API keys:

```env
ELEVENLABS_API_KEY=your-key-here
ELEVENLABS_VOICE_ID=21m00Tcm4TlvDq8ikWAM  # or your preferred voice
ELEVENLABS_MODEL_ID=eleven_turbo_v2_5
GEMINI_API_KEY=your-key-here
GOOGLE_MAPS_API_KEY=your-key-here
ORS_API_KEY=your-key-here  # optional alternative to Google Maps
PORT=3001
NODE_ENV=production
# FRONTEND_ORIGIN will be set when connecting ngrok
```

### 2. Start the backend server

```bash
npm run dev
# or for production: npm run build && npm start
```

Server should be running on `http://localhost:3001`

### 3. Connect ngrok

**For ngrok free tier with authentication:**

```bash
ngrok config add-authtoken YOUR_NGROK_AUTH_TOKEN
ngrok http --domain=YOUR_STATIC_DOMAIN 3001
```

Or without static domain:

```bash
ngrok http 3001
```

**Important:** ngrok will output a URL like `https://xxxx-xxxx-xxxx-xxxx.ngrok.io`

### 4. Update CORS (only if using ngrok free tier)

If ngrok requires browser warning page, add this header to ngrok configuration or use:

```bash
ngrok http --request-header-remove=ngrok-skip-browser-warning 3001
```

## Frontend Setup (Vercel)

### 1. Set Environment Variables in Vercel

Go to your Vercel project settings → Environment Variables

Add:

```
VITE_BACKEND_URL=https://xxxx-xxxx-xxxx-xxxx.ngrok.io
```

⚠️ **Replace with your actual ngrok URL** (including `https://` prefix)

### 2. Deploy to Vercel

```bash
vercel deploy --prod
```

Or push to your git repository connected to Vercel for automatic deployments.

## Troubleshooting

### Voice feature doesn't work after deployment

1. **Check that `VITE_BACKEND_URL` is set in Vercel:**
   ```bash
   vercel env list
   ```
   
2. **Verify ngrok is running and accessible:**
   ```bash
   curl https://xxxx-xxxx-xxxx-xxxx.ngrok.io/api/health
   ```
   Should return JSON with service statuses

3. **Check browser console for errors:**
   - Look for "[API] Backend connection failed" errors
   - Verify the ngrok URL in Network tab requests

### CORS errors

If you see CORS errors:

1. **Make sure ngrok URL is in Vercel's `VITE_BACKEND_URL`**
2. **Update backend `FRONTEND_ORIGIN` if needed:**
   
   When deploying, set in server `.env`:
   ```env
   FRONTEND_ORIGIN=https://your-vercel-domain.vercel.app
   ```

### ngrok connection timeouts

1. **Check ngrok session is active:** `ngrok http 3001`
2. **Verify no firewall/proxy is blocking requests**
3. **If using free tier, ngrok may restart:** Keep ngrok running or use paid plan for stable URL

### "ELEVENLABS_API_KEY is not configured"

Ensure `ELEVENLABS_API_KEY` is set in `server/.env` before starting backend.

## Architecture

```
┌─────────────────────────┐
│  Vercel (Frontend)      │
│  blindVision2.0         │
│  vite-prod.vercel.app   │
└────────┬────────────────┘
         │ HTTPS
         ├─ VITE_BACKEND_URL
         │  (ngrok URL)
         │
┌────────▼────────────────┐
│  ngrok Tunnel           │
│  xxxx.ngrok.io          │
│  (HTTPS proxy)          │
└────────┬────────────────┘
         │
┌────────▼────────────────┐
│  Local Server           │
│  localhost:3001         │
│  • ElevenLabs TTS       │
│  • Gemini API           │
│  • Navigation Routes    │
└─────────────────────────┘
```

## Advanced: Static ngrok Domain (Recommended for Production)

To avoid ngrok URL changes on restart, use a static domain:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
ngrok http --domain=your-static-domain.ngrok.io 3001
```

Then set `VITE_BACKEND_URL=https://your-static-domain.ngrok.io` in Vercel (once, no need to update).

## Performance Notes

- Voice TTS requests go: Vercel → ngrok → Local Server → ElevenLabs API
- Network latency will be higher than local development
- Consider ngrok paid plans for production use (better reliability)
- Cache audio responses when possible (audioQueue already does this)
