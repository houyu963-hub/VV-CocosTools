@echo off

:: 检查参数是否存在
if "%1"=="" (
    echo Error: Missing argument 'bundleName'
    exit /b 1
)
if "%2"=="" (
    echo Error: Missing argument 'version'
    exit /b 1
)
if "%3"=="" (
    echo Error: Missing argument 'hotupdateUrl'
    exit /b 1
)
if "%4"=="" (
    echo Error: Missing argument 'minipackage'
    exit /b 1
)

:: bundle name
set bundleName=%1 
:: 版本号
set version=%2
:: 热更新地址
set hotupdateUrl=%3
:: minipackage
set minipackage=%4

echo bundleName:%bundleName%
echo version:%version%
echo hotupdateUrl:%hotupdateUrl%

:: 项目路径
set projectPath=../

:: 资源根目录
set assetsRootPath=%projectPath%/build/android/data/assets/

:: 保存版本号和manifest的目录
set saveVersionPath=%projectPath%/tools/version/%bundleName%/
set saveManifestPath=%projectPath%/tools/manifest/%bundleName%/

:: 哪些bundle需要放进manifest中
if "%bundleName%"=="hall" (
    if "%minipackage%"=="true" (
        set inBundlePathToManifest=[
            "src",
            "jsb-adapter",
            "assets/internal",
            "assets/resources",
            "assets/main",
        ]
    ) else (
            "src",
            "jsb-adapter",
            "assets/internal",
            "assets/resources",
            "assets/main",
            "assets/common",
            "assets/loading",
            "assets/hall",
            "assets/mahjong",
        )
) else (
    set inBundlePathToManifest=[
      %bundleName%
    ]
)

:: 生成 manifest
:: -v 指定 Manifest 文件的主版本号。
:: -u 指定服务器远程包的地址，这个地址需要和最初发布版本中 Manifest 文件的远程包地址一致，否则无法检测到更新，。
:: -s 本地原生打包版本的目录相对路径, 比如 ./build/android/assets。
:: -d 保存 Manifest 文件的相对路径。
node js/gen_manifest.js -v %version% -u %hotupdateUrl%/%bundleName%/ -s "%assetsRootPath%" -d "%assetsRootPath%" -i "%inBundlePathToManifest%"

if errorlevel 1 (
    echo Error: Failed to generate manifest
    exit /b 1
)
echo generate %bundleName% manifest succeed!

set src=%assetsRootPath%%bundleName%/
:: 压缩资源
if "%bundleName%"=="hall" (
    :: 把 manifest 文件移动到data目录也就是资源根目录的上级目录
    cd %assetsRootPath%
    move *.manifest ..
    :: 进入data目录
    cd ..
    :: 压缩资源
    %rarPath% a -ed version_%version%.zip ^
    :: src 目录引擎相关代码、插件脚本、配置管理脚本 settings.js 等
    "src" ^
    "jsb-adapter" ^

    :: 生成的manifest文件
    "*.manifest" ^

    :: 引擎内部bundle
    "assets/internal" ^
    "assets/resources" ^
    "assets/main" ^

    :: 自定义bundle
    "assets/common" ^
    "assets/loading" ^
    "assets/hall" ^
    "assets/mahjong"
) else (
    :: 子游戏直接压缩
    cd %src%
    %rarPath% a -r version_%version%.zip *
)
if errorlevel 1 (
    echo Error: Compression failed
    exit /b 1
)

:: 创建保存目录
if not exist "%saveVersionPath%" mkdir "%saveVersionPath%"

:: 移动inBundlePathToManifest的资源到保存目录
for %%i in %inBundlePathToManifest% do (
    if exist "%assetsRootPath%%%i" (
        echo move %%i to %saveVersionPath%
        move "%src%%%i" "%saveVersionPath%"
    )
)

:: 

move "version_%version%.zip" "%saveVersionPath%"

:: 移动生成的.manifest文件到保存目录
if not exist "%saveManifestPath%" mkdir "%saveManifestPath%"
move "*.manifest" "%saveManifestPath%"

echo generate %bundleName% version_%version%.zip succeed!