// copy 产物到发布目录
def call(ctx) {
    def timeDir = new Date().format("yyyyMMdd_HHmmss")
    def root = "${ctx.env.WORKSPACE}/publish/${ctx.params.PLATFORM}/${ctx.params.CHANNEL}/${ctx.params.ENV}"
    def target = "${root}/${timeDir}"

    bat "mkdir \"${target}\" 2>nul"

    if (ctx.params.PLATFORM == 'android') {
        def apk = "Game_${ctx.params.CHANNEL}_${ctx.params.ENV}_v${ctx.env.ANDROID_VERSION_CODE}.apk"
        bat "copy build\\android\\**\\${apk} \"${target}\\${apk}\""
    }

    if (ctx.params.PLATFORM == 'web') {
        bat "xcopy /E /I /Y build\\web-mobile \"${target}\""
    }

    // 清理旧目录 只保留 最近10 个
    org.cocos.FileUtils.cleanupOldDirs(this, root, 10)
}
