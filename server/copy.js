const fs = require('fs');
const path = require('path');

/**
 * 复制文件
 * @param {string} src 源文件路径
 * @param {string} dest 目标文件路径
 */
function copyFileSync(src, dest) {
  fs.copyFileSync(src, dest);
  console.log(`复制文件: ${src} 到 ${dest}`);
}

/**
 * 递归创建目录
 * @param {string} dirPath 目录路径
 */
function createDirSync(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`创建目录: ${dirPath}`);
  }
}

/**
 * 递归复制目录
 * @param {string} src 源目录路径
 * @param {string} dest 目标目录路径
 */
function copyDirRecursiveSync(src, dest) {
  createDirSync(dest);
  const entries = fs.readdirSync(src, { withFileTypes: true });

  entries.forEach(entry => {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDirRecursiveSync(srcPath, destPath);
    } else if (entry.isFile()) {
      copyFileSync(srcPath, destPath);
    }
  });
}

// 示例用法
const sourceDir = path.join(__dirname, 'web');
const destinationDir = path.join(__dirname, 'dist/web');

copyDirRecursiveSync(sourceDir, destinationDir);
copyDirRecursiveSync(path.join(__dirname, 'swagger'), path.join(__dirname, 'dist/web/swagger'))
console.log('目录复制完成！');
