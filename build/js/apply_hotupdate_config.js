const fs = require("fs");
const path = require("path");

const configPath = process.argv[2];
if (!configPath) {
    console.error("❌ missing config json path");
    process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

const output = {
    channel: config.channel,
    env: config.env,
    hotupdateUrl: config.hotupdateUrl,
    time: new Date().toISOString(),
};

const outPath = path.resolve(__dirname, "../hotupdate/config.json");
fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
console.log("✅ hotupdate config generated");
