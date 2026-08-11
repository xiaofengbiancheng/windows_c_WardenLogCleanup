@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Optional overrides for local testing.
if defined WARDEN_TARGET_DIR set "TARGET_DIR=%WARDEN_TARGET_DIR%"
if defined WARDEN_LOG_FILE set "LOG_FILE=%WARDEN_LOG_FILE%"
if defined WARDEN_WHITELIST set "WHITELIST=%WARDEN_WHITELIST%"
if defined WARDEN_TASK_NAME set "TASK_NAME=%WARDEN_TASK_NAME%"
if defined WARDEN_TASK_TIME set "TASK_TIME=%WARDEN_TASK_TIME%"
if defined WARDEN_SKIP_TASK_INSTALL set "SKIP_TASK_INSTALL=%WARDEN_SKIP_TASK_INSTALL%"

if not defined TARGET_DIR set "TARGET_DIR=C:\warden\wisps\health-check\log"
if not defined LOG_FILE set "LOG_FILE=cleanup_action.log"
if not defined WHITELIST set "WHITELIST=health-check-win.log cleanup_action.log"
if not defined TASK_NAME set "TASK_NAME=WardenLogCleanupTask"
if not defined TASK_TIME set "TASK_TIME=09:00"
set "TASK_PATH=\%TASK_NAME%"

set "RUN_MODE=manual"
if /I "%~1"=="/scheduled" set "RUN_MODE=scheduled"
if /I "%~1"=="--scheduled" set "RUN_MODE=scheduled"
if /I "%~1"=="-uninstall" set "RUN_MODE=uninstall"
if /I "%~1"=="--uninstall" set "RUN_MODE=uninstall"
if /I "%~1"=="/uninstall" set "RUN_MODE=uninstall"

set "DELETE_COUNT=0"
set "CLEAR_COUNT=0"
set "FAIL_COUNT=0"
set "EXIT_CODE=0"

call :CheckAdmin
if errorlevel 1 (
    set "EXIT_CODE=1"
    goto :finish
)

if /I "%RUN_MODE%"=="uninstall" (
    call :UninstallTask
    if errorlevel 1 set "EXIT_CODE=1"
    goto :finish
)

if /I "%RUN_MODE%"=="scheduled" goto :skip_task_install
if defined SKIP_TASK_INSTALL goto :skip_task_install
call :register_task
:skip_task_install

call :EnsureTargetDir
if errorlevel 1 (
    set "EXIT_CODE=1"
    goto :finish
)

call :GetToday
if errorlevel 1 (
    echo [ERROR] Unable to determine today's date from: %DATE%
    set "EXIT_CODE=1"
    goto :finish
)

for /f "delims=" %%F in ('dir /b /a-d "%TARGET_DIR%" 2^>nul') do call :ProcessFile "%TARGET_DIR%\%%F"

call :WriteSummary

:finish
if /I not "%RUN_MODE%"=="scheduled" pause
endlocal & exit /b %EXIT_CODE%

:CheckAdmin
net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Please run this script as Administrator.
    exit /b 1
)
exit /b 0

:register_task
for %%I in ("%~f0") do set "SCRIPT_SHORT=%%~sI"
set "TASK_ACTION=cmd.exe /d /c %SCRIPT_SHORT% /scheduled"
schtasks /Create /TN "%TASK_PATH%" /SC DAILY /ST %TASK_TIME% /RU SYSTEM /RL HIGHEST /TR "%TASK_ACTION%" /F
if errorlevel 1 (
    echo [WARN] Scheduled task registration failed: %TASK_NAME%
    exit /b 0
)

call :TaskExists
if errorlevel 1 (
    echo [WARN] Scheduled task registration could not be verified: %TASK_NAME%
    exit /b 0
)

echo [OK] Scheduled task registered: %TASK_NAME%
exit /b 0

:UninstallTask
call :TaskExists
if errorlevel 1 (
    echo [INFO] Scheduled task not found: %TASK_NAME%
    exit /b 0
)

schtasks /Delete /TN "%TASK_PATH%" /F >nul 2>&1
if errorlevel 1 (
    echo [WARN] Failed to remove scheduled task: %TASK_NAME%
    exit /b 1
)

echo [OK] Scheduled task removed: %TASK_NAME%
exit /b 0

:TaskExists
schtasks /Query /TN "%TASK_PATH%" >nul 2>&1
if not errorlevel 1 exit /b 0
schtasks /Query /TN "%TASK_NAME%" >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:EnsureTargetDir
if exist "%TARGET_DIR%\" exit /b 0
echo [ERROR] Target directory not found: %TARGET_DIR%
exit /b 1

:GetToday
set "DATE_A="
set "DATE_B="
set "DATE_C="
set "DATE_D="
for /f "tokens=1-4 delims=/-. " %%A in ("%DATE%") do (
    set "DATE_A=%%~A"
    set "DATE_B=%%~B"
    set "DATE_C=%%~C"
    set "DATE_D=%%~D"
)
set "TODAY="
if "!DATE_A:~0,1!"=="1" set "TODAY=!DATE_A!!DATE_B!!DATE_C!"
if "!DATE_A:~0,1!"=="2" set "TODAY=!DATE_A!!DATE_B!!DATE_C!"
if not defined TODAY if "!DATE_D:~0,1!"=="1" set "TODAY=!DATE_D!!DATE_B!!DATE_C!"
if not defined TODAY if "!DATE_D:~0,1!"=="2" set "TODAY=!DATE_D!!DATE_B!!DATE_C!"
if not defined TODAY if "!DATE_C:~0,1!"=="1" set "TODAY=!DATE_C!!DATE_A!!DATE_B!"
if not defined TODAY if "!DATE_C:~0,1!"=="2" set "TODAY=!DATE_C!!DATE_A!!DATE_B!"
if not "!TODAY:~7,1!"=="" if "!TODAY:~8,1!"=="" exit /b 0
set "TODAY="
exit /b 1

:ProcessFile
set "FILE_FULL=%~1"
set "FILE_NAME=%~nx1"

if /I "%FILE_NAME%"=="%LOG_FILE%" exit /b 0

set "IS_WHITELIST=0"
for %%W in (%WHITELIST%) do (
    if /I "!FILE_NAME!"=="%%~W" set "IS_WHITELIST=1"
)
if "!IS_WHITELIST!"=="1" (
    if /I not "%RUN_MODE%"=="scheduled" echo [KEEP] !FILE_NAME! [whitelist]
    exit /b 0
)

call :GetFileTimestamp "%FILE_FULL%" FILE_TS
if errorlevel 1 (
    set /a FAIL_COUNT+=1
    if /I not "%RUN_MODE%"=="scheduled" echo [FAIL] !FILE_NAME! [timestamp]
    exit /b 0
)

set "FILE_DAY=!FILE_TS:~0,8!"
if "!FILE_DAY!"=="!TODAY!" (
    if /I not "%RUN_MODE%"=="scheduled" echo [KEEP] !FILE_NAME! [today]
    exit /b 0
)

call :IsLocked "%FILE_FULL%" IS_LOCKED
if errorlevel 1 (
    set /a FAIL_COUNT+=1
    if /I not "%RUN_MODE%"=="scheduled" echo [FAIL] !FILE_NAME! [lock check]
    exit /b 0
)

if "!IS_LOCKED!"=="0" (
    call :DeleteFile "%FILE_FULL%" FILE_RESULT
) else (
    call :ClearFile "%FILE_FULL%" FILE_RESULT
)

if /I "!FILE_RESULT!"=="OK_DELETE" (
    set /a DELETE_COUNT+=1
    if /I not "%RUN_MODE%"=="scheduled" echo [DELETE] !FILE_NAME!
    exit /b 0
)

if /I "!FILE_RESULT!"=="OK_CLEAR" (
    set /a CLEAR_COUNT+=1
    if /I not "%RUN_MODE%"=="scheduled" echo [CLEAR] !FILE_NAME!
    exit /b 0
)

set /a FAIL_COUNT+=1
if /I not "%RUN_MODE%"=="scheduled" echo [FAIL] !FILE_NAME! [cleanup]
exit /b 0

:GetFileTimestamp
set "OUT_VAR=%~2"
set "FILE_RAW_TS="
for %%A in ("%~1") do set "FILE_RAW_TS=%%~tA"
if not defined FILE_RAW_TS exit /b 1
for /f "tokens=1 delims= " %%A in ("%FILE_RAW_TS%") do set "FILE_DATE=%%~A"
for /f "tokens=1-3 delims=/-. " %%A in ("%FILE_DATE%") do (
    set "FILE_A=%%~A"
    set "FILE_B=%%~B"
    set "FILE_C=%%~C"
)
set "FILE_NORMALIZED=!FILE_A!!FILE_B!!FILE_C!"
if "!FILE_A:~0,1!"=="1" set "FILE_NORMALIZED=!FILE_A!!FILE_B!!FILE_C!"
if "!FILE_A:~0,1!"=="2" set "FILE_NORMALIZED=!FILE_A!!FILE_B!!FILE_C!"
if not "!FILE_NORMALIZED:~7,1!"=="" if "!FILE_NORMALIZED:~8,1!"=="" (
    set "%OUT_VAR%=!FILE_NORMALIZED!"
    exit /b 0
)
set "%OUT_VAR%=!FILE_C!!FILE_A!!FILE_B!"
if not "!%OUT_VAR%:~7,1!"=="" if "!%OUT_VAR%:~8,1!"=="" exit /b 0
set "%OUT_VAR%="
exit /b 1

:IsLocked
set "OUT_VAR=%~2"
set "FILE_DIR=%~dp1"
set "FILE_NAME=%~nx1"
set "TEMP_NAME=.__warden_lock_test_%RANDOM%%RANDOM%.tmp"

pushd "%FILE_DIR%" >nul 2>&1
if errorlevel 1 (
    set "%OUT_VAR%=1"
    exit /b 1
)

ren "%FILE_NAME%" "%TEMP_NAME%" >nul 2>&1
if errorlevel 1 (
    popd >nul
    set "%OUT_VAR%=1"
    exit /b 0
)

ren "%TEMP_NAME%" "%FILE_NAME%" >nul 2>&1
if errorlevel 1 (
    popd >nul
    set "%OUT_VAR%=1"
    exit /b 1
)

popd >nul
set "%OUT_VAR%=0"
exit /b 0

:DeleteFile
set "FILE_FULL_PATH=%~1"
del /f /q "%FILE_FULL_PATH%" >nul 2>&1
if errorlevel 1 (
    set "%~2=FAIL"
    exit /b 0
)
set "%~2=OK_DELETE"
exit /b 0

:ClearFile
set "FILE_FULL_PATH=%~1"
type nul > "%FILE_FULL_PATH%" 2>nul
if errorlevel 1 (
    set "%~2=FAIL"
    exit /b 0
)
set "%~2=OK_CLEAR"
exit /b 0

:WriteSummary
call :GetToday
if errorlevel 1 exit /b 1
set "NOW_TIME=%TIME: =0%"
set "SUMMARY=[%TODAY:~0,4%/%TODAY:~4,2%/%TODAY:~6,2% %NOW_TIME:~0,2%:%NOW_TIME:~3,2%:%NOW_TIME:~6,2%] Delete: %DELETE_COUNT%, Clear: %CLEAR_COUNT%, Fail: %FAIL_COUNT%"
>>"%TARGET_DIR%\%LOG_FILE%" echo %SUMMARY%
if /I not "%RUN_MODE%"=="scheduled" echo %SUMMARY%
exit /b 0
