const { execSync } = require("child_process");
const path = require("path");

const platform = process.argv[2];
const channel = process.argv[3];
const env = process.argv[4];

if (!platform || !channel || !env) {
    console.error("❌ usage: node build_web.js");
    process.exit(1);
}

// 获取项目根目录
const projectRoot = path.join(__dirname, '..', '..', '..').replace(/\\/g, '/');
const configJson = `${projectRoot}/build-config/${platform}/${channel}/config_${env}.json`;

console.log("▶ Using config:", configJson);

// 1️⃣ 应用配置
execSync(`node js/apply_channel_config.js ${configJson}`, { stdio: "inherit" });

// 2️⃣ Cocos 构建
try {
    execSync(
        `CocosCreator.exe --project ${projectRoot} --build "platform=web-mobile;configPath=${projectRoot}/build-config/web/buildConfig_web-mobile.json"`,
        { stdio: "inherit" }
    );
} catch (error) {
    // 如果是退出码 36，表示构建成功，不算真正的错误
    if (error.status === 36) {
        console.log("✅ Cocos build done:", platform, channel, env);
    } else {
        console.error("❌ Cocos build failed:", error.message);
        console.error("Exit code:", error.status);
        if (error.stdout) console.log("Stdout:", error.stdout.toString());
        if (error.stderr) console.error("Stderr:", error.stderr.toString());
        process.exit(error.status);
    }
}

