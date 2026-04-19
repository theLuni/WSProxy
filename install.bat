@echo off
chcp 65001 >nul
title TG Proxy Installer - Python 3.12.8 Setup
color 0A

echo ================================================
echo    TG MTProto Proxy Installer
echo    Python 3.12.8 + Dependencies
echo ================================================
echo.

:: Проверяем права администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] This script requires Administrator privileges.
    echo [INFO] Please run as Administrator for Python installation.
    echo.
    echo Right-click on this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

:: Создаем временную папку
set TEMP_DIR=%TEMP%\tg_proxy_installer
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Проверка наличия Python 3.12
echo [1/6] Checking Python installation...
python --version >nul 2>&1
if %errorLevel% equ 0 (
    python --version | find "3.12" >nul
    if %errorLevel% equ 0 (
        echo [✓] Python 3.12 found!
        goto :install_pip
    ) else (
        echo [!] Python found but not version 3.12
    )
)

:: Скачивание Python 3.12.8
echo [2/6] Downloading Python 3.12.8...
set PYTHON_URL=https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe
set PYTHON_INSTALLER=%TEMP_DIR%\python-3.12.8-amd64.exe

echo Downloading from: %PYTHON_URL%
echo This may take a few minutes...

:: Проверяем наличие PowerShell и интернета
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%' -TimeoutSec 30}" >nul 2>&1

if not exist "%PYTHON_INSTALLER%" (
    echo [✗] Failed to download Python installer via PowerShell
    echo Trying with bitsadmin...
    bitsadmin /transfer "PythonDownload" /priority high "%PYTHON_URL%" "%PYTHON_INSTALLER%" >nul 2>&1
)

if not exist "%PYTHON_INSTALLER%" (
    echo [✗] Cannot download Python. Please check your internet connection.
    echo.
    echo You can manually download Python 3.12.8 from:
    echo %PYTHON_URL%
    echo.
    pause
    exit /b 1
)

echo [✓] Python 3.12.8 downloaded successfully!

:: Установка Python
echo [3/6] Installing Python 3.12.8...
echo This may take a few minutes...

:: Тихая установка с добавлением в PATH
"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0 Include_symbols=0 Include_tcltk=0 >nul 2>&1

if %errorLevel% neq 0 (
    echo [✗] Silent installation failed
    echo Starting manual installer...
    start /wait "%PYTHON_INSTALLER%"
    echo Please complete the Python installation manually.
    echo Make sure to check "Add Python to PATH"
    pause
)

:: Обновляем PATH для текущей сессии
echo [4/6] Updating environment...
set "PATH=%PATH%;C:\Program Files\Python312;C:\Program Files\Python312\Scripts"
setx PATH "%PATH%" /M >nul 2>&1

:: Проверяем установку
echo [✓] Python installation completed!
python --version 2>nul
if %errorLevel% neq 0 (
    echo [✗] Python not found in PATH
    echo Please add Python to PATH manually or reboot your computer
    pause
)

:install_pip
:: Установка/обновление pip
echo.
echo [5/6] Installing/Upgrading pip...
python -m ensurepip --upgrade >nul 2>&1
python -m pip install --upgrade pip --quiet

if %errorLevel% neq 0 (
    echo [✗] Failed to install pip
    pause
    exit /b 1
)

echo [✓] pip ready

:: Установка зависимостей
echo.
echo [6/6] Installing required packages...
echo This may take a moment...

:: Создаем requirements.txt со всеми необходимыми библиотеками
(
echo # Core dependencies
echo cryptography>=41.0.0
echo httpx>=0.27.0
echo websockets>=12.0
echo
echo # QR code generation
echo qrcode>=7.4.0
echo pillow>=10.0.0
echo
echo # Optional: GUI (if needed)
echo customtkinter>=5.2.0
echo
echo # Utilities
echo colorama>=0.4.6
echo requests>=2.31.0
) > "%TEMP_DIR%\requirements.txt"

:: Установка через pip с отображением прогресса
echo Installing from requirements.txt...
python -m pip install -r "%TEMP_DIR%\requirements.txt" --no-cache-dir

if %errorLevel% neq 0 (
    echo.
    echo [WARNING] Some packages failed to install
    echo Trying individual installation...
    
    :: Core packages
    echo Installing cryptography...
    python -m pip install cryptography --quiet
    
    echo Installing httpx...
    python -m pip install httpx --quiet
    
    echo Installing websockets...
    python -m pip install websockets --quiet
    
    :: QR packages
    echo Installing qrcode...
    python -m pip install qrcode --quiet
    
    echo Installing pillow...
    python -m pip install pillow --quiet
    
    :: Optional packages
    echo Installing optional packages...
    python -m pip install customtkinter --quiet 2>nul
    python -m pip install colorama --quiet 2>nul
    python -m pip install requests --quiet 2>nul
)

:: Проверяем успешность установки ключевых библиотек
echo.
echo Verifying installation...
python -c "import cryptography; print('✓ cryptography')" 2>nul
if %errorLevel% equ 0 (echo [✓] cryptography) else (echo [✗] cryptography)

python -c "import websockets; print('✓ websockets')" 2>nul
if %errorLevel% equ 0 (echo [✓] websockets) else (echo [✗] websockets)

python -c "import qrcode; print('✓ qrcode')" 2>nul
if %errorLevel% equ 0 (echo [✓] qrcode) else (echo [✗] qrcode)

python -c "import PIL; print('✓ pillow')" 2>nul
if %errorLevel% equ 0 (echo [✓] pillow) else (echo [✗] pillow)

python -c "import httpx; print('✓ httpx')" 2>nul
if %errorLevel% equ 0 (echo [✓] httpx) else (echo [✗] httpx)

echo.
echo ================================================
echo    INSTALLATION COMPLETE!
echo ================================================
echo.
echo [✓] Python 3.12.8 installed
echo [✓] pip upgraded
echo [✓] Required packages installed
echo.
echo You can now run the proxy using:
echo   start.bat
echo.
echo Or manually:
echo   python -m proxy.tg_ws_proxy --host 0.0.0.0 --port 1443
echo.

:: Очистка временных файлов
echo Cleaning temporary files...
timeout /t 3 /nobreak >nul 2>&1
rd /s /q "%TEMP_DIR%" 2>nul

echo.
echo Press any key to exit...
pause >nul
exit /b 0