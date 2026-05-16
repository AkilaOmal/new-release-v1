# Vercel + ngrok Quick Setup Guide

This is a quick reference for deploying blindVision with Vercel (frontend) and ngrok (backend).

## 5-Minute Setup

### Step 1: Prepare your API keys
Get keys from:
- **ElevenLabs** → https://elevenlabs.io (free tier available)
- **Google Gemini** → https://makersuite.google.com/app/apikey
- **OpenRouteService** → https://openrouteservice.org/profile (free tier)

### Step 2: Start backend locally
```bash
cd server
cp .env.example .env

# Edit .env with your keys:
# - ELEVENLABS_API_KEY=xxx
# - GEMINI_API_KEY=xxx
# - ORS_API_KEY=xxx
```

Then run:
```bash
npm install
npm run build
npm start
```

Server should be at `http://localhost:3001`

### Step 3: Expose with ngrok
```bash
ngrok http 3001
```

Save the output URL (e.g., `https://abc123-xx-xxx-xxx-xx.ngrok.io`)

**Note:** If using ngrok free tier and seeing a browser warning page:
```bash
ngrok http --request-header-remove=ngrok-skip-browser-warning 3001
```

### Step 4: Update server CORS
Edit `server/.env`:
```env
FRONTEND_ORIGIN=https://your-app.vercel.app
```

Restart the backend:
```bash
npm start
```

### Step 5: Deploy frontend to Vercel
Push to GitHub:
```bash
git push origin main
```

Or deploy directly:
```bash
vercel deploy --prod
```

### Step 6: Set environment variable in Vercel
1. Go to **Project Settings** → **Environment Variables**
2. Add:
   - **Name:** `VITE_BACKEND_URL`
   - **Value:** `https://abc123-xx-xxx-xxx-xx.ngrok.io` (your ngrok URL)
   - **Environments:** Production

3. Redeploy (or wait for next push)

### Step 7: Test voice feature
1. Open your Vercel app in browser
2. Click "Enable Voice"
3. Say wake word: "Assistant"
4. Say command: "Test voice" or "What's around me?"
5. Should hear response from ElevenLabs

## If voice doesn't work:

### Test backend directly
```bash
curl https://abc123-xx-xxx-xxx-xx.ngrok.io/api/health
```

Should return:
```json
{
  "status": "ok",
  "services": {
    "elevenlabs": true,
    "gemini": true,
    ...
  }
}
```

### Check Vercel env vars
```bash
vercel env list
```

Should show `VITE_BACKEND_URL` ✓

### Check browser console
Open DevTools → Console, look for:
- `[API] Backend connection failed` → ngrok URL is wrong
- `CORS error` → update `FRONTEND_ORIGIN` in `server/.env`
- `413 Payload too large` → increase Express limit (unlikely)

### Common fixes

| Error | Fix |
|-------|-----|
| "ELEVENLABS_API_KEY is not configured" | Check `server/.env` has key, restart server |
| 404 on `/api/tts/speak` | Check backend is running, ngrok is active |
| CORS error | Update `FRONTEND_ORIGIN` in `server/.env` to Vercel URL |
| ngrok tunnel timeout | Keep ngrok window open, or upgrade to paid tier |

## Production Tips

1. **Use ngrok paid plan** for stable, persistent URLs (recommended)
   - Static domain: `ngrok http --domain=myapp.ngrok.io 3001`
   - More reliability and bandwidth

2. **Or use a VPS** (cheaper long-term)
   - Rent a DigitalOcean/AWS droplet
   - Run backend there instead of ngrok

3. **Keep server logs**
   ```bash
   npm start 2>&1 | tee server.log
   ```

4. **Monitor Vercel deployments**
   - Set up GitHub branch protection
   - Automatic deployments on push to `main`

## For more details, see [DEPLOYMENT.md](../DEPLOYMENT.md)
