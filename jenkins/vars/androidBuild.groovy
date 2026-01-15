// 生成 Android apk
def call(ctx) {
    def (versionName, versionCode) =
        org.cocos.AndroidUtils.resolveVersion(this, ctx.params, ctx.env.WORKSPACE)

    ctx.env.ANDROID_VERSION_NAME = versionName
    ctx.env.ANDROID_VERSION_CODE = versionCode.toString()

    dir('build/android') {
        bat """
        gradlew assemble${ctx.params.CHANNEL.capitalize()}${ctx.params.MODE.capitalize()} \
        -PversionName=${versionName} \
        -PversionCode=${versionCode}
        """
    }
}
