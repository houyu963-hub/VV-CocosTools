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
set MINI=%7

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
node tools\js\gen_channel_config.js %CHANNEL_CONFIG% %CHANNEL_TS%

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
REM 读取上一次热更新版本
REM ===============================
set LAST_VERSION=
for /f %%i in ('node tools\js\read_version.js tools\version\hall\version.manifest') do (
  set LAST_VERSION=%%i
)

if "%LAST_VERSION%"=="" (
  echo ❌ Failed to read last version
  exit /b 1
)

echo Last hotupdate version: %LAST_VERSION%


REM ===============================
REM 每次构建生成apk都要是最新的资源不要再走热更新了，热更新版本号应该是上次生成的版本，
REM 注意:这里似乎需要cocoscreator构建两次，
REM 第一次用于生成最新资源manifest文件放进项目resources/manifest/hall/project.manifest、version.manifest，gen_hotupdate.bat会自动放。
REM 所以当第一次构建后需要执行gen_hotupdate.bat，之后进行第二次构建
REM 第二次使用最新的project.manifest、version.manifest文件构建android工程，
REM gen_hotupdate.bat会把生成的.manifest文件放在/tools/version/%name%/下面，
REM ===============================
if exist "tools\gen_hotupdate.bat" (
  set version=应该从上次生成的版本.manifest文件中读取获取远程资源的.manifest文件中读取
  set hotupdateUrl=应该从CHANNEL_CONFIG中读取或是从注入后的ChannelConfig.ts中读取
  call tools\gen_hotupdate.bat "hall" version %hotupdateUrl% %MINI%
)

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
