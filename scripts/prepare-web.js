import fs from 'node:fs';
import path from 'node:path';

const rootDir = process.cwd();
const publicDir = path.resolve(rootDir, 'public');

// Reset public directory
if (fs.existsSync(publicDir)) {
  fs.rmSync(publicDir, { recursive: true, force: true });
}
fs.mkdirSync(publicDir, { recursive: true });

// 1. Copy web-facing root files
const rootFiles = fs.readdirSync(rootDir).filter(file => {
  if (file === 'package.json' || file === 'package-lock.json') return false;
  return (
    file.endsWith('.html') ||
    file.endsWith('.js') ||
    file.endsWith('.json') ||
    file.endsWith('.apk') ||
    file === 'CNAME' ||
    file === 'robots.txt' ||
    file === '_headers' ||
    file === '_redirects'
  );
});

for (const file of rootFiles) {
  fs.copyFileSync(path.join(rootDir, file), path.join(publicDir, file));
}

// 2. Copy directories needed for web serving
const webDirs = ['assets', 'apt', 'debian'];
for (const dir of webDirs) {
  const src = path.join(rootDir, dir);
  const dest = path.join(publicDir, dir);
  if (fs.existsSync(src)) {
    fs.cpSync(src, dest, { recursive: true });
  }
}

console.log(`✅ Web assets prepared successfully in 'public/' (${rootFiles.length} root files + asset dirs).`);
