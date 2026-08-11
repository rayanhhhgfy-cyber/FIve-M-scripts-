@echo off
setlocal enabledelayedexpansion

:: ====================================================================
::               QBox Framework FiveM Roleplay Server
::                     Interactive Startup Script
:: ====================================================================

title QBox FiveM Server Startup Utility
color 0B
cls

echo ====================================================================
echo *        QBOX FRAMEWORK FIVEM ROLEPLAY SERVER STARTUP UTILITY       *
echo ====================================================================
echo.

set "CONFIG_FILE=resources\server.cfg"
set "SAVED_PATH_FILE=.fxserver_path.txt"
set "FXSERVER_PATH="

:: 1. Check if server.cfg exists
if not exist "%CONFIG_FILE%" (
    color 0C
    echo [ERROR] Could not find server configuration file at:
    echo         %CONFIG_FILE%
    echo         Please make sure you are running this script from the
    echo         root directory of the FiveM server project.
    echo.
    pause
    exit /b 1
)

:: 2. Check if port 30120 is already in use
echo [INFO] Checking if default FiveM port 30120 is in use...
netstat -ano | findstr /R /C:":30120 " >nul 2>&1
if !errorlevel! equ 0 (
    color 0E
    echo [WARNING] Port 30120 is already in use!
    echo           Another server instance might be running.
    echo.
    choice /C YN /M "[?] Would you like to attempt to close the blocking process"
    if !errorlevel! equ 1 (
        echo [INFO] Attempting to terminate process using port 30120...
        for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:":30120 "') do (
            taskkill /PID %%a /F >nul 2>&1
        )
        echo [SUCCESS] Process terminated.
        echo.
    ) else (
        echo [INFO] Continuing anyway...
        echo.
    )
    color 0B
) else (
    echo [SUCCESS] Port 30120 is free.
    echo.
)

:: 3. Load saved FXServer.exe path if it exists
if exist "%SAVED_PATH_FILE%" (
    set /p FXSERVER_PATH=<"%SAVED_PATH_FILE%"
    :: Strip any surrounding quotes
    set "FXSERVER_PATH=!FXSERVER_PATH:"=!"
    if exist "!FXSERVER_PATH!" (
        echo [INFO] Found saved FXServer path: "!FXSERVER_PATH!"
        goto :launch
    )
)

:: 4. Search for FXServer.exe in standard directories
echo [INFO] Searching for FXServer.exe...

set "SEARCH_PATHS[1]=..\bin\FXServer.exe"
set "SEARCH_PATHS[2]=..\FXServer.exe"
set "SEARCH_PATHS[3]=..\server\FXServer.exe"
set "SEARCH_PATHS[4]=..\artifacts\FXServer.exe"
set "SEARCH_PATHS[5]=C:\FXServer\server\FXServer.exe"
set "SEARCH_PATHS[6]=C:\FiveM_Server\bin\FXServer.exe"
set "SEARCH_PATHS[7]=D:\FXServer\server\FXServer.exe"
set "SEARCH_PATHS[8]=.\FXServer.exe"

for /L %%i in (1,1,8) do (
    set "CURRENT_PATH=!SEARCH_PATHS[%%i]!"
    if exist "!CURRENT_PATH!" (
        set "FXSERVER_PATH=!CURRENT_PATH!"
        echo [SUCCESS] Found FXServer.exe at: "!FXSERVER_PATH!"
        echo !FXSERVER_PATH!> "%SAVED_PATH_FILE%"
        goto :launch
    )
)

:: 5. Prompt user if not found
color 0E
echo [WARNING] Could not automatically find FXServer.exe in common locations.
echo.
echo Please enter the absolute path to your FXServer.exe:
echo Example: C:\FXServer\server\FXServer.exe
echo.
set /p USER_PATH="Path: "

:: Remove quotes if entered by user
set USER_PATH=!USER_PATH:"=!

if not exist "!USER_PATH!" (
    color 0C
    echo.
    echo [ERROR] The path entered does not exist: "!USER_PATH!"
    echo         Please make sure the file exists and try again.
    echo.
    pause
    exit /b 1
)

:: Check if the path is indeed to FXServer.exe or run.cmd
set "FXSERVER_PATH=!USER_PATH!"
echo !FXSERVER_PATH!> "%SAVED_PATH_FILE%"
color 0B
echo [SUCCESS] Saved path to %SAVED_PATH_FILE%
echo.

:launch
echo ====================================================================
echo [INFO] Launching FiveM Server...
echo [INFO] Executing config: %CONFIG_FILE%
echo ====================================================================
echo.

:: Launch the server
"!FXSERVER_PATH!" +exec "%CONFIG_FILE%"

if !errorlevel! neq 0 (
    color 0C
    echo.
    echo [ERROR] FXServer exited with an error code (!errorlevel!).
    echo         Check your server console logs above for more details.
    echo.
    pause
)

endlocal
