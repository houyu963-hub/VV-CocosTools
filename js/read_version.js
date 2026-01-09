// tools/js/read_version.js
const fs = require('fs');

const file = process.argv[2];
const json = JSON.parse(fs.readFileSync(file, 'utf8'));

console.log(json.version || json.versionName || '0.0.0');
