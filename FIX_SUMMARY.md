# Fix Summary: Voice Feature on Vercel + ngrok

## Problem
The voice feature using ElevenLabs wasn't working when the frontend was deployed on Vercel and the backend was running on ngrok. The main issue was that the client didn't know the backend URL.

## Root Cause
1. **Missing environment variable** - `VITE_BACKEND_URL` wasn't being set during Vercel build
2. **Hardcoded localhost default** - Client defaulted to `http://localhost:3001` which doesn't exist in production
3. **No deployment documentation** - Unclear how to properly configure Vercel + ngrok setup

## Changes Made

### 1. Enhanced Client API Configuration
**File:** `client/src/services/apiClient.ts`
- Added warning when using localhost in production
- Added better error logging to identify backend connection issues
- Now logs the actual backend URL being used for debugging

### 2. Environment Configuration Files
**Created/Updated:**
- `client/.env.example` - Added documentation for `VITE_BACKEND_URL` and other variables
- `client/.env.production` - Added placeholder for production environment
- `server/.env.example` - Enhanced with deployment instructions
- `client/vercel.json` - Added `buildEnv` configuration to pass environment variables during build

### 3. Deployment Documentation
**Created:**
- `DEPLOYMENT.md` - Comprehensive guide for Vercel + ngrok deployment
- `VERCEL_NGROK_SETUP.md` - Quick 5-minute setup guide
- `scripts/test-deployment.sh` - Bash script to diagnose deployment issues
- `scripts/test-deployment.bat` - Batch script for Windows users

### 4. README Updates
- Added "Deployment (Vercel + ngrok)" section with quick start guide
- Added troubleshooting checklist for voice features
- Links to detailed deployment documentation

## How to Fix Your Deployment

### Step 1: Configure Backend (ngrok)
```bash
cd server
cp .env.example .env

# Edit .env and add your API keys:
# - ELEVENLABS_API_KEY=your_key
# - GEMINI_API_KEY=your_key
# - ORS_API_KEY=your_key
# - FRONTEND_ORIGIN=https://your-app.vercel.app

npm run build
npm start
```

### Step 2: Expose Backend
```bash
ngrok http 3001
# Copy the URL: https://abc123-xx-xxx-xxx-xx.ngrok.io
```

### Step 3: Deploy to Vercel
1. Push to GitHub
2. In Vercel Project Settings → Environment Variables
3. Add new variable:
   - **Name:** `VITE_BACKEND_URL`
   - **Value:** `https://abc123-xx-xxx-xxx-xx.ngrok.io` (your ngrok URL)
   - **Environments:** Production
4. Deploy or wait for automatic deployment

### Step 4: Test
```bash
# Test backend health
curl https://abc123-xx-xxx-xxx-xx.ngrok.io/api/health

# Or use the test script
./scripts/test-deployment.sh https://abc123-xx-xxx-xxx-xx.ngrok.io
```

## What the Client Now Does

1. **Reads `VITE_BACKEND_URL`** from environment variables at build time
2. **Falls back to localhost** only in local development
3. **Warns in console** if using localhost in production
4. **Logs connection errors** with the actual backend URL being used
5. **Includes helpful error messages** for debugging

## Socket.IO Fallback
The Socket.IO client now:
- Uses `VITE_SOCKET_URL` if set, otherwise falls back to `VITE_BACKEND_URL`
- Supports both WebSocket and polling transports
- Automatically reconnects on failure

## Testing the Fix

### Local Development (no changes needed)
```bash
cd server && npm run dev
cd client && npm run dev
# Visit http://localhost:5173
```

### Vercel + ngrok Deployment
1. Set `VITE_BACKEND_URL` in Vercel environment variables
2. Run test script: `./scripts/test-deployment.bat` (Windows) or `./scripts/test-deployment.sh` (Unix)
3. Check browser DevTools Console for `[API]` logs
4. Verify `/api/tts/speak` requests in Network tab

## Key Points

✅ **VITE_BACKEND_URL** must be set in Vercel environment variables  
✅ **Must include `https://` prefix** for ngrok URLs  
✅ **No trailing slash** in the URL  
✅ **FRONTEND_ORIGIN** in server `.env` must match your Vercel domain  
✅ **Keep ngrok running** for voice features to work  

## Files Changed
- `client/src/services/apiClient.ts` - Enhanced error handling
- `client/vercel.json` - Added environment variable configuration
- `client/.env.example` - Added documentation
- `client/.env.production` - Added placeholder
- `server/.env.example` - Enhanced with deployment notes
- `README.md` - Added deployment section
- `DEPLOYMENT.md` (new) - Detailed deployment guide
- `VERCEL_NGROK_SETUP.md` (new) - Quick setup guide
- `scripts/test-deployment.sh` (new) - Diagnostics script
- `scripts/test-deployment.bat` (new) - Windows diagnostics

## Next Steps
1. Follow the setup guide in `VERCEL_NGROK_SETUP.md`
2. Set `VITE_BACKEND_URL` in Vercel
3. Test with the diagnostic script
4. Check browser console for any remaining issues
