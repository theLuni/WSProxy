@echo off
chcp 65001 >nul
title TG MTProto Proxy Server
color 0A

cd /d "%~dp0"

echo ================================================
echo    TG MTProto Proxy Server
echo ================================================
echo.

:: Проверка Python
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python not found!
    echo Please install Python 3.8 or higher
    pause
    exit /b 1
)

echo Python found:
python --version
echo.

:: ============================================
:: ВАШ ПОСТОЯННЫЙ СЕКРЕТ (32 hex символа)
:: Сгенерируйте новый через: python -c "import os; print(os.urandom(16).hex())"
:: ============================================
set SECRET=0123456789abcdef0123456789abcdef
:: ============================================

set PROXY_HOST=0.0.0.0
set PROXY_PORT=1443

echo Configuration:
echo   Host: %PROXY_HOST%
echo   Port: %PROXY_PORT%
echo   Secret: dd%SECRET%
echo.

:: Определяем внешний IP
echo Detecting external IP...
for /f "tokens=*" %%a in ('curl -s ifconfig.me 2^>nul') do set EXTERNAL_IP=%%a
if "%EXTERNAL_IP%"=="" (
    echo [WARN] Could not detect external IP via curl
    echo Trying alternative method...
    for /f "tokens=*" %%a in ('powershell -Command "(Invoke-WebRequest -Uri 'https://api.ipify.org' -UseBasicParsing).Content" 2^>nul') do set EXTERNAL_IP=%%a
)
if "%EXTERNAL_IP%"=="" (
    echo [WARN] Could not detect external IP, using localhost
    set EXTERNAL_IP=127.0.0.1
)
echo External IP: %EXTERNAL_IP%
echo.

:: Формируем ссылку для Telegram
set TG_LINK=tg://proxy?server=%EXTERNAL_IP%&port=%PROXY_PORT%&secret=dd%SECRET%

echo Your proxy link:
echo %TG_LINK%
echo.

:: Генерация QR-кода
echo Generating QR code...

where qrencode >nul 2>nul
if %errorLevel% equ 0 (
    qrencode -t UTF8 "%TG_LINK%"
    echo.
) else (
    echo Trying python-qrcode...
    python -c "import qrcode; qr = qrcode.QRCode(border=1); qr.add_data(r'%TG_LINK%'); qr.print_ascii(invert=True)" 2>nul
    if %errorLevel% neq 0 (
        echo.
        echo [WARN] QR code generation not available
        echo Install with: pip install qrcode[pil]
        echo.
    )
)

echo.
echo ================================================
echo Starting proxy...
echo ================================================
echo.

:: Проверяем существование модуля
python -c "import proxy.tg_ws_proxy" 2>nul
if %errorLevel% neq 0 (
    echo [ERROR] Module 'proxy.tg_ws_proxy' not found!
    echo.
    echo Please make sure you have the correct file structure:
    echo   %~dp0
    echo   └── proxy\
    echo       └── tg_ws_proxy.py
    echo.
    echo Current directory contents:
    dir /b
    echo.
    if exist "proxy\" (
        echo proxy directory contents:
        dir /b proxy\
    )
    echo.
    pause
    exit /b 1
)

:: Запуск прокси с выводом ошибок
python -m proxy.tg_ws_proxy --host %PROXY_HOST% --port %PROXY_PORT% --secret %SECRET% --dc-ip 2:149.154.167.220 --dc-ip 4:149.154.167.220

if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Proxy failed to start with error code: %errorLevel%
    echo.
    echo Possible solutions:
    echo 1. Install required packages: pip install cryptography websockets
    echo 2. Check if proxy.tg_ws_proxy.py exists
    echo 3. Run install.bat first
    echo.
)

pause