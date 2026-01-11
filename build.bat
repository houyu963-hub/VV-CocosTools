@echo off
chcp 65001
setlocal enabledelayedexpansion

REM ===============================
REM 参数说明
REM build.bat android xiaomi dev debug CocosCreator.exe true true
REM build.bat web official test debug CocosCreator.exe true true
REM ===============================

if "%1"=="" goto usage
if "%2"=="" goto usage
if "%3"=="" goto usage
if "%4"=="" goto usage
if "%5"=="" goto usage
if "%6"=="" goto usage
if "%7"=="" goto usage

set PLATFORM=%1
set CHANNEL=%2
set ENV=%3
set MODE=%4
set CREATOR=%5
set CLEAN=%6
set MINI_APK=%7

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
  echo ❌ 错误: 未发现渠道配置:%CHANNEL_CONFIG%
  exit /b 1
)

REM ===============================
REM 注入 ChannelConfig.ts
REM ===============================
node tools\js\gen_channel_config.js %CHANNEL_CONFIG% %CHANNEL_TS%
if errorlevel 1 (
  echo ❌ 错误: 注入 ChannelConfig.ts 失败
  exit /b 1
)
echo ===========  注入 ChannelConfig.ts 完成: %CHANNEL_CONFIG% ===========

REM ===============================
REM 安装项目依赖
REM ===============================
if exist "package.json" (
  echo =========== Installing dependencies ===========
  call npm install --registry https://registry.npmmirror.com
  if errorlevel 1 (
    echo ❌ 错误: npm 安装失败 errorlevel: %ERRORLEVEL%
    exit /b 1
  )
) else (
  echo 未发现package.json, 跳过 npm install
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
REM 热更新流程（必须双构建）
REM ===============================

REM 1. 第一次构建（生成最新资源）
%CREATOR% --project %cd% --build "%BUILD_ARGS%;mode=%MODE%"
if errorlevel 36 (
  if "%PLATFORM%"=="web" (
      echo 🎉 构建任务全部完成
      exit /b 0
  ) else ( 
    echo ✅ 第1次构建完成: code 36
  )
) else (
    echo ❌ 错误: 第1次构建失败
    exit /b 1
)

REM 2. 读取上一次版本号
set LAST_VERSION_PATH=tools\hoteupdateversion\hall\version.manifest
set LAST_VERSION=
if exist LAST_VERSION_PATH (
  for /f %%i in ('node tools\js\read_value.js tools\hoteupdateversion\hall\version.manifest version') do (
    set LAST_VERSION=%%i
  )
) else (
  echo 未发现version.manifest,默认热更新版本: 0.0.0.0
  set LAST_VERSION=0.0.0.0
)

if "%LAST_VERSION%"=="" (
  echo ❌ 错误: 读取上一次版本号失败
  exit /b 1
)

REM 3. 读取热更新地址
set HOTUPDATE_URL=
for /f %%i in ('node tools\js\read_value.js %CHANNEL_CONFIG% hotupdateUrl') do (
  set HOTUPDATE_URL=%%i
)

if "%HOTUPDATE_URL%"=="" (
  echo ❌ 错误: 读取热更新地址失败
  exit /b 1
)

REM 4. 生成热更新 manifest
call tools\gen_hotupdate.bat hall %LAST_VERSION% %HOTUPDATE_URL% %MINI_APK%
if errorlevel 1 (
  echo ❌ 错误: 生成热更新 manifest 失败
  exit /b 1
)

REM 5. 第二次构建（正式 APK）
echo.
echo =========== 第二次构建 ===========
echo   Platform: %PLATFORM%
echo   Channel : %CHANNEL%
echo   Env     : %ENV%
echo   MODE    : %MODE%
echo   CREATOR : %CREATOR%
echo =========== 第二次构建 ===========
echo.

%CREATOR% --project %cd% --build "%BUILD_ARGS%;mode=%MODE%"
if errorlevel 36 (
  echo ✅ 第2次构建完成: code 36
) else (
    echo ❌ 错误: 第2次构建失败
    exit /b 1
)

echo 🎉 构建任务全部完成
exit /b 0

:usage
echo.
echo 用法:
echo   build.bat ^<platform^> ^<channel^> ^<env^> ^<mode^> ^<creator^> ^<clean^> ^<mini_apk^>
echo.
echo 示例:
echo   build.bat android xiaomi dev debug CocosCreator.exe true true
echo   build.bat android huawei prod debug CocosCreator.exe true true
echo   build.bat web official test debug CocosCreator.exe true true
exit /b 1