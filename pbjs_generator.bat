@echo off
echo generate pb...
pbjs --keep-case --force-number -t static-module -w commonjs -o pbjs.js ^
./proto/client/*.proto ^
./proto/share/*.proto && ^
pbts -o pbjs.d.ts pbjs.js
echo succeed!
pause