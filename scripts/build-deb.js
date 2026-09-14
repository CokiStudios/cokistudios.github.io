#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════
// 📦 DEBIAN / APT PACKAGER FOR LOOPING & RUUPING
// Generates official .deb packages and APT repository metadata
// Developed by Holo Entertainment & Coki Studios
// ═══════════════════════════════════════════════════════════════

import fs from 'fs';
import path from 'path';
import zlib from 'zlib';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');

const PKG_NAME = 'looping';
const PKG_VERSION = '2.1.0';
const PKG_REVISION = '1';
const FULL_VERSION = `${PKG_VERSION}-${PKG_REVISION}`;
const MAINTAINER = 'Coki Studios <support@cokistudios.com>';
const HOMEPAGE = 'https://cokistudios.com';

// ── USTAR Tar Builder ──
class TarBuilder {
    constructor() {
        this.buffers = [];
    }

    addEntry(entryPath, contentBuffer, options = {}) {
        const isDir = options.isDir || false;
        const isSymlink = options.isSymlink || false;
        const mode = options.mode || (isDir ? 0o755 : 0o644);
        const mtime = Math.floor((options.mtime || Date.now()) / 1000);
        const linkname = options.linkname || '';

        // Normalize path (must start with ./ or name)
        let normalizedPath = entryPath.replace(/\\/g, '/');
        if (!normalizedPath.startsWith('./')) {
            normalizedPath = './' + normalizedPath;
        }
        if (isDir && !normalizedPath.endsWith('/')) {
            normalizedPath += '/';
        }

        const header = Buffer.alloc(512, 0);

        // Name (100)
        header.write(normalizedPath.slice(0, 100), 0, 100, 'utf8');
        // Mode (8)
        header.write(mode.toString(8).padStart(6, '0') + ' \0', 100, 8, 'ascii');
        // UID (8)
        header.write('0000000\0', 108, 8, 'ascii');
        // GID (8)
        header.write('0000000\0', 116, 8, 'ascii');
        // Size (12)
        const size = isDir || isSymlink ? 0 : contentBuffer.length;
        header.write(size.toString(8).padStart(11, '0') + ' ', 124, 12, 'ascii');
        // Mtime (12)
        header.write(mtime.toString(8).padStart(11, '0') + ' ', 136, 12, 'ascii');
        // Checksum placeholder (8 spaces)
        header.fill(32, 148, 156);
        // Typeflag (1)
        let typeflag = '0';
        if (isDir) typeflag = '5';
        else if (isSymlink) typeflag = '2';
        header.write(typeflag, 156, 1, 'ascii');
        // Linkname (100)
        if (linkname) {
            header.write(linkname.slice(0, 100), 157, 100, 'utf8');
        }
        // Magic (6) + Version (2)
        header.write('ustar\0', 257, 6, 'ascii');
        header.write('00', 263, 2, 'ascii');
        // Uname (32) + Gname (32)
        header.write('root', 265, 4, 'ascii');
        header.write('root', 297, 4, 'ascii');

        // Calculate Checksum
        let chksum = 0;
        for (let i = 0; i < 512; i++) {
            chksum += header[i];
        }
        header.write(chksum.toString(8).padStart(6, '0') + '\0 ', 148, 8, 'ascii');

        this.buffers.push(header);

        if (!isDir && !isSymlink && contentBuffer && contentBuffer.length > 0) {
            this.buffers.push(contentBuffer);
            const padding = (512 - (contentBuffer.length % 512)) % 512;
            if (padding > 0) {
                this.buffers.push(Buffer.alloc(padding, 0));
            }
        }
    }

    toGzipBuffer() {
        // End of archive marker (1024 zero bytes)
        this.buffers.push(Buffer.alloc(1024, 0));
        const combined = Buffer.concat(this.buffers);
        return zlib.gzipSync(combined, { level: 9 });
    }
}

// ── Debian Ar Archive Builder ──
function createDebArchive(controlGz, dataGz) {
    const debianBinary = Buffer.from('2.0\n', 'utf8');
    const parts = [
        Buffer.from('!<arch>\n', 'ascii')
    ];

    function addArMember(name, buf) {
        const header = Buffer.alloc(60, 32); // Space filled
        // Name (16)
        header.write(name.padEnd(16, ' '), 0, 16, 'ascii');
        // Timestamp (12)
        const ts = Math.floor(Date.now() / 1000).toString().padEnd(12, ' ');
        header.write(ts, 16, 12, 'ascii');
        // UID (6), GID (6)
        header.write('0     ', 28, 6, 'ascii');
        header.write('0     ', 34, 6, 'ascii');
        // Mode (8)
        header.write('100644  ', 40, 8, 'ascii');
        // Size (10)
        header.write(buf.length.toString().padEnd(10, ' '), 48, 10, 'ascii');
        // End marker (2)
        header.write('`\n', 58, 2, 'ascii');

        parts.push(header);
        parts.push(buf);
        if (buf.length % 2 !== 0) {
            parts.push(Buffer.from('\n', 'ascii'));
        }
    }

    addArMember('debian-binary', debianBinary);
    addArMember('control.tar.gz', controlGz);
    addArMember('data.tar.gz', dataGz);

    return Buffer.concat(parts);
}

// ── Recursive Directory Collector ──
function collectFiles(baseDir, currentRel = '') {
    const results = [];
    const fullCurrent = path.join(baseDir, currentRel);
    if (!fs.existsSync(fullCurrent)) return results;

    const entries = fs.readdirSync(fullCurrent, { withFileTypes: true });
    for (const ent of entries) {
        const rel = currentRel ? path.join(currentRel, ent.name) : ent.name;
        if (ent.isDirectory()) {
            results.push({ relPath: rel, isDir: true });
            results.push(...collectFiles(baseDir, rel));
        } else if (ent.isFile()) {
            results.push({ relPath: rel, isDir: false, fullPath: path.join(baseDir, rel) });
        }
    }
    return results;
}

// ── Build Package ──
export function buildDeb(architecture = 'all') {
    console.log(`\n📦 [DEB BUILDER] Assembling ${PKG_NAME}_${FULL_VERSION}_${architecture}.deb ...`);

    // 1. Prepare Data Tar
    const dataTar = new TarBuilder();
    const md5sums = [];

    // Base directories
    const baseDirs = [
        'usr',
        'usr/bin',
        'usr/lib',
        'usr/lib/looping',
        'usr/lib/looping/bin',
        'usr/share',
        'usr/share/applications',
        'usr/share/man',
        'usr/share/man/man1',
        'usr/share/doc',
        'usr/share/doc/looping',
        'etc',
        'etc/looping'
    ];

    for (const d of baseDirs) {
        dataTar.addEntry(d, Buffer.alloc(0), { isDir: true, mode: 0o755 });
    }

    // Runner script for /usr/bin/looping
    const runnerScript = `#!/usr/bin/env bash
# Official Looping Launcher for Holo Looping OoS / Linux
export LOOPING_HOME="/usr/lib/looping"
if command -v node >/dev/null 2>&1; then
    exec node /usr/lib/looping/bin/looping "$@"
else
    echo "Error: Node.js (>= 18.0.0) is required to run Looping." >&2
    exit 1
fi
`;
    dataTar.addEntry('usr/bin/looping', Buffer.from(runnerScript, 'utf8'), { mode: 0o755 });

    // Include workspace source files into /usr/lib/looping
    const copyDirs = [
        { dir: 'bin', dest: 'usr/lib/looping/bin' },
        { dir: 'LoopingEngine', dest: 'usr/lib/looping/LoopingEngine' },
        { dir: 'holo-looping-oos', dest: 'usr/lib/looping/holo-looping-oos' },
        { dir: 'loop_modules', dest: 'usr/lib/looping/loop_modules' },
        { dir: 'sample_loop_projects', dest: 'usr/lib/looping/sample_loop_projects' }
    ];

    for (const item of copyDirs) {
        const fullSource = path.join(ROOT_DIR, item.dir);
        if (!fs.existsSync(fullSource)) continue;

        dataTar.addEntry(item.dest, Buffer.alloc(0), { isDir: true, mode: 0o755 });
        const items = collectFiles(fullSource);

        for (const f of items) {
            const destPath = path.join(item.dest, f.relPath).replace(/\\/g, '/');
            if (f.isDir) {
                dataTar.addEntry(destPath, Buffer.alloc(0), { isDir: true, mode: 0o755 });
            } else {
                const content = fs.readFileSync(f.fullPath);
                const isExecutable = destPath.includes('/bin/') || destPath.endsWith('.sh');
                dataTar.addEntry(destPath, content, { mode: isExecutable ? 0o755 : 0o644 });

                const hash = crypto.createHash('md5').update(content).digest('hex');
                md5sums.push(`${hash}  ${destPath}`);
            }
        }
    }

    // Add Desktop Entry
    const desktopFile = path.join(ROOT_DIR, 'debian', 'looping.desktop');
    if (fs.existsSync(desktopFile)) {
        const content = fs.readFileSync(desktopFile);
        dataTar.addEntry('usr/share/applications/looping.desktop', content, { mode: 0o644 });
    }
    const launcherDesktop = path.join(ROOT_DIR, 'debian', 'shine-launcher.desktop');
    if (fs.existsSync(launcherDesktop)) {
        const content = fs.readFileSync(launcherDesktop);
        dataTar.addEntry('usr/share/applications/shine-launcher.desktop', content, { mode: 0o644 });
    }

    // Add Man Page
    const manFile = path.join(ROOT_DIR, 'debian', 'looping.1');
    if (fs.existsSync(manFile)) {
        const manGz = zlib.gzipSync(fs.readFileSync(manFile), { level: 9 });
        dataTar.addEntry('usr/share/man/man1/looping.1.gz', manGz, { mode: 0o644 });
    }

    // Add Copyright and Changelog
    const copyrightFile = path.join(ROOT_DIR, 'debian', 'copyright');
    if (fs.existsSync(copyrightFile)) {
        dataTar.addEntry('usr/share/doc/looping/copyright', fs.readFileSync(copyrightFile), { mode: 0o644 });
    }
    const changelogFile = path.join(ROOT_DIR, 'debian', 'changelog');
    if (fs.existsSync(changelogFile)) {
        const changeGz = zlib.gzipSync(fs.readFileSync(changelogFile), { level: 9 });
        dataTar.addEntry('usr/share/doc/looping/changelog.Debian.gz', changeGz, { mode: 0o644 });
    }

    // Default configuration
    const configContent = JSON.stringify({
        version: PKG_VERSION,
        theme: "frosted_aqua_a17",
        kernel: "Holo Looping OoS 1.0 (Linux Core)",
        targetPlatform: "Shine Loop Console",
        vsync_fps: 60
    }, null, 2);
    dataTar.addEntry('etc/looping/config.json', Buffer.from(configContent, 'utf8'), { mode: 0o644 });

    const dataGz = dataTar.toGzipBuffer();

    // 2. Prepare Control Tar
    const controlTar = new TarBuilder();
    const installedSizeKb = Math.ceil(dataGz.length / 1024 * 3); // Estimate uncompressed size

    const controlFileContent = `Package: ${PKG_NAME}
Version: ${FULL_VERSION}
Section: devel
Priority: optional
Architecture: ${architecture}
Installed-Size: ${installedSizeKb}
Maintainer: ${MAINTAINER}
Depends: nodejs (>= 18.0.0), python3 (>= 3.8), python3-pip
Recommends: xdg-utils, alsa-utils
Homepage: ${HOMEPAGE}
Description: Official Looping & Ruuping Runtime for Shine Loop Console
 Looping is a high-performance declarative programming language and
 multimedia game engine developed by Holo Entertainment & Coki Studios.
 Features 60 FPS low-latency canvas, Python interop bridge, and
 Ruuping native compiler subsystem.
`;

    controlTar.addEntry('control', Buffer.from(controlFileContent, 'utf8'), { mode: 0o644 });

    const postinst = path.join(ROOT_DIR, 'debian', 'postinst');
    if (fs.existsSync(postinst)) {
        controlTar.addEntry('postinst', fs.readFileSync(postinst), { mode: 0o755 });
    }
    const prerm = path.join(ROOT_DIR, 'debian', 'prerm');
    if (fs.existsSync(prerm)) {
        controlTar.addEntry('prerm', fs.readFileSync(prerm), { mode: 0o755 });
    }

    if (md5sums.length > 0) {
        controlTar.addEntry('md5sums', Buffer.from(md5sums.join('\n') + '\n', 'utf8'), { mode: 0o644 });
    }

    const controlGz = controlTar.toGzipBuffer();

    // 3. Assemble .deb Archive
    const debBuffer = createDebArchive(controlGz, dataGz);

    const distDir = path.join(ROOT_DIR, 'dist');
    if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });

    const debFilename = `${PKG_NAME}_${FULL_VERSION}_${architecture}.deb`;
    const outDebPath = path.join(distDir, debFilename);
    fs.writeFileSync(outDebPath, debBuffer);

    console.log(`✅ [SUCCESS] Generated: ${outDebPath} (${(debBuffer.length / 1024).toFixed(1)} KB)`);
    return {
        filename: debFilename,
        path: outDebPath,
        buffer: debBuffer,
        architecture,
        installedSizeKb
    };
}

// ── Generate APT Repository Structure ──
export function generateAptRepo(debPackages) {
    console.log(`\n🌐 [APT REPO] Building APT Repository Metadata (dists/stable, pool/main) ...`);
    const aptDir = path.join(ROOT_DIR, 'apt');
    const poolDir = path.join(aptDir, 'pool', 'main', 'l', PKG_NAME);
    fs.mkdirSync(poolDir, { recursive: true });

    // Copy packages to pool
    for (const pkg of debPackages) {
        fs.writeFileSync(path.join(poolDir, pkg.filename), pkg.buffer);
    }

    const archs = ['all', 'amd64'];
    const releaseEntries = [];

    for (const arch of archs) {
        const binDir = path.join(aptDir, 'dists', 'stable', 'main', `binary-${arch}`);
        fs.mkdirSync(binDir, { recursive: true });

        let packagesContent = '';
        for (const pkg of debPackages) {
            if (pkg.architecture === arch || (arch === 'amd64' && pkg.architecture === 'all')) {
                const sha256 = crypto.createHash('sha256').update(pkg.buffer).digest('hex');
                const sha1 = crypto.createHash('sha1').update(pkg.buffer).digest('hex');
                const md5 = crypto.createHash('md5').update(pkg.buffer).digest('hex');

                packagesContent += `Package: ${PKG_NAME}
Version: ${FULL_VERSION}
Architecture: ${pkg.architecture}
Maintainer: ${MAINTAINER}
Installed-Size: ${pkg.installedSizeKb}
Depends: nodejs (>= 18.0.0), python3 (>= 3.8), python3-pip
Filename: pool/main/l/${PKG_NAME}/${pkg.filename}
Size: ${pkg.buffer.length}
MD5sum: ${md5}
SHA1: ${sha1}
SHA256: ${sha256}
Section: devel
Priority: optional
Homepage: ${HOMEPAGE}
Description: Official Looping & Ruuping Runtime for Shine Loop Console
 Looping is a high-performance declarative programming language and
 multimedia game engine developed by Holo Entertainment & Coki Studios.

`;
            }
        }

        const packagesPath = path.join(binDir, 'Packages');
        fs.writeFileSync(packagesPath, packagesContent);

        const packagesGz = zlib.gzipSync(Buffer.from(packagesContent, 'utf8'), { level: 9 });
        fs.writeFileSync(path.join(binDir, 'Packages.gz'), packagesGz);

        const releaseContent = `Archive: stable
Component: main
Architecture: ${arch}
`;
        fs.writeFileSync(path.join(binDir, 'Release'), releaseContent);
    }

    // Generate Global dists/stable/Release
    const stableDir = path.join(aptDir, 'dists', 'stable');
    let releaseManifest = `Origin: Coki Studios
Label: Coki Studios Repository
Suite: stable
Codename: stable
Components: main
Architectures: all amd64
Description: Official Holo Entertainment & Coki Studios APT Repository for Shine Loop OS
Date: ${new Date().toUTCString()}
MD5Sum:
`;

    // Add hashes for Packages files
    const hashFiles = [
        'main/binary-all/Packages',
        'main/binary-all/Packages.gz',
        'main/binary-all/Release',
        'main/binary-amd64/Packages',
        'main/binary-amd64/Packages.gz',
        'main/binary-amd64/Release'
    ];

    for (const rel of hashFiles) {
        const fullP = path.join(stableDir, rel);
        if (fs.existsSync(fullP)) {
            const buf = fs.readFileSync(fullP);
            const md5 = crypto.createHash('md5').update(buf).digest('hex');
            releaseManifest += ` ${md5} ${buf.length.toString().padStart(16, ' ')} ${rel}\n`;
        }
    }

    releaseManifest += `SHA256:\n`;
    for (const rel of hashFiles) {
        const fullP = path.join(stableDir, rel);
        if (fs.existsSync(fullP)) {
            const buf = fs.readFileSync(fullP);
            const sha256 = crypto.createHash('sha256').update(buf).digest('hex');
            releaseManifest += ` ${sha256} ${buf.length.toString().padStart(16, ' ')} ${rel}\n`;
        }
    }

    fs.writeFileSync(path.join(stableDir, 'Release'), releaseManifest);

    // Create Quick Installer Script: apt/install.sh
    const installSh = `#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ♾️ COKI STUDIOS — ONE-STEP APT REPO INSTALLER FOR LOOPING
# ═══════════════════════════════════════════════════════════════
set -e

echo "🌟 Installing Looping & Ruuping Runtime for Ubuntu/Debian/Holo Looping OoS..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo bash install.sh"
    exit 1
fi

apt-get update -y
apt-get install -y curl ca-certificates nodejs python3 python3-pip

# Add Coki Studios APT Repository
echo "deb [trusted=yes] https://cokistudios.github.io/apt stable main" > /etc/apt/sources.list.d/cokistudios.list

apt-get update -y
apt-get install -y looping

echo "✅ Looping v2.1.0 installed successfully!"
echo "Type 'looping --help' or 'looping repl' to start."
`;
    fs.writeFileSync(path.join(aptDir, 'install.sh'), installSh);

    // Create apt/README.md
    const aptReadme = `# Coki Studios APT Repository

Official Debian/Ubuntu APT repository for **Looping**, **Ruuping**, and **Holo Looping OoS**.

## Quick Install (One-Liner)
\`\`\`bash
curl -fsSL https://cokistudios.github.io/apt/install.sh | sudo bash
\`\`\`

## Manual Setup
1. Add the repository to your APT sources:
\`\`\`bash
echo "deb [trusted=yes] https://cokistudios.github.io/apt stable main" | sudo tee /etc/apt/sources.list.d/cokistudios.list
\`\`\`

2. Update and install:
\`\`\`bash
sudo apt update
sudo apt install looping
\`\`\`

## Direct .deb Download
- [looping_2.1.0-1_all.deb](https://cokistudios.github.io/apt/pool/main/l/looping/looping_2.1.0-1_all.deb)
- [looping_2.1.0-1_amd64.deb](https://cokistudios.github.io/apt/pool/main/l/looping/looping_2.1.0-1_amd64.deb)

Install with:
\`\`\`bash
sudo apt install ./looping_2.1.0-1_all.deb
\`\`\`
`;
    fs.writeFileSync(path.join(aptDir, 'README.md'), aptReadme);

    console.log(`✅ [SUCCESS] APT Repository generated at: ${aptDir}`);
}

// ── Main Entry ──
const pkgAll = buildDeb('all');
const pkgAmd64 = buildDeb('amd64');
generateAptRepo([pkgAll, pkgAmd64]);
console.log(`\n🎉 [COMPLETE] APT Package & Repository Build Finished!\n`);
