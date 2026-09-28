import fs from 'node:fs';
import path from 'node:path';

const rootDir = process.cwd();
const publicDir = path.resolve(rootDir, 'public');
const MAX_ASSET_SIZE = 24 * 1024 * 1024; // 24 MiB (Cloudflare Workers max is 25 MiB)

// Helper: Check effective file size (handles Git LFS pointer files as well)
function getEffectiveSize(filePath) {
  try {
    const stat = fs.statSync(filePath);
    if (stat.size < 1024) {
      const content = fs.readFileSync(filePath, 'utf8');
      if (content.startsWith('version https://git-lfs.github.com/spec/v1')) {
        const match = content.match(/size\s+(\d+)/);
        if (match) return parseInt(match[1], 10);
      }
    }
    return stat.size;
  } catch {
    return 0;
  }
}

// Reset public directory
if (fs.existsSync(publicDir)) {
  fs.rmSync(publicDir, { recursive: true, force: true });
}
fs.mkdirSync(publicDir, { recursive: true });

const largeFileRedirects = [];

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

let copiedRootCount = 0;
for (const file of rootFiles) {
  const src = path.join(rootDir, file);
  const dest = path.join(publicDir, file);
  const size = getEffectiveSize(src);

  if (size >= MAX_ASSET_SIZE) {
    const sizeMb = (size / (1024 * 1024)).toFixed(2);
    console.log(`⚠️ Skipping root asset >= 25MB: ${file} (${sizeMb} MB) -> Adding 302 redirect`);
    largeFileRedirects.push(`/${file} https://github.com/CokiStudios/cokistudios.github.io/raw/main/${file} 302`);
  } else {
    fs.copyFileSync(src, dest);
    copiedRootCount++;
  }
}

// 2. Recursive copy for directories with large file filtering
function copyFilteredDir(srcDir, destDir, relDir = '') {
  fs.mkdirSync(destDir, { recursive: true });
  const entries = fs.readdirSync(srcDir, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(srcDir, entry.name);
    const destPath = path.join(destDir, entry.name);
    const relPath = path.posix.join(relDir, entry.name);

    if (entry.isDirectory()) {
      copyFilteredDir(srcPath, destPath, relPath);
    } else if (entry.isFile()) {
      const size = getEffectiveSize(srcPath);
      if (size >= MAX_ASSET_SIZE) {
        const sizeMb = (size / (1024 * 1024)).toFixed(2);
        console.log(`⚠️ Skipping directory asset >= 25MB: ${relPath} (${sizeMb} MB) -> Adding 302 redirect`);
        largeFileRedirects.push(`/${relPath} https://github.com/CokiStudios/cokistudios.github.io/raw/main/${relPath} 302`);
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    }
  }
}

const webDirs = ['assets', 'apt', 'debian'];
for (const dir of webDirs) {
  const src = path.join(rootDir, dir);
  const dest = path.join(publicDir, dir);
  if (fs.existsSync(src)) {
    copyFilteredDir(src, dest, dir);
  }
}

// 3. Write _redirects if any large files need fallback routing
if (largeFileRedirects.length > 0) {
  const redirectsPath = path.join(publicDir, '_redirects');
  let existingContent = '';
  if (fs.existsSync(redirectsPath)) {
    existingContent = fs.readFileSync(redirectsPath, 'utf8') + '\n';
  } else if (fs.existsSync(path.join(rootDir, '_redirects'))) {
    existingContent = fs.readFileSync(path.join(rootDir, '_redirects'), 'utf8') + '\n';
  }
  fs.writeFileSync(redirectsPath, existingContent + largeFileRedirects.join('\n') + '\n');
  console.log(`🔀 Configured ${largeFileRedirects.length} fallback redirect(s) in 'public/_redirects'.`);
}

console.log(`✅ Web assets prepared successfully in 'public/' (${copiedRootCount} root files + asset dirs, 0 files > 24MB).`);
