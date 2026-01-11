@echo off
chcp 65001

:: ===============================
:: 参数说明
:: ===============================

if "%1"=="" goto usage
if "%2"=="" goto usage
if "%3"=="" goto usage
if "%4"=="" goto usage

:: bundle name
set bundleName=%1
:: 版本号
set version=%2
:: 热更新地址
set hotupdateUrl=%3
:: 是否使用小包体 使用的话就只会放入引擎相关的资源
set miniApk=%4

:: ===============================
:: 热更新参数
:: ===============================
echo.
echo =========== Hotupdate Building ===========
echo   bundleName  :%bundleName%
echo   version     :%version%
echo   hotupdateUrl:%hotupdateUrl%
echo   miniApk :%miniApk%
echo =========== Hotupdate Building ===========
echo.

:: 项目路径
set projectPath=%cd%

:: 资源根目录
set assetsRootPath=%projectPath%\build\android\data\assets\

:: 产物保存目录
set saveVersionPath=%projectPath%\tools\hoteupdateversion\%bundleName%\

:: 哪些bundle需要放进manifest中
if "%bundleName%"=="hall" (
    if "%miniApk%"=="true" (
        set resourceFolder="src","jsb-adapter","assets\internal","assets\resources","assets\main"
    ) else (
        set resourceFolder="src","jsb-adapter","assets\internal","assets\resources","assets\main","assets\common","assets\loading","assets\hall","assets\mahjong"
    )
) else (
    set resourceFolder=["%bundleName%"]
)
if errorlevel 1 (
    echo ❌ 错误: 选择资源失败
    exit /b 1
)
set UPDATE_URL=%hotupdateUrl%\%bundleName%\
set ASSETSROOT_PATH=%assetsRootPath%
set RESOURCE_FOLDER=%resourceFolder%

:: 将路径中的反斜杠替换为正斜杠
set "UPDATE_URL=%UPDATE_URL:\=/%"
set "ASSETSROOT_PATH=%ASSETSROOT_PATH:\=/%"
set "RESOURCE_FOLDER=%RESOURCE_FOLDER:\=/%"

node tools/js/gen_manifest.js ^
  -v "%version%" ^
  -u "%UPDATE_URL%" ^
  -s "%ASSETSROOT_PATH%" ^
  -d "%ASSETSROOT_PATH%" ^
  -i "%RESOURCE_FOLDER%"

if errorlevel 1 (
    exit /b 1
)
echo 生成 %bundleName% manifest 完成

set src=%assetsRootPath%%bundleName%\

:: 删除旧文件
if exist "%saveVersionPath%" (
    :: 先尝试删除其中的文件 防止被占用的情况
    attrib -R "%saveVersionPath%"*.* /S
    rmdir /s /q "%saveVersionPath%"
) 
mkdir "%saveVersionPath%"

set dataPath=%assetsRootPath%..

:: 移动inBundlePathToManifest的资源到保存目录
setlocal enabledelayedexpansion
for %%i in (%resourceFolder%) do (
    set "item=%%i"
    set "item=!item:"=!"
    if exist "%dataPath%\!item!" (
        echo 移动 !item! 到 "%saveVersionPath%"
        move "%dataPath%\!item!" "%saveVersionPath%" >nul
    )
)
endlocal
if errorlevel 1 (
    echo ❌ 错误: 移动产物文件到保存目录失败1
    exit /b 1
)
:: 移动生成的.manifest文件到保存目录
move "%assetsRootPath%*.manifest" "%saveVersionPath%"
if errorlevel 1 (
    echo ❌ 错误: 移动产物文件到保存目录失败
    exit /b 1
)
echo 生成%bundleName%热更新文件完成

exit /b 0

:usage
echo.
echo 用法:
echo   gen_hotupdate.bat ^<bundleName^> ^<version^> ^<hotupdateUrl^> ^<miniApk^>
echo.
echo 示例:
echo   build.bat hall 0.0.1 dev https://test.cdn.xxx.com/xiaomi true
exit /b 1