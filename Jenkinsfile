pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'PLATFORM',
            choices: ['web', 'android'],
            description: '构建平台'
        )

        choice(
            name: 'CHANNEL',
            choices: ['official', 'xiaomi', 'huawei'],
            description: '渠道（web 可选 official）'
        )

        choice(
            name: 'ENV',
            choices: ['dev', 'test', 'prod'],
            description: '环境'
        )

        choice(
            name: 'MODE',
            choices: ['debug', 'release'],
            description: '构建模式（debug / release）'
        )

        string(
            name: 'GIT_REF',
            defaultValue: 'main',
            description: '分支名 / tag / commit hash'
        )

        booleanParam(
            name: 'CLEAN_BUILD',
            defaultValue: true,
            description: '是否清理旧构建产物'
        )
    }

    environment {
        // Cocos Creator 安装路径（按你机器实际改）
        CREATOR_PATH = 'CocosCreator.exe'

        // 项目根目录
        PROJECT_DIR = "${WORKSPACE}"

        // 构建脚本
        BUILD_SCRIPT = 'tools\\build.bat'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: params.GIT_REF]],
                    userRemoteConfigs: [[url: 'https://github.com/houyu963-hub/VV-CocosGameClient.git']]
                ])
            }
        }

        stage('Build') {
            steps {
                bat """
                cd /d %PROJECT_DIR%

                call %BUILD_SCRIPT% ^
                  --platform ${params.PLATFORM} ^
                  --channel ${params.CHANNEL} ^
                  --env ${params.ENV} ^
                  --mode ${params.MODE} ^
                  --creator "${env.CREATOR_PATH}" ^
                  ${params.CLEAN_BUILD ? "--clean" : ""}
                """
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "✅ 构建成功：${params.PLATFORM} / ${params.CHANNEL} / ${params.ENV}"
        }
        failure {
            echo "❌ 构建失败，请查看日志"
        }
    }
}
