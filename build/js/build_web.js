const { execSync } = require("child_process");

const platform = process.argv[2];
const channel = process.argv[3];
const env = process.argv[4];

if (!platform || !channel || !env) {
    console.error("❌ usage: node build_web.js");
    process.exit(1);
}

const configJson = `${__dirname}build-config/${platform}/${channel}/config_${env}.json`;

console.log("▶ Using config:", configJson);

// 1️⃣ 应用配置
execSync(`node js/apply_channel_config.js ${configJson}`, { stdio: "inherit" });

// 2️⃣ Cocos 构建
execSync(
    `CocosCreator.exe --project ${__dirname} --build "platform=web-mobile;configPath=../../build-config/web/buildConfig_web-mobile.json"`,
    { stdio: "inherit" }
);

console.log("✅ web build done:", channel, env);
