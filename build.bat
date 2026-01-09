@echo off
setlocal enabledelayedexpansion

REM ===============================
REM 参数说明
REM build.bat android xiaomi dev
REM build.bat web official prod
REM ===============================

if "%1"=="" goto usage
if "%2"=="" goto usage
if "%3"=="" goto usage
if "%4"=="" goto usage
if "%5"=="" goto usage
if "%6"=="" goto usage

set PLATFORM=%1
set CHANNEL=%2
set ENV=%3
set MODE=%4
set CREATOR=%5
set CLEAN=%6

REM ===============================
REM 环境名归一化
REM ===============================
if "%ENV%"=="prod" set ENV=prod
if "%ENV%"=="test" set ENV=test
if "%ENV%"=="dev" set ENV=dev
if "%MODE%"=="debug" set MODE=debug
if "%MODE%"=="release" set MODE=release

REM ===============================
REM 渠道配置文件
REM ===============================
if "%ENV%"=="dev"  set CONFIG_NAME=dev.json
if "%ENV%"=="test" set CONFIG_NAME=test.json
if "%ENV%"=="prod" set CONFIG_NAME=prod.json

set CHANNEL_CONFIG=build-config\%PLATFORM%\%CHANNEL%\%CONFIG_NAME%
set CHANNEL_TS=assets\frame\config\ChannelConfig.ts

if not exist "%CHANNEL_CONFIG%" (
  echo ❌ Channel config not found:
  echo %CHANNEL_CONFIG%
  exit /b 1
)

REM ===============================
REM 注入 ChannelConfig.ts
REM ===============================
echo =========== Inject ChannelConfig.ts ===========
echo %CHANNEL_CONFIG%
node tools\gen_channel_config.js %CHANNEL_CONFIG% %CHANNEL_TS%

if errorlevel 1 (
  echo ❌ Failed to inject ChannelConfig.ts
  exit /b 1
)

REM ===============================
REM 安装项目依赖
REM ===============================
if exist "package.json" (
  echo =========== Installing dependencies ===========
  call npm install --registry https://registry.npmmirror.com
  echo npm install completed with errorlevel: %ERRORLEVEL%
) else (
  echo package.json not found, skipping npm install
)

REM ===============================
REM 设置热更新地址（独立处理）
REM ===============================
@REM if exist "hotupdate\set_hotupdate.bat" (
@REM   call hotupdate\set_hotupdate.bat %PLATFORM% %CHANNEL% %ENV%
@REM )

REM ===============================
REM 选择构建参数
REM ===============================
if "%PLATFORM%"=="android" (
  set BUILD_ARGS=platform=android;configPath=build-config\android\buildConfig_android.json
)

if "%PLATFORM%"=="web" (
  set BUILD_ARGS=platform=web-mobile;configPath=build-config\web\buildConfig_web-mobile.json
)

if "%PLATFORM%"=="ios" (
  set BUILD_ARGS=platform=ios;configPath=build-config\ios\buildConfig_ios.json
)

REM ===============================
REM 开始构建 Android 工程
REM ===============================
echo.
echo =========== Cocoscreator Building ===========
echo   Platform: %PLATFORM%
echo   Channel : %CHANNEL%
echo   Env     : %ENV%
echo   MODE    : %MODE%
echo   CREATOR : %CREATOR%
echo   CLEAN   : %CLEAN%
echo =========== Cocoscreator Building ===========
echo.

REM 检查 CREATOR 路径
if not exist "%CREATOR%" (
  echo ❌ Cocos Creator not found at: %CREATOR%
  exit /b 1
)

%CREATOR% --project %cd% --build "%BUILD_ARGS%;mode=%MODE%"

echo 🎉 ALL DONE
exit /b 0

:usage
echo.
echo 用法:
echo   build.bat ^<platform^> ^<channel^> ^<env^>
echo.
echo 示例:
echo   build.bat android xiaomi dev
echo   build.bat android huawei prod
echo   build.bat web official test
exit /b 1
