const { execSync } = require("child_process");

const platform = process.argv[2];
const channel = process.argv[3];
const env = process.argv[4];

if (!platform || !channel || !env) {
    console.error("❌ usage: node build_android.js");
    process.exit(1);
}

const configJson = `../../build-config/${platform}/${channel}/config_${env}.json`;

console.log("▶ Using config:", configJson);

// 1️⃣ 应用配置
execSync(`node js/apply_channel_config.js ${configJson}`, { stdio: "inherit" });
// execSync(`node js/apply_hotupdate_config.js ${configJson}`, { stdio: "inherit" });

// 2️⃣ Cocos 构建
execSync(
    `CocosCreator.exe --project ../../ --build "platform=android;configPath=../../build-config/${platform}/buildConfig_android.json"`,
    { stdio: "inherit" }
);

// 3️⃣ Gradle 渠道打包（示例）
// execSync(
//     `cd build/android/proj && gradlew assemble${channel.charAt(0).toUpperCase() + channel.slice(1)}Release`,
//     { stdio: "inherit" }
// );

console.log("✅ Android build done:", channel, env);
