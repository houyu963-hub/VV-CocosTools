@echo off
REM 检查参数是否存在
if "%1"=="" (
    echo Error: Missing argument 'name'
    exit /b 1
)
if "%2"=="" (
    echo Error: Missing argument 'version'
    exit /b 1
)

set name=%1
set version=%2
echo name:%name%
echo version:%version%

 :: 你的项目路径、rar执行程序路径
set projectPath=D:/project/game
set rarPath=D:/software/WinRAR/Rar.exe

set genPath=%projectPath%/build/android/data/assets/
set versionPath=%projectPath%/tools/version/%name%/
set manifestPath=%projectPath%/tools/manifest/%name%/
set src=%genPath%%name%/
set hall_remote_url=http://192.168.1.99:8081/%name%/
set subgames_remote_url=https://cdn.g2qdh.com/hot-update/subgames/%name%/

REM 生成 manifest
if "%name%"=="hall" (
    node gen_manifest.js -v %version% -u %hall_remote_url% -s "%genPath%" -d "%genPath%" -n %name%
) else (
    node gen_manifest.js -v %version% -u %subgames_remote_url% -s "%genPath%" -d "%genPath%" -n %name%
)
if errorlevel 1 (
    echo Error: Failed to generate manifest
    exit /b 1
)
echo generate %name% manifest succeed!

REM 压缩资源
if "%name%"=="hall" (
    REM 把 manifest 文件移动到资源根目录
    cd %genPath%
    move *.manifest ..
    cd ..
    %rarPath% a -ed version_%version%.zip "src" "*.manifest" ^
    "assets/internal" ^
    "assets/resources" ^
    "assets/main" ^
    "assets/common" ^
    "assets/loading" ^
    "assets/hall" ^
    "assets/mahjong"
) else (
    REM 子游戏直接压缩
    cd %src%
    %rarPath% a -r version_%version%.zip *
)
if errorlevel 1 (
    echo Error: Compression failed
    exit /b 1
)

REM 创建目录并移动文件
if not exist "%versionPath%" mkdir "%versionPath%"
move "version_%version%.zip" "%versionPath%"
if not exist "%manifestPath%" mkdir "%manifestPath%"
move "*.manifest" "%manifestPath%"

echo generate %name% version_%version%.zip succeed!