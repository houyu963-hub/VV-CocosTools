@echo off
chcp 65001
node js/build_android.js android website test
echo ===== ✔ ✔ ✔  ANDROID WEBSITE TEST 构建完成  ✔ ✔ ✔ =====
pause
