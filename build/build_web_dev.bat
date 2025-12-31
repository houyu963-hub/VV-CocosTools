@echo off
chcp 65001
node js/build_web.js web h5 dev
echo ===== ✔ ✔ ✔  WEB DEV 构建完成  ✔ ✔ ✔ =====
pause
