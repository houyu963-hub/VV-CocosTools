pipeline {
    agent any
    // 设置环境变量确保正确编码
    environment {
        // 编码相关环境变量
        LANG = 'zh_CN.UTF-8'
        LC_ALL = 'zh_CN.UTF-8'
        JAVA_TOOL_OPTIONS = '-Dfile.encoding=UTF-8'
        
        // Windows 中文编码
        CHCP_CMD = 'chcp 65001 >nul'  // UTF-8
        CHCP_GBK = 'chcp 936 >nul'    // GBK (Windows中文默认)
        
        // Cocos Creator 安装路径（按你机器实际改）
        CREATOR_PATH = 'D:\\software\\CocosEditors\\Creator\\3.8.1\\CocosCreator.exe'

        // 项目根目录
        PROJECT_DIR = "${WORKSPACE}"

        // 构建脚本
        BUILD_SCRIPT = 'tools\\build.bat'
    }

    
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

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: params.GIT_REF]],
                    userRemoteConfigs: [[url: 'https://github.com/houyu963-hub/VV-CocosGameClient.git']],
                    extensions: [
                       // 启用子模块递归拉取
                       [$class: 'SubmoduleOption',
                        disableSubmodules: false,  // 启用子模块
                        recursiveSubmodules: true, // 递归拉取子模块
                        trackingSubmodules: false, // 不跟踪子模块的上游分支
                        reference: '',             // 不使用参考仓库
                        parentCredentials: true,   // 使用父仓库的凭据
                        depth: 0,                  // 完整克隆
                        shallow: false             // 非浅克隆
                       ],
                       // 清理工作区：先清理，再进行代码拉取
                      [$class: 'CleanBeforeCheckout'], // 在拉取代码之前清理工作区
                      [$class: 'CleanCheckout']        // 拉取代码时清理工作区
                    ]
                ])
            }
        }

       stage('Build') {
            steps {
                bat """
                call ${env.BUILD_SCRIPT} ${params.PLATFORM} ${params.CHANNEL} ${params.ENV} ${params.MODE} ${env.CREATOR_PATH} ${params.CLEAN_BUILD ? "clean" : ""}
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
