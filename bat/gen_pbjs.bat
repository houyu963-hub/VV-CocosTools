@echo off

REM your proto dir
set proto_dir=../../proto/Enum.proto

if not exist "%proto_dir%" (
  echo ❌ Error: proto_dir not found
  pause
  exit /b 1
)

echo generate pb...
pbjs --keep-case --force-number -t static-module -w commonjs -o pbjs.js ^
proto_dir*.proto && ^
pbts -o pbjs.d.ts pbjs.js
if errorlevel 1 (
  echo ❌ Error: Failed to generate pbjs.d.ts
  pause
  exit /b 1
)

echo move to project
move /y pbjs.js ../assets/resources/
move /y pbjs.d.ts ../assets/resources/

if errorlevel 1 (
  echo ❌ Error: Failed to move pbjs.js pbjs.d.ts
  pause
  exit /b 1
)

echo succeed!
pause