@echo off
REM Troubleshoot Vercel + ngrok voice feature connectivity
REM Usage: test-deployment.bat https://xxxx-xxxx-xxxx-xxxx.ngrok.io

setlocal enabledelayedexpansion

set BACKEND_URL=%1
set FRONTEND_URL=%2

if "!BACKEND_URL!"=="" set BACKEND_URL=http://localhost:3001
if "!FRONTEND_URL!"=="" set FRONTEND_URL=http://localhost:5173

echo.
echo 🔍 Testing blindVision deployment...
echo    Backend:  !BACKEND_URL!
echo    Frontend: !FRONTEND_URL!
echo.

REM Test 1: Backend health
echo ✓ Test 1: Backend health check
for /f %%A in ('curl -s "!BACKEND_URL!/api/health"') do set RESPONSE=%%A

if "!RESPONSE!"=="" (
    echo   ❌ Backend is NOT reachable
    echo   → Check if ngrok is running: ngrok http 3001
    exit /b 1
) else (
    echo   Response: !RESPONSE!
    echo   ✅ Backend is reachable
)
echo.

REM Test 2: TTS endpoint
echo ✓ Test 2: TTS endpoint test
echo   Making POST request to /api/tts/speak...
curl -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"text\":\"Test\"}" ^
  "!BACKEND_URL!/api/tts/speak" ^
  --max-time 10 ^
  -w "HTTP Status: %%{http_code}\n" ^
  -s -o nul

if errorlevel 0 (
    echo   ✅ TTS endpoint responded
) else (
    echo   ❌ TTS endpoint not responding
)
echo.

REM Test 3: Check ngrok (if using ngrok URL)
if "!BACKEND_URL!"=="!BACKEND_URL:ngrok=!" (
    echo ✓ Test 3: ngrok tunnel status
    curl -s -H "ngrok-skip-browser-warning: 1" "!BACKEND_URL!/api/health" >nul
    if errorlevel 0 (
        echo   ✅ ngrok tunnel is active
    ) else (
        echo   ❌ ngrok tunnel failed or requires authentication
    )
    echo.
)

echo ═══════════════════════════════════════════════════════════
echo 📋 Deployment Checklist:
echo.
echo Backend (ngrok^):
echo   [ ] npm run build ^&^& npm start in server\ directory
echo   [ ] ngrok http 3001 running in another terminal
echo   [ ] ELEVENLABS_API_KEY set in server\.env
echo   [ ] FRONTEND_ORIGIN updated in server\.env
echo.
echo Frontend (Vercel^):
echo   [ ] VITE_BACKEND_URL set to ngrok URL (in Vercel env^)
echo   [ ] Environment variable includes https:// prefix
echo   [ ] No trailing slash in VITE_BACKEND_URL
echo.
echo For more details, see DEPLOYMENT.md
echo.
