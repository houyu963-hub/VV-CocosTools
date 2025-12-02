#!/bin/bash

(
    cd ../../config
    git clean -fdx client
    cp -r share/xlsx/* client/
)
start=$(date +%s)
./go/build_config/build/build_config \
    --template_path ./go/build_config/template \
    --config_path ../../config/client \
    --output_config ../assets/resources/config_bin \
    --output_ts ../assets/resources/script/tables 
end=$(date +%s)
echo "cost $(($end - $start)) s"
