const XLSX = require('xlsx');
const fs = require('fs');

const path = require('path');
const excelDir = path.join(__dirname, 'excel');
const files = fs.readdirSync(excelDir).filter(f => f.endsWith('.xlsx'));
const generate = require('./generateTableTs')

files.forEach(file => {
    const filePath = path.join(excelDir, file);
    const workbook = XLSX.readFile(filePath);
    const worksheet = workbook.Sheets[workbook.SheetNames[0]];
    const jsonData = XLSX.utils.sheet_to_json(worksheet);
    let obj = {};
    jsonData.forEach(item => obj[item.ID] = item);
    const jsonName = file.replace(/\.xlsx$/i, '.json');
    fs.writeFileSync(jsonName, JSON.stringify(obj, null, 2));

    generate(jsonName, jsonData)
    console.log(`${file} -> ${jsonName} completed!`);
});
