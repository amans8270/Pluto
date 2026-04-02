@echo off
REM ===========================================
REM Pluto - Supabase Edge Function Setup Script
REM ===========================================

echo.
echo =============================================
echo   Pluto - Image Compression Setup
echo =============================================
echo.

REM Check if supabase CLI is installed
where supabase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Supabase CLI not found!
    echo.
    echo Install it by running:
    echo   npm install -g supabase
    echo.
    pause
    exit /b 1
)

echo [OK] Supabase CLI found
echo.

REM Check if linked to project
echo Checking Supabase project link...
supabase status >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Linking to Supabase project...
    supabase link --project-ref esedlxfmzwndjhqboknl
)

echo.
echo =============================================
echo   Deploying Edge Function: compress-image
echo =============================================
echo.

cd /d "%~dp0"

REM Deploy the Edge Function
supabase functions deploy compress-image --no-verify-jwt

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =============================================
    echo   SUCCESS! Edge Function deployed!
    echo =============================================
    echo.
    echo Next steps:
    echo   1. Create 'photos' bucket in Supabase Dashboard
    echo      - Storage ^> New Bucket
    echo      - Name: photos
    echo      - Public: Yes
    echo.
    echo   2. Set Edge Function env vars in Dashboard:
    echo      - SUPABASE_URL
    echo      - SUPABASE_SERVICE_ROLE_KEY
    echo.
    echo   3. Restart your FastAPI backend
    echo.
) else (
    echo.
    echo [ERROR] Deployment failed. Check the error above.
    echo.
)

pause
