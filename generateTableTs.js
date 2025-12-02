const XLSX = require('xlsx');
const fs = require('fs');

function generate(filename, datas) {
    if (datas.length > 0) {
        filename = filename.replace('.json', '')
        let data = datas[0]
        let tableName = filename
        tableName = tableName.split('_').map(v => v.charAt(0).toUpperCase() + v.slice(1)).join('')
        _generate(filename, tableName, Object.keys(data), Object.values(data))
    }
}

function _generate(tableFileName, tableName, fields, values) {
    let fieldArr = []
    fields.forEach((field, index) => {
        let type = 'string'
        if (null != values[index] && typeof values[index] == 'number') {
            type = 'number'
        }
        fieldArr.push(`\tpublic ${field}: ${type}`);
    })
    let code = `import TableBase from "../core/TableBase"

export default class Table${tableName} extends TableBase {
${fieldArr.join('\n')}

    public static TableName: string = "${tableFileName}"
}`
    console.log(code)
    fs.writeFileSync(`../assets/hall/script/tables/model/Table${tableName}.ts`, code)
}

module.exports = generate