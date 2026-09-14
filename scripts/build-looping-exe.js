// ═══════════════════════════════════════════════════════════════
// 🛠️ BUILD SCRIPT: Compile Looping CLI to Windows Standalone EXE
// Uses Node.js Single Executable Application (SEA) & Postject
// ═══════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
const distDir = path.join(rootDir, 'dist');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });

console.log('\x1b[36m[BUILD] Preparing Looping Standalone Executable...\x1b[0m');

// 1. Read LoopingEngine core to embed as fallback
const coreJsPath = path.join(rootDir, 'LoopingEngine/looping_core.js');
let embeddedCoreJs = '';
if (fs.existsSync(coreJsPath)) {
    embeddedCoreJs = fs.readFileSync(coreJsPath, 'utf8');
}

// 2. Read bin/looping source
const loopingSourcePath = path.join(rootDir, 'bin/looping');
let loopingSource = fs.readFileSync(loopingSourcePath, 'utf8');

// Convert ESM to CommonJS and embed core engine
let cjsSource = loopingSource
    .replace(/^#!\/usr\/bin\/env node/m, '')
    .replace(/import\s+fs\s+from\s+['"]fs['"];?/g, "const fs = require('fs');")
    .replace(/import\s+path\s+from\s+['"]path['"];?/g, "const path = require('path');")
    .replace(/import\s+readline\s+from\s+['"]readline['"];?/g, "const readline = require('readline');")
    .replace(/import\s+\{\s*([^}]+)\s*\}\s+from\s+['"]child_process['"];?/g, "const { $1 } = require('child_process');")
    .replace(/import\s+\{\s*fileURLToPath\s*\}\s+from\s+['"]url['"];?/g, '')
    .replace(/export\s+class\s+LoopingCLI/g, 'class LoopingCLI')
    .replace(/const\s+__filename\s*=\s*fileURLToPath\(import\.meta\.url\);?/g, '')
    .replace(/const\s+__dirname\s*=\s*path\.dirname\(__filename\);?/g, '')
    .replace(/import\('child_process'\)/g, "Promise.resolve(require('child_process'))")
    .replace(/import\('https'\)/g, "Promise.resolve(require('https'))");

// Replace dynamic core read with embedded fallback
const engineLoader = `
        let engineSource = '';
        const coreLocalPath = path.join(__dirname, '../LoopingEngine/looping_core.js');
        const coreLocalPathSame = path.join(process.cwd(), 'LoopingEngine/looping_core.js');
        if (fs.existsSync(coreLocalPath)) {
            engineSource = fs.readFileSync(coreLocalPath, 'utf8');
        } else if (fs.existsSync(coreLocalPathSame)) {
            engineSource = fs.readFileSync(coreLocalPathSame, 'utf8');
        } else {
            engineSource = ${JSON.stringify(embeddedCoreJs)};
        }
        engineSource = engineSource
            .replace('export class LoopingInterpreter', 'class LoopingInterpreter')
            .replace(/export\\s+/g, '');
`;

cjsSource = cjsSource.replace(
    /let engineSource = '';[\s\S]*?\.replace\(\/export\\s\+\/g,\s*''\);\s*\}/,
    engineLoader
);

const bundlePath = path.join(distDir, 'looping.cjs');
fs.writeFileSync(bundlePath, cjsSource, 'utf8');
console.log('\x1b[32m[OK] Generated CommonJS bundle:\x1b[0m', bundlePath);

// 3. Create SEA configuration
const seaConfigPath = path.join(distDir, 'sea-config.json');
const seaPrepBlobPath = path.join(distDir, 'sea-prep.blob');
const seaConfig = {
    main: bundlePath,
    output: seaPrepBlobPath,
    disableExperimentalSEAWarning: true
};
fs.writeFileSync(seaConfigPath, JSON.stringify(seaConfig, null, 2), 'utf8');

// 4. Generate SEA Blob
console.log('\x1b[36m[BUILD] Generating Single Executable Blob...\x1b[0m');
execSync(`node --experimental-sea-config "${seaConfigPath}"`, { stdio: 'inherit' });

// 5. Copy node.exe to target output
const nodeExePath = process.execPath;
const binDir = path.join(rootDir, 'bin');
const targetExePath = path.join(binDir, 'looping.exe');

console.log('\x1b[36m[BUILD] Copying Node runtime binary to:\x1b[0m', targetExePath);
fs.copyFileSync(nodeExePath, targetExePath);

// 6. Inject blob into target exe using postject
console.log('\x1b[36m[BUILD] Injecting SEA Blob into looping.exe...\x1b[0m');
const postjectCmd = `npx -y postject "${targetExePath}" NODE_SEA_BLOB "${seaPrepBlobPath}" --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2 --overwrite`;
execSync(postjectCmd, { stdio: 'inherit' });

// 7. Cleanup temp blobs
try {
    fs.unlinkSync(seaPrepBlobPath);
    fs.unlinkSync(seaConfigPath);
} catch (e) {}

console.log('\n\x1b[32m\x1b[1m🎉 [SUCCESS] Standalone Windows Executable Ready!\x1b[0m');
console.log('\x1b[33mLocation:\x1b[0m', targetExePath);
