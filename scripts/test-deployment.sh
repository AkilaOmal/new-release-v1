#!/bin/bash
# Troubleshoot Vercel + ngrok voice feature connectivity
# Usage: ./scripts/test-deployment.sh https://xxxx-xxxx-xxxx-xxxx.ngrok.io

set -e

BACKEND_URL="${1:-http://localhost:3001}"
FRONTEND_URL="${2:-http://localhost:5173}"

echo "🔍 Testing blindVision deployment..."
echo "   Backend:  $BACKEND_URL"
echo "   Frontend: $FRONTEND_URL"
echo ""

# Test 1: Backend health
echo "✓ Test 1: Backend health check"
if response=$(curl -s "$BACKEND_URL/api/health"); then
  echo "  Response: $response"
  if echo "$response" | grep -q "ok"; then
    echo "  ✅ Backend is reachable"
  else
    echo "  ⚠️  Backend returned unexpected response"
  fi
else
  echo "  ❌ Backend is NOT reachable"
  echo "  → Check if ngrok is running: ngrok http 3001"
  exit 1
fi
echo ""

# Test 2: ELEVENLABS service
echo "✓ Test 2: ElevenLabs service status"
if response=$(curl -s "$BACKEND_URL/api/health"); then
  if echo "$response" | grep -q '"elevenlabs":true'; then
    echo "  ✅ ElevenLabs API key is configured"
  else
    echo "  ❌ ElevenLabs API key is NOT set"
    echo "  → Set ELEVENLABS_API_KEY in server/.env"
  fi
else
  echo "  ❌ Could not check service status"
fi
echo ""

# Test 3: TTS endpoint
echo "✓ Test 3: TTS endpoint (POST /api/tts/speak)"
if response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"text":"Test"}' \
  "$BACKEND_URL/api/tts/speak" \
  -w "\n%{http_code}" \
  --max-time 10); then
  
  http_code=$(echo "$response" | tail -n1)
  
  if [ "$http_code" = "200" ]; then
    echo "  ✅ TTS endpoint is working (returns audio)"
  elif [ "$http_code" = "503" ]; then
    echo "  ❌ ELEVENLABS_API_KEY is missing or invalid"
  elif [ "$http_code" = "429" ]; then
    echo "  ⚠️  Rate limited (try again in a moment)"
  else
    echo "  ❌ Unexpected status: $http_code"
  fi
else
  echo "  ❌ TTS endpoint not responding"
fi
echo ""

# Test 4: CORS headers (simulating browser request from Vercel)
echo "✓ Test 4: CORS headers (for $FRONTEND_URL)"
if response=$(curl -s -I -X OPTIONS \
  -H "Origin: $FRONTEND_URL" \
  -H "Access-Control-Request-Method: POST" \
  "$BACKEND_URL/api/tts/speak"); then
  
  if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
    echo "  ✅ CORS headers present"
    echo "$response" | grep "Access-Control" | sed 's/^/  /'
  else
    echo "  ⚠️  No CORS headers detected"
    echo "  → Check FRONTEND_ORIGIN in server/.env"
  fi
else
  echo "  ❌ Could not check CORS headers"
fi
echo ""

# Test 5: ngrok status (if Backend URL is ngrok)
if [[ "$BACKEND_URL" == *"ngrok.io"* ]]; then
  echo "✓ Test 5: ngrok tunnel status"
  if response=$(curl -s -H "ngrok-skip-browser-warning: 1" "$BACKEND_URL/api/health"); then
    echo "  ✅ ngrok tunnel is active and accessible"
  else
    echo "  ❌ ngrok tunnel failed or requires authentication"
    echo "  → Make sure ngrok is running: ngrok http 3001"
  fi
  echo ""
fi

echo "═══════════════════════════════════════════════════════════"
echo "📋 Deployment Checklist:"
echo ""
echo "Backend (ngrok):"
echo "  [ ] \`npm run build && npm start\` in server/ directory"
echo "  [ ] \`ngrok http 3001\` running in another terminal"
echo "  [ ] ELEVENLABS_API_KEY set in server/.env"
echo "  [ ] FRONTEND_ORIGIN updated in server/.env"
echo ""
echo "Frontend (Vercel):"
echo "  [ ] VITE_BACKEND_URL set to ngrok URL (in Vercel env)"
echo "  [ ] Environment variable includes https:// prefix"
echo "  [ ] No trailing slash in VITE_BACKEND_URL"
echo ""
echo "For more details, see DEPLOYMENT.md"
