// 更新JenkinsManifest.json
def call(ctx) {
    def publishRoot = "${ctx.env.WORKSPACE}/../publish"
    def manifestFile = "${publishRoot}/JenkinsManifest.json"

    if (!fileExists(manifestFile)) {
        writeFile file: manifestFile, text: "{}"
    }

    def manifest = readJSON(file: manifestFile)

    def commit = org.cocos.GitUtils.shortCommit(this)
    def time = new Date().format("yyyy-MM-dd HH:mm:ss")

    def artifact = [
        time: time,
        author: ctx.env.BUILD_USER ?: "jenkins",
        commit: commit,
        duration: currentBuild.durationString
    ]

    manifest[ctx.params.PLATFORM] =
        manifest.get(ctx.params.PLATFORM, [:])

    manifest[ctx.params.PLATFORM][ctx.params.CHANNEL] =
        manifest[ctx.params.PLATFORM][ctx.params.CHANNEL] ?: [:]

    manifest[ctx.params.PLATFORM][ctx.params.CHANNEL][ctx.params.ENV] =
        (manifest[ctx.params.PLATFORM][ctx.params.CHANNEL][ctx.params.ENV] ?: [])

    manifest[ctx.params.PLATFORM][ctx.params.CHANNEL][ctx.params.ENV].add(0, artifact)
    manifest[ctx.params.PLATFORM][ctx.params.CHANNEL][ctx.params.ENV] =
        manifest[ctx.params.PLATFORM][ctx.params.CHANNEL][ctx.params.ENV].take(10)

    writeJSON file: manifestFile, json: manifest, pretty: 2
}
