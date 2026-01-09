pipeline {
    agent  {
        label 'cocos-windows-agent'  // 指定需要 GUI 支持的 Windows 节点
    }
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
            choices: ['web', 'android', 'ios'],
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
        stage('拉代码') {
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

        stage('构建') {
            steps {
                bat """
                call ${env.BUILD_SCRIPT} ${params.PLATFORM} ${params.CHANNEL} ${params.ENV} ${params.MODE} ${env.CREATOR_PATH} ${params.CLEAN_BUILD ? "clean" : ""}
                """
            }
        }

        stage('生成apk') {
            when {
                expression { params.PLATFORM == 'android' }
            }
            steps {
                dir('build/android') {
                    bat """
                    gradlew assemble${params.CHANNEL.capitalize()}${params.MODE.capitalize()}
                    """
                }
            }
        }

        stage('归档') {
            steps {
                archiveArtifacts artifacts: 'build/**', fingerprint: true
            }
        }

        stage('更新下载列表') {
            steps {
                script {
                    def manifestFile = "${env.WORKSPACE}/tools/JenkinsManifest.json"

                    def platform = params.PLATFORM
                    def channel  = params.CHANNEL
                    def envName  = params.ENV

                    def version  = env.BUILD_VERSION ?: "unknown"
                    def commit   = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def author   = env.BUILD_USER ?: "jenkins"
                    def time     = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                    def duration = currentBuild.durationString.replace(" and counting", "")

                    // Android / Web 差异
                    def artifact = [:]
                    if (platform == 'android') {
                        artifact = [
                            version: version,
                            time: time,
                            author: author,
                            apk: "android/${channel}/${envName}/app.apk",
                            apkSize: "unknown",
                            androidVersion: version,
                            hotupdateVersion: "unknown",
                            commit: commit,
                            duration: duration
                        ]
                    } else if (platform == 'web') {
                        artifact = [
                            version: version,
                            time: time,
                            author: author,
                            url: "web/${envName}/index.html",
                            commit: commit,
                            duration: duration
                        ]
                    }

                    // 如果 manifest.json 不存在，初始化
                    if (!fileExists(manifestFile)) {
                        writeFile file: manifestFile, text: "{}"
                    }

                    def manifest = readJSON file: manifestFile

                    // 逐层确保存在
                    manifest[platform] = manifest.get(platform, [:])
                    manifest[platform][channel] = manifest[platform][channel] ?: [:]
                    manifest[platform][channel][envName] = manifest[platform][channel][envName] ?: []

                    // 插到最前面（最新的在前）
                    manifest[platform][channel][envName].add(0, artifact)

                    // 只保留最近 10 个
                    manifest[platform][channel][envName] =
                        manifest[platform][channel][envName].take(10)

                    writeJSON file: manifestFile, json: manifest, pretty: 2

                    echo "✅ JenkinsManifest.json updated"
                }
            }
        }
    }

    post {
        success {
            echo "✅ 构建成功：${params.PLATFORM} / ${params.CHANNEL} / ${params.ENV} / ${params.MODE} / ${params.ENV}"
        }
        failure {
            echo "❌ 构建失败，请查看日志"
        }
    }
}
