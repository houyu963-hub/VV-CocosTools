var fs = require('fs');
var path = require('path');
var crypto = require('crypto');

var manifest = {
    packageUrl: '',
    remoteManifestUrl: '',
    remoteVersionUrl: '',
    version: '',
    assets: {},
    searchPaths: []
};

var dest = './remote-assets/';
var src = './jsb/';
var name = '';

// Parse arguments
var i = 2;
while (i < process.argv.length) {
    var arg = process.argv[i];

    switch (arg) {
        case '--url':
        case '-u':
            var url = process.argv[i + 1];
            manifest.packageUrl = url;
            manifest.remoteManifestUrl = url + 'project.manifest';
            manifest.remoteVersionUrl = url + 'version.manifest';
            i += 2;
            break;
        case '--version':
        case '-v':
            manifest.version = process.argv[i + 1];
            i += 2;
            break;
        case '--src':
        case '-s':
            src = process.argv[i + 1];
            i += 2;
            break;
        case '--dest':
        case '-d':
            dest = process.argv[i + 1];
            i += 2;
            break;
        case '-name':
        case '-n':
            name = process.argv[i + 1];
            i += 2;
            break;
        default:
            i++;
            break;
    }
}


function readDir(dir, obj) {
    try {
        var stat = fs.statSync(dir);
        if (!stat.isDirectory()) {
            return;
        }
        var subpaths = fs.readdirSync(dir), subpath, size, md5, compressed, relative;
        for (var i = 0; i < subpaths.length; ++i) {
            if (subpaths[i][0] === '.') {
                continue;
            }
            subpath = path.join(dir, subpaths[i]);
            stat = fs.statSync(subpath);
            if (stat.isDirectory()) {
                readDir(subpath, obj);
            }
            else if (stat.isFile()) {
                // Size in Bytes
                size = stat['size'];
                md5 = crypto.createHash('md5').update(fs.readFileSync(subpath)).digest('hex');
                compressed = path.extname(subpath).toLowerCase() === '.zip';
                relative = path.relative(path.join(src, '../'), subpath);
                relative = relative.replace(/\\/g, '/');
                relative = encodeURI(relative);
                obj[relative] = {
                    'size': size,
                    'md5': md5
                };
                if (compressed) {
                    obj[relative].compressed = true;
                }
            }
        }
    } catch (err) {
        console.error(err)
    }
}

var mkdirSync = function (path) {
    try {
        fs.mkdirSync(path);
    } catch (e) {
        if (e.code != 'EEXIST') throw e;
    }
}

// Iterate assets and src folder
console.log('脚本执行name:' + name);
var dataDir = path.join(dest, "..")
if (name === 'hall') {
    console.log('脚本执行大厅');

    readDir(path.join(dataDir, 'src'), manifest.assets);
    readDir(path.join(dataDir, 'jsb-adapter'), manifest.assets);

    /** 在执行底包 manifest 生成时 !!只需要!! 放入 cocos 内置 bundle*/

    // cocos内置bundle
    readDir(path.join(dataDir, 'assets/internal'), manifest.assets);
    readDir(path.join(dataDir, 'assets/resources'), manifest.assets);
    readDir(path.join(dataDir, 'assets/main'), manifest.assets);

    /** 在执行底包 manifest 生成时 --不需要-- 放入 自定义 bundle*/
    /** 在执行底包 manifest 生成时 --请注释-- 下面代码 */

    // 自定义bundle
    readDir(path.join(dataDir, 'assets/common'), manifest.assets);
    readDir(path.join(dataDir, 'assets/loading'), manifest.assets);
    readDir(path.join(dataDir, 'assets/hall'), manifest.assets);
    readDir(path.join(dataDir, 'assets/mahjong'), manifest.assets);
} else {
    console.log('脚本执行 子游戏');
    readDir(path.join(dataDir, 'assets/' + name), manifest.assets);
}

var destManifest = path.join(dest, 'project.manifest');
var destVersion = path.join(dest, 'version.manifest');

mkdirSync(dest);

fs.writeFile(destManifest, JSON.stringify(manifest), (err) => {
    if (err) throw err;
    console.log('Manifest successfully generated');
});

delete manifest.assets;
delete manifest.searchPaths;
fs.writeFile(destVersion, JSON.stringify(manifest), (err) => {
    if (err) throw err;
    console.log('Version successfully generated');
});
