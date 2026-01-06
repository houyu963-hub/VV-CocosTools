@echo off
setlocal enabledelayedexpansion

REM ===============================
REM 参数说明
REM build.bat android xiaomi dev
REM build.bat web official prod
REM ===============================

"%CREATOR%" --project %cd% --build platform=web-mobile

@REM if "%1"=="" goto usage
@REM if "%2"=="" goto usage
@REM if "%3"=="" goto usage
@REM if "%4"=="" goto usage
@REM if "%5"=="" goto usage
@REM if "%6"=="" goto usage

@REM set PLATFORM=%1
@REM set CHANNEL=%2
@REM set ENV=%3
@REM set MODE=%4
@REM set CREATOR=%5
@REM set CLEAN=%6

@REM REM ===============================
@REM REM 环境名归一化
@REM REM ===============================
@REM if "%ENV%"=="prod" set ENV=prod
@REM if "%ENV%"=="test" set ENV=test
@REM if "%ENV%"=="dev" set ENV=dev
@REM if "%MODE%"=="debug" set MODE=debug
@REM if "%MODE%"=="release" set MODE=release

@REM REM ===============================
@REM REM 渠道配置文件
@REM REM ===============================
@REM if "%ENV%"=="dev"  set CONFIG_NAME=dev.json
@REM if "%ENV%"=="test" set CONFIG_NAME=test.json
@REM if "%ENV%"=="prod" set CONFIG_NAME=prod.json

@REM set CHANNEL_CONFIG=build-config\%PLATFORM%\%CHANNEL%\%CONFIG_NAME%
@REM set CHANNEL_TS=assets\frame\config\ChannelConfig.ts

@REM if not exist "%CHANNEL_CONFIG%" (
@REM   echo ❌ Channel config not found:
@REM   echo %CHANNEL_CONFIG%
@REM   exit /b 1
@REM )

@REM REM ===============================
@REM REM 注入 ChannelConfig.ts
@REM REM ===============================
@REM echo =========== Inject ChannelConfig.ts ===========
@REM copy /Y "%CHANNEL_CONFIG%" "%CHANNEL_TS%" >nul

@REM if errorlevel 1 (
@REM   echo ❌ Failed to inject ChannelConfig.ts
@REM   exit /b 1
@REM )

@REM REM ===============================
@REM REM 设置热更新地址（独立处理）
@REM REM ===============================
@REM @REM if exist "hotupdate\set_hotupdate.bat" (
@REM @REM   call hotupdate\set_hotupdate.bat %PLATFORM% %CHANNEL% %ENV%
@REM @REM )

@REM REM ===============================
@REM REM 选择构建参数
@REM REM ===============================
@REM if "%PLATFORM%"=="android" (
@REM   set BUILD_ARGS=platform=android;configPath=build-config/android/buildConfig_android.json
@REM )

@REM if "%PLATFORM%"=="web" (
@REM   set BUILD_ARGS=platform=web-mobile;configPath=build-config/web/buildConfig_web-mobile.json
@REM )

@REM if "%PLATFORM%"=="ios" (
@REM   set BUILD_ARGS=platform=ios;configPath=build-config/ios/buildConfig_ios.json
@REM )

@REM REM ===============================
@REM REM 开始构建
@REM REM ===============================
@REM echo.
@REM echo =========== Building ===========
@REM echo   Platform: %PLATFORM%
@REM echo   Channel : %CHANNEL%
@REM echo   Env     : %ENV%
@REM echo   MODE    : %MODE%
@REM echo   CREATOR : %CREATOR%
@REM echo   CLEAN   : %CLEAN%
@REM echo =========== Building ===========
@REM echo.

@REM REM 检查 CREATOR 路径
@REM if not exist "%CREATOR%" (
@REM   echo ❌ Cocos Creator not found at: %CREATOR%
@REM   exit /b 1
@REM )

@REM "%CREATOR%" --project %cd% --build "%BUILD_ARGS%;mode=%MODE%"

@REM set CODE=%ERRORLEVEL%

@REM REM ===============================
@REM REM Cocos exit code 36 视为成功
@REM REM ===============================
@REM if %CODE%==0 (
@REM   echo ✅ Build success
@REM ) else if %CODE%==36 (
@REM   echo ⚠️ Build success (exit code 36)
@REM ) else (
@REM   echo ❌ Build failed, exit code=%CODE%
@REM   exit /b %CODE%
@REM )

@REM echo 🎉 ALL DONE
@REM exit /b 0

@REM :usage
@REM echo.
@REM echo 用法:
@REM echo   build.bat ^<platform^> ^<channel^> ^<env^>
@REM echo.
@REM echo 示例:
@REM echo   build.bat android xiaomi dev
@REM echo   build.bat android huawei prod
@REM echo   build.bat web official test
@REM exit /b 1
