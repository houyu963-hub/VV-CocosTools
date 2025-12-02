#!/bin/bash
if [ ! -d "proto" ]; then
    git clone ssh://git@192.168.1.100:222/zhanglifan/proto.git 
fi
cd proto
git pull --rebase
cd ..
echo "generate pb..."
pbjs --keep-case --force-number -t static-module -w commonjs -o pbjs.js \
./proto/client/*.proto \
./proto/share/*.proto && \
pbts -o pbjs.d.ts pbjs.js
echo "succeed!"

echo move to project
mv pbjs.js ../assets/resources/
mv pbjs.d.ts ../assets/resources/