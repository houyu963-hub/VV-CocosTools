const fs = require("fs");
const path = require("path");

const configPath = process.argv[2];
if (!configPath) {
  console.error("❌ missing config json path");
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

const tsContent = `
// ⚠️ AUTO GENERATED — DO NOT EDIT
export const ChannelConfig = {
  description: "${config.description}",
  env: "${config.env}",
  debug: "${config.debug}",
  platform: "${config.platform}",
  channel: "${config.channel}",
  serverUrl: "${config.serverUrl}",
  public_http_address: "${config.public_http_address}",
};
`;

const target = path.resolve(
  __dirname,
  "../../../assets/frame/config/ChannelConfig.ts"
);

fs.writeFileSync(target, tsContent.trim());
console.log("✅ ChannelConfig.ts updated");
