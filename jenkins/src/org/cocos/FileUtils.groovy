package org.cocos

// 文件 工具类
class FileUtils implements Serializable {

    // 清理旧目录 保留最新的 keep 个目录
    static void cleanupOldDirs(script, String baseDir, int keep) {
        if (!script.fileExists(baseDir)) return

        script.bat(
            script:
                'powershell -NoProfile -Command "& {' +
                '  Get-ChildItem \'' + baseDir + '\' -Directory | ' +
                '  Sort-Object Name -Descending | ' +
                '  Select-Object -Skip ' + keep + ' | ' +
                '  ForEach-Object { Remove-Item $_.FullName -Recurse -Force }' +
                '}"'
        )
    }
}
