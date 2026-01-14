def resolveAndroidVersion(params, workspace) {
    def manifestFile = "${workspace}/tools/JenkinsManifest.json"

    def lastVersionName = "1.0.0"
    def lastVersionCode = 10000

    if (fileExists(manifestFile)) {
        def m = readJSON file: manifestFile
        def list = m?.android?."${params.CHANNEL}"?."${params.ENV}"
        if (list && list.size() > 0) {
            lastVersionName = list[0].versionName
            lastVersionCode = list[0].versionCode as int
        }
    }

    def versionName = params.VERSION_NAME?.trim()
        ? params.VERSION_NAME
        : lastVersionName

    def versionCode = params.VERSION_CODE?.trim()
        ? params.VERSION_CODE.toInteger()
        : lastVersionCode

    return [versionName, versionCode]
}

def resolveApkSize(String apkPath) {
    if (!fileExists(apkPath)) {
        error "APK not found: ${apkPath}"
    }

    def file = new File(apkPath)
    long bytes = file.length()

    return [
        bytes : bytes,
        mb    : String.format("%.2f", bytes / 1024.0 / 1024.0)
    ]
}

def cleanupOldArtifacts(String baseDir, int keepCount) {
    if (!fileExists(baseDir)) {
        return
    }

    def dirs = bat(
        script: """
        powershell -NoProfile -Command ^
        "Get-ChildItem '${baseDir}' -Directory |
         Sort-Object Name -Descending |
         Select-Object -Skip ${keepCount} |
         ForEach-Object { Remove-Item $_.FullName -Recurse -Force }"
        """,
        returnStdout: true
    )

    echo "🧹 清理 ${baseDir} 下多余历史产物（保留 ${keepCount} 个）"
}

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
        
        // Cocos Creator 安装路径(按你机器实际改)
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
            description: '渠道'
        )

        choice(
            name: 'ENV',
            choices: ['dev', 'test', 'prod'],
            description: '环境'
        )

        choice(
            name: 'BUILD_TYPE',
            choices: ['hotupdate', 'generateApk'],
            description: '构建类型(生热更新文件 / 生成apk)'
        )

        string(
            name: 'VERSION_NAME',
            defaultValue: '',
            description: 'Android 版本名称(如 1.3.2,留空自动使用上次)'
        )

        string(
            name: 'VERSION_CODE',
            defaultValue: '',
            description: 'Android 版本号(如 10302,留空自动使用上次)'
        )

        choice(
            name: 'MODE',
            choices: ['release', 'debug'],
            description: '构建模式(debug / release)'
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

         booleanParam(
            name: 'MINI_APK',
            defaultValue: true,
            description: '小包体'
        )
    }

    stages {
        stage('参数验证') {
            steps {
                script {
                    if (params.PLATFORM == 'web') {
                        if (params.CHANNEL != 'official') {
                            error "Web平台只支持official渠道"
                        }
                    }
                }
            }
        }

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
                       // 清理工作区：先清理,再进行代码拉取
                      [$class: 'CleanBeforeCheckout'], // 在拉取代码之前清理工作区
                      [$class: 'CleanCheckout']        // 拉取代码时清理工作区
                    ]
                ])
            }
        }

        stage('构建') {
            steps {
                bat """
                call ${env.BUILD_SCRIPT} ${params.PLATFORM} ${params.CHANNEL} ${params.ENV} ${params.MODE} ${env.CREATOR_PATH} ${params.CLEAN_BUILD ? "true" : "false"} ${params.MINI_APK ? "true" : "false"} ${params.BUILD_TYPE}
                """
            }
        }

        stage('生成apk') {
            when {
                expression { params.PLATFORM == 'android' }
            }
            steps {
                dir('build/android') {
                    script {
                        def (versionName, versionCode) = resolveAndroidVersion(params, env.WORKSPACE)

                        env.ANDROID_VERSION_NAME = versionName
                        env.ANDROID_VERSION_CODE = versionCode.toString()

                        echo "Android Version → name=${versionName}, code=${versionCode}"

                        bat """
                        gradlew assemble${params.CHANNEL.capitalize()}${params.MODE.capitalize()} -PversionName=${versionName} -PversionCode=${versionCode}
                        """
                    }
                }
            }
        }

       stage('存档') {
            steps {
                script {
                    def platform = params.PLATFORM
                    def channel  = params.CHANNEL
                    def envName  = params.ENV
                    def mode  = params.MODE
                    //========== jenkins 归档 ==========
                    if (platform == 'android') {
                        archiveArtifacts artifacts: "build/android/proj/build/*/*/outputs/apk/${channel}/${envName}/**/*.apk", fingerprint: true
                    } else if (platform == 'web-mobile') {
                        archiveArtifacts artifacts: 'build/web/**/*', fingerprint: true
                    } else if (platform == 'ios') {
                        archiveArtifacts artifacts: 'build/ios/**/*', fingerprint: true
                    }
                    //========== 保存到发布目录 ==========
                    // 时间戳目录
                    def timeDir = new Date().format("yyyyMMdd_HHmmss")
                    def publishRoot = "${env.WORKSPACE}/publish/${platform}/${channel}/${envName}"
                    def targetDir   = "${publishRoot}/${timeDir}"
                    bat """
                    mkdir "${targetDir}" 2>nul
                    """
                    if (platform == 'android') {
                        def apkName = "Game_${channel}_${envName}_v${env.ANDROID_VERSION_CODE}.apk"
                        def apkSrc  = "build/android/proj/build/*/*/outputs/apk/${channel}/${mode}/${apkName}"
                        bat """
                        copy /Y "${apkSrc}" "${targetDir}\\${apkName}"
                        """
                    }
                    if (platform == 'web') {
                        bat """
                        xcopy /E /I /Y "build/web-mobile" "${targetDir}"
                        """
                    }
                    echo "✅ 构建产物已保存到 ${targetDir}"
                    // ===== 只保留最近 10 个 =====
                    cleanupOldArtifacts(publishRoot, 10)
                }
            }
        }

        stage('更新下载列表') {
            steps {
                script {
                    def manifestFile = "${env.WORKSPACE}/tools/JenkinsManifest.json"

                    def platform = params.PLATFORM.toString()
                    def channel  = params.CHANNEL.toString()
                    def envName  = params.ENV.toString()

                    def commit = bat(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim().split('\r\n')[-1]

                    def time = new Date().format("yyyy-MM-dd HH:mm:ss")
                    def author = env.BUILD_USER?.toString() ?: "jenkins"
                    def duration = currentBuild.durationString.replace(" and counting", "").toString()

                    // ===== hotupdate version =====
                    def hotupdateVersion = ""
                    def versionManifestPath = "${env.WORKSPACE}/assets/resources/manifest/hall/version.manifest"

                    if (fileExists(versionManifestPath)) {
                        def versionManifest = readJSON file: versionManifestPath
                        hotupdateVersion = versionManifest?.version?.toString() ?: "x.x.x.x"
                    }

                    def PUBLISH_ROOT = "publish"
                    def apkRelativePath = "${PUBLISH_ROOT}/android/${channel}/${envName}/${apkName}"
                    def webRelativePath = "${PUBLISH_ROOT}/web/${channel}/${envName}/index.html"

                    def artifact = [:]

                    if (platform == 'android') {
                        def apkName = "Game_${channel}_${envName}_v${env.ANDROID_VERSION_CODE}.apk"
                        def apkPath = "${env.WORKSPACE}/build/android/${channel}/${envName}/${apkName}"

                        def sizeInfo = resolveApkSize(apkPath)
                        def APK_SIZE_MB = sizeInfo.mb

                        artifact = [
                            versionCode      : env.ANDROID_VERSION_CODE as int,
                            versionName      : env.ANDROID_VERSION_NAME.toString(),
                            time             : time,
                            author           : author,
                            apk              : apkRelativePath,
                            apkSize          : (APK_SIZE_MB + "MB"),
                            hotupdateVersion : hotupdateVersion,
                            commit           : commit,
                            duration         : duration
                        ]
                    }

                    if (platform == 'web') {
                        artifact = [
                            time     : time,
                            author   : author,
                            url      : webRelativePath,
                            commit   : commit,
                            duration : duration
                        ]
                    }

                    // 如果 manifest.json 不存在,初始化
                    if (!fileExists(manifestFile)) {
                        writeFile file: manifestFile, text: "{}"
                    }

                    def manifest = readJSON file: manifestFile

                    // 逐层确保存在
                    manifest[platform] = manifest.get(platform, [:])
                    manifest[platform][channel] = manifest[platform][channel] ?: [:]
                    manifest[platform][channel][envName] = manifest[platform][channel][envName] ?: []

                    // 插到最前面(最新的在前)
                    manifest[platform][channel][envName].add(0, artifact)

                    // 只保留最近 10 个
                    manifest[platform][channel][envName] =
                        manifest[platform][channel][envName].take(10)

                    writeJSON file: manifestFile, json: manifest, pretty: 2

                    echo "✅ JenkinsManifest.json 更新完成"
                }
            }
        }

    }

    post {
        success {
            echo "✅ 构建成功：${params.PLATFORM} / ${params.CHANNEL} / ${params.ENV} / ${params.MODE} / ${params.ENV}"
        }
        failure {
            echo "❌ 构建失败,请查看日志"
        }
    }
}
