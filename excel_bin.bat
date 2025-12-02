@echo off
.\tool\build_config\build_config.exe ^
    --platform cocosCreator ^
    --config_path ..\..\config\client^
    --output_config ..\assets\resources\config_bin ^
    --output_code ..\assets\resources\script\tables
@pause