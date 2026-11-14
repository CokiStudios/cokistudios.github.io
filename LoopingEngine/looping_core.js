// ═══════════════════════════════════════════════════════════════
//  LOOPING COMPILE — CORE RUNTIME & 2D/3D QUANTUM ENGINE v1.1 (Production)
//  Architecture Core: 3.0A (Quantum 3D Perspective, 120Hz Physics, .obj, C# & loopize++)
//  Channels: Looping (Prod) • Omega Looping (RC) • Alpha! Looping (Super Experimental)
//  Developed by Holo Entertainment & Coki Studios © 2026
// ═══════════════════════════════════════════════════════════════

export const BUILTIN_OBJ_MODELS = {
    starfighter: `# Wavefront OBJ — Angel Interceptor Starfighter
o AngelStarfighter
v  0.0000  0.0800  1.8500
v -0.4800  0.1800  0.4500
v  0.4800  0.1800  0.4500
v -1.6500 -0.0800 -0.9500
v  1.6500 -0.0800 -0.9500
v -0.6200  0.2600 -1.4500
v  0.6200  0.2600 -1.4500
v  0.0000 -0.3600  0.7500
v -0.5800 -0.3200 -1.3500
v  0.5800 -0.3200 -1.3500
v  0.0000  0.6400 -0.1500
v -0.3200  0.3200 -0.8500
v  0.3200  0.3200 -0.8500
v  0.0000  0.9200 -1.1000
v -1.3500  0.1200 -1.3000
v  1.3500  0.1200 -1.3000
usemtl CyberHullCyan
f 1 3 2
f 2 12 6 4
f 3 5 7 13
f 1 2 4 9 8
f 1 8 10 5 3
f 8 9 10
usemtl HoloCanopyGlass
f 2 3 11
f 2 11 12
f 3 13 11
f 11 13 12
usemtl CyberWingIndigo
f 11 12 14
f 11 14 13
f 4 6 15
f 5 16 7
usemtl IonThrusterNeon
f 6 7 10 9
f 12 13 7 6`,
    valkyrie_drone: `# Wavefront OBJ — Valkyrie Sentinel Drone
o ValkyrieDrone
v  0.0000  0.0000  1.3000
v -0.7500  0.2500  0.3000
v  0.7500  0.2500  0.3000
v -0.7500 -0.2500  0.3000
v  0.7500 -0.2500  0.3000
v  0.0000  0.8500 -0.1000
v  0.0000 -0.7500 -0.1000
v -1.4000  0.0000 -0.4500
v  1.4000  0.0000 -0.4500
v -0.5500  0.3000 -1.1000
v  0.5500  0.3000 -1.1000
v  0.0000 -0.3500 -1.2000
usemtl CrimsonArmor
f 1 3 2
f 1 4 5
f 1 2 4
f 1 5 3
f 2 3 6
f 4 7 5
usemtl DarkTitanium
f 2 6 8
f 4 8 7
f 3 9 6
f 5 7 9
f 6 11 10
f 10 11 12
f 8 6 10
f 9 11 6
f 8 10 12 7
f 9 7 12 11`,
    omega_titan: `# Wavefront OBJ — Omega Titan Mecha Boss
o OmegaTitanMecha
v -1.4000 -1.2000  0.9000
v  1.4000 -1.2000  0.9000
v  1.8000  1.1000  1.1000
v -1.8000  1.1000  1.1000
v -1.4000 -1.2000 -0.9000
v  1.4000 -1.2000 -0.9000
v  1.8000  1.1000 -1.1000
v -1.8000  1.1000 -1.1000
v  0.0000  0.1000  1.6500
v  0.0000  2.3500  0.2000
v -3.1000  1.6500  0.0000
v  3.1000  1.6500  0.0000
v  0.0000 -2.4000  0.0000
usemtl OmegaReactorCore
f 1 2 9
f 2 3 9
f 3 4 9
f 4 1 9
usemtl OmegaChassisRose
f 5 8 7 6
f 4 3 10
f 3 7 10
f 7 8 10
f 8 4 10
f 1 4 11 5
f 4 8 11
f 2 6 12 3
f 3 12 7
f 1 13 2
f 2 13 6
f 6 13 5
f 5 13 1`,
    cyber_crystal: `# Wavefront OBJ — Quantum Cyber Crystal
o CyberCrystal
v  0.0000  1.4500  0.0000
v  0.0000 -1.4500  0.0000
v -0.8500  0.3500  0.0000
v  0.0000  0.3500  0.8500
v  0.8500  0.3500  0.0000
v  0.0000  0.3500 -0.8500
v -0.8500 -0.3500  0.0000
v  0.0000 -0.3500  0.8500
v  0.8500 -0.3500  0.0000
v  0.0000 -0.3500 -0.8500
usemtl GoldQuantumGem
f 1 4 3
f 1 5 4
f 1 6 5
f 1 3 6
f 3 4 8 7
f 4 5 9 8
f 5 6 10 9
f 6 3 7 10
f 2 7 8
f 2 8 9
f 2 9 10
f 2 10 7`,
    star_gate: `# Wavefront OBJ — Quantum Star Gate Portal Ring
o StarGateRing
v  0.0000  3.2000  0.4500
v  2.2627  2.2627  0.4500
v  3.2000  0.0000  0.4500
v  2.2627 -2.2627  0.4500
v  0.0000 -3.2000  0.4500
v -2.2627 -2.2627  0.4500
v -3.2000  0.0000  0.4500
v -2.2627  2.2627  0.4500
v  0.0000  3.2000 -0.4500
v  2.2627  2.2627 -0.4500
v  3.2000  0.0000 -0.4500
v  2.2627 -2.2627 -0.4500
v  0.0000 -3.2000 -0.4500
v -2.2627 -2.2627 -0.4500
v -3.2000  0.0000 -0.4500
v -2.2627  2.2627 -0.4500
v  0.0000  2.3500  0.0000
v  1.6617  1.6617  0.0000
v  2.3500  0.0000  0.0000
v  1.6617 -1.6617  0.0000
v  0.0000 -2.3500  0.0000
v -1.6617 -1.6617  0.0000
v -2.3500  0.0000  0.0000
v -1.6617  1.6617  0.0000
usemtl PortalNeonViolet
f 1 2 18 17
f 2 3 19 18
f 3 4 20 19
f 4 5 21 20
f 5 6 22 21
f 6 7 23 22
f 7 8 24 23
f 8 1 17 24
f 9 17 18 10
f 10 18 19 11
f 11 19 20 12
f 12 20 21 13
f 13 21 22 14
f 14 22 23 15
f 15 23 24 16
f 16 24 17 9
f 1 9 10 2
f 2 10 11 3
f 3 11 12 4
f 4 12 13 5
f 5 13 14 6
f 6 14 15 7
f 7 15 16 8
f 8 16 9 1`
};

const OBJ_MATERIAL_TINTS = {
    cyberhullcyan: '#38bdf8',
    holocanopyglass: '#e0f2fe',
    cyberwingindigo: '#6366f1',
    ionthrusterneon: '#00f5d4',
    crimsonarmor: '#ef4444',
    darktitanium: '#475569',
    omegareactorcore: '#00f5d4',
    omegachassisrose: '#f43f5e',
    goldquantumgem: '#fbbf24',
    portalneonviolet: '#c084fc'
};

export function resolveBuiltinOBJKey(pathOrKey) {
    const k = String(pathOrKey || '').toLowerCase().split('/').pop().replace(/\.obj$/, '').trim();
    if (BUILTIN_OBJ_MODELS[k]) return k;
    if (k.includes('starfighter') || k.includes('ship') || k.includes('fighter')) return 'starfighter';
    if (k.includes('valkyrie') || k.includes('drone')) return 'valkyrie_drone';
    if (k.includes('omega') || k.includes('titan') || k.includes('boss')) return 'omega_titan';
    if (k.includes('crystal') || k.includes('gem')) return 'cyber_crystal';
    if (k.includes('gate') || k.includes('ring') || k.includes('portal')) return 'star_gate';
    return '';
}

export function recomputeOBJBounds(mesh) {
    const verts = mesh.vertices || [];
    if (!verts.length) {
        mesh.size = [0, 0, 0];
        mesh.center = [0, 0, 0];
        mesh.boundingRadius = 0;
        return mesh;
    }
    let minX = Infinity, minY = Infinity, minZ = Infinity;
    let maxX = -Infinity, maxY = -Infinity, maxZ = -Infinity;
    for (const v of verts) {
        if (v[0] < minX) minX = v[0]; if (v[1] < minY) minY = v[1]; if (v[2] < minZ) minZ = v[2];
        if (v[0] > maxX) maxX = v[0]; if (v[1] > maxY) maxY = v[1]; if (v[2] > maxZ) maxZ = v[2];
    }
    const cx = (minX + maxX) * 0.5, cy = (minY + maxY) * 0.5, cz = (minZ + maxZ) * 0.5;
    let maxR2 = 0;
    for (const v of verts) {
        const dx = v[0] - cx, dy = v[1] - cy, dz = v[2] - cz;
        const r2 = dx * dx + dy * dy + dz * dz;
        if (r2 > maxR2) maxR2 = r2;
    }
    mesh.center = [cx, cy, cz];
    mesh.size = [maxX - minX, maxY - minY, maxZ - minZ];
    mesh.boundingRadius = Math.sqrt(maxR2);
    let tris = 0;
    for (const f of (mesh.faces || [])) {
        if (f.indices.length >= 3) tris += f.indices.length - 2;
    }
    mesh.triangles = tris;
    return mesh;
}

export function parseWavefrontOBJ(objText, scale = 1, name = 'ObjMesh') {
    const rawVerts = [];
    const faces = [];
    let objName = name;
    let currentMtl = '';
    const s = Number(scale) || 1;
    const lines = String(objText || '').split(/\r?\n/);

    for (const raw of lines) {
        const line = raw.trim();
        if (!line || line.startsWith('#')) continue;
        const parts = line.split(/\s+/);
        const cmd = parts[0];
        if (cmd === 'o' && parts[1]) {
            objName = parts[1];
        } else if (cmd === 'usemtl' && parts[1]) {
            currentMtl = parts[1].toLowerCase();
        } else if (cmd === 'v' && parts.length >= 4) {
            rawVerts.push([parseFloat(parts[1]) * s, parseFloat(parts[2]) * s, parseFloat(parts[3]) * s]);
        } else if (cmd === 'f' && parts.length >= 4) {
            const idxs = [];
            for (let k = 1; k < parts.length; k++) {
                const tok = parts[k].split('/')[0];
                let vi = parseInt(tok, 10);
                if (isNaN(vi)) continue;
                vi = vi < 0 ? rawVerts.length + vi : vi - 1;
                if (vi >= 0 && vi < rawVerts.length) idxs.push(vi);
            }
            if (idxs.length >= 3) {
                const p0 = rawVerts[idxs[0]], p1 = rawVerts[idxs[1]], p2 = rawVerts[idxs[2]];
                const ux = p1[0] - p0[0], uy = p1[1] - p0[1], uz = p1[2] - p0[2];
                const vx = p2[0] - p0[0], vy = p2[1] - p0[1], vz = p2[2] - p0[2];
                let nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
                const nl = Math.hypot(nx, ny, nz) || 1;
                nx /= nl; ny /= nl; nz /= nl;
                const tint = OBJ_MATERIAL_TINTS[currentMtl] || null;
                faces.push({ indices: idxs, nx, ny, nz, bias: tint ? 1.08 : 0.96, tint, material: currentMtl });
            }
        }
    }
    return recomputeOBJBounds({ name: objName, vertices: rawVerts, faces });
}

export function normalizeOBJMesh(mesh, targetExtent = 2.0) {
    recomputeOBJBounds(mesh);
    if (!mesh.vertices.length) return mesh;
    const maxDim = Math.max(mesh.size[0], mesh.size[1], mesh.size[2], 1e-6);
    const sc = targetExtent / maxDim;
    const c = mesh.center;
    mesh.vertices = mesh.vertices.map(v => [(v[0] - c[0]) * sc, (v[1] - c[1]) * sc, (v[2] - c[2]) * sc]);
    return recomputeOBJBounds(mesh);
}

export function subdivideOBJMesh(mesh) {
    const verts = mesh.vertices.map(v => [...v]);
    const newFaces = [];
    for (const f of mesh.faces) {
        if (f.indices.length < 3) continue;
        const i0 = f.indices[0];
        for (let k = 1; k + 1 < f.indices.length; k++) {
            const i1 = f.indices[k], i2 = f.indices[k + 1];
            const v0 = verts[i0], v1 = verts[i1], v2 = verts[i2];
            const m01 = verts.length; verts.push([(v0[0] + v1[0]) * 0.5, (v0[1] + v1[1]) * 0.5, (v0[2] + v1[2]) * 0.5]);
            const m12 = verts.length; verts.push([(v1[0] + v2[0]) * 0.5, (v1[1] + v2[1]) * 0.5, (v1[2] + v2[2]) * 0.5]);
            const m20 = verts.length; verts.push([(v2[0] + v0[0]) * 0.5, (v2[1] + v0[1]) * 0.5, (v2[2] + v0[2]) * 0.5]);
            for (const tri of [[i0, m01, m20], [m01, i1, m12], [m20, m12, i2], [m01, m12, m20]]) {
                newFaces.push({ indices: tri, nx: f.nx, ny: f.ny, nz: f.nz, bias: f.bias, tint: f.tint, material: f.material });
            }
        }
    }
    return recomputeOBJBounds({ name: `${mesh.name}_Subdiv`, vertices: verts, faces: newFaces });
}

export function exportWavefrontOBJ(mesh) {
    const out = [`# Wavefront OBJ exported by Looping Engine v1.1 + Web Loopize Kit`, `o ${mesh.name || 'LoopMesh3D'}`];
    for (const v of mesh.vertices || []) {
        out.push(`v ${v[0].toFixed(4)} ${v[1].toFixed(4)} ${v[2].toFixed(4)}`);
    }
    let lastMtl = '';
    for (const f of mesh.faces || []) {
        if (f.material && f.material !== lastMtl) { out.push(`usemtl ${f.material}`); lastMtl = f.material; }
        out.push(`f ${f.indices.map(idx => idx + 1).join(' ')}`);
    }
    return out.join('\n');
}

export class CSharpMiniVM {
    constructor(interp) {
        this.interp = interp;
        this.classes = {};
        this.instances = {};
        this.snippets = {};
        this.logs = [];
    }
    stripComments(code) {
        return String(code || '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '');
    }
    findMatching(str, openIdx, openCh, closeCh) {
        let d = 0, inS = false, q = '';
        for (let i = openIdx; i < str.length; i++) {
            const c = str[i];
            if (inS) { if (c === '\\') { i++; continue; } if (c === q) inS = false; continue; }
            if (c === '"' || c === "'") { inS = true; q = c; continue; }
            if (c === openCh) d++;
            else if (c === closeCh && --d === 0) return i;
        }
        return -1;
    }
    parseAndRegisterClasses(rawCode) {
        const clean = this.stripComments(rawCode);
        const leftover = [];
        let pos = 0;
        while (pos < clean.length) {
            while (pos < clean.length && /\s/.test(clean[pos])) pos++;
            if (pos >= clean.length) break;
            if (clean.slice(pos).startsWith('using ')) {
                const sc = clean.indexOf(';', pos);
                pos = sc < 0 ? clean.length : sc + 1;
                continue;
            }
            const rest = clean.slice(pos);
            const clsMatch = rest.match(/^(?:(?:public|private|internal|sealed|static)\s+)*class\s+([A-Za-z0-9_]+)(?:\s*:\s*([A-Za-z0-9_<>,.\s]+))?\s*\{/);
            if (clsMatch) {
                const ob = pos + clsMatch[0].length - 1;
                const cb = this.findMatching(clean, ob, '{', '}');
                if (cb > ob) {
                    const clsName = clsMatch[1];
                    const def = { name: clsName, base: (clsMatch[2] || 'MonoBehaviour').trim(), fields: {}, methods: {} };
                    this.parseClassBody(clean.slice(ob + 1, cb), def);
                    this.classes[clsName] = def;
                    pos = cb + 1;
                    continue;
                }
            }
            const sc = clean.indexOf(';', pos);
            if (sc >= 0) { leftover.push(clean.slice(pos, sc)); pos = sc + 1; }
            else { leftover.push(clean.slice(pos)); break; }
        }
        return leftover.join(';\n');
    }
    parseClassBody(body, def) {
        let pos = 0;
        while (pos < body.length) {
            while (pos < body.length && /\s/.test(body[pos])) pos++;
            if (pos >= body.length) break;
            const ob = body.indexOf('{', pos);
            const sc = body.indexOf(';', pos);
            if (ob >= 0 && (sc < 0 || ob < sc)) {
                const cb = this.findMatching(body, ob, '{', '}');
                if (cb < 0) break;
                const sig = body.slice(pos, ob).trim();
                const lp = sig.indexOf('('), rp = sig.lastIndexOf(')');
                if (lp > 0 && rp > lp) {
                    const mName = sig.slice(0, lp).trim().split(/\s+/).pop();
                    const params = sig.slice(lp + 1, rp).split(',').map(p => p.trim().split(/\s+/).pop()).filter(Boolean);
                    def.methods[mName] = { params, body: body.slice(ob + 1, cb) };
                }
                pos = cb + 1;
            } else if (sc >= 0) {
                const fLine = body.slice(pos, sc).trim();
                const m = fLine.match(/^(?:(?:public|private|protected|internal|static|readonly|const)\s+)*(?:int|float|double|bool|string|var|Vector3)\s+([A-Za-z0-9_]+)(?:\s*=\s*(.+))?$/);
                if (m) def.fields[m[1]] = m[2] !== undefined ? this.evalExpr(m[2], def.fields) : 0;
                pos = sc + 1;
            } else break;
        }
    }
    instantiate(className, instId, entityName) {
        const cls = this.classes[className];
        if (!cls) return '';
        const id = instId || `${className}_${Object.keys(this.instances).length + 1}`;
        this.instances[id] = { id, className, entityName: entityName || '', fields: { ...cls.fields, gameObject: entityName || '' }, started: false };
        if (cls.methods.Start) {
            this.callMethod(id, 'Start', []);
            this.instances[id].started = true;
        }
        return id;
    }
    callMethod(instId, methodName, args = []) {
        const inst = this.instances[instId];
        if (!inst) return undefined;
        const cls = this.classes[inst.className];
        const method = cls && cls.methods[methodName];
        if (!method) return undefined;
        const locals = { ...inst.fields };
        method.params.forEach((p, idx) => { locals[p] = args[idx]; });
        const res = this.execStatements(method.body, locals, inst.entityName);
        for (const k of Object.keys(inst.fields)) {
            if (Object.prototype.hasOwnProperty.call(locals, k)) inst.fields[k] = locals[k];
        }
        return res;
    }
    stepAll(dt = 1 / 60) {
        let count = 0;
        for (const id of Object.keys(this.instances)) {
            const inst = this.instances[id];
            const cls = this.classes[inst.className];
            if (!cls) continue;
            if (!inst.started && cls.methods.Start) { this.callMethod(id, 'Start', []); inst.started = true; }
            if (cls.methods.Update) { this.callMethod(id, 'Update', [dt]); count++; }
        }
        return count;
    }
    evalExpr(raw, locals = {}, boundEntity = '') {
        let s = String(raw || '').trim().replace(/\b(\d+(?:\.\d+)?)[fFdDmL]\b/g, '$1');
        if (!s) return 0;
        const vars = this.interp ? this.interp.variables : {};
        const findEnt = (name) => (this.interp?.entities3D || []).find(e => e.name === name || e.label === name);
        const fnEnv = {
            Mathf: {
                Clamp: (v, a, b) => Math.max(a, Math.min(b, v)),
                Lerp: (a, b, t) => a + (b - a) * t,
                MoveTowards: (cur, tgt, maxD) => {
                    const diff = tgt - cur;
                    if (Math.abs(diff) <= maxD) return tgt;
                    return cur + Math.sign(diff) * maxD;
                },
                SmoothStep: (a, b, t) => {
                    const c = Math.max(0, Math.min(1, Number(t) || 0));
                    return a + (b - a) * (c * c * (3 - 2 * c));
                },
                Sin: Math.sin, Cos: Math.cos, Abs: Math.abs, Sqrt: Math.sqrt, Min: Math.min, Max: Math.max, PI: Math.PI
            },
            Math,
            Time: { deltaTime: 1 / 60 },
            Console: { WriteLine: (...a) => { const msg = a.join(' '); this.logs.push(msg); this.interp?.log(`[C#] ${msg}`, 'output'); return msg; } },
            Debug: { Log: (...a) => { const msg = a.join(' '); this.logs.push(msg); this.interp?.log(`[C#] ${msg}`, 'output'); return msg; } },
            LoopingBridge: { Get: (k) => vars[k], Set: (k, v) => { vars[k] = v; return v; } },
            Vector3: {
                zero: [0, 0, 0], one: [1, 1, 1], up: [0, 1, 0], forward: [0, 0, 1],
                Distance: (a, b) => Math.hypot((a[0] || 0) - (b[0] || 0), (a[1] || 0) - (b[1] || 0), (a[2] || 0) - (b[2] || 0)),
                Lerp: (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]
            },
            Scene3D: {
                Find: (n) => findEnt(n || boundEntity) ? findEnt(n || boundEntity).name : '',
                GetHealth: (n) => { const e = findEnt(n || boundEntity); return e ? e.health : 0; },
                SetColor: (n, hex) => {
                    const e = findEnt(n || boundEntity);
                    if (e && this.interp) { e.color = String(hex); e.rgb = this.interp.parseHexRGB(e.color); return 1; }
                    return 0;
                },
                LookAt: (n, tx, ty, tz) => {
                    const e = findEnt(n || boundEntity);
                    if (!e) return 0;
                    const dx = (Number(tx) || 0) - e.x;
                    const dy = (Number(ty) || 0) - e.y;
                    const dz = (Number(tz) || 0) - e.z;
                    e.yaw = Math.atan2(dx, dz);
                    e.pitch = -Math.atan2(dy, Math.hypot(dx, dz) || 1);
                    return e.yaw;
                },
                Move: (n, dx, dy, dz) => { const e = findEnt(n || boundEntity); if (e) { e.x += dx || 0; e.y += dy || 0; e.z += dz || 0; } return e ? [e.x, e.y, e.z] : [0, 0, 0]; },
                Rotate: (n, rx, ry, rz) => { const e = findEnt(n || boundEntity); if (e) { e.pitch += (rx || 0) * Math.PI / 180; e.yaw += (ry || 0) * Math.PI / 180; e.roll += (rz || 0) * Math.PI / 180; } return e ? [e.pitch, e.yaw, e.roll] : [0, 0, 0]; },
                SetPosition: (n, x, y, z) => { const e = findEnt(n || boundEntity); if (e) { e.x = x; e.y = y; e.z = z; } return [x, y, z]; },
                Damage: (n, amt) => {
                    const e = findEnt(n || boundEntity);
                    if (e) {
                        e.health = Math.max(0, e.health - (amt || 0));
                        e.hitFlash = 1.0;
                        if (e.health <= 0) e.isAlive = false;
                        return e.health;
                    }
                    return 0;
                }
            }
        };
        s = s.replace(/new\s+Vector3\(([^)]+)\)/g, '[$1]');
        try {
            const keys = [...Object.keys(fnEnv), ...Object.keys(locals), ...Object.keys(vars).filter(k => /^[A-Za-z_][A-Za-z0-9_]*$/.test(k) && !(k in fnEnv) && !(k in locals))];
            const vals = keys.map(k => (k in fnEnv ? fnEnv[k] : (k in locals ? locals[k] : vars[k])));
            return Function(...keys, `"use strict"; return (${s});`)(...vals);
        } catch (e) {
            return 0;
        }
    }
    execStatements(code, locals = {}, boundEntity = '') {
        const stmts = String(code || '').split(/[;\n]+/).map(s => s.trim()).filter(Boolean);
        let last = 0;
        const vars = this.interp ? this.interp.variables : {};
        for (const raw of stmts) {
            let line = raw.replace(/^(?:public|private|internal|static)\s+/, '');
            if (line.startsWith('return ')) return this.evalExpr(line.slice(7), locals, boundEntity);
            const declM = line.match(/^(?:var|int|float|double|bool|string|Vector3)\s+([A-Za-z0-9_]+)\s*=\s*(.+)$/);
            if (declM) { locals[declM[1]] = this.evalExpr(declM[2], locals, boundEntity); last = locals[declM[1]]; continue; }
            const opM = line.match(/^([A-Za-z0-9_]+)\s*(\+=|-=|\*=|\/=|=)\s*(.+)$/);
            if (opM) {
                const [, k, op, rhs] = opM;
                const rv = this.evalExpr(rhs, locals, boundEntity);
                const cur = k in locals ? locals[k] : vars[k];
                const next = op === '=' ? rv : op === '+=' ? cur + rv : op === '-=' ? cur - rv : op === '*=' ? cur * rv : cur / (rv || 1);
                if (k in locals || !(k in vars)) locals[k] = next; else vars[k] = next;
                last = next;
                continue;
            }
            const incM = line.match(/^([A-Za-z0-9_]+)(\+\+|--)$/);
            if (incM) {
                const k = incM[1], d = incM[2] === '++' ? 1 : -1;
                if (k in locals) locals[k] = Number(locals[k] || 0) + d; else vars[k] = Number(vars[k] || 0) + d;
                continue;
            }
            last = this.evalExpr(line, locals, boundEntity);
        }
        return last;
    }
    executeBlock(rawCode) {
        const leftover = this.parseAndRegisterClasses(rawCode);
        const locals = {};
        const ret = this.execStatements(leftover, locals);
        if (this.interp) Object.assign(this.interp.variables, locals);
        return ret;
    }
    exportScene(className = 'LoopizeGeneratedGame') {
        const scene = this.interp?.scene3D || { name: 'LoopizeWorld' };
        const ents = this.interp?.entities3D || [];
        return [
            `// Generated by Looping Engine v1.1 (Arch 3.0A) + Web Loopize Kit`,
            `using System;`,
            `using System.Collections.Generic;`,
            `namespace CokiStudios.Loopize {`,
            `    public class ${className} {`,
            `        public string WorldName = "${scene.name}";`,
            `        public int EntityCount = ${ents.length};`,
            `    }`,
            `}`
        ].join('\n');
    }
}

export class LoopizeRuntimeJS {
    constructor(interp) {
        this.interp = interp;
        this.initialized = true;
        this.projectName = 'LoopizeGame';
        this.ecs = [];
        this.nextId = 1;
        this.waves = {};
        this.currentWave = 0;
        this.fsm = {};
        this.combo = { hits: 0, timer: 0, window: 2.8, multiplier: 1.0, score: 0, maxCombo: 0 };
        this.tweens = {};
        this.inventory = {};
        this.quests = {};
        this.xp = 0;
        this.level = 1;
        this.cameraShake = { trauma: 0, maxOffset: 0.75 };
    }
    init(name = 'LoopizeGame') {
        this.initialized = true;
        this.projectName = String(name || 'LoopizeGame');
        return true;
    }
    ease(mode, tRaw) {
        const t = Math.max(0, Math.min(1, Number(tRaw) || 0));
        switch (String(mode || 'linear').toLowerCase()) {
            case 'in_quad': return t * t;
            case 'out_quad': return 1 - (1 - t) * (1 - t);
            case 'in_out_quad': return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
            case 'in_cubic': return t * t * t;
            case 'out_cubic': return 1 - Math.pow(1 - t, 3);
            case 'in_out_cubic': return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
            case 'out_back': { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); }
            case 'out_bounce': {
                const n1 = 7.5625, d1 = 2.75;
                if (t < 1 / d1) return n1 * t * t;
                if (t < 2 / d1) { const u = t - 1.5 / d1; return n1 * u * u + 0.75; }
                if (t < 2.5 / d1) { const u = t - 2.25 / d1; return n1 * u * u + 0.9375; }
                const u = t - 2.625 / d1; return n1 * u * u + 0.984375;
            }
            case 'out_elastic': {
                if (t === 0 || t === 1) return t;
                return Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * ((2 * Math.PI) / 3)) + 1;
            }
            default: return t;
        }
    }
    ecsSpawn(name, tag = 'entity', pos = [0, 2, 0], hp = 100, objFile = '', csClass = '') {
        const id = this.nextId++;
        this.ecs.push({ id, name, tag, pos: [...pos], hp, maxHp: hp, objFile, csClass, alive: true, data: {} });
        if (this.interp && objFile && !this.interp.entities3D.some(e => e.name === name)) {
            const roleType = (tag === 'enemy' || tag === 'boss' || tag === 'player') ? tag : 'obj';
            this.interp.spawnObjEntity3D({ name, obj: objFile, at: pos, health: hp, type: roleType, tag, cs: csClass });
        }
        return id;
    }
    ecsQueryTag(tag) {
        return this.ecs.filter(e => e.alive && (!tag || e.tag === tag)).map(e => e.id);
    }
    ecsSet(id, key, val) {
        const ent = this.ecs.find(e => e.id === Number(id) || e.name === String(id));
        if (!ent) return false;
        ent.data[key] = val;
        if (key === 'hp') { ent.hp = Number(val); if (ent.hp <= 0) ent.alive = false; }
        return true;
    }
    ecsGet(id, key) {
        const ent = this.ecs.find(e => e.id === Number(id) || e.name === String(id));
        if (!ent) return undefined;
        if (key === 'hp') return ent.hp;
        if (key === 'name') return ent.name;
        if (key === 'tag') return ent.tag;
        return ent.data[key];
    }
    ecsDestroy(id) {
        const ent = this.ecs.find(e => e.id === Number(id) || e.name === String(id));
        if (!ent) return false;
        ent.alive = false;
        if (this.interp) {
            const e3 = this.interp.entities3D.find(x => x.name === ent.name);
            if (e3) { e3.isAlive = false; e3.health = 0; }
        }
        return true;
    }
    spatialRadius(center, radius, tag = '') {
        const out = [];
        for (const s of this.ecs) {
            if (!s.alive || (tag && s.tag !== tag)) continue;
            if (Math.hypot(s.pos[0] - center[0], s.pos[1] - center[1], s.pos[2] - center[2]) <= radius) out.push(s.id);
        }
        return out;
    }
    waveDefine(waveNum, count = 4, hp = 80, archetype = 'valkyrie', objFile = 'valkyrie_drone.obj') {
        this.waves[waveNum] = { waveNum, count, hp, archetype, objFile, spawned: false, cleared: false };
        return true;
    }
    waveAdd(waveNum, archetype = 'valkyrie', count = 4, hp = 80, objFile = 'valkyrie_drone.obj') {
        return this.waveDefine(waveNum, count, hp, archetype, objFile);
    }
    waveSpawn(waveNum) {
        const w = this.waves[waveNum];
        if (!w) return 0;
        this.currentWave = waveNum;
        let spawned = 0;
        for (let i = 0; i < w.count; i++) {
            const ang = (i / Math.max(1, w.count)) * Math.PI * 2;
            const pos = [Number((Math.cos(ang) * 9.5).toFixed(2)), 2.2, Number((14 + Math.sin(ang) * 9.5).toFixed(2))];
            this.ecsSpawn(`Wave${waveNum}_${w.archetype}_${i + 1}`, 'enemy', pos, w.hp, w.objFile, '');
            spawned++;
        }
        w.spawned = true;
        return spawned;
    }
    waveNext() {
        const keys = Object.keys(this.waves).map(Number).sort((a, b) => a - b);
        const nextNum = keys.find(n => n > this.currentWave && !this.waves[n].spawned);
        if (nextNum === undefined) return 0;
        return this.waveSpawn(nextNum);
    }
    waveStatus(waveNum = 0) {
        const target = waveNum || this.currentWave || 1;
        const w = this.waves[target];
        const prefix = `Wave${target}_`;
        const aliveEnemies = this.interp
            ? this.interp.entities3D.filter(e => e.isAlive && e.name.startsWith(prefix)).length
            : this.ecs.filter(e => e.alive && e.name.startsWith(prefix)).length;
        if (w && w.spawned && aliveEnemies === 0) w.cleared = true;
        return {
            wave: target,
            exists: Boolean(w),
            spawned: Boolean(w && w.spawned),
            cleared: Boolean(w && w.cleared),
            alive_enemies: aliveEnemies
        };
    }
    comboHit(basePoints = 100) {
        this.combo.hits++;
        this.combo.timer = this.combo.window;
        this.combo.maxCombo = Math.max(this.combo.maxCombo, this.combo.hits);
        this.combo.multiplier = Math.min(8.0, 1.0 + (this.combo.hits - 1) * 0.25);
        const award = basePoints * this.combo.multiplier;
        this.combo.score += award;
        if (this.interp) { this.interp.score += Math.round(award); this.interp.combo = this.combo.hits; this.interp.comboTimer = this.combo.window; }
        return award;
    }
    tween(key, mode = 'linear', from = 0, to = 1, dur = 1.0, loop = false, pingPong = false) {
        this.tweens[key] = {
            key: String(key),
            mode: String(mode || 'linear'),
            from: Number(from),
            to: Number(to),
            cur: Number(from),
            dur: Math.max(1e-4, Number(dur) || 1),
            elapsed: 0,
            loop: Boolean(loop),
            pingPong: Boolean(pingPong),
            done: false
        };
        return Number(from);
    }
    tweenValue(key) {
        const tw = this.tweens[key];
        return tw ? tw.cur : 0;
    }
    shake(trauma = 0.45) {
        this.cameraShake.trauma = Math.min(1.0, this.cameraShake.trauma + Number(trauma || 0));
        if (this.interp?.camera3D) this.interp.camera3D.shake = Math.max(this.interp.camera3D.shake || 0, this.cameraShake.trauma);
        return this.cameraShake.trauma;
    }
    questAdd(id, title, goal = 1, rewardXp = 500) {
        this.quests[id] = { id, title, progress: 0, goal, rewardXp, completed: false };
        return true;
    }
    questProgress(id, delta = 1) {
        const q = this.quests[id];
        if (!q || q.completed) return q ? q.completed : false;
        q.progress = Math.min(q.goal, q.progress + delta);
        if (q.progress >= q.goal) {
            q.completed = true;
            this.xp += q.rewardXp;
            this.level = 1 + Math.floor(this.xp / 500);
        }
        return q.completed;
    }
    tick(dt) {
        if (this.combo.timer > 0) {
            this.combo.timer = Math.max(0, this.combo.timer - dt);
            if (this.combo.timer <= 0) { this.combo.hits = 0; this.combo.multiplier = 1.0; }
        }
        this.cameraShake.trauma = Math.max(0, this.cameraShake.trauma - 1.6 * dt);
        for (const tw of Object.values(this.tweens)) {
            if (!tw.done) {
                tw.elapsed += dt;
                if (tw.loop || tw.pingPong) {
                    const cycles = tw.elapsed / tw.dur;
                    const frac = cycles - Math.floor(cycles);
                    const rawP = (tw.pingPong && Math.floor(cycles) % 2 === 1) ? (1 - frac) : frac;
                    tw.cur = tw.from + (tw.to - tw.from) * this.ease(tw.mode, rawP);
                } else {
                    const p = Math.min(1, tw.elapsed / tw.dur);
                    tw.cur = tw.from + (tw.to - tw.from) * this.ease(tw.mode, p);
                    if (p >= 1) tw.done = true;
                }
            }
        }
    }
    stats() {
        const aliveEnemies = this.interp
            ? this.interp.entities3D.filter(e => e.isAlive && (e.type === 'enemy' || e.type === 'boss')).length
            : this.ecs.filter(e => e.alive && e.tag === 'enemy').length;
        return {
            initialized: this.initialized,
            project: this.projectName,
            ecs_count: this.ecs.filter(e => e.alive).length,
            waves_total: Object.keys(this.waves).length,
            current_wave: this.currentWave,
            alive_enemies: aliveEnemies,
            combo_hits: this.combo.hits,
            combo_mult: this.combo.multiplier,
            combo_max: this.combo.maxCombo,
            camera_trauma: Number(this.cameraShake.trauma.toFixed(3)),
            tweens_active: Object.values(this.tweens).filter(t => !t.done).length,
            xp: this.xp,
            level: this.level,
            quests_done: Object.values(this.quests).filter(q => q.completed).length,
            cs_classes: Object.keys(this.interp?.csharpBridge?.classes || {}).length,
            obj_cache: Object.keys(this.interp?.objMeshes3D || {}).length
        };
    }
}

export class LoopingInterpreter {
    constructor(canvas, terminalOutput) {
        this.canvas = canvas;
        this.ctx = canvas ? canvas.getContext('2d') : null;
        this.terminalOutput = terminalOutput || console.log;
        
        // Virtual Machine, Version & Official Release Nomenclature
        this.engineVersion = "1.1";
        this.archVersion = "3.0A";
        this.releaseChannel = "prod";
        this.channelName = "Looping";
        this.releaseChannels = {
            alpha: "Alpha! Looping (Super Experimental)",
            omega: "Omega Looping (Release Candidate / RC)",
            prod: "Looping (Production Release)"
        };
        this.systemTarget = "Holo Looping Runtime Core";
        this.targetPlatform = "Shine Loop Game Runtime";
        
        this.variables = {};
        this.functions = {};
        this.gameEntities = [];
        this.renderQueue = [];
        this.particles = [];
        this.projectiles = [];
        this.popups = [];
        this.sounds = {};
        this.theme = 'dark_neon';
        this.isRunning = false;
        this.animationFrameId = null;
        this.lastTime = 0;
        this.fps = 60;
        this.fpsSmooth = 60;
        this.score = 0;
        this.lives = 3;
        this.maxLives = 3;
        this.gameOver = false;
        this.gameWon = false;
        this.paused = false;
        this.hitstopTimer = 0;
        this.sourceCode = '';
        
        // World, Scenario & 2D Physics Configuration
        this.gravity = 980;
        this.friction = 0.82;
        this.timeScale = 1.0;
        this.combo = 0;
        this.comboTimer = 0;
        this.scenario = { name: 'Holo Cyber Stage', weather: 'stars', bg: '#06090f', accent: '#38bdf8' };
        this.world = { width: 1200, height: 480, hasCustomBounds: false };
        this.camera = { x: 0, y: 0, targetX: 0, targetY: 0, smooth: 0.12, shake: 0 };
        this.coyoteTime = 0.12;
        this.jumpBuffer = 0.12;

        // 3D Quantum Perspective Engine State
        this.init3DState();
        
        // Web Audio Synthesizer Core
        this.audioCtx = null;
        
        // Input Controller State (Keyboard + Gamepad + Touch + 3D Orbit Mouse)
        this.keysDown = {};
        this.mousePos = { x: 0, y: 0 };
        this.isMouseDown = false;
        this.dragOrbit = { active: false, lastX: 0, lastY: 0, moved: false };
        this.prevGamepadButtons = {};
        this.gamepadState = {
            dpad: { left: false, right: false, up: false, down: false },
            axisX: 0,
            axisY: 0,
            axisCamX: 0,
            btnA: false, // Jump
            btnB: false, // Attack / Shoot
            btnX: false, // Dash / Special
            btnY: false
        };
        this.touchState = {
            hasTouch: false,
            left: false, right: false, up: false, down: false,
            stickX: 0, stickY: 0,
            btnA: false, btnB: false, btnX: false
        };
        
        this.setupInputListeners();
    }

    init3DState() {
        this.is3DMode = false;
        this.entities3D = [];
        this.particles3D = [];
        this.projectiles3D = [];
        this.popups3D = [];
        this.objMeshes3D = {};
        this.csharpBridge = new CSharpMiniVM(this);
        this.loopize = new LoopizeRuntimeJS(this);
        this.scene3D = {
            name: 'Neon Cyber Horizon 3D',
            sizeX: 180,
            sizeY: 90,
            sizeZ: 240,
            sky: 'cyber_night',
            fogDensity: 0.0085,
            showGrid: true,
            floorY: 0,
            hasFloorPlane: false,
            ambientColor: '#1e293b',
            ambientIntensity: 0.38
        };
        this.camera3D = {
            mode: 'chase', // 'chase' | 'orbit' | 'fps' | 'topdown'
            x: 0, y: 8.5, z: -16,
            targetX: 0, targetY: 2.2, targetZ: 10,
            yaw: 0,
            yawOffset: 0,
            pitchOffset: 0.24,
            distance: 15.5,
            heightOffset: 6.2,
            baseFov: 64,
            fov: 64,
            near: 0.25,
            far: 280,
            smooth: 0.14,
            shake: 0
        };
        this.lights3D = [
            { type: 'directional', dx: -0.42, dy: -0.88, dz: -0.32, color: '#ffffff', intensity: 1.05 }
        ];
        this.physics3D = {
            gravity: -28.0,
            substeps: 4,
            friction: 0.86,
            airDrag: 0.985,
            bounce: 0.08
        };
    }
    
    setupInputListeners() {
        if (!this.canvas) return;
        
        const ensureAudio = () => {
            try {
                if (!this.audioCtx) {
                    const AudioCtx = window.AudioContext || window.webkitAudioContext;
                    if (AudioCtx) this.audioCtx = new AudioCtx();
                }
                if (this.audioCtx && this.audioCtx.state === 'suspended') {
                    this.audioCtx.resume();
                }
            } catch (e) {}
        };

        window.addEventListener('keydown', (e) => {
            const activeTag = document.activeElement ? document.activeElement.tagName : '';
            if (activeTag === 'TEXTAREA' || activeTag === 'INPUT') return;

            ensureAudio();
            const key = e.key.toLowerCase();
            this.keysDown[key] = true;
            this.keysDown[e.code.toLowerCase()] = true;

            if (this.isRunning && ['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(key)) {
                e.preventDefault();
            }
            
            // Map to Shine Loop Gamepad Buttons
            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = true;
            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = true;

            if (this.is3DMode) {
                if (key === 'w' || key === 'arrowup') this.gamepadState.dpad.up = true;
                if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = true;
                if (key === ' ') {
                    this.gamepadState.btnA = true;
                    const p3 = this.getPlayer3D();
                    if (p3) p3.jumpBufferTimer = this.jumpBuffer;
                }
                if (key === 'j' || key === 'z' || key === 'f' || key === 'enter') {
                    this.gamepadState.btnB = true;
                    const p3 = this.getPlayer3D();
                    if (p3 && !this.gameOver && !this.gameWon) this.shootProjectile3D(p3);
                }
                if (key === 'k' || key === 'x' || key === 'shift') {
                    this.gamepadState.btnX = true;
                    const p3 = this.getPlayer3D();
                    if (p3) this.triggerDash3D(p3);
                }
                if (key === 'c' || key === 'v') {
                    this.cycleCamera3DMode();
                }
            } else {
                if (key === 'w' || key === 'arrowup' || key === ' ') {
                    this.gamepadState.btnA = true;
                    this.gamepadState.dpad.up = true;
                    const p = this.getPlayer();
                    if (p) p.jumpBufferTimer = this.jumpBuffer;
                }
                if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = true;
                if (key === 'j' || key === 'z' || key === 'enter') {
                    this.gamepadState.btnB = true;
                    const p = this.getPlayer();
                    if (p && !this.gameOver && !this.gameWon) this.shootProjectile(p);
                }
                if (key === 'k' || key === 'x' || key === 'shift') {
                    this.gamepadState.btnX = true;
                    const p = this.getPlayer();
                    if (p) this.triggerDash(p);
                }
            }

            if (key === 'r') {
                if (this.gameOver || this.gameWon || this.is3DMode) {
                    if (this.gameOver || this.gameWon) this.restartGame();
                }
            }
            if ((key === 'p' || key === 'escape') && !e.repeat) {
                if (this.isRunning && !this.gameOver && !this.gameWon) {
                    this.paused = !this.paused;
                    this.log(this.paused ? '⏸️ Juego en pausa [P/Esc para reanudar]' : '▶️ Juego reanudado', 'system');
                }
            }
            
            this.triggerEvent('keydown', e.key);
        });
        
        window.addEventListener('keyup', (e) => {
            const key = e.key.toLowerCase();
            this.keysDown[key] = false;
            this.keysDown[e.code.toLowerCase()] = false;
            
            if (key === 'a' || key === 'arrowleft') this.gamepadState.dpad.left = false;
            if (key === 'd' || key === 'arrowright') this.gamepadState.dpad.right = false;
            if (this.is3DMode) {
                if (key === 'w' || key === 'arrowup') this.gamepadState.dpad.up = false;
                if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = false;
                if (key === ' ') this.gamepadState.btnA = false;
            } else {
                if (key === 'w' || key === 'arrowup' || key === ' ') {
                    this.gamepadState.btnA = false;
                    this.gamepadState.dpad.up = false;
                }
                if (key === 's' || key === 'arrowdown') this.gamepadState.dpad.down = false;
            }
            if (key === 'j' || key === 'z' || key === 'f' || key === 'enter') this.gamepadState.btnB = false;
            if (key === 'k' || key === 'x' || key === 'shift') this.gamepadState.btnX = false;
            
            this.triggerEvent('keyup', e.key);
        });
        
        this.canvas.addEventListener('mousemove', (e) => {
            const rect = this.canvas.getBoundingClientRect();
            const scaleX = this.canvas.width / rect.width;
            const scaleY = this.canvas.height / rect.height;
            const mx = (e.clientX - rect.left) * scaleX;
            const my = (e.clientY - rect.top) * scaleY;

            if (this.is3DMode && this.dragOrbit.active) {
                const dx = mx - this.dragOrbit.lastX;
                const dy = my - this.dragOrbit.lastY;
                if (Math.abs(dx) > 2 || Math.abs(dy) > 2) this.dragOrbit.moved = true;
                this.camera3D.yawOffset += dx * 0.0065;
                this.camera3D.pitchOffset = Math.max(-0.15, Math.min(0.95, this.camera3D.pitchOffset + dy * 0.0045));
                this.dragOrbit.lastX = mx;
                this.dragOrbit.lastY = my;
            }

            this.mousePos.x = mx;
            this.mousePos.y = my;
        });
        
        this.canvas.addEventListener('mousedown', (e) => {
            ensureAudio();
            this.isMouseDown = true;
            this.triggerEvent('click', this.mousePos);

            if (this.gameOver || this.gameWon) {
                this.restartGame();
                return;
            }

            // 3D Camera Mode Pill Click (Top-Right under radar/score)
            if (this.is3DMode && this.camPillBounds) {
                const b = this.camPillBounds;
                if (this.mousePos.x >= b.x && this.mousePos.x <= b.x + b.w &&
                    this.mousePos.y >= b.y && this.mousePos.y <= b.y + b.h) {
                    this.cycleCamera3DMode();
                    return;
                }
            }

            // Interactive Button Click Dispatcher (CS Button System)
            let hitUIButton = false;
            for (let elem of this.renderQueue) {
                if (elem.type === 'button') {
                    if (this.mousePos.x >= elem.x && this.mousePos.x <= elem.x + elem.w &&
                        this.mousePos.y >= elem.y && this.mousePos.y <= elem.y + elem.h) {
                        
                        hitUIButton = true;
                        elem.isPressed = true;
                        this.log(`[BUTTON CLICK] Triggered action: "${elem.action || elem.text}"`, 'success');
                        this.playSfx('coin');

                        if (elem.action && typeof this.functions[elem.action] === 'function') {
                            this.functions[elem.action]();
                        } else if (elem.action && this.functions[elem.action] && this.functions[elem.action].body) {
                            this.executeSubScript(this.functions[elem.action].body);
                        } else if (elem.action === 'launch_arcade' || elem.action === 'launch_forkar') {
                            this.log(`[LAUNCHER] Booting game module: ${elem.action} @ 60 FPS...`, 'system');
                        }
                    }
                }
            }

            if (this.is3DMode && !hitUIButton && this.mousePos.y < this.canvas.height - 130) {
                this.dragOrbit.active = true;
                this.dragOrbit.lastX = this.mousePos.x;
                this.dragOrbit.lastY = this.mousePos.y;
                this.dragOrbit.moved = false;
            }

            // Check touch controls click / tap
            this.handleVirtualControlClick(this.mousePos.x, this.mousePos.y, true);
        });
        
        window.addEventListener('mouseup', () => {
            if (this.is3DMode && this.dragOrbit.active && !this.dragOrbit.moved) {
                const p3 = this.getPlayer3D();
                if (p3 && !this.gameOver && !this.gameWon && this.mousePos.y < this.canvas.height - 130) {
                    this.shootProjectile3D(p3);
                }
            }
            this.dragOrbit.active = false;
            this.isMouseDown = false;
            for (let elem of this.renderQueue) {
                if (elem.type === 'button') elem.isPressed = false;
            }
            this.handleVirtualControlClick(0, 0, false);
        });

        // Touch Listeners for Mobile & iPad (Universal Responsive Controls)
        const handleTouch = (e) => {
            ensureAudio();
            this.touchState.hasTouch = true;
            const rect = this.canvas.getBoundingClientRect();
            const scaleX = this.canvas.width / rect.width;
            const scaleY = this.canvas.height / rect.height;

            if (this.gameOver || this.gameWon) {
                this.restartGame();
                return;
            }

            // Reset touch state
            this.touchState.left = false;
            this.touchState.right = false;
            this.touchState.up = false;
            this.touchState.down = false;
            this.touchState.stickX = 0;
            this.touchState.stickY = 0;
            this.touchState.btnA = false;
            this.touchState.btnB = false;
            this.touchState.btnX = false;

            for (let i = 0; i < e.touches.length; i++) {
                const t = e.touches[i];
                const tx = (t.clientX - rect.left) * scaleX;
                const ty = (t.clientY - rect.top) * scaleY;
                this.evaluateTouchCoordinate(tx, ty);
            }
        };

        this.canvas.addEventListener('touchstart', (e) => {
            e.preventDefault();
            handleTouch(e);
        }, { passive: false });

        this.canvas.addEventListener('touchmove', (e) => {
            e.preventDefault();
            handleTouch(e);
        }, { passive: false });

        this.canvas.addEventListener('touchend', (e) => {
            e.preventDefault();
            if (e.touches.length === 0) {
                this.touchState.left = false;
                this.touchState.right = false;
                this.touchState.up = false;
                this.touchState.down = false;
                this.touchState.stickX = 0;
                this.touchState.stickY = 0;
                this.touchState.btnA = false;
                this.touchState.btnB = false;
                this.touchState.btnX = false;
            } else {
                handleTouch(e);
            }
        }, { passive: false });
    }

    evaluateTouchCoordinate(tx, ty) {
        const h = this.canvas.height;
        const w = this.canvas.width;

        if (this.is3DMode) {
            // 3D Virtual Analog Stick (Bottom-Left)
            const cx = 78;
            const cy = h - 74;
            const dx = tx - cx;
            const dy = ty - cy;
            const dist = Math.hypot(dx, dy);
            if (tx < 185 && ty > h - 165) {
                const maxR = 46;
                const clamped = Math.min(dist, maxR) / maxR;
                const ang = Math.atan2(dy, dx);
                this.touchState.stickX = Math.cos(ang) * clamped;
                this.touchState.stickY = -Math.sin(ang) * clamped;
                if (this.touchState.stickX < -0.25) this.touchState.left = true;
                if (this.touchState.stickX > 0.25) this.touchState.right = true;
                if (this.touchState.stickY > 0.25) this.touchState.up = true;
                if (this.touchState.stickY < -0.25) this.touchState.down = true;
            }
            // 3D Action Buttons (Bottom-Right: A=Jump, B=Plasma, X=Dash)
            if (tx > w - 210 && ty > h - 140) {
                const p3 = this.getPlayer3D();
                if (tx > w - 74) {
                    this.touchState.btnA = true;
                    if (p3) p3.jumpBufferTimer = this.jumpBuffer;
                } else if (tx > w - 138) {
                    this.touchState.btnB = true;
                    if (p3 && !this.gameOver && !this.gameWon) this.shootProjectile3D(p3);
                } else {
                    this.touchState.btnX = true;
                    if (p3) this.triggerDash3D(p3);
                }
            }
            return;
        }

        // Bottom Left D-Pad region (2D)
        if (tx < 180 && ty > h - 140) {
            if (tx < 85) this.touchState.left = true;
            else if (tx > 95) this.touchState.right = true;
            if (ty < h - 70) this.touchState.up = true;
        }

        // Bottom Right Action buttons region (2D)
        if (tx > w - 180 && ty > h - 140) {
            if (tx > w - 90) {
                this.touchState.btnA = true; // Jump
                const p = this.getPlayer();
                if (p) p.jumpBufferTimer = this.jumpBuffer;
            } else {
                this.touchState.btnB = true; // Shoot
                const p = this.getPlayer();
                if (p && !this.gameOver && !this.gameWon) this.shootProjectile(p);
            }
        }
    }

    handleVirtualControlClick(x, y, isDown) {
        if (!isDown) {
            this.touchState.left = false;
            this.touchState.right = false;
            this.touchState.up = false;
            this.touchState.down = false;
            this.touchState.stickX = 0;
            this.touchState.stickY = 0;
            this.touchState.btnA = false;
            this.touchState.btnB = false;
            this.touchState.btnX = false;
            return;
        }
        this.evaluateTouchCoordinate(x, y);
    }

    getPlayer() {
        return this.gameEntities.find(e => e.isPlayer);
    }

    triggerDash(player) {
        if (player.dashCooldown <= 0 && !this.gameOver && !this.gameWon) {
            player.isDashing = true;
            player.dashTimer = 0.18;
            player.dashCooldown = 0.6;
            player.vx = (player.facing || 1) * 620;
            player.vy = 0;
            this.playSfx('dash');
            this.spawnParticleBurst(player.x + player.w / 2, player.y + player.h / 2, '#00f5d4', 22);
            this.addPopup(player.x, player.y - 12, 'DASH!', '#00f5d4');
        }
    }

    shootProjectile(player) {
        const now = performance.now();
        const cooldown = player.overdrive ? 130 : 200;
        if (player.lastShotTime && now - player.lastShotTime < cooldown) return;
        player.lastShotTime = now;

        const dir = player.facing || 1;
        const isOver = Boolean(player.overdrive);
        const pw = isOver ? 24 : 14;
        const ph = isOver ? 9 : 5;
        const px = dir > 0 ? player.x + player.w + 2 : player.x - pw;
        const py = player.y + player.h * (isOver ? 0.36 : 0.42);
        const pColor = isOver ? '#ef4444' : (player.color || '#38bdf8');

        this.projectiles.push({
            type: 'projectile',
            x: px,
            y: py,
            vx: dir * (isOver ? 700 : 580),
            vy: 0,
            w: pw,
            h: ph,
            color: pColor,
            isPlayer: true,
            damage: isOver ? 65 : 25,
            life: 1.5
        });

        this.playSfx('shoot');
        this.spawnParticleBurst(px, py, pColor, isOver ? 12 : 6);
    }

    // ── Web Audio Synthesizer (Crystal Clear & Hardware-Optimized) ──
    playSfx(type) {
        try {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            if (!this.audioCtx) this.audioCtx = new AudioCtx();
            if (this.audioCtx.state === 'suspended') this.audioCtx.resume();

            const ctx = this.audioCtx;
            const now = ctx.currentTime;
            const masterGain = ctx.createGain();
            masterGain.gain.setValueAtTime(0.35, now); // Global volume cap
            masterGain.connect(ctx.destination);

            if (type === 'jump') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(280, now);
                osc.frequency.exponentialRampToValueAtTime(740, now + 0.12);
                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
                osc.connect(gain);
                gain.connect(masterGain);
                osc.start(now);
                osc.stop(now + 0.12);
            } else if (type === 'double_jump') {
                const osc = ctx.createOscillator();
                const noise = this.createNoiseBuffer(0.08);
                const noiseNode = ctx.createBufferSource();
                const noiseGain = ctx.createGain();
                noiseNode.buffer = noise;
                noiseGain.gain.setValueAtTime(0.1, now);
                noiseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

                osc.type = 'triangle';
                osc.frequency.setValueAtTime(560, now);
                osc.frequency.exponentialRampToValueAtTime(1080, now + 0.15);
                const gain = ctx.createGain();
                gain.gain.setValueAtTime(0.16, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

                osc.connect(gain);
                gain.connect(masterGain);
                noiseNode.connect(noiseGain);
                noiseGain.connect(masterGain);
                osc.start(now);
                osc.stop(now + 0.15);
                noiseNode.start(now);
            } else if (type === 'dash') {
                const osc = ctx.createOscillator();
                const osc2 = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sawtooth';
                osc2.type = 'square';
                osc.frequency.setValueAtTime(420, now);
                osc.frequency.exponentialRampToValueAtTime(80, now + 0.18);
                osc2.frequency.setValueAtTime(210, now);
                osc2.frequency.exponentialRampToValueAtTime(40, now + 0.18);
                gain.gain.setValueAtTime(0.14, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
                osc.connect(gain);
                osc2.connect(gain);
                gain.connect(masterGain);
                osc.start(now);
                osc2.start(now);
                osc.stop(now + 0.18);
                osc2.stop(now + 0.18);
            } else if (type === 'coin') {
                const osc1 = ctx.createOscillator();
                const osc2 = ctx.createOscillator();
                const gain = ctx.createGain();
                osc1.type = 'sine';
                osc2.type = 'sine';
                osc1.frequency.setValueAtTime(987.77, now); // B5
                osc2.frequency.setValueAtTime(1318.51, now + 0.06); // E6
                gain.gain.setValueAtTime(0.14, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.28);
                osc1.connect(gain);
                osc2.connect(gain);
                gain.connect(masterGain);
                osc1.start(now);
                osc1.stop(now + 0.1);
                osc2.start(now + 0.06);
                osc2.stop(now + 0.28);
            } else if (type === 'hurt') {
                const osc = ctx.createOscillator();
                const noise = this.createNoiseBuffer(0.2);
                const noiseNode = ctx.createBufferSource();
                const noiseGain = ctx.createGain();
                noiseNode.buffer = noise;
                noiseGain.gain.setValueAtTime(0.3, now);
                noiseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);

                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(140, now);
                osc.frequency.linearRampToValueAtTime(40, now + 0.15);
                const oscGain = ctx.createGain();
                oscGain.gain.setValueAtTime(0.2, now);
                oscGain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

                osc.connect(oscGain);
                oscGain.connect(masterGain);
                noiseNode.connect(noiseGain);
                noiseGain.connect(masterGain);
                osc.start(now);
                osc.stop(now + 0.15);
                noiseNode.start(now);
            } else if (type === 'shoot') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'square';
                osc.frequency.setValueAtTime(1200, now);
                osc.frequency.exponentialRampToValueAtTime(100, now + 0.1);
                gain.gain.setValueAtTime(0.08, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
                osc.connect(gain);
                gain.connect(masterGain);
                osc.start(now);
                osc.stop(now + 0.1);
            } else if (type === 'pad') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(160, now);
                osc.frequency.exponentialRampToValueAtTime(940, now + 0.25);
                gain.gain.setValueAtTime(0.2, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
                osc.connect(gain);
                gain.connect(masterGain);
                osc.start(now);
                osc.stop(now + 0.25);
            } else if (type === 'stomp') {
                const osc = ctx.createOscillator();
                const gain = ctx.createGain();
                osc.type = 'square';
                osc.frequency.setValueAtTime(220, now);
                osc.frequency.exponentialRampToValueAtTime(60, now + 0.16);
                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
                osc.connect(gain);
                gain.connect(masterGain);
                osc.start(now);
                osc.stop(now + 0.16);
            } else if (type === 'heal') {
                const notes = [523.25, 659.25, 783.99]; // C5, E5, G5
                notes.forEach((freq, idx) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    const t = now + idx * 0.08;
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(freq, t);
                    gain.gain.setValueAtTime(0.12, t);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
                    osc.connect(gain);
                    gain.connect(masterGain || ctx.destination);
                    osc.start(t);
                    osc.stop(t + 0.18);
                });
            } else if (type === 'victory') {
                const notes = [587.33, 739.99, 880.00, 1174.66]; // D5, F#5, A5, D6
                notes.forEach((freq, idx) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    const t = now + idx * 0.11;
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(freq, t);
                    gain.gain.setValueAtTime(0.16, t);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2);
                    osc.connect(gain);
                    gain.connect(masterGain || ctx.destination);
                    osc.start(t);
                    osc.stop(t + 0.2);
                });
            } else if (type === 'gameover') {
                const notes = [349.23, 311.13, 277.18, 220.00];
                notes.forEach((freq, idx) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    const t = now + idx * 0.14;
                    osc.type = 'sawtooth';
                    osc.frequency.setValueAtTime(freq, t);
                    gain.gain.setValueAtTime(0.14, t);
                    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.22);
                    osc.connect(gain);
                    gain.connect(masterGain || ctx.destination);
                    osc.start(t);
                    osc.stop(t + 0.22);
                });
            }
        } catch (e) { console.error("Sound Synthesis Error:", e); }
    }

    createNoiseBuffer(duration) {
        if (!this.audioCtx) return null;
        const bufferSize = this.audioCtx.sampleRate * duration;
        const buffer = this.audioCtx.createBuffer(1, bufferSize, this.audioCtx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
            data[i] = Math.random() * 2 - 1;
        }
        return buffer;
    }

    addPopup(x, y, text, color = '#38bdf8') {
        this.popups.push({
            x: x,
            y: y,
            text: text,
            color: color,
            alpha: 1.0,
            vy: -48
        });
    }

    triggerGameOver() {
        if (this.gameOver) return;
        this.gameOver = true;
        this.playSfx('gameover');
        this.camera.shake = 16;
        this.log('💀 [GAME OVER] Operación terminada. Presiona [R] o Toca para Reintentar.', 'error');
    }

    triggerVictory() {
        if (this.gameWon) return;
        this.gameWon = true;
        this.score += 500;
        this.playSfx('victory');
        this.log(`🏆 [VICTORY] ¡Etapa completada con éxito! Puntaje Final: ${this.score}`, 'success');
    }

    restartGame() {
        this.log('🔄 Reiniciando misión Shine Loop...', 'system');
        this.score = 0;
        this.lives = this.maxLives;
        this.gameOver = false;
        this.gameWon = false;
        if (this.sourceCode) {
            this.execute(this.sourceCode);
        }
    }

    log(message, type = 'info') {
        if (typeof this.terminalOutput === 'function') {
            this.terminalOutput(message, type);
        } else {
            console.log(`[Holo-Looping-${type.toUpperCase()}]:`, message);
        }
    }

    reset() {
        if (this.animationFrameId) {
            cancelAnimationFrame(this.animationFrameId);
            this.animationFrameId = null;
        }
        this.isRunning = false;
        this.variables = {};
        this.functions = {};
        this.gameEntities = [];
        this.renderQueue = [];
        this.particles = [];
        this.projectiles = [];
        this.popups = [];
        this.timeScale = 1.0;
        this.combo = 0;
        this.comboTimer = 0;
        this.scenario = { name: 'Holo Cyber Stage', weather: 'stars', bg: '#06090f', accent: '#38bdf8' };
        this.camera = { x: 0, y: 0, targetX: 0, targetY: 0, smooth: 0.12, shake: 0 };
        this.world = { width: this.canvas ? this.canvas.width : 1200, height: this.canvas ? this.canvas.height : 480, hasCustomBounds: false };
        this.init3DState();
        this.gameOver = false;
        this.gameWon = false;
        this.paused = false;
        this.hitstopTimer = 0;
        this.keysDown = {};
        this.prevGamepadButtons = {};
        if (this.gamepadState) {
            this.gamepadState.dpad = { left: false, right: false, up: false, down: false };
            this.gamepadState.axisX = 0;
            this.gamepadState.axisY = 0;
            this.gamepadState.axisCamX = 0;
            this.gamepadState.btnA = false;
            this.gamepadState.btnB = false;
            this.gamepadState.btnX = false;
            this.gamepadState.btnY = false;
        }
        if (this.ctx && this.canvas) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }

    // ── AST & Lexer Compiler ──
    execute(code) {
        this.sourceCode = code;
        this.reset();
        this.log(`⚙️ Compilando Código Fuente ${this.channelName} v${this.engineVersion} (Arch ${this.archVersion})...`, "system");
        
        const lines = code.split(/\r?\n/);
        let i = 0;

        while (i < lines.length) {
            const rawLine = lines[i];
            let line = rawLine.trim();
            i++;

            if (!line || line.startsWith('#') || line.startsWith('//')) continue;

            // Embedded Looping Snippet Block: insert snippet as <name>:
            if (line.startsWith('insert snippet')) {
                const snipMatch = line.match(/insert snippet\s+(?:as\s+)?([A-Za-z0-9_]+)\s*[:{]?/);
                if (snipMatch) {
                    const snipName = snipMatch[1];
                    const baseIndent = rawLine.search(/\S|$/);
                    const bodyLines = [];
                    while (i < lines.length) {
                        const nextRaw = lines[i];
                        const nextTrim = nextRaw.trim();
                        if (!nextTrim || nextTrim.startsWith('#') || nextTrim.startsWith('//')) {
                            i++;
                            continue;
                        }
                        if (nextTrim === '}' || nextTrim === 'end') {
                            i++;
                            break;
                        }
                        const nextIndent = nextRaw.search(/\S|$/);
                        if (line.endsWith(':') && nextIndent <= baseIndent) {
                            break;
                        }
                        bodyLines.push(nextTrim);
                        i++;
                    }
                    this.functions[snipName] = { params: [], body: bodyLines.join('\n') };
                    this.log(`[SNIPPET] Registrado bloque embebido: "${snipName}"`, 'system');
                    continue;
                }
            }

            // Multiline C# Block: cs! { ... } / csharp! { ... } / cs { ... } / cs: ... end
            if (line.startsWith('cs! {') || line.startsWith('csharp! {') ||
                line.startsWith('cs {') || line.startsWith('csharp {') ||
                line === 'csharp:' || line === 'cs:' || line === 'cs:begin') {
                const csLines = [];
                if (line.includes('{')) {
                    const ob = line.indexOf('{');
                    const after = line.slice(ob + 1);
                    let depth = 1;
                    for (const ch of after) { if (ch === '{') depth++; else if (ch === '}') depth--; }
                    if (depth <= 0) {
                        const rb = after.lastIndexOf('}');
                        csLines.push(rb >= 0 ? after.slice(0, rb) : after);
                    } else {
                        if (after.trim()) csLines.push(after);
                        while (i < lines.length && depth > 0) {
                            const nl = lines[i++];
                            for (const ch of nl) { if (ch === '{') depth++; else if (ch === '}') depth--; }
                            if (depth <= 0) {
                                const rb = nl.lastIndexOf('}');
                                if (rb > 0) csLines.push(nl.slice(0, rb));
                                break;
                            }
                            if (nl.trim() === 'cs:end') break;
                            csLines.push(nl);
                        }
                    }
                } else {
                    while (i < lines.length) {
                        const nl = lines[i++];
                        const tn = nl.trim();
                        if (tn === 'end' || tn === 'cs:end') break;
                        csLines.push(nl);
                    }
                }
                const csCode = csLines.join('\n');
                this.csharpBridge.executeBlock(csCode);
                this.log(`⚡ [C# BRIDGE] Bloque C# ejecutado (${Object.keys(this.csharpBridge.classes).length} clases MonoBehaviour)`, 'system');
                continue;
            }

            // Embedded C# Snippet: insert cssnippet as <name>:
            if (line.startsWith('insert cssnippet') || line.startsWith('cssnippet ')) {
                const csm = line.match(/(?:insert\s+)?(?:cs|csharp)snippet\s+(?:as\s+)?([A-Za-z0-9_]+)\s*[:{]?/);
                if (csm) {
                    const sName = csm[1];
                    const baseIndent = rawLine.search(/\S|$/);
                    const sLines = [];
                    while (i < lines.length) {
                        const nextRaw = lines[i];
                        const nextTrim = nextRaw.trim();
                        if (nextTrim === '}' || nextTrim === 'end' || nextTrim === 'cs:end') { i++; break; }
                        if (line.endsWith(':') && nextTrim && nextRaw.search(/\S|$/) <= baseIndent) break;
                        sLines.push(nextRaw);
                        i++;
                    }
                    this.csharpBridge.snippets[sName] = sLines.join('\n');
                    this.variables[sName] = this.csharpBridge.snippets[sName];
                    this.log(`[C# SNIPPET] Registrado cssnippet "${sName}"`, 'system');
                    continue;
                }
            }

            // Multiline Python Block: python { ... } OR py: ... end
            if (line.startsWith('python {') || line === 'python:' || line === 'py:' || line.startsWith('py:begin')) {
                let pyBlockLines = [];
                if (line.startsWith('python {') && line.endsWith('}')) {
                    pyBlockLines.push(line.slice(8, -1).trim());
                } else {
                    while (i < lines.length) {
                        const nextLine = lines[i];
                        i++;
                        const trimmedNext = nextLine.trim();
                        if (trimmedNext === '}' || trimmedNext === 'end' || trimmedNext === 'py:end') {
                            break;
                        }
                        pyBlockLines.push(nextLine);
                    }
                }
                const pyCode = pyBlockLines.join('\n');
                this.log(`[PYTHON BLOCK] Interpretando módulo Python integrado (${pyBlockLines.length} líneas)...`, 'system');
                this.executePythonSimulation(pyCode);
                continue;
            }

            // Function Definition: function <name>(<args>) { ... }
            if (line.startsWith('function ') || line.startsWith('def ')) {
                const fnMatch = line.match(/(?:function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)\s*[:{]?/);
                if (fnMatch) {
                    const fnName = fnMatch[1];
                    const fnParams = fnMatch[2].split(',').map(s => s.trim()).filter(Boolean);
                    const baseIndent = rawLine.search(/\S|$/);
                    const bodyLines = [];

                    while (i < lines.length) {
                        const nextLine = lines[i];
                        const nextTrim = nextLine.trim();
                        if (!nextTrim) { i++; continue; }
                        if (nextTrim === '}' || nextTrim === 'end') { i++; break; }
                        if (line.endsWith(':') && nextLine.search(/\S|$/) <= baseIndent) break;
                        bodyLines.push(nextLine);
                        i++;
                    }

                    this.functions[fnName] = { params: fnParams, body: bodyLines.join('\n') };
                    this.log(`[FUNCTION] Registrada función "${fnName}" (${fnParams.length} parámetros)`, 'info');
                    continue;
                }
            }

            // Loop / Repeat: repeat <N> times { ... } OR loop <N> { ... }
            if (line.startsWith('repeat ') || line.startsWith('loop ')) {
                const countMatch = line.match(/(?:repeat|loop)\s+(\d+|[A-Za-z0-9_]+)\s*(?:times)?\s*[:{]?/i);
                if (countMatch) {
                    const countVal = Number(this.evaluateExpression(countMatch[1])) || 0;
                    const baseIndent = rawLine.search(/\S|$/);
                    const bodyLines = [];
                    while (i < lines.length) {
                        const nextLine = lines[i];
                        const nextTrim = nextLine.trim();
                        if (!nextTrim) { i++; continue; }
                        if (nextTrim === '}' || nextTrim === 'end') { i++; break; }
                        if (line.endsWith(':') && nextLine.search(/\S|$/) <= baseIndent) break;
                        bodyLines.push(nextLine);
                        i++;
                    }
                    const loopScript = bodyLines.join('\n');
                    for (let c = 0; c < countVal; c++) {
                        this.variables['i'] = c;
                        this.variables['loop_index'] = c;
                        this.executeSubScript(loopScript);
                    }
                    continue;
                }
            }

            try {
                this.parseLine(line);
            } catch (err) {
                this.log(`❌ [Syntax Error at line ${i}]: ${err.message}`, "error");
                return false;
            }
        }

        // Adjust world bounds if not explicitly set
        if (!this.is3DMode && !this.world.hasCustomBounds && this.canvas) {
            let maxX = this.canvas.width;
            for (let ent of this.gameEntities) {
                if (ent.x + (ent.w || 40) > maxX) maxX = ent.x + (ent.w || 40) + 100;
            }
            this.world.width = Math.max(this.canvas.width, maxX);
            this.world.height = this.canvas.height;
        }

        if (this.is3DMode) {
            const hz = 60 * (this.physics3D.substeps || 4);
            this.log(`✨ Compilación 3D Quantum Completa (${this.entities3D.length} entidades 3D | Física ${hz}Hz). Inicializando Z-Buffer @ 60 FPS...`, "success");
        } else {
            this.log("✨ Compilación 2D Completa. Inicializando pipeline gráfico Shine Loop @ 60 FPS...", "success");
        }
        this.startLoop();
        return true;
    }

    executeSubScript(script) {
        const lines = script.split(/\r?\n/);
        for (let l of lines) {
            let line = l.trim();
            if (!line || line.startsWith('#') || line.startsWith('//')) continue;
            this.parseLine(line);
        }
    }

    executePythonSimulation(pyCode) {
        try {
            const lines = pyCode.split('\n');
            for (let raw of lines) {
                const line = raw.trim();
                if (!line || line.startsWith('#')) continue;

                const assignMatch = line.match(/^([A-Za-z0-9_]+)\s*=\s*(.*)$/);
                if (assignMatch) {
                    const k = assignMatch[1];
                    const v = assignMatch[2];
                    this.variables[k] = this.evaluateExpression(v);
                } else if (line.startsWith('print(')) {
                    const pMatch = line.match(/print\((.*)\)/);
                    if (pMatch) {
                        this.log(`[PYTHON] ${this.parsePrint(pMatch[1])}`, 'output');
                    }
                }
            }
        } catch (e) {
            this.log(`[PYTHON ERROR] ${e.message}`, 'error');
        }
    }

    // Helper: Parse named arguments like ("Hero", at: (0, 2, 14), size: (6, 1, 8), color: "#38bdf8")
    parseNamedArgs(argStr) {
        const res = {};
        if (!argStr) return res;
        const trimmed = argStr.trim();

        // Extract optional leading positional string literal e.g. spawn3d.player("AngelPilot3D", at: ...)
        const leadStr = trimmed.match(/^(?:"([^"]*)"|'([^']*)')\s*(?:,|$)/);
        if (leadStr) {
            res._pos0 = leadStr[1] !== undefined ? leadStr[1] : leadStr[2];
            res.name = res._pos0;
        }

        const regex = /([A-Za-z0-9_]+)\s*:\s*(\([^)]+\)|\[[^\]]+\]|"[^"]*"|'[^']*'|[^,]+)/g;
        let match;
        while ((match = regex.exec(argStr)) !== null) {
            const key = match[1].trim();
            let val = match[2].trim();
            if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
                res[key] = val.slice(1, -1);
            } else if ((val.startsWith('(') && val.endsWith(')')) || (val.startsWith('[') && val.endsWith(']'))) {
                const parts = val.slice(1, -1).split(',').map(s => {
                    const st = s.trim();
                    if (st !== '' && !isNaN(st)) return parseFloat(st);
                    const ev = this.evaluateExpression(st);
                    return isNaN(ev) ? 0 : Number(ev);
                });
                res[key] = parts;
            } else if (val !== '' && !isNaN(val)) {
                res[key] = parseFloat(val);
            } else if (val === 'true') res[key] = true;
            else if (val === 'false') res[key] = false;
            else if (this.variables.hasOwnProperty(val)) res[key] = this.variables[val];
            else res[key] = val;
        }
        return res;
    }

    parseLine(line) {
        // 1. Module Imports (import / use)
        if (line.startsWith('import ') && !line.startsWith('import python ')) {
            const modulePath = line.replace('import ', '').trim();
            this.log(`[MODULE LOADER] Vinculado módulo: ${modulePath}`, 'system');
            return;
        }
        if (line.startsWith('use ') && !line.startsWith('use python ')) {
            const modName = line.replace('use ', '').trim().replace(/['"]/g, '');
            if (modName === 'loopize++') {
                this.log(`⚡ [LOOPIZE++ WEB] Módulo híbrido cargado (.obj + C# + ECS + Waves + FSM + Combo + Shake)`, 'success');
            } else {
                this.log(`[MODULE LOADER] Vinculado paquete smiledev: ${modName}`, 'system');
            }
            return;
        }

        // 1.1 Python Imports
        if (line.startsWith('use python ') || line.startsWith('import python ')) {
            const pyLib = line.replace(/^(use|import) python /, '').trim().replace(/['"]/g, '');
            this.log(`[PYTHON BRIDGE] Enlace de biblioteca: ${pyLib}`, 'system');
            return;
        }

        // 2. App, 2D Game & 3D Game Definition
        if (line.startsWith('define game3d') || line.startsWith('@game3d')) {
            this.is3DMode = true;
            let appName = 'QuantumOdyssey3D';
            const quoteMatch = line.match(/(?:define game3d|@game3d)\s*(?:as)?\s*["'](.*?)["']/);
            const asMatch = line.match(/define game3d\s+as\s+([A-Za-z0-9_]+)/);
            if (quoteMatch) appName = quoteMatch[1];
            else if (asMatch) appName = asMatch[1];
            this.scene3D.name = appName;
            this.log(`🕹️ [ENGINE 3D] Registrado título 3D: "${appName}" en Shine Loop Quantum 3D`, 'info');
            return;
        }

        if (line.startsWith('define app') || line.startsWith('define game') || line.startsWith('@app') || line.startsWith('@game')) {
            let appName = 'HoloGame';
            const quoteMatch = line.match(/(?:define (?:app|game)|@(?:app|game))\s*(?:as)?\s*["'](.*?)["']/);
            const asMatch = line.match(/define (?:app|game)\s+as\s+([A-Za-z0-9_]+)/);
            if (quoteMatch) appName = quoteMatch[1];
            else if (asMatch) appName = asMatch[1];
            
            this.log(`[APP] Registrado título: "${appName}" en Shine Loop Console`, 'info');
            return;
        }

        // 2.5 Explicit 2D / 3D Mode Switch & Scene3D / Camera3D / Light3D / Physics3D Directives
        if (line.startsWith('game.mode(') || line.startsWith('set mode to ')) {
            const m = line.match(/["'](2d|3d)["']/i);
            if (m) {
                this.is3DMode = m[1].toLowerCase() === '3d';
                this.log(`🎛️ [ENGINE MODE] Pipeline conmutado a: ${this.is3DMode ? '3D Quantum Perspective' : '2D Arcade'}`, 'system');
            }
            return;
        }

        if (line.startsWith('scene3d.') || line.startsWith('camera3d.') ||
            line.startsWith('light3d.') || line.startsWith('physics3d.config')) {
            this.parseScene3DDirective(line);
            return;
        }

        if (line.startsWith('spawn3d.') || line.startsWith('spawn 3d ') ||
            line.startsWith('spawn.player3d') || line.startsWith('spawn.cube') ||
            line.startsWith('spawn.sphere') || line.startsWith('spawn.pyramid') ||
            line.startsWith('spawn.cylinder') || line.startsWith('spawn.torus') ||
            line.startsWith('spawn.ring3d') || line.startsWith('spawn.crystal') ||
            line.startsWith('spawn.portal3d') || line.startsWith('spawn.obj')) {
            this.parseSpawn3DDirective(line);
            return;
        }

        // 3. UI System Profile & Invis. Compile Binary Directive
        if (line.startsWith('invis. compile') || line.startsWith('invis.compile') || line.startsWith('invis compile') || line.startsWith('compile invis') || line.startsWith('@invis_compile')) {
            const targetMatch = line.match(/for\s+([A-Za-z0-9_]+)/i);
            const toMatch = line.match(/to\s+["'](.*?)["']/i);
            const tgt = targetMatch ? targetMatch[1].toUpperCase() : (this.uiProfile || 'SHINE_UI').toUpperCase();
            const outBin = toMatch ? toMatch[1] : 'build/app.bin';
            this.log(`🔒 [INVIS. COMPILE] Binary pipeline LPBN v3.0A -> ${outBin} [Target: ${tgt} | SHA-256 CTR]`, 'success');
            return;
        }

        if (line.startsWith('set ui_profile to') || line.startsWith('set ui_profile as') || line.startsWith('set ui to')) {
            const match = line.match(/set (?:ui_profile|ui) (?:to|as) ["'](.*?)["']/);
            if (match) {
                this.uiProfile = match[1].toLowerCase();
                this.log(`[CS DESIGN UI] Perfil UI cargado: "${this.uiProfile.toUpperCase()}"`, 'info');
            }
            return;
        }

        // 4. Theme configuration
        if (line.startsWith('set theme to') || line.startsWith('set theme as')) {
            const match = line.match(/set theme (?:to|as) ["'](.*?)["']/);
            if (match) this.theme = match[1];
            return;
        }

        // 5. Game Configuration Directives (Gravity, World, Friction, Lives)
        if (line.startsWith('game.gravity(') || line.startsWith('set gravity to ')) {
            const m = line.match(/(?:game\.gravity\(|set gravity to\s+)([\d.]+)/);
            if (m) {
                this.gravity = parseFloat(m[1]);
                this.log(`[PHYSICS] Gravedad configurada: ${this.gravity} px/s²`, 'system');
            }
            return;
        }

        if (line.startsWith('game.friction(') || line.startsWith('set friction to ')) {
            const m = line.match(/(?:game\.friction\(|set friction to\s+)([\d.]+)/);
            if (m) {
                this.friction = parseFloat(m[1]);
                this.log(`[PHYSICS] Fricción de superficie: ${this.friction}`, 'system');
            }
            return;
        }

        if (line.startsWith('game.world(') || line.startsWith('set world_size to ')) {
            const sizeMatch = line.match(/\((\d+),\s*(\d+)\)/);
            if (sizeMatch) {
                this.world.width = parseInt(sizeMatch[1]);
                this.world.height = parseInt(sizeMatch[2]);
                this.world.hasCustomBounds = true;
                this.log(`[WORLD] Dimensiones de nivel configuradas: ${this.world.width}x${this.world.height}px`, 'info');
            }
            return;
        }

        if (line.startsWith('game.lives(') || line.startsWith('set lives to ')) {
            const m = line.match(/(?:game\.lives\(|set lives to\s+)(\d+)/);
            if (m) {
                this.lives = parseInt(m[1]);
                this.maxLives = this.lives;
                this.log(`[GAME] Vidas iniciales: ${this.lives}`, 'info');
            }
            return;
        }

        if (line.startsWith('game.scenario(') || line.startsWith('game.background(')) {
            const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
            const args = this.parseNamedArgs(inner);
            if (args.name) this.scenario.name = args.name;
            if (args.weather || args.theme) this.scenario.weather = args.weather || args.theme;
            if (args.bg) this.scenario.bg = args.bg;
            if (args.accent) this.scenario.accent = args.accent;
            this.log(`🌌 [SCENARIO] Escenario activo: "${this.scenario.name}" [Clima: ${this.scenario.weather}]`, 'info');
            return;
        }

        if (line.startsWith('game.physics(')) {
            const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
            const args = this.parseNamedArgs(inner);
            if (args.gravity !== undefined) this.gravity = Number(args.gravity);
            if (args.friction !== undefined) this.friction = Number(args.friction);
            if (args.time_scale !== undefined) this.timeScale = Number(args.time_scale);
            if (args.coyote_time !== undefined) this.coyoteTime = Number(args.coyote_time);
            this.log(`⚙️ [PHYSICS] Gravity: ${this.gravity} | Friction: ${this.friction} | TimeScale: ${this.timeScale}x`, 'system');
            return;
        }

        if (line.startsWith('game.time_scale(')) {
            const m = line.match(/game\.time_scale\(([\d.]+)\)/);
            if (m) {
                this.timeScale = parseFloat(m[1]);
                this.log(`⏱️ [TIME SCALE] Factor temporal: ${this.timeScale}x`, 'system');
            }
            return;
        }

        // 6. Window Canvas: create window with title "Title" and size (width, height)
        if (line.startsWith('create window')) {
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            if (sizeMatch && this.canvas) {
                this.canvas.width = parseInt(sizeMatch[1]);
                this.canvas.height = parseInt(sizeMatch[2]);
            }
            if (titleMatch) {
                this.log(` Modo de Visualización Shine Loop: "${titleMatch[1]}" (${this.canvas.width}x${this.canvas.height})`, 'info');
            }
            return;
        }

        // 7. Bubbly Dot Component
        if (line.startsWith('spawn bubbly_dot') || line.startsWith('draw bubbly_dot')) {
            const textMatch = line.match(/text ["'](.*?)["']/);
            const stateMatch = line.match(/state ["'](.*?)["']/);
            this.bubblyDot = {
                active: true,
                text: textMatch ? textMatch[1] : 'Shine Audio Active',
                state: stateMatch ? stateMatch[1] : 'music',
                pulse: 0
            };
            return;
        }

        // 8. Conditional Logic
        if (line.startsWith('if ')) {
            const conditionMatch = line.match(/^if\s+(.*?)\s+(?:then|do)\s+(.*)$/i);
            if (conditionMatch) {
                const condition = conditionMatch[1];
                const action = conditionMatch[2];
                if (this.evaluateCondition(condition)) {
                    this.parseLine(action);
                }
                return;
            }
        }

        // 9. Input Field UI Component
        if (line.startsWith('draw input at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            const placeMatch = line.match(/placeholder ["'](.*?)["']/);
            const varMatch = line.match(/var ["'](.*?)["']/);

            this.renderQueue.push({
                type: 'input',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 200,
                w: sizeMatch ? parseInt(sizeMatch[1]) : 260,
                h: sizeMatch ? parseInt(sizeMatch[2]) : 40,
                placeholder: placeMatch ? placeMatch[1] : 'Type here...',
                targetVar: varMatch ? varMatch[1] : 'user_input',
                value: ''
            });
            return;
        }

        // 10. Variables: val <var> [= | :=] <value> | var/let/mut <var> [= | :=] <value>
        if ((line.startsWith('val ') || line.startsWith('var ') || line.startsWith('let ') || line.startsWith('mut ')) && line.includes('=')) {
            const eqIdx = line.indexOf('=');
            const varName = line.slice(4, eqIdx).replace(/:$/, '').trim();
            const valExpr = line.slice(eqIdx + 1).trim();
            this.variables[varName] = this.evaluateExpression(valExpr);
            return;
        }

        if (line.startsWith('set ') && (line.includes(' to ') || line.includes(' as ') || line.includes(' = '))) {
            let delimiter = ' to ';
            if (line.includes(' to ')) delimiter = ' to ';
            else if (line.includes(' as ')) delimiter = ' as ';
            else if (line.includes(' = ')) delimiter = ' = ';

            const parts = line.replace('set ', '').split(delimiter);
            const varName = parts[0].trim();
            const valExpr = parts.slice(1).join(delimiter).trim();
            this.variables[varName] = this.evaluateExpression(valExpr);
            return;
        }

        // Functional Window & UI Directives (window.create / window.ui / ui.card / ui.button)
        if (line.startsWith('window.create(')) {
            const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
            const args = this.parseNamedArgs(inner);
            const title = args.title || args.name || 'Shine Loop Window';
            if (args.size && Array.isArray(args.size) && this.canvas) {
                this.canvas.width = parseInt(args.size[0]);
                this.canvas.height = parseInt(args.size[1]);
            }
            this.log(`🖥️ Ventana Shine Loop: "${title}" (${this.canvas ? this.canvas.width : 900}x${this.canvas ? this.canvas.height : 600})`, 'info');
            return;
        }

        if (line.startsWith('window.ui(')) {
            const m = line.match(/["'](.*?)["']/);
            if (m) {
                this.uiProfile = m[1].toLowerCase();
                this.log(`[CS DESIGN UI] Perfil UI cargado: "${this.uiProfile.toUpperCase()}"`, 'info');
            }
            return;
        }

        if (line.startsWith('ui.card(')) {
            const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
            const args = this.parseNamedArgs(inner);
            this.renderQueue.push({
                type: 'card',
                x: args.at ? args.at[0] : 20,
                y: args.at ? args.at[1] : 20,
                w: args.size ? args.size[0] : 280,
                h: args.size ? args.size[1] : 110,
                title: args.title || args.name || 'Holo UI Card',
                text: args.text || ''
            });
            return;
        }

        if (line.startsWith('ui.button(')) {
            const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
            const args = this.parseNamedArgs(inner);
            this.renderQueue.push({
                type: 'button',
                x: args.at ? args.at[0] : 20,
                y: args.at ? args.at[1] : 150,
                w: args.size ? args.size[0] : 190,
                h: args.size ? args.size[1] : 40,
                text: args.text || args.name || 'Shine Action',
                action: args.action || ''
            });
            return;
        }

        // Shorthand assignments: x = 10, x += 5
        const assignMatch = line.match(/^([A-Za-z0-9_]+)\s*(\+=|-=|\*=|\/=|=)\s*(.*)$/);
        if (assignMatch && !line.startsWith('create ') && !line.startsWith('draw ') && !line.startsWith('spawn ')) {
            const varName = assignMatch[1];
            const op = assignMatch[2];
            const expr = assignMatch[3];
            const val = this.evaluateExpression(expr);

            if (op === '=') this.variables[varName] = val;
            else if (op === '+=') this.variables[varName] = (Number(this.variables[varName]) || 0) + Number(val);
            else if (op === '-=') this.variables[varName] = (Number(this.variables[varName]) || 0) - Number(val);
            else if (op === '*=') this.variables[varName] = (Number(this.variables[varName]) || 0) * Number(val);
            else if (op === '/=') this.variables[varName] = (Number(this.variables[varName]) || 0) / Number(val);
            return;
        }

        // 11. Function Calls: call <fn>()
        if (line.startsWith('call ')) {
            const callMatch = line.match(/call\s+([A-Za-z0-9_]+)\s*(?:\((.*?)\))?/);
            if (callMatch) {
                const fnName = callMatch[1];
                if (this.functions[fnName]) {
                    this.executeSubScript(this.functions[fnName].body);
                }
                return;
            }
        }

        // 12. Print output: print ... | echo ... | print(...)
        if (line.startsWith('print(') && line.endsWith(')')) {
            const inner = line.slice(6, -1).trim();
            const val = this.parsePrint(inner);
            this.log(val, 'output');
            return;
        }
        if (line.startsWith('print ') || line.startsWith('echo ')) {
            const expr = line.replace(/^(print|echo)\s+/, '').trim();
            const val = this.parsePrint(expr);
            this.log(val, 'output');
            return;
        }

        // 13. System Calls & Kernel Control
        if (line.startsWith('syscall')) {
            const match = line.match(/syscall\s+([A-Za-z0-9_]+)(?:\s+with\s+args\s+["'](.*?)["'])?/);
            if (match) {
                this.log(`[KERNEL SYSCALL] 0x${Math.floor(Math.random() * 0xFFFFFF).toString(16).toUpperCase()} :: ${match[1]}() -> OK`, 'system');
            }
            return;
        }

        // 14. Hardware Audio Tone
        if (line.startsWith('play tone') || line.startsWith('audio.tone(')) {
            const freqMatch = line.match(/(?:at\s+|freq:\s*|tone\()(\d+)/i);
            const durMatch = line.match(/(?:for\s+|dur:\s*|,\s*)(\d+)\s*(?:ms|\))/i);
            const freq = freqMatch ? parseInt(freqMatch[1]) : 440;
            const dur = durMatch ? parseInt(durMatch[1]) : 100;
            try {
                if (!this.audioCtx) {
                    const AudioCtx = window.AudioContext || window.webkitAudioContext;
                    if (AudioCtx) this.audioCtx = new AudioCtx();
                }
                if (this.audioCtx) {
                    const ctx = this.audioCtx;
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(freq, ctx.currentTime);
                    gain.gain.setValueAtTime(0.1, ctx.currentTime);
                    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + (dur / 1000));
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start();
                    osc.stop(ctx.currentTime + (dur / 1000));
                }
            } catch (e) {}
            this.log(`[AUDIO HARDWARE] Tono sintetizado: ${freq}Hz (${dur}ms)`, 'system');
            return;
        }

        // 15. UI Card & Button
        if (line.startsWith('draw card at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
            const titleMatch = line.match(/title ["'](.*?)["']/);
            const textMatch = line.match(/text ["'](.*?)["']/);
            
            this.renderQueue.push({
                type: 'card',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 50,
                w: sizeMatch ? parseInt(sizeMatch[1]) : 300,
                h: sizeMatch ? parseInt(sizeMatch[2]) : 140,
                title: titleMatch ? titleMatch[1] : 'Holo UI Card',
                text: textMatch ? textMatch[1] : ''
            });
            return;
        }

        if (line.startsWith('draw button at')) {
            const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
            const textMatch = line.match(/text ["'](.*?)["']/);
            const actionMatch = line.match(/action ["'](.*?)["']/);
            
            this.renderQueue.push({
                type: 'button',
                x: posMatch ? parseInt(posMatch[1]) : 50,
                y: posMatch ? parseInt(posMatch[2]) : 200,
                w: 180,
                h: 44,
                text: textMatch ? textMatch[1] : 'Shine Action',
                action: actionMatch ? actionMatch[1] : ''
            });
            return;
        }

        // ═══════════════════════════════════════════════════════════════
        //  2D GAME ENTITY SPAWNERS (Classic & Modern Functional Syntax)
        // ═══════════════════════════════════════════════════════════════

        // 16. Player / Sprite: spawn sprite / spawn.sprite / spawn.player / spawn player
        if (line.startsWith('spawn sprite') || line.startsWith('spawn.sprite') || 
            line.startsWith('spawn.player') || line.startsWith('spawn player')) {
            
            let name = 'Angel Helium';
            let x = 100, y = 300, w = 34, h = 46;
            let color = '#38bdf8';
            let speed = 270;
            let jumpForce = 430;
            let health = 100;
            let doubleJump = true;

            if (line.includes('(') && (line.startsWith('spawn.sprite(') || line.startsWith('spawn.player('))) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.name) name = args.name;
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.color) color = args.color;
                if (args.speed) speed = args.speed;
                if (args.jump) jumpForce = args.jump;
                if (args.health) health = args.health;
                if (args.double_jump !== undefined) doubleJump = args.double_jump;
            } else {
                const nameMatch = line.match(/spawn (?:sprite|player)\s+["'](.*?)["']/);
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                if (nameMatch) name = nameMatch[1];
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (colorMatch) color = colorMatch[1];
            }

            const isPlayer = line.includes('player') || name.toLowerCase().includes('angel') || 
                             name.toLowerCase().includes('player') || name.toLowerCase().includes('hero');

            const sprite = {
                type: 'sprite',
                name: name,
                isPlayer: isPlayer,
                x: x,
                y: y,
                spawnX: x,
                spawnY: y,
                w: w,
                h: h,
                vx: 0,
                vy: 0,
                speed: speed,
                jumpForce: jumpForce,
                health: health,
                maxHealth: health,
                color: color,
                facing: 1,
                isJumping: false,
                doubleJumpAvailable: doubleJump,
                canDoubleJump: doubleJump,
                coyoteTimer: 0,
                jumpBufferTimer: 0,
                isDashing: false,
                dashTimer: 0,
                dashCooldown: 0,
                invulnerableTimer: 0,
                teleportCooldown: 0,
                overdrive: false,
                squash: 1.0,
                stretch: 1.0,
                glowPulse: 0,
                lastShotTime: 0
            };

            this.gameEntities.push(sprite);
            this.log(`🎮 Entidad 2D generada: "${sprite.name}" (${isPlayer ? 'PROTAGONISTA' : 'NPC'})`, 'info');
            return;
        }

        // 17. Enemy NPC: spawn enemy / spawn.enemy
        if (line.startsWith('spawn enemy') || line.startsWith('spawn.enemy')) {
            let name = 'CorruptedDrone';
            let x = 460, y = 300, w = 34, h = 44;
            let color = '#ef4444';
            let minX = 350, maxX = 620;
            let speed = 75;
            let health = 30;

            if (line.includes('(') && line.startsWith('spawn.enemy(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.name) name = args.name;
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.range && Array.isArray(args.range)) { minX = args.range[0]; maxX = args.range[1]; }
                if (args.color) color = args.color;
                if (args.speed) speed = args.speed;
                if (args.health) health = args.health;
            } else {
                const nameMatch = line.match(/spawn enemy\s+["'](.*?)["']/);
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const rangeMatch = line.match(/range \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (nameMatch) name = nameMatch[1];
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (rangeMatch) { minX = parseFloat(rangeMatch[1]); maxX = parseFloat(rangeMatch[2]); }
                else { minX = x - 120; maxX = x + 120; }
                if (colorMatch) color = colorMatch[1];
            }

            const enemy = {
                type: 'enemy',
                name: name,
                x: x,
                y: y,
                w: w,
                h: h,
                vx: speed,
                vy: 0,
                speed: speed,
                dir: 1,
                minX: minX,
                maxX: maxX,
                health: health,
                maxHealth: health,
                color: color,
                isAlive: true,
                glowPulse: 0
            };
            this.gameEntities.push(enemy);
            this.log(`👾 Enemigo autónomo desplegado: "${enemy.name}" [Patrulla: ${minX}-${maxX}]`, 'info');
            return;
        }

        // 18. Moving Platform: spawn moving_platform / spawn.moving_platform
        if (line.startsWith('spawn moving_platform') || line.startsWith('spawn.moving_platform')) {
            let x = 250, y = 280, w = 130, h = 18;
            let axis = 'x';
            let minP = 200, maxP = 450;
            let speed = 75;
            let color = '#06b6d4';

            if (line.includes('(') && line.startsWith('spawn.moving_platform(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.axis) axis = args.axis;
                if (args.range && Array.isArray(args.range)) { minP = args.range[0]; maxP = args.range[1]; }
                if (args.speed) speed = args.speed;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const axisMatch = line.match(/axis ["'](.*?)["']/);
                const rangeMatch = line.match(/range \((\d+),\s*(\d+)\)/);
                const speedMatch = line.match(/speed (\d+)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (axisMatch) axis = axisMatch[1];
                if (rangeMatch) { minP = parseFloat(rangeMatch[1]); maxP = parseFloat(rangeMatch[2]); }
                else { minP = x; maxP = x + 180; }
                if (speedMatch) speed = parseFloat(speedMatch[1]);
                if (colorMatch) color = colorMatch[1];
            }

            const mp = {
                type: 'moving_platform',
                x: x,
                y: y,
                w: w,
                h: h,
                axis: axis,
                minPos: minP,
                maxPos: maxP,
                speed: speed,
                dir: 1,
                vx: axis === 'x' ? speed : 0,
                vy: axis === 'y' ? speed : 0,
                color: color
            };
            this.gameEntities.push(mp);
            this.log(` Maglev Plataforma Móvil en (${x}, ${y}) [Eje ${axis.toUpperCase()} | Rango ${minP}-${maxP}]`, 'info');
            return;
        }

        // 19. Static Platform: spawn platform / spawn.platform
        if (line.startsWith('spawn platform') || line.startsWith('spawn.platform')) {
            let x = 200, y = 300, w = 160, h = 18;
            let color = '#6366f1';

            if (line.includes('(') && line.startsWith('spawn.platform(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (colorMatch) color = colorMatch[1];
            }

            const platform = {
                type: 'platform',
                x: x,
                y: y,
                w: w,
                h: h,
                color: color
            };
            this.gameEntities.push(platform);
            return;
        }

        // 20. Spikes / Hazards: spawn spike / spawn hazard / spawn.spike
        if (line.startsWith('spawn spike') || line.startsWith('spawn hazard') || line.startsWith('spawn.spike')) {
            let x = 300, y = 420, w = 34, h = 20;
            let damage = 35;
            let color = '#ef4444';

            if (line.includes('(') && line.startsWith('spawn.spike(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.damage) damage = args.damage;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const sizeMatch = line.match(/size \((\d+),\s*(\d+)\)/);
                const damMatch = line.match(/damage (\d+)/);
                const colMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (sizeMatch) { w = parseFloat(sizeMatch[1]); h = parseFloat(sizeMatch[2]); }
                if (damMatch) damage = parseFloat(damMatch[1]);
                if (colMatch) color = colMatch[1];
            }

            const spike = {
                type: 'spike',
                x: x,
                y: y,
                w: w,
                h: h,
                damage: damage,
                color: color
            };
            this.gameEntities.push(spike);
            this.log(`⚠️ Trampa de Picos Neón en (${x}, ${y})`, 'info');
            return;
        }

        // 21. Jump Pad: spawn jump_pad / spawn pad / spawn.pad
        if (line.startsWith('spawn jump_pad') || line.startsWith('spawn pad') || line.startsWith('spawn.pad')) {
            let x = 200, y = 420, w = 44, h = 14;
            let power = 650;
            let color = '#fbbf24';

            if (line.includes('(') && line.startsWith('spawn.pad(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.power) power = args.power;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const powMatch = line.match(/power (\d+)/);
                const colMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (powMatch) power = parseFloat(powMatch[1]);
                if (colMatch) color = colMatch[1];
            }

            const pad = {
                type: 'jump_pad',
                x: x,
                y: y,
                w: w,
                h: h,
                power: power,
                color: color,
                pulse: 0
            };
            this.gameEntities.push(pad);
            this.log(`🚀 Plataforma Impulsora en (${x}, ${y}) [Impulso: ${power}]`, 'info');
            return;
        }

        // 22. Jump Ring / Orb: spawn orb / spawn jump_ring / spawn.orb
        if (line.startsWith('spawn orb') || line.startsWith('spawn jump_ring') || line.startsWith('spawn.orb')) {
            let x = 350, y = 220, r = 16;
            let power = 550;
            let color = '#f59e0b';

            if (line.includes('(') && line.startsWith('spawn.orb(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.power) power = args.power;
                if (args.color) color = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const powMatch = line.match(/power (\d+)/);
                const colMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (powMatch) power = parseFloat(powMatch[1]);
                if (colMatch) color = colMatch[1];
            }

            const orb = {
                type: 'orb',
                x: x,
                y: y,
                r: r,
                power: power,
                color: color,
                pulse: 0
            };
            this.gameEntities.push(orb);
            this.log(`✨ Anillo de Salto Aéreo en (${x}, ${y})`, 'info');
            return;
        }

        // 23. Collectible Star / Coin: spawn coin / spawn star / spawn.coin
        if (line.startsWith('spawn coin') || line.startsWith('spawn star') || line.startsWith('spawn.coin')) {
            let x = 300, y = 250, points = 100;

            if (line.includes('(') && line.startsWith('spawn.coin(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.points) points = args.points;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const pointsMatch = line.match(/points\s+(\d+)/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (pointsMatch) points = parseInt(pointsMatch[1]);
            }

            const coin = {
                type: 'coin',
                x: x,
                y: y,
                r: 10,
                points: points,
                collected: false,
                floatOffset: Math.random() * 10
            };
            this.gameEntities.push(coin);
            return;
        }

        // 24. Health Pack / Heart: spawn heart / spawn potion / spawn.heart
        if (line.startsWith('spawn heart') || line.startsWith('spawn potion') || line.startsWith('spawn.heart')) {
            let x = 400, y = 260, heal = 30;

            if (line.includes('(') && line.startsWith('spawn.heart(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.heal) heal = args.heal;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const healMatch = line.match(/health (\d+)|heal (\d+)/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (healMatch) heal = parseInt(healMatch[1] || healMatch[2]);
            }

            const heart = {
                type: 'heart',
                x: x,
                y: y,
                r: 11,
                heal: heal,
                collected: false,
                floatOffset: Math.random() * 10
            };
            this.gameEntities.push(heart);
            this.log(`💚 Kit de Salud en (${x}, ${y}) [+${heal} HP]`, 'info');
            return;
        }

        // 25. Goal / Victory Portal: spawn portal / spawn goal / spawn.portal
        if (line.startsWith('spawn portal') || line.startsWith('spawn goal') || line.startsWith('spawn.portal')) {
            let x = 700, y = 350, w = 44, h = 68;
            let label = 'STAGE GOAL';

            if (line.includes('(') && line.startsWith('spawn.portal(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.label) label = args.label;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const labelMatch = line.match(/(?:label|destination)\s+["'](.*?)["']/);
                if (posMatch) { x = parseFloat(posMatch[1]); y = parseFloat(posMatch[2]); }
                if (labelMatch) label = labelMatch[1];
            }

            const portal = {
                type: 'portal',
                x: x,
                y: y,
                w: w,
                h: h,
                label: label,
                angle: 0,
                color: '#a855f7'
            };
            this.gameEntities.push(portal);
            this.log(`🌌 Portal de Victoria en (${x}, ${y}) ["${label}"]`, 'info');
            return;
        }

        // 25b. Boss Entity: spawn boss / spawn.boss
        if (line.startsWith('spawn boss') || line.startsWith('spawn.boss')) {
            let name = 'TITÁN BLUELINE';
            let x = 1280, y = 316, w = 58, h = 76;
            let minX = 1100, maxX = 1450;
            let speed = 95, health = 450, fireRate = 1.7;
            let color = '#ef4444';

            if (line.includes('(') && line.startsWith('spawn.boss(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.name) name = args.name;
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.range && Array.isArray(args.range)) { minX = args.range[0]; maxX = args.range[1]; }
                if (args.speed) speed = args.speed;
                if (args.health) health = args.health;
                if (args.fire_rate) fireRate = args.fire_rate;
                if (args.color) color = args.color;
            }

            const boss = {
                type: 'boss',
                name: name,
                x: x, y: y, w: w, h: h,
                vx: speed, vy: 0,
                speed: speed, dir: -1,
                minX: minX, maxX: maxX,
                health: health, maxHealth: health,
                fireRate: fireRate, fireTimer: fireRate,
                enraged: false,
                color: color,
                isAlive: true,
                glowPulse: 0
            };
            this.gameEntities.push(boss);
            this.log(`👹 Jefe Final desplegado: "${boss.name}" (HP: ${health} | Rango: ${minX}-${maxX})`, 'info');
            return;
        }

        // 25c. Checkpoint Beacon: spawn checkpoint / spawn.checkpoint
        if (line.startsWith('spawn checkpoint') || line.startsWith('spawn.checkpoint')) {
            let x = 500, y = 336, label = 'CHECKPOINT', color = '#38bdf8';
            if (line.includes('(') && line.startsWith('spawn.checkpoint(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.label) label = args.label;
                if (args.color) color = args.color;
            }
            this.gameEntities.push({
                type: 'checkpoint',
                x: x, y: y, w: 28, h: 60,
                label: label, color: color,
                activated: false, pulse: 0
            });
            this.log(`🚩 Checkpoint registrado en (${x}, ${y}) ["${label}"]`, 'info');
            return;
        }

        // 25d. Gravity / Anomaly Zone: spawn.gravity_zone / spawn.zone / spawn gravity_zone
        if (line.startsWith('spawn.gravity_zone') || line.startsWith('spawn.zone') || line.startsWith('spawn gravity_zone')) {
            let x = 400, y = 80, w = 280, h = 320, scale = 0.35, windX = 0, windY = 0;
            let label = 'LOW-G ZONE', color = '#c084fc';
            if (line.includes('(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.scale !== undefined) scale = args.scale;
                if (args.wind_x !== undefined) windX = args.wind_x;
                if (args.wind_y !== undefined) windY = args.wind_y;
                if (args.label) label = args.label;
                if (args.color) color = args.color;
            }
            this.gameEntities.push({
                type: 'gravity_zone',
                x: x, y: y, w: w, h: h,
                scale: scale, windX: windX, windY: windY,
                label: label, color: color
            });
            this.log(`🌀 Zona Física en (${x}, ${y}) [${w}x${h} | Gravedad: ${scale}G | "${label}"]`, 'info');
            return;
        }

        // 25e. Teleporter: spawn.teleporter / spawn teleporter
        if (line.startsWith('spawn.teleporter') || line.startsWith('spawn teleporter')) {
            let x = 400, y = 300, toX = 800, toY = 200, label = 'WARP', color = '#00f5d4';
            if (line.includes('(') && line.startsWith('spawn.teleporter(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.to && Array.isArray(args.to)) { toX = args.to[0]; toY = args.to[1]; }
                if (args.label) label = args.label;
                if (args.color) color = args.color;
            }
            this.gameEntities.push({
                type: 'teleporter',
                x: x, y: y, w: 38, h: 58,
                toX: toX, toY: toY,
                label: label, color: color, angle: 0
            });
            this.log(`⚡ Teletransportador en (${x}, ${y}) -> (${toX}, ${toY}) ["${label}"]`, 'info');
            return;
        }

        // 25f. Breakable Barrier / Debris: spawn.breakable / spawn breakable
        if (line.startsWith('spawn.breakable') || line.startsWith('spawn breakable')) {
            let x = 300, y = 260, w = 36, h = 76, health = 40, points = 120, color = '#f59e0b';
            if (line.includes('(') && line.startsWith('spawn.breakable(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.health) health = args.health;
                if (args.points) points = args.points;
                if (args.color) color = args.color;
            }
            this.gameEntities.push({
                type: 'breakable',
                x: x, y: y, w: w, h: h,
                health: health, maxHealth: health,
                points: points, color: color,
                broken: false
            });
            this.log(`🧱 Barrera destructible en (${x}, ${y}) [HP: ${health}]`, 'info');
            return;
        }

        // 25g. Laser Gate Hazard: spawn.laser_hazard / spawn laser_hazard
        if (line.startsWith('spawn.laser_hazard') || line.startsWith('spawn laser_hazard')) {
            let x = 350, y = 240, w = 12, h = 110, interval = 2.0, damage = 30, color = '#f43f5e';
            if (line.includes('(') && line.startsWith('spawn.laser_hazard(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { x = args.at[0]; y = args.at[1]; }
                if (args.size && Array.isArray(args.size)) { w = args.size[0]; h = args.size[1]; }
                if (args.interval) interval = args.interval;
                if (args.damage) damage = args.damage;
                if (args.color) color = args.color;
            }
            this.gameEntities.push({
                type: 'laser_hazard',
                x: x, y: y, w: w, h: h,
                interval: interval, timer: 0,
                active: true, damage: damage, color: color
            });
            this.log(`🚨 Láser rítmico en (${x}, ${y}) [Ciclo: ${interval}s]`, 'info');
            return;
        }

        // 26. Particle System / Spark emitter: emit particles
        if (line.startsWith('emit particles') || line.startsWith('fx.particles(')) {
            let px = 200, py = 200, pColor = '#38bdf8';
            if (line.includes('(') && line.startsWith('fx.particles(')) {
                const inner = line.slice(line.indexOf('(') + 1, line.lastIndexOf(')'));
                const args = this.parseNamedArgs(inner);
                if (args.at && Array.isArray(args.at)) { px = args.at[0]; py = args.at[1]; }
                if (args.color) pColor = args.color;
            } else {
                const posMatch = line.match(/at \((\d+),\s*(\d+)\)/);
                const colorMatch = line.match(/color ["'](.*?)["']/);
                if (posMatch) { px = parseInt(posMatch[1]); py = parseInt(posMatch[2]); }
                if (colorMatch) pColor = colorMatch[1];
            }
            this.spawnParticleBurst(px, py, pColor, 20);
            return;
        }

        // 27. Standalone 3D / .obj / C# / loopize++ statement calls
        if (/^(?:obj3d|mesh3d|csharp|cs|loopize|lz|ecs)\.[A-Za-z0-9_]+\(/.test(line) ||
            /^(?:lz_[A-Za-z0-9_]+|runcs|cs!)\(/.test(line)) {
            this.evaluate3DBuiltin(line);
            return;
        }
    }

    spawnParticleBurst(x, y, color, count = 16) {
        for (let i = 0; i < count; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = Math.random() * 160 + 40;
            this.particles.push({
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                color: color,
                alpha: 1.0,
                size: Math.random() * 4 + 2,
                life: Math.random() * 0.7 + 0.35
            });
        }
    }

    evaluateCondition(cond) {
        cond = cond.trim();
        const ops = ['==', '!=', '>=', '<=', '>', '<'];
        for (let op of ops) {
            if (cond.includes(op)) {
                const parts = cond.split(op);
                const left = this.evaluateExpression(parts[0]);
                const right = this.evaluateExpression(parts[1]);

                if (op === '==') return left == right;
                if (op === '!=') return left != right;
                if (op === '>=') return Number(left) >= Number(right);
                if (op === '<=') return Number(left) <= Number(right);
                if (op === '>') return Number(left) > Number(right);
                if (op === '<') return Number(left) < Number(right);
            }
        }
        return Boolean(this.evaluateExpression(cond));
    }

    isSingleQuotedLiteral(expr) {
        if (!expr || expr.length < 2) return false;
        const first = expr[0];
        if (first !== '"' && first !== "'") return false;
        for (let i = 1; i < expr.length; i++) {
            if (expr[i] === first && expr[i - 1] !== '\\') {
                return i === expr.length - 1;
            }
        }
        return false;
    }

    evaluateExpression(expr) {
        if (expr === undefined || expr === null) return '';
        expr = String(expr).trim();
        if (!expr) return '';

        if (expr.startsWith('py:') || expr.startsWith('py ')) {
            expr = expr.replace(/^(py:\s*|py\s+)/, '').trim();
        } else if (expr.startsWith('python:') || expr.startsWith('python eval ') || expr.startsWith('python ')) {
            expr = expr.replace(/^(python eval\s*|python:\s*|python\s+)/, '').trim();
        }
        
        if (this.isSingleQuotedLiteral(expr)) {
            let strContent = expr.slice(1, -1);
            strContent = strContent.replace(/\{([A-Za-z0-9_]+)\}/g, (match, varKey) => {
                return this.variables.hasOwnProperty(varKey) ? this.variables[varKey] : match;
            });
            return strContent;
        }

        if (!isNaN(expr) && expr !== '') return Number(expr);
        if (expr === 'true') return true;
        if (expr === 'false') return false;

        // 3D Native Built-in Evaluation (math3d.* / physics3d.* / scene3d.* / obj3d.* / csharp.* / loopize.* / lz_*)
        if (expr.startsWith('math3d.') || expr.startsWith('physics3d.') || expr.startsWith('scene3d.') ||
            expr.startsWith('obj3d.') || expr.startsWith('mesh3d.') ||
            expr.startsWith('csharp.') || expr.startsWith('cs.') || expr.startsWith('cs!(') || expr.startsWith('runcs(') ||
            expr.startsWith('loopize.') || expr.startsWith('lz.') || expr.startsWith('lz_') || expr.startsWith('ecs.')) {
            return this.evaluate3DBuiltin(expr);
        }

        // Array / Vector literal e.g. [1, 2, 3]
        if (expr.startsWith('[') && expr.endsWith(']')) {
            return expr.slice(1, -1).split(',').map(s => this.evaluateExpression(s.trim()));
        }

        // Map / Array indexing e.g. st3d["entities"] or vec[0]
        const idxMatch = expr.match(/^([A-Za-z0-9_]+)\[\s*(?:"([^"]*)"|'([^']*)'|(\d+))\s*\]$/);
        if (idxMatch && this.variables.hasOwnProperty(idxMatch[1])) {
            const target = this.variables[idxMatch[1]];
            const key = idxMatch[2] !== undefined ? idxMatch[2] : (idxMatch[3] !== undefined ? idxMatch[3] : Number(idxMatch[4]));
            if (target !== null && target !== undefined && target[key] !== undefined) {
                return target[key];
            }
        }

        // Property / method access e.g. ship_info.triangles or cs_export.length()
        if (expr.endsWith('.length()')) {
            const target = this.evaluateExpression(expr.slice(0, -9));
            return (target && target.length !== undefined) ? target.length : 0;
        }
        const dotPropMatch = expr.match(/^([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)$/);
        if (dotPropMatch && this.variables.hasOwnProperty(dotPropMatch[1])) {
            const obj = this.variables[dotPropMatch[1]];
            if (obj && typeof obj === 'object' && dotPropMatch[2] in obj) return obj[dotPropMatch[2]];
        }

        // Python Math Module & Arithmetic Expressions
        if (expr.startsWith('math.') || expr.includes(' + ') || expr.includes(' - ') || expr.includes(' * ') || expr.includes(' / ') || expr.includes(' % ')) {
            try {
                let resolvedExpr = expr;
                const varKeys = Object.keys(this.variables).sort((a, b) => b.length - a.length);
                for (let k of varKeys) {
                    const regex = new RegExp(`\\b${k}\\b`, 'g');
                    const val = this.variables[k];
                    const valRepr = typeof val === 'string' ? JSON.stringify(val) : String(val);
                    resolvedExpr = resolvedExpr.replace(regex, valRepr);
                }
                
                resolvedExpr = resolvedExpr
                    .replace(/math\.pi/g, Math.PI.toString())
                    .replace(/math\.e/g, Math.E.toString())
                    .replace(/math\.sqrt/g, 'Math.sqrt')
                    .replace(/math\.pow/g, 'Math.pow')
                    .replace(/math\.sin/g, 'Math.sin')
                    .replace(/math\.cos/g, 'Math.cos')
                    .replace(/math\.tan/g, 'Math.tan')
                    .replace(/math\.floor/g, 'Math.floor')
                    .replace(/math\.ceil/g, 'Math.ceil')
                    .replace(/math\.round/g, 'Math.round')
                    .replace(/math\.abs/g, 'Math.abs')
                    .replace(/math\.min/g, 'Math.min')
                    .replace(/math\.max/g, 'Math.max')
                    .replace(/math\.random/g, 'Math.random');

                return Function(`"use strict"; return (${resolvedExpr});`)();
            } catch(e) {
                if (expr.includes(' + ')) {
                    return expr.split(/\s+\+\s+/).map(p => this.evaluateExpression(p)).join('');
                }
            }
        }

        if (this.variables.hasOwnProperty(expr)) {
            return this.variables[expr];
        }

        return expr;
    }

    parsePrint(rawExpr) {
        const args = [];
        let current = '';
        let inQuotes = false;
        let quoteChar = '';

        for (let i = 0; i < rawExpr.length; i++) {
            const char = rawExpr[i];
            if ((char === '"' || char === "'") && (i === 0 || rawExpr[i - 1] !== '\\')) {
                if (!inQuotes) {
                    inQuotes = true;
                    quoteChar = char;
                } else if (quoteChar === char) {
                    inQuotes = false;
                }
            }

            if (char === ',' && !inQuotes) {
                args.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }
        if (current.trim()) args.push(current.trim());

        const evaluated = args.map(arg => this.evaluateExpression(arg));
        return evaluated.join(' ');
    }

    triggerEvent(event, data) {
        if (event === 'click') {
            for (let item of this.renderQueue) {
                if (item.type === 'button') {
                    if (data.x >= item.x && data.x <= item.x + item.w &&
                        data.y >= item.y && data.y <= item.y + item.h) {
                        this.spawnParticleBurst(data.x, data.y, '#38bdf8', 25);
                    }
                }
            }
        }
    }

    startLoop() {
        this.isRunning = true;
        this.lastTime = performance.now();
        
        const loop = (timestamp) => {
            if (!this.isRunning) return;
            const dt = Math.min((timestamp - this.lastTime) / 1000, 0.1);
            this.lastTime = timestamp;
            
            this.update(dt);
            this.render();
            
            this.animationFrameId = requestAnimationFrame(loop);
        };
        this.animationFrameId = requestAnimationFrame(loop);
    }

    // ── GAMEPLAY PHYSICS & ENTITY SIMULATION ──
    update(dt) {
        if (dt > 0.0005) {
            const instFps = Math.min(240, 1 / dt);
            this.fpsSmooth = this.fpsSmooth * 0.92 + instFps * 0.08;
            this.fps = Math.round(this.fpsSmooth);
        }

        // Poll Gamepad Hardware via Standard HTML5 API (with clean release + edge triggers)
        if (typeof navigator !== 'undefined' && navigator.getGamepads) {
            const gps = navigator.getGamepads();
            const gp = gps && gps[0];
            if (gp) {
                const axisX = gp.axes[0] || 0;
                const axisY = gp.axes[1] || 0;
                const axisCamX = gp.axes[2] || 0;
                this.gamepadState.axisX = Math.abs(axisX) > 0.16 ? axisX : 0;
                this.gamepadState.axisY = Math.abs(axisY) > 0.16 ? -axisY : 0;
                this.gamepadState.axisCamX = Math.abs(axisCamX) > 0.18 ? axisCamX : 0;

                const kbLeft = !!(this.keysDown['a'] || this.keysDown['arrowleft']);
                const kbRight = !!(this.keysDown['d'] || this.keysDown['arrowright']);
                const kbUp = !!(this.keysDown['w'] || this.keysDown['arrowup']);
                const kbDown = !!(this.keysDown['s'] || this.keysDown['arrowdown']);
                const kbJump = this.is3DMode ? !!this.keysDown[' '] : !!(this.keysDown['w'] || this.keysDown['arrowup'] || this.keysDown[' ']);
                const kbShoot = !!(this.keysDown['j'] || this.keysDown['z'] || this.keysDown['f'] || this.keysDown['enter']);
                const kbDash = !!(this.keysDown['k'] || this.keysDown['x'] || this.keysDown['shift']);

                const gpLeft = axisX < -0.3 || !!(gp.buttons[14] && gp.buttons[14].pressed);
                const gpRight = axisX > 0.3 || !!(gp.buttons[15] && gp.buttons[15].pressed);
                const gpUp = axisY < -0.3 || !!(gp.buttons[12] && gp.buttons[12].pressed);
                const gpDown = axisY > 0.3 || !!(gp.buttons[13] && gp.buttons[13].pressed);
                const btnAHeld = !!(gp.buttons[0] && gp.buttons[0].pressed) || (!this.is3DMode && gpUp);
                const btnBHeld = !!(gp.buttons[1] && gp.buttons[1].pressed) || !!(gp.buttons[2] && gp.buttons[2].pressed);
                const btnXHeld = !!(gp.buttons[3] && gp.buttons[3].pressed);
                const btnPauseHeld = !!(gp.buttons[9] && gp.buttons[9].pressed);

                this.gamepadState.dpad.left = kbLeft || gpLeft;
                this.gamepadState.dpad.right = kbRight || gpRight;
                this.gamepadState.dpad.up = kbUp || gpUp;
                this.gamepadState.dpad.down = kbDown || gpDown;
                this.gamepadState.btnA = kbJump || btnAHeld;
                this.gamepadState.btnB = kbShoot || btnBHeld;
                this.gamepadState.btnX = kbDash || btnXHeld;

                if (btnPauseHeld && !this.prevGamepadButtons.pause && !this.gameOver && !this.gameWon) {
                    this.paused = !this.paused;
                }
                if (!this.paused && !this.gameOver && !this.gameWon) {
                    if (btnAHeld && !this.prevGamepadButtons.a) {
                        const actor = this.is3DMode ? this.getPlayer3D() : this.getPlayer();
                        if (actor) actor.jumpBufferTimer = this.jumpBuffer;
                    }
                    if (btnBHeld && !this.prevGamepadButtons.b) {
                        if (this.is3DMode) {
                            const p3 = this.getPlayer3D();
                            if (p3) this.shootProjectile3D(p3);
                        } else {
                            const p = this.getPlayer();
                            if (p) this.shootProjectile(p);
                        }
                    }
                    if (btnXHeld && !this.prevGamepadButtons.x) {
                        if (this.is3DMode) {
                            const p3 = this.getPlayer3D();
                            if (p3) this.triggerDash3D(p3);
                        } else {
                            const p = this.getPlayer();
                            if (p) this.triggerDash(p);
                        }
                    }
                }
                this.prevGamepadButtons = { a: btnAHeld, b: btnBHeld, x: btnXHeld, pause: btnPauseHeld };
            }
        }

        if (this.paused && !this.gameOver && !this.gameWon) {
            return;
        }
        if (this.hitstopTimer > 0) {
            this.hitstopTimer = Math.max(0, this.hitstopTimer - dt);
            return;
        }

        if (this.is3DMode) {
            this.update3D(dt);
            return;
        }

        dt = dt * (this.timeScale || 1.0);
        if (this.comboTimer > 0) {
            this.comboTimer -= dt;
            if (this.comboTimer <= 0) this.combo = 0;
        }
        const floorY = this.canvas ? this.canvas.height - 44 : 436;

        // 1. Update Moving Platforms, Portals, Teleporters & Laser Gates
        for (let other of this.gameEntities) {
            if (other.type === 'moving_platform') {
                if (other.axis === 'x') {
                    other.x += other.dir * other.speed * dt;
                    other.vx = other.dir * other.speed;
                    other.vy = 0;
                    if (other.x >= other.maxPos) { other.x = other.maxPos; other.dir = -1; }
                    if (other.x <= other.minPos) { other.x = other.minPos; other.dir = 1; }
                } else {
                    other.y += other.dir * other.speed * dt;
                    other.vx = 0;
                    other.vy = other.dir * other.speed;
                    if (other.y >= other.maxPos) { other.y = other.maxPos; other.dir = -1; }
                    if (other.y <= other.minPos) { other.y = other.minPos; other.dir = 1; }
                }
            } else if (other.type === 'portal' || other.type === 'teleporter') {
                other.angle = (other.angle || 0) + dt * 2.5;
            } else if (other.type === 'jump_pad' || other.type === 'orb' || other.type === 'checkpoint') {
                if (other.pulse > 0) other.pulse = Math.max(0, other.pulse - dt * 3.5);
            } else if (other.type === 'laser_hazard') {
                other.timer = (other.timer || 0) + dt;
                if (other.timer >= (other.interval || 2.0)) {
                    other.timer = 0;
                    other.active = !other.active;
                }
            }
        }

        // 2. Update Entities (Player, Enemies, Bosses)
        for (let entity of this.gameEntities) {
            entity.glowPulse = (entity.glowPulse || 0) + dt * 5;

            if (entity.isPlayer && !this.gameOver) {
                // Timers
                if (entity.coyoteTimer > 0) entity.coyoteTimer -= dt;
                if (entity.jumpBufferTimer > 0) entity.jumpBufferTimer -= dt;
                if (entity.invulnerableTimer > 0) entity.invulnerableTimer -= dt;
                if (entity.dashCooldown > 0) entity.dashCooldown -= dt;
                if (entity.teleportCooldown > 0) entity.teleportCooldown -= dt;
                
                // Dash handling
                if (entity.isDashing) {
                    entity.dashTimer -= dt;
                    this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#00f5d4', 2);
                    if (entity.dashTimer <= 0) {
                        entity.isDashing = false;
                    }
                } else {
                    // Left / Right Movement
                    const moveLeft = this.gamepadState.dpad.left || this.touchState.left || 
                                     this.keysDown['arrowleft'] || this.keysDown['a'];
                    const moveRight = this.gamepadState.dpad.right || this.touchState.right || 
                                      this.keysDown['arrowright'] || this.keysDown['d'];

                    if (moveLeft) {
                        entity.vx = -entity.speed;
                        entity.facing = -1;
                    } else if (moveRight) {
                        entity.vx = entity.speed;
                        entity.facing = 1;
                    } else {
                        entity.vx *= this.friction;
                    }

                    // Jump Execution (Jump Buffering + Coyote Time)
                    const wantsJump = this.gamepadState.btnA || this.touchState.btnA || 
                                      this.keysDown['arrowup'] || this.keysDown['w'] || this.keysDown[' '];

                    if (wantsJump && entity.jumpBufferTimer <= 0) {
                        entity.jumpBufferTimer = this.jumpBuffer;
                    }

                    if (entity.jumpBufferTimer > 0) {
                        if (entity.coyoteTimer > 0 && !entity.isJumping) {
                            // First Jump
                            entity.vy = -entity.jumpForce;
                            entity.isJumping = true;
                            entity.coyoteTimer = 0;
                            entity.jumpBufferTimer = 0;
                            entity.doubleJumpAvailable = entity.canDoubleJump;
                            entity.stretch = 1.25;
                            entity.squash = 0.85;
                            this.playSfx('jump');
                            this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h, '#38bdf8', 12);
                        } else if (entity.doubleJumpAvailable && entity.isJumping) {
                            // Double Jump
                            entity.vy = -entity.jumpForce * 0.92;
                            entity.doubleJumpAvailable = false;
                            entity.jumpBufferTimer = 0;
                            entity.stretch = 1.3;
                            entity.squash = 0.8;
                            this.playSfx('double_jump');
                            this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h, '#c084fc', 18);
                            this.addPopup(entity.x, entity.y - 12, 'DOUBLE JUMP!', '#c084fc');
                        }
                    }

                    // Check Gravity Zones & Wind Anomalies
                    let gravScale = 1.0;
                    let windX = 0, windY = 0;
                    for (let gz of this.gameEntities) {
                        if (gz.type === 'gravity_zone') {
                            if (entity.x + entity.w > gz.x && entity.x < gz.x + gz.w &&
                                entity.y + entity.h > gz.y && entity.y < gz.y + gz.h) {
                                gravScale = gz.scale !== undefined ? gz.scale : 0.35;
                                windX = gz.windX || 0;
                                windY = gz.windY || 0;
                            }
                        }
                    }
                    entity.vx += windX * dt;
                    entity.vy += (this.gravity * gravScale + windY) * dt;
                }

                // Apply Velocities
                entity.x += entity.vx * dt;
                entity.y += entity.vy * dt;

                // Squash & Stretch decay
                entity.squash += (1.0 - entity.squash) * dt * 10;
                entity.stretch += (1.0 - entity.stretch) * dt * 10;

                // Floor Collision
                if (entity.y + entity.h >= floorY) {
                    entity.y = floorY - entity.h;
                    entity.vy = 0;
                    entity.isJumping = false;
                    entity.coyoteTimer = this.coyoteTime;
                    entity.doubleJumpAvailable = entity.canDoubleJump;
                }

                // Entity Interactions & Collisions
                let onMovingPlatform = null;

                for (let other of this.gameEntities) {
                    if (other === entity) continue;

                    // Static Platform Collision
                    if (other.type === 'platform') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 14 && entity.vy >= 0) {
                                entity.y = other.y - entity.h;
                                entity.vy = 0;
                                entity.isJumping = false;
                                entity.coyoteTimer = this.coyoteTime;
                                entity.doubleJumpAvailable = entity.canDoubleJump;
                            }
                        }
                    } 
                    // Moving Platform Collision (Ride along!)
                    else if (other.type === 'moving_platform') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 16 && entity.vy >= 0) {
                                entity.y = other.y - entity.h;
                                entity.vy = 0;
                                entity.isJumping = false;
                                entity.coyoteTimer = this.coyoteTime;
                                entity.doubleJumpAvailable = entity.canDoubleJump;
                                onMovingPlatform = other;
                            }
                        }
                    }
                    // Spike / Hazard Collision
                    else if (other.type === 'spike') {
                        if (entity.x + entity.w > other.x + 4 && entity.x < other.x + other.w - 4 &&
                            entity.y + entity.h >= other.y + 6 && entity.y <= other.y + other.h) {
                            
                            if (entity.invulnerableTimer <= 0 && !entity.isDashing) {
                                entity.health -= other.damage || 35;
                                entity.invulnerableTimer = 1.0;
                                this.camera.shake = 10;
                                this.playSfx('hurt');
                                this.addPopup(entity.x, entity.y - 12, `-${other.damage || 35} HP`, '#ef4444');
                                this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#ef4444', 20);
                                entity.vy = -300; // Knockback rebound
                            }
                        }
                    }
                    // Jump Pad Collision
                    else if (other.type === 'jump_pad') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w) {
                            if (entity.y + entity.h >= other.y && entity.y + entity.h <= other.y + other.h + 12 && entity.vy >= 0) {
                                entity.vy = -(other.power || 650);
                                entity.isJumping = true;
                                entity.doubleJumpAvailable = true;
                                other.pulse = 1.0;
                                this.playSfx('pad');
                                this.addPopup(other.x + other.w / 2, other.y - 14, 'MEGA BOOST!', '#fbbf24');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y, '#fbbf24', 22);
                            }
                        }
                    }
                    // Jump Ring / Orb Collision
                    else if (other.type === 'orb') {
                        const dist = Math.hypot((entity.x + entity.w / 2) - other.x, (entity.y + entity.h / 2) - other.y);
                        if (dist < other.r + 26) {
                            if (this.gamepadState.btnA || this.keysDown[' '] || this.keysDown['w'] || this.touchState.btnA) {
                                entity.vy = -(other.power || 540);
                                entity.isJumping = true;
                                entity.doubleJumpAvailable = true;
                                other.pulse = 1.0;
                                this.playSfx('pad');
                                this.addPopup(other.x, other.y - 14, 'AIR BOOST!', '#f59e0b');
                                this.spawnParticleBurst(other.x, other.y, '#f59e0b', 24);
                            }
                        }
                    }
                    // Coin Collectible
                    else if (other.type === 'coin' && !other.collected) {
                        const cx = other.x;
                        const cy = other.y;
                        if (entity.x + entity.w >= cx - other.r && entity.x <= cx + other.r &&
                            entity.y + entity.h >= cy - other.r && entity.y <= cy + other.r) {
                            other.collected = true;
                            this.score += other.points;
                            this.playSfx('coin');
                            this.addPopup(cx, cy - 10, `+${other.points}`, '#fbbf24');
                            this.spawnParticleBurst(cx, cy, '#fbbf24', 20);
                            this.log(` Moneda obtenida! +${other.points} (Puntaje Total: ${this.score})`, 'success');
                        }
                    }
                    // Health Pack Collectible
                    else if (other.type === 'heart' && !other.collected) {
                        const dist = Math.hypot((entity.x + entity.w / 2) - other.x, (entity.y + entity.h / 2) - other.y);
                        if (dist < other.r + 20) {
                            other.collected = true;
                            entity.health = Math.min(entity.maxHealth, entity.health + (other.heal || 30));
                            this.playSfx('heal');
                            this.addPopup(other.x, other.y - 12, `+${other.heal || 30} HP`, '#10b981');
                            this.spawnParticleBurst(other.x, other.y, '#10b981', 20);
                        }
                    }
                    // Checkpoint Beacon
                    else if (other.type === 'checkpoint') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h > other.y && entity.y < other.y + other.h) {
                            if (!other.activated) {
                                other.activated = true;
                                other.pulse = 1.0;
                                entity.spawnX = other.x;
                                entity.spawnY = other.y - 10;
                                entity.health = Math.min(entity.maxHealth, entity.health + 25);
                                this.playSfx('heal');
                                this.addPopup(other.x, other.y - 14, `🚩 ${other.label}`, '#4ade80');
                                this.spawnParticleBurst(other.x + 14, other.y + 20, '#4ade80', 22);
                                this.log(`🚩 Checkpoint activado: "${other.label}" en (${other.x}, ${other.y})`, 'success');
                            }
                        }
                    }
                    // Teleporter Quantum Warp
                    else if (other.type === 'teleporter') {
                        if (entity.teleportCooldown <= 0 &&
                            entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h > other.y && entity.y < other.y + other.h) {
                            this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, other.color || '#00f5d4', 24);
                            entity.x = other.toX;
                            entity.y = other.toY;
                            entity.vy = -120;
                            entity.teleportCooldown = 1.1;
                            this.playSfx('pad');
                            this.addPopup(entity.x, entity.y - 14, `⚡ ${other.label}`, other.color || '#00f5d4');
                            this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, other.color || '#00f5d4', 28);
                        }
                    }
                    // Breakable Barrier / Debris
                    else if (other.type === 'breakable' && !other.broken) {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h > other.y && entity.y < other.y + other.h) {
                            if (entity.isDashing || entity.overdrive) {
                                other.broken = true;
                                this.score += (other.points || 120);
                                this.camera.shake = 8;
                                this.playSfx('stomp');
                                this.addPopup(other.x, other.y - 10, `+${other.points || 120} SHATTER!`, '#fbbf24');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y + other.h / 2, other.color || '#f59e0b', 28);
                            } else if (entity.vy >= 0 && (entity.y + entity.h) <= other.y + 16) {
                                entity.y = other.y - entity.h;
                                entity.vy = 0;
                                entity.isJumping = false;
                                entity.coyoteTimer = this.coyoteTime;
                                entity.doubleJumpAvailable = entity.canDoubleJump;
                            } else {
                                if (entity.x + entity.w / 2 < other.x + other.w / 2) entity.x = other.x - entity.w;
                                else entity.x = other.x + other.w;
                                entity.vx = 0;
                            }
                        }
                    }
                    // Laser Hazard Gate
                    else if (other.type === 'laser_hazard' && other.active) {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h > other.y && entity.y < other.y + other.h) {
                            if (entity.invulnerableTimer <= 0 && !entity.isDashing) {
                                entity.health -= (other.damage || 30);
                                entity.invulnerableTimer = 1.0;
                                this.camera.shake = 10;
                                this.playSfx('hurt');
                                this.addPopup(entity.x, entity.y - 12, `-${other.damage || 30} LASER`, '#f43f5e');
                                this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#f43f5e', 18);
                                entity.vx = -entity.facing * 260;
                                entity.vy = -220;
                            }
                        }
                    }
                    // Portal / Victory Goal
                    else if (other.type === 'portal') {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h > other.y && entity.y < other.y + other.h) {
                            this.triggerVictory();
                        }
                    }
                    // Enemy & Boss Interaction: Stomp vs Collision Damage
                    else if ((other.type === 'enemy' || other.type === 'boss') && other.isAlive) {
                        if (entity.x + entity.w > other.x && entity.x < other.x + other.w &&
                            entity.y + entity.h >= other.y && entity.y <= other.y + other.h) {
                            
                            // Stomp from above (or Overdrive Slam)!
                            if ((entity.vy > 0 && (entity.y + entity.h) <= (other.y + other.h * 0.45 + 12)) || (entity.isDashing && entity.overdrive)) {
                                const stompDmg = entity.overdrive ? 150 : (other.type === 'boss' ? 90 : other.health);
                                other.health -= stompDmg;
                                entity.vy = -410;
                                entity.doubleJumpAvailable = true;
                                this.combo = (this.combo || 0) + 1;
                                this.comboTimer = 3.5;
                                this.playSfx('stomp');
                                if (other.health <= 0) {
                                    other.isAlive = false;
                                    const pts = other.type === 'boss' ? 1000 : 250 * Math.min(4, this.combo);
                                    this.score += pts;
                                    this.camera.shake = other.type === 'boss' ? 18 : 8;
                                    this.addPopup(other.x + other.w / 2, other.y - 14, `+${pts} ${other.type === 'boss' ? 'BOSS DEFEATED!' : 'STOMP!'}`, '#38bdf8');
                                    this.spawnParticleBurst(other.x + other.w / 2, other.y + other.h / 2, '#ef4444', other.type === 'boss' ? 48 : 26);
                                    this.log(`💥 ${other.type === 'boss' ? 'Jefe' : 'Enemigo'} "${other.name}" derrotado! (+${pts} Pts)`, 'success');
                                } else {
                                    this.score += 120;
                                    this.camera.shake = 10;
                                    this.addPopup(other.x + other.w / 2, other.y - 14, `-${stompDmg} BOSS HIT!`, '#fbbf24');
                                    this.spawnParticleBurst(other.x + other.w / 2, other.y + 12, '#fbbf24', 22);
                                }
                            } 
                            // Collision Damage to player
                            else if (entity.invulnerableTimer <= 0) {
                                const hitDmg = other.type === 'boss' ? 35 : 25;
                                entity.health -= hitDmg;
                                entity.invulnerableTimer = 1.0;
                                this.camera.shake = 11;
                                this.playSfx('hurt');
                                this.addPopup(entity.x, entity.y - 12, `-${hitDmg} HP`, '#ef4444');
                                this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#ef4444', 16);
                                entity.vx = -entity.facing * 260;
                                entity.vy = -230;
                            }
                        }
                    }
                }

                // Check player death & Checkpoint Respawn
                if (entity.health <= 0) {
                    this.lives--;
                    if (this.lives > 0) {
                        entity.health = entity.maxHealth;
                        entity.x = entity.spawnX !== undefined ? entity.spawnX : 100;
                        entity.y = entity.spawnY !== undefined ? entity.spawnY : 280;
                        entity.vx = 0;
                        entity.vy = 0;
                        this.log(`⚠️ Te quedan ${this.lives} vidas. Reapareciendo en Checkpoint (${Math.round(entity.x)}, ${Math.round(entity.y)})...`, 'error');
                    } else {
                        this.triggerGameOver();
                    }
                }

                // If standing on moving platform, ride along with its velocity!
                if (onMovingPlatform) {
                    entity.x += onMovingPlatform.vx * dt;
                    entity.y += onMovingPlatform.vy * dt;
                }

                // World Boundaries Clamping
                if (entity.x < 0) entity.x = 0;
                if (entity.x + entity.w > this.world.width) entity.x = this.world.width - entity.w;

            } else if ((entity.type === 'enemy' || entity.type === 'boss') && entity.isAlive) {
                // Autonomous AI Patrol for Enemy NPCs & Bosses
                const spdMult = (entity.type === 'boss' && entity.enraged) ? 1.45 : 1.0;
                entity.x += entity.dir * entity.speed * spdMult * dt;
                if (entity.x >= entity.maxX) { entity.x = entity.maxX; entity.dir = -1; }
                if (entity.x <= entity.minX) { entity.x = entity.minX; entity.dir = 1; }

                // Boss Ranged Plasma Attacks & Enrage State
                if (entity.type === 'boss') {
                    if (!entity.enraged && entity.health <= entity.maxHealth * 0.5) {
                        entity.enraged = true;
                        this.camera.shake = 14;
                        this.addPopup(entity.x, entity.y - 24, '⚠️ BOSS ENRAGED!', '#ef4444');
                        this.spawnParticleBurst(entity.x + entity.w / 2, entity.y + entity.h / 2, '#ef4444', 32);
                    }
                    entity.fireTimer = (entity.fireTimer || 1.6) - dt;
                    const pl = this.getPlayer();
                    if (entity.fireTimer <= 0 && pl && Math.abs(pl.x - entity.x) < 620) {
                        entity.fireTimer = entity.enraged ? (entity.fireRate * 0.62) : entity.fireRate;
                        const bDir = pl.x < entity.x ? -1 : 1;
                        entity.dir = bDir;
                        this.projectiles.push({
                            type: 'projectile',
                            x: bDir > 0 ? entity.x + entity.w : entity.x - 18,
                            y: entity.y + entity.h * 0.45,
                            vx: bDir * (entity.enraged ? 430 : 340),
                            vy: 0,
                            w: 18,
                            h: 8,
                            color: '#f43f5e',
                            isPlayer: false,
                            damage: entity.enraged ? 30 : 20,
                            life: 2.0
                        });
                        this.playSfx('shoot');
                    }
                }
            }
        }

        // 3. Update Projectiles (Player & Boss/Enemy)
        for (let i = this.projectiles.length - 1; i >= 0; i--) {
            const pr = this.projectiles[i];
            pr.x += pr.vx * dt;
            pr.y += pr.vy * dt;
            pr.life -= dt;

            if (Math.random() < 0.4) {
                this.particles.push({
                    x: pr.x + (pr.vx > 0 ? 0 : pr.w),
                    y: pr.y + pr.h / 2,
                    vx: (Math.random() - 0.5) * 20,
                    vy: (Math.random() - 0.5) * 20,
                    color: pr.color,
                    alpha: 0.6,
                    size: 2,
                    life: 0.2
                });
            }

            if (pr.isPlayer) {
                for (let other of this.gameEntities) {
                    if ((other.type === 'enemy' || other.type === 'boss') && other.isAlive) {
                        if (pr.x + pr.w >= other.x && pr.x <= other.x + other.w &&
                            pr.y + pr.h >= other.y && pr.y <= other.y + other.h) {
                            
                            other.health -= pr.damage;
                            this.combo = (this.combo || 0) + 1;
                            this.comboTimer = 3.5;
                            this.playSfx('stomp');
                            this.addPopup(other.x + other.w / 2, other.y - 10, `-${pr.damage}`, pr.color || '#38bdf8');
                            this.spawnParticleBurst(pr.x, pr.y, pr.color || '#38bdf8', 12);
                            pr.life = 0;

                            if (other.health <= 0) {
                                other.isAlive = false;
                                const pts = other.type === 'boss' ? 1000 : 200 * Math.min(4, this.combo);
                                this.score += pts;
                                this.camera.shake = other.type === 'boss' ? 18 : 7;
                                this.hitstopTimer = Math.max(this.hitstopTimer || 0, other.type === 'boss' ? 0.075 : 0.04);
                                this.addPopup(other.x + other.w / 2, other.y - 14, `+${pts} ${other.type === 'boss' ? 'BOSS SLAIN!' : 'DESTROYED!'}`, '#fbbf24');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y + other.h / 2, '#ef4444', other.type === 'boss' ? 48 : 24);
                            }
                            break;
                        }
                    } else if (other.type === 'breakable' && !other.broken) {
                        if (pr.x + pr.w >= other.x && pr.x <= other.x + other.w &&
                            pr.y + pr.h >= other.y && pr.y <= other.y + other.h) {
                            other.health -= pr.damage;
                            this.playSfx('stomp');
                            this.spawnParticleBurst(pr.x, pr.y, other.color || '#f59e0b', 10);
                            pr.life = 0;
                            if (other.health <= 0) {
                                other.broken = true;
                                this.score += (other.points || 120);
                                this.addPopup(other.x, other.y - 10, `+${other.points || 120} BREAK!`, '#fbbf24');
                                this.spawnParticleBurst(other.x + other.w / 2, other.y + other.h / 2, other.color || '#f59e0b', 24);
                            }
                            break;
                        }
                    } else if (other.type === 'platform' || other.type === 'moving_platform') {
                        if (pr.x + pr.w >= other.x && pr.x <= other.x + other.w &&
                            pr.y + pr.h >= other.y && pr.y <= other.y + other.h) {
                            this.spawnParticleBurst(pr.x, pr.y, pr.color || '#38bdf8', 6);
                            pr.life = 0;
                            break;
                        }
                    }
                }
            } else {
                // Enemy/Boss Projectile hitting Solid Platform or Player
                let hitWall = false;
                for (let other of this.gameEntities) {
                    if ((other.type === 'platform' || other.type === 'moving_platform') &&
                        pr.x + pr.w >= other.x && pr.x <= other.x + other.w &&
                        pr.y + pr.h >= other.y && pr.y <= other.y + other.h) {
                        this.spawnParticleBurst(pr.x, pr.y, '#f43f5e', 5);
                        pr.life = 0;
                        hitWall = true;
                        break;
                    }
                }
                const pl = this.getPlayer();
                if (!hitWall && pl && !this.gameOver && pl.invulnerableTimer <= 0 && !pl.isDashing) {
                    if (pr.x + pr.w >= pl.x && pr.x <= pl.x + pl.w &&
                        pr.y + pr.h >= pl.y && pr.y <= pl.y + pl.h) {
                        pl.health -= pr.damage || 20;
                        pl.invulnerableTimer = 0.9;
                        this.camera.shake = 9;
                        this.playSfx('hurt');
                        this.addPopup(pl.x, pl.y - 12, `-${pr.damage || 20} HP`, '#f43f5e');
                        this.spawnParticleBurst(pr.x, pr.y, '#f43f5e', 16);
                        pr.life = 0;
                    }
                }
            }

            if (pr.life <= 0 || pr.x < 0 || pr.x > this.world.width) {
                this.projectiles.splice(i, 1);
            }
        }

        // 4. Update Particle Sparks
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.vy += 320 * dt; // Gravity on particles
            p.alpha -= dt / p.life;
            if (p.alpha <= 0) {
                this.particles.splice(i, 1);
            }
        }

        // 5. Update Floating Popups
        for (let i = this.popups.length - 1; i >= 0; i--) {
            const pop = this.popups[i];
            pop.y += pop.vy * dt;
            pop.alpha -= dt * 1.1;
            if (pop.alpha <= 0) {
                this.popups.splice(i, 1);
            }
        }

        // 6. Smooth Camera Tracking Follow
        const player = this.getPlayer();
        if (player && this.canvas) {
            const targetCamX = player.x + player.w / 2 - (this.canvas.width / 2);
            const targetCamY = player.y + player.h / 2 - (this.canvas.height / 2);
            const maxCamX = Math.max(0, this.world.width - this.canvas.width);
            const maxCamY = Math.max(0, this.world.height - this.canvas.height);

            this.camera.x += (Math.max(0, Math.min(maxCamX, targetCamX)) - this.camera.x) * this.camera.smooth;
            this.camera.y += (Math.max(0, Math.min(maxCamY, targetCamY)) - this.camera.y) * this.camera.smooth;
        }

        // Camera Shake Decay
        if (this.camera.shake > 0) {
            this.camera.shake = Math.max(0, this.camera.shake - dt * 22);
        }
    }

    // ── GRAPHICS & SHINE LOOP RENDERING PIPELINE ──
    render() {
        if (!this.ctx || !this.canvas) return;
        if (this.is3DMode) {
            this.render3D();
            return;
        }
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;

        // Apply Camera Shake
        const shakeX = (Math.random() - 0.5) * this.camera.shake;
        const shakeY = (Math.random() - 0.5) * this.camera.shake;

        // 1. Clear Stage & Scenario Atmosphere Background
        const sc = this.scenario || { name: 'Holo Cyber Stage', weather: 'stars', bg: '#06090f', accent: '#38bdf8' };
        ctx.fillStyle = sc.bg || '#06090f';
        ctx.fillRect(0, 0, w, h);

        // 2. Parallax Cyber Starfield, Singularity Vortex & Weather FX
        const parallaxX = this.camera.x * 0.15;
        ctx.save();
        if (sc.weather === 'void' || sc.weather === 'singularity') {
            // Black Hole Event Horizon in Parallax Space
            const bhX = w * 0.52 - (this.camera.x * 0.08) % (w * 0.4);
            const bhY = h * 0.38;
            const bhGrad = ctx.createRadialGradient(bhX, bhY, 12, bhX, bhY, 130);
            bhGrad.addColorStop(0, '#000000');
            bhGrad.addColorStop(0.35, 'rgba(192, 132, 252, 0.32)');
            bhGrad.addColorStop(0.7, 'rgba(56, 189, 248, 0.12)');
            bhGrad.addColorStop(1, 'transparent');
            ctx.fillStyle = bhGrad;
            ctx.beginPath();
            ctx.arc(bhX, bhY, 130, 0, Math.PI * 2);
            ctx.fill();
        } else if (sc.weather === 'rain') {
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.18)';
            ctx.lineWidth = 1;
            for (let r = 0; r < 28; r++) {
                const rx = ((r * 73 + this.lastTime * 0.25) % w);
                const ry = ((r * 47 + this.lastTime * 0.65) % h);
                ctx.beginPath();
                ctx.moveTo(rx, ry);
                ctx.lineTo(rx - 4, ry + 14);
                ctx.stroke();
            }
        } else if (sc.weather === 'ember' || sc.weather === 'debris') {
            ctx.fillStyle = 'rgba(244, 63, 94, 0.28)';
            for (let d = 0; d < 18; d++) {
                const dx = ((d * 89 - this.lastTime * 0.06) % w + w) % w;
                const dy = ((d * 53 - this.lastTime * 0.09) % h + h) % h;
                ctx.fillRect(dx, dy, 4, 4);
            }
        }

        ctx.strokeStyle = 'rgba(99, 102, 241, 0.16)';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        for (let x = 0; x <= w + 40; x += 15) {
            const y = h * 0.45 + Math.sin((x + parallaxX) * 0.015 + this.lastTime * 0.0018) * 24;
            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.stroke();

        // Cyber Grid Lines (Parallaxed)
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.05)';
        ctx.lineWidth = 1;
        const gridOffset = (this.camera.x * 0.3) % 40;
        for (let x = -gridOffset; x < w; x += 40) {
            ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
        }
        for (let y = 0; y < h; y += 40) {
            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
        }
        ctx.restore();

        // ═══════════════════════════════════════════════════════════════
        //  WORLD SPACE (Camera Translated)
        // ═══════════════════════════════════════════════════════════════
        ctx.save();
        ctx.translate(-Math.round(this.camera.x + shakeX), -Math.round(this.camera.y + shakeY));

        // 3. World Ground Surface
        const floorY = h - 44;
        const groundGrad = ctx.createLinearGradient(0, floorY, 0, h);
        groundGrad.addColorStop(0, '#0f172a');
        groundGrad.addColorStop(1, '#020617');
        ctx.fillStyle = groundGrad;
        ctx.fillRect(0, floorY, this.world.width, 44);

        // Neon Barrier Line
        ctx.strokeStyle = '#38bdf8';
        ctx.shadowColor = '#38bdf8';
        ctx.shadowBlur = 10;
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(0, floorY);
        ctx.lineTo(this.world.width, floorY);
        ctx.stroke();
        ctx.shadowBlur = 0;

        // Ground Hazard Stripes
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.12)';
        ctx.lineWidth = 2;
        for (let gx = 0; gx < this.world.width; gx += 48) {
            ctx.beginPath();
            ctx.moveTo(gx, floorY + 2);
            ctx.lineTo(gx + 20, floorY + 42);
            ctx.stroke();
        }

        // 4. Render Game Entities
        for (let entity of this.gameEntities) {
            // Static Platform
            if (entity.type === 'platform') {
                const pGrad = ctx.createLinearGradient(entity.x, entity.y, entity.x, entity.y + entity.h);
                pGrad.addColorStop(0, entity.color);
                pGrad.addColorStop(1, 'rgba(15, 23, 42, 0.92)');
                ctx.fillStyle = pGrad;
                ctx.strokeStyle = '#818cf8';
                ctx.lineWidth = 1.5;
                ctx.shadowColor = entity.color;
                ctx.shadowBlur = 8;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 6, true, true);
                ctx.shadowBlur = 0;
            }
            // Maglev Moving Platform
            else if (entity.type === 'moving_platform') {
                const mpGrad = ctx.createLinearGradient(entity.x, entity.y, entity.x, entity.y + entity.h);
                mpGrad.addColorStop(0, '#06b6d4');
                mpGrad.addColorStop(1, 'rgba(8, 47, 73, 0.95)');
                ctx.fillStyle = mpGrad;
                ctx.strokeStyle = '#22d3ee';
                ctx.lineWidth = 1.8;
                ctx.shadowColor = '#06b6d4';
                ctx.shadowBlur = 12;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 7, true, true);
                ctx.shadowBlur = 0;

                // Animated Maglev Directional Chevrons
                ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
                const chevronX = entity.x + entity.w / 2 + Math.sin(this.lastTime * 0.008) * 18;
                ctx.beginPath();
                ctx.arc(chevronX, entity.y + entity.h / 2, 3, 0, Math.PI * 2);
                ctx.fill();
            }
            // Spikes / Hazards
            else if (entity.type === 'spike') {
                ctx.fillStyle = '#ef4444';
                ctx.shadowColor = '#ef4444';
                ctx.shadowBlur = 10;
                const spikeCount = Math.max(1, Math.floor(entity.w / 14));
                const sWidth = entity.w / spikeCount;

                for (let k = 0; k < spikeCount; k++) {
                    const sx = entity.x + k * sWidth;
                    ctx.beginPath();
                    ctx.moveTo(sx, entity.y + entity.h);
                    ctx.lineTo(sx + sWidth / 2, entity.y);
                    ctx.lineTo(sx + sWidth, entity.y + entity.h);
                    ctx.closePath();
                    ctx.fill();
                }
                ctx.shadowBlur = 0;
            }
            // Jump Pad
            else if (entity.type === 'jump_pad') {
                ctx.fillStyle = '#1e1b4b';
                ctx.strokeStyle = '#fbbf24';
                ctx.lineWidth = 1.8;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 5, true, true);

                // Pulsing spring wave
                ctx.fillStyle = '#fbbf24';
                ctx.shadowColor = '#f59e0b';
                ctx.shadowBlur = 8 + (entity.pulse || 0) * 12;
                const padH = 4 + (entity.pulse || 0) * 6;
                ctx.fillRect(entity.x + 6, entity.y - padH, entity.w - 12, padH);
                ctx.shadowBlur = 0;
            }
            // Jump Ring / Orb
            else if (entity.type === 'orb') {
                ctx.save();
                ctx.strokeStyle = entity.color;
                ctx.shadowColor = entity.color;
                ctx.shadowBlur = 14 + (entity.pulse || 0) * 10;
                ctx.lineWidth = 2.5;

                // Outer Ring
                ctx.beginPath();
                ctx.arc(entity.x, entity.y, entity.r, 0, Math.PI * 2);
                ctx.stroke();

                // Inner pulsing core
                ctx.fillStyle = '#ffffff';
                ctx.beginPath();
                ctx.arc(entity.x, entity.y, 4 + Math.sin(this.lastTime * 0.008) * 1.5, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            }
            // Spinning Star/Coin
            else if (entity.type === 'coin' && !entity.collected) {
                const floatY = entity.y + Math.sin(this.lastTime * 0.005 + entity.floatOffset) * 4;
                ctx.fillStyle = '#fbbf24';
                ctx.shadowColor = '#f59e0b';
                ctx.shadowBlur = 12;
                ctx.beginPath();
                ctx.arc(entity.x, floatY, entity.r, 0, Math.PI * 2);
                ctx.fill();
                
                ctx.fillStyle = '#000000';
                ctx.font = 'bold 10px monospace';
                ctx.textAlign = 'center';
                ctx.fillText("*", entity.x, floatY + 3.5);
                ctx.textAlign = 'left';
                ctx.shadowBlur = 0;
            }
            // Health Heart Collectible
            else if (entity.type === 'heart' && !entity.collected) {
                const floatY = entity.y + Math.sin(this.lastTime * 0.006 + entity.floatOffset) * 4;
                ctx.fillStyle = '#10b981';
                ctx.shadowColor = '#10b981';
                ctx.shadowBlur = 14;
                ctx.beginPath();
                ctx.arc(entity.x, floatY, entity.r, 0, Math.PI * 2);
                ctx.fill();
                
                ctx.fillStyle = '#ffffff';
                ctx.font = 'bold 11px sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText("+", entity.x, floatY + 4);
                ctx.textAlign = 'left';
                ctx.shadowBlur = 0;
            }
            // Victory Portal Vortex
            else if (entity.type === 'portal') {
                ctx.save();
                ctx.translate(entity.x + entity.w / 2, entity.y + entity.h / 2);
                ctx.rotate(entity.angle || 0);

                ctx.strokeStyle = '#c084fc';
                ctx.shadowColor = '#c084fc';
                ctx.shadowBlur = 16;
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.ellipse(0, 0, entity.w / 2, entity.h / 2, 0, 0, Math.PI * 2);
                ctx.stroke();

                ctx.strokeStyle = '#38bdf8';
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                ctx.ellipse(0, 0, entity.w / 3, entity.h / 3, Math.PI / 4, 0, Math.PI * 2);
                ctx.stroke();
                ctx.restore();

                // Stage Goal Label
                ctx.fillStyle = '#f8fafc';
                ctx.font = 'bold 11px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(entity.label || "GOAL", entity.x + entity.w / 2, entity.y - 10);
                ctx.textAlign = 'left';
            }
            // Gravity / Anomaly Zone
            else if (entity.type === 'gravity_zone') {
                ctx.save();
                ctx.fillStyle = 'rgba(192, 132, 252, 0.08)';
                ctx.strokeStyle = entity.color || '#c084fc';
                ctx.lineWidth = 1.2;
                ctx.setLineDash([6, 6]);
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 10, true, true);
                ctx.setLineDash([]);
                ctx.fillStyle = entity.color || '#c084fc';
                ctx.font = 'bold 10px monospace';
                ctx.textAlign = 'center';
                ctx.fillText(`${entity.label || 'LOW-G'} (${entity.scale}G)`, entity.x + entity.w / 2, entity.y + 16);
                ctx.textAlign = 'left';
                ctx.restore();
            }
            // Checkpoint Beacon
            else if (entity.type === 'checkpoint') {
                const cpColor = entity.activated ? '#4ade80' : (entity.color || '#38bdf8');
                ctx.fillStyle = '#1e293b';
                ctx.fillRect(entity.x + 11, entity.y, 6, entity.h);
                ctx.fillStyle = cpColor;
                ctx.shadowColor = cpColor;
                ctx.shadowBlur = entity.activated ? 16 : 8;
                ctx.beginPath();
                ctx.arc(entity.x + 14, entity.y + 10, 9, 0, Math.PI * 2);
                ctx.fill();
                ctx.shadowBlur = 0;
                ctx.font = 'bold 9.5px monospace';
                ctx.textAlign = 'center';
                ctx.fillText(entity.activated ? '✔ SAVED' : entity.label, entity.x + 14, entity.y - 8);
                ctx.textAlign = 'left';
            }
            // Teleporter Ring
            else if (entity.type === 'teleporter') {
                ctx.save();
                ctx.translate(entity.x + entity.w / 2, entity.y + entity.h / 2);
                ctx.strokeStyle = entity.color || '#00f5d4';
                ctx.shadowColor = entity.color || '#00f5d4';
                ctx.shadowBlur = 14;
                ctx.lineWidth = 2.5;
                ctx.beginPath();
                ctx.arc(0, 0, 20, (entity.angle || 0), (entity.angle || 0) + Math.PI * 1.5);
                ctx.stroke();
                ctx.restore();
                ctx.fillStyle = entity.color || '#00f5d4';
                ctx.font = 'bold 9.5px monospace';
                ctx.textAlign = 'center';
                ctx.fillText(entity.label || 'WARP', entity.x + entity.w / 2, entity.y - 6);
                ctx.textAlign = 'left';
            }
            // Breakable Barrier
            else if (entity.type === 'breakable' && !entity.broken) {
                ctx.fillStyle = 'rgba(245, 158, 11, 0.25)';
                ctx.strokeStyle = entity.color || '#f59e0b';
                ctx.lineWidth = 2;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, 5, true, true);
                ctx.beginPath();
                ctx.moveTo(entity.x + 6, entity.y + 8);
                ctx.lineTo(entity.x + entity.w - 6, entity.y + entity.h / 2);
                ctx.lineTo(entity.x + 10, entity.y + entity.h - 8);
                ctx.stroke();
            }
            // Laser Gate Hazard
            else if (entity.type === 'laser_hazard') {
                ctx.fillStyle = '#334155';
                ctx.fillRect(entity.x - 2, entity.y, entity.w + 4, 8);
                ctx.fillRect(entity.x - 2, entity.y + entity.h - 8, entity.w + 4, 8);
                if (entity.active) {
                    ctx.fillStyle = entity.color || '#f43f5e';
                    ctx.shadowColor = entity.color || '#f43f5e';
                    ctx.shadowBlur = 16;
                    ctx.fillRect(entity.x + 2, entity.y + 8, entity.w - 4, entity.h - 16);
                    ctx.shadowBlur = 0;
                } else {
                    ctx.strokeStyle = 'rgba(244, 63, 94, 0.28)';
                    ctx.setLineDash([4, 4]);
                    ctx.beginPath();
                    ctx.moveTo(entity.x + entity.w / 2, entity.y + 8);
                    ctx.lineTo(entity.x + entity.w / 2, entity.y + entity.h - 8);
                    ctx.stroke();
                    ctx.setLineDash([]);
                }
            }
            // Autonomous Enemy NPC or Boss
            else if ((entity.type === 'enemy' || entity.type === 'boss') && entity.isAlive) {
                const isBoss = entity.type === 'boss';
                const eColor = (isBoss && entity.enraged) ? '#f43f5e' : entity.color;
                ctx.fillStyle = eColor;
                ctx.shadowColor = eColor;
                ctx.shadowBlur = isBoss ? 20 : 12;
                this.roundRect(ctx, entity.x, entity.y, entity.w, entity.h, isBoss ? 12 : 8, true, false);
                ctx.shadowBlur = 0;

                // Glowing Robotic Eye Visor
                ctx.fillStyle = '#ffffff';
                const eyeW = isBoss ? 16 : 8;
                const eyeH = isBoss ? 7 : 4;
                const eyeX = entity.dir > 0 ? entity.x + entity.w - eyeW - 6 : entity.x + 6;
                ctx.fillRect(eyeX, entity.y + (isBoss ? 16 : 12), eyeW, eyeH);

                // Enemy/Boss HP Bar
                if (entity.health < entity.maxHealth || isBoss) {
                    ctx.fillStyle = 'rgba(0, 0, 0, 0.75)';
                    ctx.fillRect(entity.x, entity.y - 12, entity.w, 5);
                    ctx.fillStyle = isBoss ? '#f43f5e' : '#ef4444';
                    ctx.fillRect(entity.x, entity.y - 12, entity.w * Math.max(0, entity.health / entity.maxHealth), 5);
                }

                // Name tag
                ctx.fillStyle = isBoss ? '#fbbf24' : '#f87171';
                ctx.font = isBoss ? 'bold 11.5px Outfit, sans-serif' : 'bold 10px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(isBoss && entity.enraged ? `⚡ ${entity.name} [FURIA]` : entity.name, entity.x + entity.w / 2, entity.y - 16);
                ctx.textAlign = 'left';
            }
            // Player Hero Character
            else if (entity.isPlayer) {
                if (entity.invulnerableTimer > 0 && Math.floor(this.lastTime / 90) % 2 === 0) {
                    continue;
                }

                ctx.save();
                ctx.translate(entity.x + entity.w / 2, entity.y + entity.h / 2);
                ctx.scale((entity.facing || 1) * (entity.squash || 1), entity.stretch || 1);

                const pCol = entity.overdrive ? '#ef4444' : (entity.color || '#38bdf8');
                const heroGrad = ctx.createLinearGradient(-entity.w / 2, -entity.h / 2, entity.w / 2, entity.h / 2);
                heroGrad.addColorStop(0, pCol);
                heroGrad.addColorStop(1, entity.overdrive ? '#7f1d1d' : '#0284c7');
                ctx.fillStyle = heroGrad;
                ctx.shadowColor = pCol;
                ctx.shadowBlur = (entity.overdrive ? 22 : 14) + Math.sin(entity.glowPulse || 0) * 4;
                this.roundRect(ctx, -entity.w / 2, -entity.h / 2, entity.w, entity.h, 10, true, false);
                ctx.shadowBlur = 0;

                ctx.fillStyle = '#ffffff';
                ctx.shadowColor = '#ffffff';
                ctx.shadowBlur = 6;
                this.roundRect(ctx, 0, -entity.h / 2 + 10, entity.w / 2 - 2, 7, 3, true, false);
                ctx.shadowBlur = 0;

                ctx.fillStyle = '#1e293b';
                ctx.fillRect(-entity.w / 2 - 4, -entity.h / 4, 4, entity.h / 2);

                ctx.restore();

                ctx.fillStyle = entity.overdrive ? '#ef4444' : '#38bdf8';
                ctx.font = 'bold 11px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(entity.overdrive ? `🔥 ${entity.name} [MONSTRUO]` : entity.name, entity.x + entity.w / 2, entity.y - 10);
                ctx.textAlign = 'left';
            }
        }

        // 5. Render Projectiles
        for (let pr of this.projectiles) {
            ctx.fillStyle = pr.color;
            ctx.shadowColor = pr.color;
            ctx.shadowBlur = 12;
            this.roundRect(ctx, pr.x, pr.y, pr.w, pr.h, 3, true, false);
            ctx.shadowBlur = 0;
        }

        // 6. Render Particle Bursts
        for (let p of this.particles) {
            ctx.fillStyle = p.color;
            ctx.globalAlpha = Math.max(0, p.alpha);
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalAlpha = 1.0;
        }

        // 7. Render Floating Text Popups
        for (let pop of this.popups) {
            ctx.fillStyle = pop.color;
            ctx.globalAlpha = Math.max(0, pop.alpha);
            ctx.font = 'bold 13px Outfit, sans-serif';
            ctx.shadowColor = pop.color;
            ctx.shadowBlur = 8;
            ctx.fillText(pop.text, pop.x, pop.y);
            ctx.shadowBlur = 0;
            ctx.globalAlpha = 1.0;
        }

        ctx.restore(); // Restore Camera Translation

        // ═══════════════════════════════════════════════════════════════
        //  SCREEN SPACE OVERLAYS & HEADS-UP DISPLAY (HUD)
        // ═══════════════════════════════════════════════════════════════

        // Boss HUD Health Bar & Combo Badge
        const activeBoss = this.gameEntities.find(e => e.type === 'boss' && e.isAlive);
        if (activeBoss) {
            const bw = Math.min(340, w - 120);
            const bx = (w - bw) / 2;
            const by = 14;
            ctx.fillStyle = 'rgba(6, 9, 19, 0.85)';
            ctx.strokeStyle = activeBoss.enraged ? '#f43f5e' : 'rgba(239, 68, 68, 0.5)';
            ctx.lineWidth = 1.5;
            this.roundRect(ctx, bx - 10, by - 6, bw + 20, 32, 8, true, true);

            ctx.fillStyle = activeBoss.enraged ? '#fbbf24' : '#f87171';
            ctx.font = 'bold 10.5px Outfit, monospace, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText(`👹 ${activeBoss.name} (${Math.max(0, Math.round(activeBoss.health))}/${activeBoss.maxHealth} HP)`, w / 2, by + 7);
            ctx.textAlign = 'left';

            ctx.fillStyle = '#1e293b';
            ctx.fillRect(bx, by + 13, bw, 7);
            ctx.fillStyle = activeBoss.enraged ? '#f43f5e' : '#ef4444';
            ctx.fillRect(bx, by + 13, bw * Math.max(0, activeBoss.health / activeBoss.maxHealth), 7);
        }

        if (this.combo > 1 && this.comboTimer > 0) {
            ctx.fillStyle = '#fbbf24';
            ctx.font = 'bold 12px Outfit, monospace, sans-serif';
            ctx.fillText(`⚡ COMBO x${this.combo}`, 18, h - 56);
        }

        // Render UI HUD Cards & Buttons
        for (let elem of this.renderQueue) {
            if (elem.type === 'card') {
                const cardGrad = ctx.createLinearGradient(elem.x, elem.y, elem.x + elem.w, elem.y + elem.h);
                cardGrad.addColorStop(0, 'rgba(15, 23, 42, 0.82)');
                cardGrad.addColorStop(1, 'rgba(30, 41, 59, 0.88)');

                ctx.fillStyle = cardGrad;
                ctx.strokeStyle = 'rgba(255, 255, 255, 0.16)';
                ctx.lineWidth = 1.2;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 14, true, true);

                ctx.fillStyle = '#38bdf8';
                ctx.font = 'bold 14px Outfit, sans-serif';
                ctx.fillText(elem.title, elem.x + 16, elem.y + 28);

                ctx.fillStyle = '#94a3b8';
                ctx.font = '11.5px Outfit, monospace, sans-serif';
                const lines = String(elem.text || '').replace(/\\n/g, '\n').split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const lineY = elem.y + 52 + (i * 20);
                    if (lineY < elem.y + elem.h - 8) {
                        ctx.fillText(lines[i], elem.x + 16, lineY);
                    }
                }
            } else if (elem.type === 'button') {
                const btnGrad = ctx.createLinearGradient(elem.x, elem.y, elem.x + elem.w, elem.y + elem.h);
                btnGrad.addColorStop(0, '#6366f1');
                btnGrad.addColorStop(1, '#8b5cf6');
                ctx.fillStyle = btnGrad;
                ctx.strokeStyle = '#a5b4fc';
                ctx.lineWidth = 1.5;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 10, true, true);

                ctx.fillStyle = '#ffffff';
                ctx.font = 'bold 13px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(elem.text, elem.x + elem.w / 2, elem.y + 26);
                ctx.textAlign = 'left';
            }
        }

        // Top Status HUD (Health, Lives, Score)
        const player = this.getPlayer();
        if (player) {
            // Health Bar Container (Top Left)
            ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
            ctx.lineWidth = 1.2;
            this.roundRect(ctx, 16, 16, 210, 48, 12, true, true);

            // Health bar fill
            const hpRatio = Math.max(0, player.health / player.maxHealth);
            const hpWidth = 120 * hpRatio;
            const hpColor = hpRatio > 0.5 ? '#10b981' : (hpRatio > 0.25 ? '#f59e0b' : '#ef4444');

            ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
            this.roundRect(ctx, 72, 26, 120, 12, 6, true, false);

            ctx.fillStyle = hpColor;
            ctx.shadowColor = hpColor;
            ctx.shadowBlur = 8;
            if (hpWidth > 0) this.roundRect(ctx, 72, 26, hpWidth, 12, 6, true, false);
            ctx.shadowBlur = 0;

            // Player Avatar Tag
            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 12px Outfit, sans-serif';
            ctx.fillText("HP", 46, 36);

            // Lives counter
            ctx.fillStyle = '#ef4444';
            for (let l = 0; l < this.lives; l++) {
                ctx.beginPath();
                ctx.arc(76 + l * 18, 49, 4.5, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        // Score Badge (Top Right)
        ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 1.5;
        this.roundRect(ctx, w - 170, 16, 154, 44, 12, true, true);

        ctx.fillStyle = '#fbbf24';
        ctx.font = 'bold 14px Outfit, sans-serif';
        ctx.fillText(`★ SCORE: ${this.score}`, w - 154, 43);

        // Virtual Touch Controls Overlay for Mobile / Tablets
        if (this.touchState.hasTouch || w < 768) {
            // D-Pad Left/Right
            ctx.fillStyle = 'rgba(30, 41, 59, 0.6)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.4)';
            ctx.lineWidth = 1.5;
            
            // Left Button
            this.roundRect(ctx, 20, h - 70, 52, 48, 12, true, true);
            ctx.fillStyle = '#f8fafc';
            ctx.font = 'bold 18px monospace';
            ctx.textAlign = 'center';
            ctx.fillText('◀', 46, h - 39);

            // Right Button
            ctx.fillStyle = 'rgba(30, 41, 59, 0.6)';
            this.roundRect(ctx, 80, h - 70, 52, 48, 12, true, true);
            ctx.fillStyle = '#f8fafc';
            ctx.fillText('▶', 106, h - 39);

            // Jump Button (A)
            ctx.fillStyle = 'rgba(56, 189, 248, 0.35)';
            ctx.strokeStyle = '#38bdf8';
            this.roundRect(ctx, w - 74, h - 70, 54, 48, 12, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('A', w - 47, h - 39);

            // Shoot Button (B)
            ctx.fillStyle = 'rgba(239, 68, 68, 0.35)';
            ctx.strokeStyle = '#ef4444';
            this.roundRect(ctx, w - 138, h - 70, 54, 48, 12, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('B', w - 111, h - 39);
            ctx.textAlign = 'left';
        }

        // Game Over Overlay
        if (this.gameOver) {
            ctx.fillStyle = 'rgba(6, 9, 15, 0.88)';
            ctx.fillRect(0, 0, w, h);

            ctx.fillStyle = '#ef4444';
            ctx.shadowColor = '#ef4444';
            ctx.shadowBlur = 20;
            ctx.font = '900 32px Outfit, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText("OPERACIÓN TERMINADA", w / 2, h / 2 - 30);
            ctx.shadowBlur = 0;

            ctx.fillStyle = '#f1f5f9';
            ctx.font = '16px Outfit, sans-serif';
            ctx.fillText(`Puntaje Final: ${this.score} Puntos`, w / 2, h / 2 + 10);

            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText("Presiona [R] o Toca la pantalla para Reintentar", w / 2, h / 2 + 48);
            ctx.textAlign = 'left';
        }

        // Victory Overlay
        if (this.gameWon) {
            ctx.fillStyle = 'rgba(6, 9, 15, 0.85)';
            ctx.fillRect(0, 0, w, h);

            ctx.fillStyle = '#fbbf24';
            ctx.shadowColor = '#fbbf24';
            ctx.shadowBlur = 24;
            ctx.font = '900 34px Outfit, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText("¡MISIÓN CUMPLIDA!", w / 2, h / 2 - 35);
            ctx.shadowBlur = 0;

            ctx.fillStyle = '#f8fafc';
            ctx.font = 'bold 18px Outfit, sans-serif';
            ctx.fillText(`ETAPA COMPLETADA • ${this.score} PUNTOS`, w / 2, h / 2 + 12);

            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText("Presiona [R] o Toca la pantalla para Jugar de Nuevo", w / 2, h / 2 + 52);
            ctx.textAlign = 'left';
        }

        // Pause Overlay
        if (this.paused && !this.gameOver && !this.gameWon) {
            ctx.fillStyle = 'rgba(6, 9, 15, 0.72)';
            ctx.fillRect(0, 0, w, h);
            ctx.fillStyle = '#38bdf8';
            ctx.font = '900 30px Outfit, sans-serif';
            ctx.textAlign = 'center';
            ctx.fillText('JUEGO EN PAUSA', w / 2, h / 2 - 14);
            ctx.fillStyle = '#e2e8f0';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText('Presiona [P] o [Esc] para continuar', w / 2, h / 2 + 20);
            ctx.textAlign = 'left';
        }

        // Bottom Watermark & Controls Helper
        ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
        ctx.font = '900 11px monospace';
        ctx.fillText("SHINE LOOP CONSOLE • 60 FPS 2D ENGINE • [P] Pausa • [R] Reiniciar", 20, h - 16);
    }

    roundRect(ctx, x, y, width, height, radius, fill, stroke) {
        ctx.beginPath();
        ctx.moveTo(x + radius, y);
        ctx.lineTo(x + width - radius, y);
        ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
        ctx.lineTo(x + width, y + height - radius);
        ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
        ctx.lineTo(x + radius, y + height);
        ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
        ctx.lineTo(x, y + radius);
        ctx.quadraticCurveTo(x, y, x + radius, y);
        ctx.closePath();
        if (fill) ctx.fill();
        if (stroke) ctx.stroke();
    }

    // ═══════════════════════════════════════════════════════════════
    //  SHINE LOOP 3D QUANTUM ENGINE (Arch 3.0A — Perspective + 120Hz)
    // ═══════════════════════════════════════════════════════════════

    getPlayer3D() {
        return this.entities3D.find(e => e.isPlayer);
    }

    cycleCamera3DMode() {
        const modes = ['chase', 'orbit', 'fps', 'topdown'];
        const idx = modes.indexOf(this.camera3D.mode);
        this.camera3D.mode = modes[(idx + 1) % modes.length];
        this.playSfx('coin');
        this.log(`🎥 [CAMERA 3D] Modo de cámara activo: ${this.camera3D.mode.toUpperCase()}`, 'info');
    }

    parseHexRGB(hex) {
        if (!hex || typeof hex !== 'string') return { r: 56, g: 189, b: 248 };
        let s = hex.trim();
        if (s.startsWith('#')) s = s.slice(1);
        if (s.length === 3) s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2];
        const num = parseInt(s.slice(0, 6), 16);
        if (isNaN(num)) return { r: 56, g: 189, b: 248 };
        return { r: (num >> 16) & 255, g: (num >> 8) & 255, b: num & 255 };
    }

    parseScene3DDirective(line) {
        this.is3DMode = true;
        const inner = line.includes('(') ? line.slice(line.indexOf('(') + 1, line.lastIndexOf(')')) : '';
        const args = this.parseNamedArgs(inner);

        if (line.startsWith('scene3d.clear')) {
            this.entities3D = [];
            this.particles3D = [];
            this.projectiles3D = [];
            return;
        }
        if (line.startsWith('scene3d.step')) {
            const dtArg = parseFloat(inner) || 0.016;
            this.update3D(dtArg);
            return;
        }
        if (line.startsWith('scene3d.world')) {
            if (args.name) this.scene3D.name = args.name;
            if (Array.isArray(args.size) && args.size.length >= 3) {
                this.scene3D.sizeX = args.size[0];
                this.scene3D.sizeY = args.size[1];
                this.scene3D.sizeZ = args.size[2];
            }
            if (args.sky) this.scene3D.sky = String(args.sky).toLowerCase();
            if (args.fog !== undefined) this.scene3D.fogDensity = Number(args.fog);
            if (args.grid !== undefined) this.scene3D.showGrid = Boolean(args.grid);
            if (args.floor !== undefined) this.scene3D.hasFloorPlane = Boolean(args.floor);
            if (args.floor_y !== undefined) this.scene3D.floorY = Number(args.floor_y);
            this.log(`🌐 [SCENE 3D] Mundo "${this.scene3D.name}" (${this.scene3D.sizeX}x${this.scene3D.sizeY}x${this.scene3D.sizeZ}m | Cielo: ${this.scene3D.sky})`, 'info');
            return;
        }
        if (line.startsWith('camera3d.set')) {
            if (args.mode) this.camera3D.mode = String(args.mode).toLowerCase();
            if (Array.isArray(args.pos) && args.pos.length >= 3) {
                this.camera3D.x = args.pos[0];
                this.camera3D.y = args.pos[1];
                this.camera3D.z = args.pos[2];
                const distXZ = Math.hypot(args.pos[0], args.pos[2]);
                if (distXZ > 2 && args.distance === undefined) {
                    this.camera3D.distance = Math.max(8, Math.min(36, distXZ));
                }
                if (args.height === undefined && args.pos[1] > 1) {
                    this.camera3D.heightOffset = Math.max(2.5, Math.min(18, args.pos[1] - 1.5));
                }
            }
            if (Array.isArray(args.target) && args.target.length >= 3) {
                this.camera3D.targetX = args.target[0];
                this.camera3D.targetY = args.target[1];
                this.camera3D.targetZ = args.target[2];
            }
            if (args.fov !== undefined) {
                this.camera3D.baseFov = Math.max(35, Math.min(110, Number(args.fov)));
                this.camera3D.fov = this.camera3D.baseFov;
            }
            if (args.smooth !== undefined) this.camera3D.smooth = Number(args.smooth);
            if (args.distance !== undefined) this.camera3D.distance = Number(args.distance);
            if (args.height !== undefined) this.camera3D.heightOffset = Number(args.height);
            this.log(`🎥 [CAMERA 3D] Modo: ${this.camera3D.mode} | FOV: ${this.camera3D.baseFov}° | Dist: ${this.camera3D.distance.toFixed(1)}m`, 'system');
            return;
        }
        if (line.startsWith('light3d.directional')) {
            const dir = Array.isArray(args.dir) ? args.dir : [-0.42, -0.88, -0.32];
            const col = args.color || '#ffffff';
            const intensity = args.intensity !== undefined ? Number(args.intensity) : 1.05;
            const existing = this.lights3D.find(l => l.type === 'directional');
            if (existing) {
                existing.dx = dir[0]; existing.dy = dir[1]; existing.dz = dir[2];
                existing.color = col; existing.intensity = intensity;
            } else {
                this.lights3D.push({ type: 'directional', dx: dir[0], dy: dir[1], dz: dir[2], color: col, intensity });
            }
            this.log(`☀️ [LIGHT 3D] Luz Direccional (${dir.join(', ')}) [Intensidad: ${intensity}]`, 'system');
            return;
        }
        if (line.startsWith('light3d.point')) {
            const at = Array.isArray(args.at) ? args.at : [0, 10, 15];
            this.lights3D.push({
                type: 'point',
                x: at[0], y: at[1], z: at[2],
                color: args.color || '#38bdf8',
                intensity: args.intensity !== undefined ? Number(args.intensity) : 1.25,
                range: args.range !== undefined ? Number(args.range) : 48
            });
            this.log(`💡 [LIGHT 3D] Luz Puntual en (${at.join(', ')}) [${args.color || '#38bdf8'}]`, 'system');
            return;
        }
        if (line.startsWith('light3d.ambient')) {
            if (args.color) this.scene3D.ambientColor = args.color;
            if (args.intensity !== undefined) this.scene3D.ambientIntensity = Number(args.intensity);
            return;
        }
        if (line.startsWith('physics3d.config')) {
            if (args.gravity !== undefined) {
                const g = Number(args.gravity);
                this.physics3D.gravity = g > 0 ? -g : g;
            }
            if (args.substeps !== undefined) this.physics3D.substeps = Math.max(1, Math.min(16, Math.round(Number(args.substeps))));
            if (args.friction !== undefined) this.physics3D.friction = Math.max(0.1, Math.min(0.99, Number(args.friction)));
            if (args.bounce !== undefined) this.physics3D.bounce = Math.max(0, Math.min(0.95, Number(args.bounce)));
            const effHz = 60 * this.physics3D.substeps;
            this.log(`⚙️ [PHYSICS 3D] Gravedad: ${this.physics3D.gravity} m/s² | Sub-steps: ${this.physics3D.substeps} (${effHz}Hz)`, 'system');
        }
    }

    parseSpawn3DDirective(line) {
        this.is3DMode = true;
        let kind = 'box';
        if (line.startsWith('spawn3d.')) {
            const dotEnd = line.indexOf('(');
            kind = (dotEnd > 8 ? line.slice(8, dotEnd) : line.slice(8)).trim().toLowerCase();
        } else if (line.startsWith('spawn 3d ')) {
            const parts = line.slice(9).trim().split(/[\s(]+/);
            kind = (parts[0] || 'box').toLowerCase();
        } else if (line.startsWith('spawn.')) {
            const dotEnd = line.indexOf('(');
            const rawK = (dotEnd > 6 ? line.slice(6, dotEnd) : line.slice(6)).trim().toLowerCase();
            const aliasMap = {
                player3d: 'player',
                cube: 'box',
                sphere: 'sphere',
                pyramid: 'pyramid',
                cylinder: 'cylinder',
                torus: 'torus',
                ring3d: 'ring',
                crystal: 'crystal',
                portal3d: 'portal'
            };
            kind = aliasMap[rawK] || rawK;
        }

        const inner = line.includes('(') ? line.slice(line.indexOf('(') + 1, line.lastIndexOf(')')) : '';
        const args = this.parseNamedArgs(inner);

        const at = Array.isArray(args.at) ? args.at : (Array.isArray(args.pos) ? args.pos : [0, 2, 0]);
        const px = Number(at[0] || 0);
        const py = Number(at[1] !== undefined ? at[1] : 2);
        const pz = Number(at[2] || 0);

        if (kind === 'cube' || kind === 'platform' || kind === 'terrain') kind = 'box';
        if (kind === 'drone') kind = 'enemy';
        if (kind === 'coin' || kind === 'gem') kind = 'crystal';
        if (kind === 'jump_pad') kind = 'pad';
        if (kind === 'spike') kind = 'hazard';
        if (kind === 'goal') kind = 'portal';

        const defaultSizes = {
            player: [2.2, 1.15, 3.1],
            box: [8, 1.2, 8],
            moving_platform: [6, 1.0, 6],
            sphere: [2.4, 2.4, 2.4],
            cylinder: [2.4, 3.2, 2.4],
            pyramid: [3.2, 3.6, 3.2],
            torus: [3.6, 3.6, 1.0],
            ring: [5.2, 5.2, 1.2],
            crystal: [1.5, 2.1, 1.5],
            heart: [1.5, 1.5, 1.5],
            pad: [3.4, 0.55, 3.4],
            hazard: [2.2, 2.0, 2.2],
            checkpoint: [1.8, 4.2, 1.8],
            enemy: [2.4, 2.0, 2.4],
            boss: [5.4, 5.0, 5.4],
            portal: [6.0, 6.0, 1.6]
        };
        const defSz = defaultSizes[kind] || [2, 2, 2];
        let sx = defSz[0], sy = defSz[1], sz = defSz[2];
        if (Array.isArray(args.size) && args.size.length >= 3) {
            sx = Number(args.size[0]);
            sy = Number(args.size[1]);
            sz = Number(args.size[2]);
        } else if (args.radius !== undefined) {
            const d = Number(args.radius) * 2;
            sx = d; sy = (kind === 'pad' ? 0.55 : d); sz = (kind === 'ring' || kind === 'portal' ? Math.max(1.0, d * 0.25) : d);
        }

        const defaultColors = {
            player: '#38bdf8',
            box: '#4f46e5',
            moving_platform: '#06b6d4',
            sphere: '#8b5cf6',
            cylinder: '#0ea5e9',
            pyramid: '#f59e0b',
            torus: '#ec4899',
            ring: '#00f5d4',
            crystal: '#fbbf24',
            heart: '#10b981',
            pad: '#f59e0b',
            hazard: '#ef4444',
            checkpoint: '#38bdf8',
            enemy: '#ef4444',
            boss: '#f43f5e',
            portal: '#c084fc'
        };

        const color = args.color || defaultColors[kind] || '#38bdf8';
        const rot = Array.isArray(args.rot) ? args.rot : [0, 0, 0];
        const axis = args.axis ? String(args.axis).toLowerCase() : 'x';
        const baseAxisCoord = axis === 'y' ? py : (axis === 'z' ? pz : px);
        const minPos = Array.isArray(args.range) ? Number(args.range[0]) : (baseAxisCoord - 8);
        const maxPos = Array.isArray(args.range) ? Number(args.range[1]) : (baseAxisCoord + 8);

        let meshType = args.mesh ? String(args.mesh).toLowerCase() : kind;
        if (kind === 'player' && (!args.mesh || meshType === 'player')) meshType = 'hovercraft';
        if (kind === 'moving_platform') meshType = 'box';

        const objSpec = args.obj || args.file || args.model || '';
        const scaleVal = args.scale !== undefined ? Number(args.scale) : 1.0;
        const csClass = args.cs || args.csharp || '';

        let customMesh = null;
        if (kind === 'obj' || objSpec) {
            const cacheKey = String(objSpec || args.name || 'starfighter');
            const cached = this.objMeshes3D[cacheKey];
            const bKey = resolveBuiltinOBJKey(cacheKey);
            if (cached) {
                customMesh = cached;
            } else if (bKey && BUILTIN_OBJ_MODELS[bKey]) {
                customMesh = parseWavefrontOBJ(BUILTIN_OBJ_MODELS[bKey], 1.0, bKey);
                this.objMeshes3D[cacheKey] = customMesh;
            }
            if (customMesh && customMesh.vertices.length) {
                meshType = 'obj';
                sx = Math.max(0.8, (customMesh.size[0] || 2) * scaleVal);
                sy = Math.max(0.8, (customMesh.size[1] || 2) * scaleVal);
                sz = Math.max(0.8, (customMesh.size[2] || 2) * scaleVal);
            }
        }

        const roleTag = String(args.tag || '').toLowerCase();
        const resolvedType = (kind === 'obj')
            ? ((roleTag === 'enemy' || roleTag === 'boss' || roleTag === 'player') ? roleTag : (objSpec ? 'obj' : kind))
            : kind;
        const ent = {
            id: this.entities3D.length + 1,
            type: resolvedType,
            meshType: meshType,
            objFile: objSpec,
            csClass: csClass,
            tag: args.tag || resolvedType,
            doubleSided: Boolean(args.double_sided || resolvedType === 'ring' || resolvedType === 'portal' || String(objSpec).includes('gate')),
            scaleVal: scaleVal,
            name: args.name || args.label || (resolvedType === 'player' ? 'AngelPilot3D' : (resolvedType === 'boss' ? 'OMEGA TITAN 3D' : resolvedType)),
            label: args.label || args.name || '',
            isPlayer: resolvedType === 'player',
            isSolid: resolvedType === 'box' || resolvedType === 'moving_platform',
            x: px, y: py, z: pz,
            spawnX: px, spawnY: py, spawnZ: pz,
            vx: 0, vy: 0, vz: 0,
            sx: sx, sy: sy, sz: sz,
            radius: args.radius !== undefined ? Number(args.radius) : Math.max(sx, sz) * 0.45,
            pitch: (rot[0] || 0) * Math.PI / 180,
            yaw: (rot[1] || 0) * Math.PI / 180,
            roll: (rot[2] || 0) * Math.PI / 180,
            color: color,
            rgb: this.parseHexRGB(color),
            speed: args.speed !== undefined ? Number(args.speed) : (resolvedType === 'player' ? 25 : (resolvedType === 'boss' ? 11 : 8.5)),
            jumpForce: args.jump !== undefined ? Number(args.jump) : 17.0,
            power: args.power !== undefined ? Number(args.power) : 25.0,
            points: args.points !== undefined ? Number(args.points) : (resolvedType === 'ring' ? 150 : 200),
            heal: args.heal !== undefined ? Number(args.heal) : 35,
            damage: args.damage !== undefined ? Number(args.damage) : 30,
            health: args.health !== undefined ? Number(args.health) : (resolvedType === 'player' ? 100 : (resolvedType === 'boss' ? 450 : 50)),
            maxHealth: args.health !== undefined ? Number(args.health) : (resolvedType === 'player' ? 100 : (resolvedType === 'boss' ? 450 : 50)),
            hitFlash: 0,
            axis: axis,
            minPos: Math.min(minPos, maxPos),
            maxPos: Math.max(minPos, maxPos),
            dir: 1,
            isAlive: true,
            collected: false,
            activated: false,
            grounded: false,
            coyoteTimer: 0,
            jumpBufferTimer: 0,
            canDoubleJump: args.double_jump !== undefined ? Boolean(args.double_jump) : true,
            doubleJumpAvailable: true,
            kers: 100,
            isDashing: false,
            dashTimer: 0,
            dashCooldown: 0,
            ringBoostCooldown: 0,
            invulnerableTimer: 0,
            lastShotTime: 0,
            fireRate: args.fire_rate !== undefined ? Number(args.fire_rate) : 1.75,
            fireTimer: 1.5,
            enraged: false,
            pulse: 0,
            floatSeed: Math.random() * Math.PI * 2,
            mesh: null
        };

        ent.mesh = customMesh
            ? {
                vertices: customMesh.vertices.map(v => [v[0] * scaleVal, v[1] * scaleVal, v[2] * scaleVal]),
                faces: customMesh.faces
            }
            : this.buildMesh3D(ent.meshType, ent.sx, ent.sy, ent.sz);
        this.entities3D.push(ent);

        if (csClass && this.csharpBridge.classes[csClass]) {
            this.csharpBridge.instantiate(csClass, `${ent.name}_cs`, ent.name);
        }

        if (ent.isPlayer) {
            this.camera3D.x = ent.x - Math.sin(ent.yaw) * this.camera3D.distance;
            this.camera3D.y = ent.y + this.camera3D.heightOffset;
            this.camera3D.z = ent.z - Math.cos(ent.yaw) * this.camera3D.distance;
            this.log(`🚀 [ENTITY 3D] Protagonista 3D "${ent.name}" en (${px}, ${py}, ${pz}) [Mesh: ${ent.meshType}]`, 'info');
        } else if (kind === 'obj' || objSpec) {
            const triCnt = ent.mesh?.faces ? ent.mesh.faces.length : 0;
            this.log(`🛸 [OBJ 3D] "${ent.name}" (${objSpec || ent.meshType}) en (${px}, ${py}, ${pz}) | Faces: ${triCnt}${csClass ? ` | C#: ${csClass}` : ''}`, 'info');
        } else if (kind === 'boss' || kind === 'enemy' || kind === 'portal' || kind === 'checkpoint') {
            this.log(`✨ [ENTITY 3D] ${kind.toUpperCase()} "${ent.name}" en (${px}, ${py}, ${pz})`, 'info');
        }
    }

    spawnObjEntity3D(opts = {}) {
        const name = String(opts.name || 'ObjEntity');
        const objSpec = String(opts.obj || opts.model || 'starfighter.obj');
        const at = Array.isArray(opts.at) ? opts.at : [0, 2, 0];
        const scale = opts.scale !== undefined ? Number(opts.scale) : 1.0;
        const color = opts.color || '#38bdf8';
        const hp = opts.health !== undefined ? Number(opts.health) : 100;
        const cs = opts.cs ? `, cs: "${opts.cs}"` : '';
        const roleType = (opts.type === 'enemy' || opts.type === 'boss' || opts.type === 'player') ? opts.type : 'obj';
        const tag = opts.tag || opts.type || roleType;
        const rangePart = (opts.range && Array.isArray(opts.range)) ? `, range: (${opts.range[0]}, ${opts.range[1]})` : '';
        const speedPart = opts.speed !== undefined ? `, speed: ${opts.speed}` : '';
        this.parseSpawn3DDirective(
            `spawn3d.${roleType}("${name}", obj: "${objSpec}", at: (${at[0] || 0}, ${at[1] ?? 2}, ${at[2] || 0}), scale: ${scale}, color: "${color}", health: ${hp}, tag: "${tag}"${rangePart}${speedPart}${cs})`
        );
        return this.entities3D.length;
    }

    evaluate3DBuiltin(expr) {
        try {
            const openIdx = expr.indexOf('(');
            if (openIdx < 0) return 0;
            const fn = expr.slice(0, openIdx).trim();
            const rawArgs = expr.slice(openIdx + 1, expr.lastIndexOf(')')).trim();

            // Split top-level arguments respecting [...] and (...)
            const parts = [];
            let cur = '', depth = 0, inQ = false, qC = '';
            for (let i = 0; i < rawArgs.length; i++) {
                const ch = rawArgs[i];
                if ((ch === '"' || ch === "'") && rawArgs[i - 1] !== '\\') {
                    if (!inQ) { inQ = true; qC = ch; }
                    else if (qC === ch) inQ = false;
                }
                if (!inQ) {
                    if (ch === '[' || ch === '(' || ch === '{') depth++;
                    else if (ch === ']' || ch === ')' || ch === '}') depth--;
                    else if (ch === ',' && depth === 0) {
                        parts.push(this.evaluateExpression(cur.trim()));
                        cur = '';
                        continue;
                    }
                }
                cur += ch;
            }
            if (cur.trim()) parts.push(this.evaluateExpression(cur.trim()));

            const toV3 = (v) => Array.isArray(v) ? [Number(v[0] || 0), Number(v[1] || 0), Number(v[2] || 0)] : [0, 0, 0];

            if (fn === 'math3d.vec3') return [Number(parts[0] || 0), Number(parts[1] || 0), Number(parts[2] || 0)];
            if (fn === 'math3d.dot') {
                const a = toV3(parts[0]), b = toV3(parts[1]);
                return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
            }
            if (fn === 'math3d.cross') {
                const a = toV3(parts[0]), b = toV3(parts[1]);
                return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
            }
            if (fn === 'math3d.length') {
                const a = toV3(parts[0]);
                return Math.hypot(a[0], a[1], a[2]);
            }
            if (fn === 'math3d.distance') {
                const a = toV3(parts[0]), b = toV3(parts[1]);
                return Number(Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]).toFixed(4));
            }
            if (fn === 'math3d.normalize') {
                const a = toV3(parts[0]);
                const l = Math.hypot(a[0], a[1], a[2]) || 1;
                return [a[0] / l, a[1] / l, a[2] / l];
            }
            if (fn === 'math3d.lerp') {
                const a = toV3(parts[0]), b = toV3(parts[1]), t = Number(parts[2] ?? 0.5);
                return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
            }
            if (fn === 'physics3d.collide_sphere') {
                const a = toV3(parts[0]), ra = Number(parts[1] || 1), b = toV3(parts[2]), rb = Number(parts[3] || 1);
                return Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]) <= (ra + rb);
            }
            if (fn === 'game.shake') {
                const amt = Number(parts[0] ?? 0.5);
                this.camera.shake = Math.max(this.camera.shake || 0, amt * 12);
                this.camera3D.shake = Math.min(1.5, Math.max(this.camera3D.shake || 0, amt));
                return amt;
            }
            if (fn === 'game.approach' || fn === 'game.move_toward') {
                const cur = Number(parts[0] || 0), tgt = Number(parts[1] || 0), maxD = Math.abs(Number(parts[2] ?? 1));
                const diff = tgt - cur;
                return Math.abs(diff) <= maxD ? tgt : cur + Math.sign(diff) * maxD;
            }
            if (fn === 'physics3d.raycast_scene' || fn === 'scene3d.raycast') {
                const orig = toV3(parts[0]), dir = toV3(parts[1]);
                const dl = Math.hypot(dir[0], dir[1], dir[2]) || 1;
                const dx = dir[0] / dl, dy = dir[1] / dl, dz = dir[2] / dl;
                let bestD = Infinity, bestName = '';
                for (const e of this.entities3D) {
                    if (e.isPlayer || !e.isAlive || e.collected) continue;
                    const ocx = e.x - orig[0], ocy = e.y - orig[1], ocz = e.z - orig[2];
                    const tProj = ocx * dx + ocy * dy + ocz * dz;
                    if (tProj < 0) continue;
                    const perp2 = (ocx * ocx + ocy * ocy + ocz * ocz) - tProj * tProj;
                    const r = Math.max(e.sx, e.sy, e.sz) * 0.55;
                    if (perp2 <= r * r && tProj < bestD) {
                        bestD = tProj - Math.sqrt(Math.max(0, r * r - perp2));
                        bestName = e.name;
                    }
                }
                return { hit: bestD < Infinity, distance: bestD < Infinity ? Number(bestD.toFixed(2)) : -1, entity: bestName };
            }
            if (fn === 'physics3d.resolve_collisions' || fn === 'scene3d.resolve_collisions') {
                const ent = this.entities3D.find(e => e.name === String(parts[0] || ''));
                if (!ent) return 0;
                let fixes = 0;
                const ehx = ent.sx * 0.5, ehy = ent.sy * 0.5, ehz = ent.sz * 0.5;
                for (const box of this.entities3D) {
                    if (box === ent || !box.isSolid || !box.isAlive) continue;
                    const bhx = box.sx * 0.5, bhy = box.sy * 0.5, bhz = box.sz * 0.5;
                    const dx = ent.x - box.x, dy = ent.y - box.y, dz = ent.z - box.z;
                    const ox = (ehx + bhx) - Math.abs(dx);
                    const oy = (ehy + bhy) - Math.abs(dy);
                    const oz = (ehz + bhz) - Math.abs(dz);
                    if (ox > 0 && oy > 0 && oz > 0) {
                        if (ox <= oy && ox <= oz) ent.x += dx >= 0 ? ox : -ox;
                        else if (oy <= ox && oy <= oz) ent.y += dy >= 0 ? oy : -oy;
                        else ent.z += dz >= 0 ? oz : -oz;
                        fixes++;
                    }
                }
                return fixes;
            }
            if (fn === 'scene3d.find') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || '') || x.label === String(parts[0] || ''));
                return e ? e.name : '';
            }
            if (fn === 'scene3d.get') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                return e ? { name: e.name, kind: e.type, x: e.x, y: e.y, z: e.z, health: e.health, active: e.isAlive, color: e.color } : {};
            }
            if (fn === 'scene3d.set_pos') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return false;
                e.x = Number(parts[1] ?? e.x); e.y = Number(parts[2] ?? e.y); e.z = Number(parts[3] ?? e.z);
                return [e.x, e.y, e.z];
            }
            if (fn === 'scene3d.move') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return [0, 0, 0];
                e.x += Number(parts[1] || 0); e.y += Number(parts[2] || 0); e.z += Number(parts[3] || 0);
                return [e.x, e.y, e.z];
            }
            if (fn === 'scene3d.rotate') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return [0, 0, 0];
                e.pitch += Number(parts[1] || 0) * Math.PI / 180;
                e.yaw += Number(parts[2] || 0) * Math.PI / 180;
                e.roll += Number(parts[3] || 0) * Math.PI / 180;
                return [e.pitch, e.yaw, e.roll];
            }
            if (fn === 'scene3d.damage') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return 0;
                e.health = Math.max(0, e.health - Number(parts[1] ?? 10));
                e.hitFlash = 1.0;
                if (e.health <= 0) e.isAlive = false;
                return e.health;
            }
            if (fn === 'scene3d.heal') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return 0;
                e.health = Math.min(e.maxHealth || 100, e.health + Number(parts[1] ?? 10));
                if (e.health > 0) e.isAlive = true;
                return e.health;
            }
            if (fn === 'scene3d.set_color') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return false;
                e.color = String(parts[1] || '#38bdf8');
                e.rgb = this.parseHexRGB(e.color);
                return true;
            }
            if (fn === 'scene3d.set_active') {
                const e = this.entities3D.find(x => x.name === String(parts[0] || ''));
                if (!e) return false;
                e.isAlive = Boolean(parts[1] ?? true);
                return e.isAlive;
            }
            if (fn === 'scene3d.alive_count') {
                const kindFilter = String(parts[0] || '');
                return this.entities3D.filter(e => e.isAlive && !e.collected && (!kindFilter || e.type === kindFilter)).length;
            }
            if (fn === 'scene3d.stats') {
                return {
                    active: this.is3DMode,
                    world: this.scene3D.name,
                    entities: this.entities3D.length,
                    alive_entities: this.entities3D.filter(e => e.isAlive && !e.collected).length,
                    substeps: this.physics3D.substeps,
                    effective_hz: 60 * this.physics3D.substeps
                };
            }

            // ── Wavefront .obj Pipeline (obj3d.* / mesh3d.*) ──
            if (fn === 'obj3d.load' || fn === 'mesh3d.load') {
                const src = String(parts[0] || 'starfighter');
                const key = String(parts[1] || src);
                const bKey = resolveBuiltinOBJKey(src) || 'starfighter';
                const mesh = parseWavefrontOBJ(BUILTIN_OBJ_MODELS[bKey] || '', 1.0, bKey);
                this.objMeshes3D[key] = mesh;
                return { ok: true, path: src, name: mesh.name, vertices: mesh.vertices.length, faces: mesh.faces.length, triangles: mesh.triangles, bounding_radius: mesh.boundingRadius, size: mesh.size };
            }
            if (fn === 'obj3d.parse' || fn === 'mesh3d.parse') {
                const key = String(parts[1] || `obj_${Object.keys(this.objMeshes3D).length + 1}`);
                const mesh = parseWavefrontOBJ(String(parts[0] || ''), 1.0, key);
                this.objMeshes3D[key] = mesh;
                return { ok: true, name: key, vertices: mesh.vertices.length, faces: mesh.faces.length, triangles: mesh.triangles, bounding_radius: mesh.boundingRadius, size: mesh.size };
            }
            if (fn === 'obj3d.subdivide' || fn === 'mesh3d.subdivide') {
                const key = String(parts[0] || '');
                if (this.objMeshes3D[key]) {
                    this.objMeshes3D[key] = subdivideOBJMesh(this.objMeshes3D[key]);
                    return this.objMeshes3D[key].faces.length;
                }
                return 0;
            }
            if (fn === 'obj3d.normalize' || fn === 'mesh3d.normalize') {
                const key = String(parts[0] || '');
                const tgt = Number(parts[1] || 2.0);
                if (this.objMeshes3D[key]) {
                    normalizeOBJMesh(this.objMeshes3D[key], tgt);
                    return this.objMeshes3D[key].boundingRadius;
                }
                return 0;
            }
            if (fn === 'obj3d.export' || fn === 'mesh3d.export_obj') {
                const key = String(parts[0] || '');
                const m = this.objMeshes3D[key] || parseWavefrontOBJ(BUILTIN_OBJ_MODELS[resolveBuiltinOBJKey(key) || 'starfighter'], 1.0, key);
                return exportWavefrontOBJ(m);
            }
            if (fn === 'obj3d.stats' || fn === 'mesh3d.stats') {
                const key = String(parts[0] || '');
                const m = this.objMeshes3D[key];
                return m ? { name: m.name, vertices: m.vertices.length, faces: m.faces.length, triangles: m.triangles, bounding_radius: m.boundingRadius, size: m.size } : {};
            }
            if (fn === 'obj3d.spawn' || fn === 'mesh3d.spawn_obj') {
                return this.spawnObjEntity3D({
                    name: String(parts[0] || 'ObjMesh'),
                    obj: String(parts[1] || 'starfighter.obj'),
                    at: [Number(parts[2] || 0), Number(parts[3] ?? 2), Number(parts[4] || 0)],
                    scale: parts[5] !== undefined ? Number(parts[5]) : 1.4,
                    color: parts[6] ? String(parts[6]) : '#38bdf8',
                    cs: parts[7] ? String(parts[7]) : ''
                });
            }

            // ── C# Bridge Builtins (csharp.* / cs.* / runcs / cs!) ──
            if (fn === 'cs!') {
                return this.csharpBridge.evalExpr(rawArgs);
            }
            if (fn === 'runcs') {
                const snipKey = rawArgs.replace(/['"]/g, '').trim();
                const code = this.csharpBridge.snippets[snipKey] || String(parts[0] || '');
                return this.csharpBridge.executeBlock(code);
            }
            if (fn === 'csharp.new' || fn === 'cs.new' || fn === 'csharp.attach' || fn === 'csharp.instantiate') {
                return this.csharpBridge.instantiate(String(parts[0] || ''), String(parts[1] || ''), String(parts[2] || parts[1] || ''));
            }
            if (fn === 'csharp.call' || fn === 'cs.call') {
                return this.csharpBridge.callMethod(String(parts[0] || ''), String(parts[1] || 'Update'), parts.slice(2));
            }
            if (fn === 'csharp.step' || fn === 'cs.step') {
                return this.csharpBridge.stepAll(Number(parts[0] ?? 1 / 60));
            }
            if (fn === 'csharp.get' || fn === 'cs.get') {
                const inst = this.csharpBridge.instances[String(parts[0] || '')];
                return inst ? inst.fields[String(parts[1] || '')] : undefined;
            }
            if (fn === 'csharp.set' || fn === 'cs.set') {
                const inst = this.csharpBridge.instances[String(parts[0] || '')];
                if (inst) { inst.fields[String(parts[1] || '')] = parts[2]; return parts[2]; }
                return undefined;
            }
            if (fn === 'csharp.classes' || fn === 'cs.classes') {
                return Object.keys(this.csharpBridge.classes);
            }
            if (fn === 'csharp.export' || fn === 'cs.export') {
                return this.csharpBridge.exportScene(String(parts[0] || 'LoopizeGeneratedGame'));
            }

            // ── loopize++ Game Additions Builtins (loopize.* / lz.* / lz_* / ecs.*) ──
            if (fn === 'lz_banner') {
                this.log(`⚡ [loopize++ v1.0.0] Game Additions Engine Ready -> ${parts[0] || ''}`, 'success');
                return true;
            }
            if (fn === 'loopize.init' || fn === 'lz.init') {
                return this.loopize.init(String(parts[0] || 'LoopizeGame'));
            }
            if (fn === 'loopize.ecs_spawn' || fn === 'lz.ecs_spawn' || fn === 'ecs.spawn' || fn === 'lz_spawn_obj') {
                return this.loopize.ecsSpawn(String(parts[0] || 'Entity'), String(parts[1] || 'entity'), parts[2] || [0, 2, 0], Number(parts[3] ?? 100), String(parts[4] || ''), String(parts[5] || ''));
            }
            if (fn === 'loopize.ecs_query_tag' || fn === 'lz.ecs_query_tag') {
                return this.loopize.ecsQueryTag(String(parts[0] || ''));
            }
            if (fn === 'loopize.ecs_set' || fn === 'lz.ecs_set') {
                return this.loopize.ecsSet(parts[0], String(parts[1] || ''), parts[2]);
            }
            if (fn === 'loopize.ecs_get' || fn === 'lz.ecs_get') {
                return this.loopize.ecsGet(parts[0], String(parts[1] || ''));
            }
            if (fn === 'loopize.ecs_destroy' || fn === 'lz.ecs_destroy') {
                return this.loopize.ecsDestroy(parts[0]);
            }
            if (fn === 'loopize.spatial_radius' || fn === 'lz.spatial_radius') {
                return this.loopize.spatialRadius(toV3(parts[0]), Number(parts[1] || 5), String(parts[2] || ''));
            }
            if (fn === 'lz_wave_rush') {
                this.loopize.waveDefine(Number(parts[0] || 1), Number(parts[2] || 3), Number(parts[3] || 90), String(parts[1] || 'valkyrie'), String(parts[4] || 'valkyrie_drone.obj'));
                return this.loopize.waveSpawn(Number(parts[0] || 1));
            }
            if (fn === 'loopize.wave_define' || fn === 'lz.wave_define') {
                return this.loopize.waveDefine(Number(parts[0] || 1), Number(parts[1] || 4), Number(parts[2] || 80), String(parts[3] || 'valkyrie'), String(parts[4] || 'valkyrie_drone.obj'));
            }
            if (fn === 'loopize.wave_add' || fn === 'lz.wave_add') {
                return this.loopize.waveAdd(Number(parts[0] || 1), String(parts[1] || 'valkyrie'), Number(parts[2] || 4), Number(parts[3] || 80), String(parts[4] || 'valkyrie_drone.obj'));
            }
            if (fn === 'loopize.wave_spawn' || fn === 'lz.wave_spawn') {
                return this.loopize.waveSpawn(Number(parts[0] || 1));
            }
            if (fn === 'loopize.wave_next' || fn === 'lz.wave_next') {
                return this.loopize.waveNext();
            }
            if (fn === 'loopize.wave_status' || fn === 'lz.wave_status') {
                return this.loopize.waveStatus(Number(parts[0] || 0));
            }
            if (fn === 'loopize.fsm_set' || fn === 'lz.fsm_set' || fn === 'lz_fsm') {
                this.loopize.fsm[String(parts[0] || 'hero')] = String(parts[1] || 'idle');
                return this.loopize.fsm[String(parts[0] || 'hero')];
            }
            if (fn === 'loopize.fsm_get' || fn === 'lz.fsm_get') {
                return this.loopize.fsm[String(parts[0] || 'hero')] || 'idle';
            }
            if (fn === 'loopize.combo_hit' || fn === 'lz.combo_hit' || fn === 'lz_hit_combo') {
                if (parts[1] !== undefined) this.loopize.shake(Number(parts[1]));
                return this.loopize.comboHit(Number(parts[0] || 100));
            }
            if (fn === 'loopize.combo_mult' || fn === 'lz.combo_mult') {
                return this.loopize.combo.multiplier;
            }
            if (fn === 'loopize.ease' || fn === 'lz.ease' || fn === 'lz_ease') {
                return this.loopize.ease(String(parts[0] || 'out_cubic'), Number(parts[1] || 0));
            }
            if (fn === 'loopize.tween' || fn === 'lz.tween' || fn === 'lz_tween') {
                return this.loopize.tween(String(parts[0] || 'tw'), String(parts[1] || 'out_cubic'), Number(parts[2] || 0), Number(parts[3] ?? 1), Number(parts[4] ?? 1), Boolean(parts[5]), Boolean(parts[6]));
            }
            if (fn === 'loopize.tween_value' || fn === 'lz.tween_value') {
                return this.loopize.tweenValue(String(parts[0] || 'tw'));
            }
            if (fn === 'loopize.shake' || fn === 'lz.shake' || fn === 'loopize.camera_shake') {
                return this.loopize.shake(Number(parts[0] || 0.4));
            }
            if (fn === 'loopize.camera_update' || fn === 'lz.camera_update') {
                this.loopize.tick(Number(parts[1] || 0.016));
                return [this.camera3D.x, this.camera3D.y, this.camera3D.z];
            }
            if (fn === 'loopize.camera_pos' || fn === 'lz.camera_pos') {
                return [this.camera3D.x, this.camera3D.y, this.camera3D.z];
            }
            if (fn === 'loopize.inventory_add' || fn === 'lz.inventory_add') {
                const k = String(parts[0] || 'item');
                this.loopize.inventory[k] = (this.loopize.inventory[k] || 0) + Number(parts[1] || 1);
                return this.loopize.inventory[k];
            }
            if (fn === 'loopize.inventory_use' || fn === 'lz.inventory_use') {
                const k = String(parts[0] || 'item'), amt = Number(parts[1] || 1);
                if ((this.loopize.inventory[k] || 0) >= amt) { this.loopize.inventory[k] -= amt; return true; }
                return false;
            }
            if (fn === 'loopize.inventory_has' || fn === 'lz.inventory_has') {
                const k = String(parts[0] || 'item'), amt = Number(parts[1] ?? 1);
                return (this.loopize.inventory[k] || 0) >= amt;
            }
            if (fn === 'loopize.quest_add' || fn === 'lz.quest_add' || fn === 'lz_mission') {
                return this.loopize.questAdd(String(parts[0] || 'q1'), String(parts[1] || 'Quest'), Number(parts[2] || 1), Number(parts[3] || 500));
            }
            if (fn === 'loopize.quest_progress' || fn === 'lz.quest_progress') {
                return this.loopize.questProgress(String(parts[0] || 'q1'), Number(parts[1] || 1));
            }
            if (fn === 'loopize.step' || fn === 'lz.step' || fn === 'lz_step') {
                this.loopize.tick(Number(parts[0] ?? 1 / 60));
                return true;
            }
            if (fn === 'loopize.stats' || fn === 'lz.stats' || fn === 'lz_report') {
                const st = this.loopize.stats();
                this.log(`📊 [loopize++] ECS=${st.ecs_count} | Waves=${st.waves_total} | AliveEnemies=${st.alive_enemies} | Combo x${st.combo_mult} | Lvl ${st.level} (${st.xp} XP)`, 'info');
                return st;
            }
        } catch (e) {}
        return 0;
    }

    // ── Procedural & Wavefront .obj 3D Mesh Synthesis ──
    buildMesh3D(meshType, sx, sy, sz) {
        const builtinKey = resolveBuiltinOBJKey(meshType);
        if (builtinKey && BUILTIN_OBJ_MODELS[builtinKey]) {
            const parsed = parseWavefrontOBJ(BUILTIN_OBJ_MODELS[builtinKey], 1.0, builtinKey);
            const rx = (sx || 2) / Math.max(parsed.size[0] || 1, 0.25);
            const ry = (sy || 2) / Math.max(parsed.size[1] || 1, 0.25);
            const rz = (sz || 2) / Math.max(parsed.size[2] || 1, 0.25);
            const sc = Math.min(rx, ry, rz);
            return {
                vertices: parsed.vertices.map(v => [v[0] * sc, v[1] * sc, v[2] * sc]),
                faces: parsed.faces
            };
        }

        const hx = sx * 0.5, hy = sy * 0.5, hz = sz * 0.5;
        const vertices = [];
        const faces = [];

        const addFace = (idxArr, shadeBias = 1.0, tint = null) => {
            const p0 = vertices[idxArr[0]], p1 = vertices[idxArr[1]], p2 = vertices[idxArr[2]];
            const ux = p1[0] - p0[0], uy = p1[1] - p0[1], uz = p1[2] - p0[2];
            const vx = p2[0] - p0[0], vy = p2[1] - p0[1], vz = p2[2] - p0[2];
            let nx = uy * vz - uz * vy;
            let ny = uz * vx - ux * vz;
            let nz = ux * vy - uy * vx;
            const nl = Math.hypot(nx, ny, nz) || 1;
            nx /= nl; ny /= nl; nz /= nl;

            // Ensure outward-pointing normal relative to mesh centroid (0,0,0)
            let cx = 0, cy = 0, cz = 0;
            for (const id of idxArr) { cx += vertices[id][0]; cy += vertices[id][1]; cz += vertices[id][2]; }
            cx /= idxArr.length; cy /= idxArr.length; cz /= idxArr.length;
            if (nx * cx + ny * cy + nz * cz < 0) {
                nx = -nx; ny = -ny; nz = -nz;
                idxArr = idxArr.slice().reverse();
            }
            faces.push({ indices: idxArr, nx, ny, nz, bias: shadeBias, tint });
        };

        if (meshType === 'hovercraft' || meshType === 'kart') {
            // Sleek Cyber-Hovercraft: Nose, Fuselage, Canopy, Delta Wings, Twin Ion Thrusters
            vertices.push(
                [0, 0.05 * sy, hz],                 // 0: Nose tip
                [-hx * 0.45, 0.18 * sy, hz * 0.25], // 1: Front-left hull
                [ hx * 0.45, 0.18 * sy, hz * 0.25], // 2: Front-right hull
                [-hx, -0.10 * sy, -hz * 0.72],      // 3: Wingtip left
                [ hx, -0.10 * sy, -hz * 0.72],      // 4: Wingtip right
                [-hx * 0.48, 0.28 * sy, -hz],       // 5: Rear-left upper
                [ hx * 0.48, 0.28 * sy, -hz],       // 6: Rear-right upper
                [0, -hy, hz * 0.55],                // 7: Keel front
                [-hx * 0.52, -hy, -hz * 0.90],      // 8: Keel rear-left
                [ hx * 0.52, -hy, -hz * 0.90],      // 9: Keel rear-right
                [0, hy * 1.08, -hz * 0.08],         // 10: Cockpit apex
                [-hx * 0.28, 0.30 * sy, -hz * 0.58],// 11: Cockpit rear-left
                [ hx * 0.28, 0.30 * sy, -hz * 0.58] // 12: Cockpit rear-right
            );
            addFace([0, 2, 1], 1.15);
            addFace([1, 2, 10], 1.25, '#e0f2fe'); // Glass canopy front
            addFace([1, 10, 11], 1.10, '#bae6fd');
            addFace([2, 12, 10], 1.10, '#bae6fd');
            addFace([10, 12, 11], 0.95, '#7dd3fc');
            addFace([1, 11, 5, 3], 1.02); // Left delta wing
            addFace([2, 4, 6, 12], 1.02); // Right delta wing
            addFace([11, 12, 6, 5], 0.92);
            addFace([0, 1, 3, 8, 7], 0.78);
            addFace([0, 7, 9, 4, 2], 0.82);
            addFace([5, 6, 9, 8], 1.30, '#00f5d4'); // Glowing Ion Thruster Backplate
            addFace([7, 8, 9], 0.55);
            return { vertices, faces };
        }

        if (meshType === 'crystal' || meshType === 'diamond') {
            vertices.push(
                [0, hy, 0], [0, -hy, 0],
                [-hx, 0, 0], [0, 0, hz], [hx, 0, 0], [0, 0, -hz]
            );
            addFace([0, 3, 2], 1.2); addFace([0, 4, 3], 1.1);
            addFace([0, 5, 4], 0.95); addFace([0, 2, 5], 1.05);
            addFace([1, 2, 3], 0.82); addFace([1, 3, 4], 0.78);
            addFace([1, 4, 5], 0.68); addFace([1, 5, 2], 0.72);
            return { vertices, faces };
        }

        if (meshType === 'pyramid' || meshType === 'hazard' || meshType === 'cone') {
            vertices.push(
                [-hx, -hy, -hz], [hx, -hy, -hz], [hx, -hy, hz], [-hx, -hy, hz], [0, hy, 0]
            );
            addFace([0, 1, 4], 0.95); addFace([1, 2, 4], 1.08);
            addFace([2, 3, 4], 1.14); addFace([3, 0, 4], 0.85);
            addFace([0, 3, 2, 1], 0.55);
            return { vertices, faces };
        }

        if (meshType === 'cylinder' || meshType === 'pad' || meshType === 'checkpoint') {
            const segs = 10;
            for (let i = 0; i < segs; i++) {
                const a = (i / segs) * Math.PI * 2;
                const x = Math.cos(a) * hx, z = Math.sin(a) * hz;
                vertices.push([x, -hy, z], [x, hy, z]);
            }
            const topRing = [], botRing = [];
            for (let i = 0; i < segs; i++) {
                const ni = (i + 1) % segs;
                const b0 = i * 2, t0 = i * 2 + 1, b1 = ni * 2, t1 = ni * 2 + 1;
                addFace([b0, b1, t1, t0], 0.95);
                topRing.push(t0);
                botRing.push(b0);
            }
            addFace(topRing, 1.18, meshType === 'pad' ? '#fef08a' : null);
            addFace(botRing.reverse(), 0.55);
            return { vertices, faces };
        }

        if (meshType === 'torus' || meshType === 'ring' || meshType === 'portal') {
            const segMajor = 12, segMinor = 6;
            const R = Math.max(hx, hy) * 0.78;
            const r = Math.max(0.28, Math.min(hx, hy) * 0.22);
            for (let i = 0; i < segMajor; i++) {
                const u = (i / segMajor) * Math.PI * 2;
                const cu = Math.cos(u), su = Math.sin(u);
                for (let j = 0; j < segMinor; j++) {
                    const v = (j / segMinor) * Math.PI * 2;
                    const cv = Math.cos(v), sv = Math.sin(v);
                    vertices.push([(R + r * cv) * cu, (R + r * cv) * su, r * sv * (sz / Math.max(1, r * 2))]);
                }
            }
            for (let i = 0; i < segMajor; i++) {
                const ni = (i + 1) % segMajor;
                for (let j = 0; j < segMinor; j++) {
                    const nj = (j + 1) % segMinor;
                    const i0 = i * segMinor + j;
                    const i1 = ni * segMinor + j;
                    const i2 = ni * segMinor + nj;
                    const i3 = i * segMinor + nj;
                    addFace([i0, i1, i2, i3], 1.12);
                }
            }
            return { vertices, faces };
        }

        if (meshType === 'sphere' || meshType === 'heart' || meshType === 'enemy' || meshType === 'boss') {
            const lat = meshType === 'boss' ? 6 : 5;
            const lon = meshType === 'boss' ? 10 : 8;
            for (let i = 0; i <= lat; i++) {
                const th = (i / lat) * Math.PI;
                const st = Math.sin(th), ct = Math.cos(th);
                for (let j = 0; j < lon; j++) {
                    const ph = (j / lon) * Math.PI * 2;
                    vertices.push([hx * st * Math.cos(ph), hy * ct, hz * st * Math.sin(ph)]);
                }
            }
            for (let i = 0; i < lat; i++) {
                for (let j = 0; j < lon; j++) {
                    const nj = (j + 1) % lon;
                    const a = i * lon + j, b = i * lon + nj;
                    const c = (i + 1) * lon + nj, d = (i + 1) * lon + j;
                    const isVisor = (meshType === 'enemy' || meshType === 'boss') && i === Math.floor(lat / 2) && (j === 1 || j === 2);
                    addFace([a, b, c, d], isVisor ? 1.35 : 1.0, isVisor ? '#fef2f2' : null);
                }
            }
            return { vertices, faces };
        }

        // Default Box / Architectural Platform (with subdivided top deck on large platforms for clean Z-sorting)
        const divX = sx > 12 ? Math.min(4, Math.ceil(sx / 10)) : 1;
        const divZ = sz > 12 ? Math.min(4, Math.ceil(sz / 10)) : 1;

        vertices.push(
            [-hx, -hy, -hz], [hx, -hy, -hz], [hx, hy, -hz], [-hx, hy, -hz],
            [-hx, -hy,  hz], [hx, -hy,  hz], [hx, hy,  hz], [-hx, hy,  hz]
        );
        addFace([0, 3, 2, 1], 0.84); // Back
        addFace([4, 5, 6, 7], 0.94); // Front
        addFace([0, 1, 5, 4], 0.52); // Bottom
        addFace([1, 2, 6, 5], 0.88); // Right
        addFace([0, 4, 7, 3], 0.78); // Left

        if (divX === 1 && divZ === 1) {
            addFace([3, 7, 6, 2], 1.12); // Top
        } else {
            const baseIdx = vertices.length;
            for (let ix = 0; ix <= divX; ix++) {
                const px = -hx + (sx * ix) / divX;
                for (let iz = 0; iz <= divZ; iz++) {
                    const pz = -hz + (sz * iz) / divZ;
                    vertices.push([px, hy, pz]);
                }
            }
            const stride = divZ + 1;
            for (let ix = 0; ix < divX; ix++) {
                for (let iz = 0; iz < divZ; iz++) {
                    const a = baseIdx + ix * stride + iz;
                    const b = baseIdx + ix * stride + (iz + 1);
                    const c = baseIdx + (ix + 1) * stride + (iz + 1);
                    const d = baseIdx + (ix + 1) * stride + iz;
                    addFace([a, b, c, d], 1.12);
                }
            }
        }
        return { vertices, faces };
    }

    triggerDash3D(player) {
        if (!player || this.gameOver || this.gameWon) return;
        if (player.dashCooldown <= 0 && player.kers >= 30) {
            player.isDashing = true;
            player.dashTimer = 0.22;
            player.dashCooldown = 0.55;
            player.kers = Math.max(0, player.kers - 35);
            const dirX = Math.sin(player.yaw);
            const dirZ = Math.cos(player.yaw);
            const boostSpd = player.speed * 2.15;
            player.vx = dirX * boostSpd;
            player.vz = dirZ * boostSpd;
            player.vy = Math.max(player.vy, 1.5);
            this.camera3D.shake = 0.35;
            this.playSfx('dash');
            this.spawnParticleBurst3D(player.x, player.y, player.z, '#00f5d4', 22, 14);
            this.addPopup3D(player.x, player.y + 1.8, player.z, '⚡ HYPER-DASH!', '#00f5d4');
        }
    }

    shootProjectile3D(player) {
        const now = performance.now();
        if (player.lastShotTime && now - player.lastShotTime < 170) return;
        player.lastShotTime = now;

        let dx = Math.sin(player.yaw);
        let dy = 0;
        let dz = Math.cos(player.yaw);

        // Subtle smart target-assist within narrow forward cone for crisp 3D arcade combat
        let bestScore = 0.86;
        for (const e of this.entities3D) {
            if ((e.type === 'enemy' || e.type === 'boss') && e.isAlive) {
                const tx = e.x - player.x, ty = e.y - player.y, tz = e.z - player.z;
                const dist = Math.hypot(tx, ty, tz);
                if (dist > 1 && dist < 68) {
                    const nx = tx / dist, ny = ty / dist, nz = tz / dist;
                    const dot = nx * dx + nz * dz;
                    if (dot > bestScore) {
                        bestScore = dot;
                        dx = nx; dy = ny; dz = nz;
                    }
                }
            }
        }

        const boltSpeed = 68;
        this.projectiles3D.push({
            x: player.x + dx * 1.8,
            y: player.y + 0.25,
            z: player.z + dz * 1.8,
            vx: dx * boltSpeed,
            vy: dy * boltSpeed,
            vz: dz * boltSpeed,
            radius: 0.55,
            color: '#38bdf8',
            isPlayer: true,
            damage: 25,
            life: 1.6
        });

        this.playSfx('shoot');
        this.spawnParticleBurst3D(player.x + dx * 1.8, player.y + 0.25, player.z + dz * 1.8, '#38bdf8', 7, 8);
    }

    spawnParticleBurst3D(x, y, z, color, count = 14, speedScale = 10) {
        for (let i = 0; i < count; i++) {
            const u = Math.random() * Math.PI * 2;
            const v = (Math.random() - 0.35) * Math.PI;
            const spd = (Math.random() * 0.7 + 0.3) * speedScale;
            this.particles3D.push({
                x, y, z,
                vx: Math.cos(u) * Math.cos(v) * spd,
                vy: Math.sin(v) * spd + 2.5,
                vz: Math.sin(u) * Math.cos(v) * spd,
                color,
                size: Math.random() * 0.28 + 0.14,
                alpha: 1.0,
                life: Math.random() * 0.55 + 0.3
            });
        }
    }

    addPopup3D(x, y, z, text, color = '#38bdf8') {
        this.popups3D.push({ x, y, z, text, color, vy: 3.5, alpha: 1.0 });
    }

    // ── 120Hz+ Sub-Stepping 3D Physics & Gameplay Loop ──
    update3D(dt) {
        dt = Math.min(dt, 0.05) * (this.timeScale || 1.0);
        if (this.comboTimer > 0) {
            this.comboTimer -= dt;
            if (this.comboTimer <= 0) this.combo = 0;
        }

        // Camera yaw manual orbit via [Q] / [E] or Right Thumbstick
        if (this.keysDown['q']) this.camera3D.yawOffset -= 1.85 * dt;
        if (this.keysDown['e']) this.camera3D.yawOffset += 1.85 * dt;
        if (this.gamepadState.axisCamX) this.camera3D.yawOffset += this.gamepadState.axisCamX * 2.1 * dt;

        const hasSolidPlatforms = this.entities3D.some(e => e.isSolid);
        const useInfiniteFloor = this.scene3D.hasFloorPlane || !hasSolidPlatforms;

        const steps = Math.max(1, Math.min(16, this.physics3D.substeps || 4));
        const sdt = dt / steps;
        if (this.loopize) this.loopize.tick(dt);
        if (this.csharpBridge && Object.keys(this.csharpBridge.instances).length > 0) {
            this.csharpBridge.stepAll(dt);
        }

        for (let step = 0; step < steps; step++) {
            // 1. Step Moving Platforms & Rotating Collectibles/Portals
            for (const ent of this.entities3D) {
                ent.vxPlatform = 0; ent.vyPlatform = 0; ent.vzPlatform = 0;
                if (ent.hitFlash > 0) ent.hitFlash = Math.max(0, ent.hitFlash - 4.5 * sdt);
                if (ent.type === 'moving_platform') {
                    const delta = ent.dir * ent.speed * sdt;
                    if (ent.axis === 'y') {
                        ent.y += delta; ent.vyPlatform = ent.dir * ent.speed;
                        if (ent.y >= ent.maxPos) { ent.y = ent.maxPos; ent.dir = -1; }
                        if (ent.y <= ent.minPos) { ent.y = ent.minPos; ent.dir = 1; }
                    } else if (ent.axis === 'z') {
                        ent.z += delta; ent.vzPlatform = ent.dir * ent.speed;
                        if (ent.z >= ent.maxPos) { ent.z = ent.maxPos; ent.dir = -1; }
                        if (ent.z <= ent.minPos) { ent.z = ent.minPos; ent.dir = 1; }
                    } else {
                        ent.x += delta; ent.vxPlatform = ent.dir * ent.speed;
                        if (ent.x >= ent.maxPos) { ent.x = ent.maxPos; ent.dir = -1; }
                        if (ent.x <= ent.minPos) { ent.x = ent.minPos; ent.dir = 1; }
                    }
                } else if (ent.type === 'crystal' || ent.type === 'heart') {
                    ent.yaw += 2.2 * sdt;
                } else if (ent.type === 'ring') {
                    ent.roll += 1.4 * sdt;
                } else if (ent.type === 'portal') {
                    ent.roll += 2.0 * sdt;
                } else if (ent.pulse > 0) {
                    ent.pulse = Math.max(0, ent.pulse - 3.2 * sdt);
                }
            }

            // 2. Step Player & Autonomous 3D Enemies/Bosses
            for (const ent of this.entities3D) {
                if (ent.isPlayer && !this.gameOver && !this.gameWon) {
                    if (ent.coyoteTimer > 0) ent.coyoteTimer -= sdt;
                    if (ent.jumpBufferTimer > 0) ent.jumpBufferTimer -= sdt;
                    if (ent.invulnerableTimer > 0) ent.invulnerableTimer -= sdt;
                    if (ent.dashCooldown > 0) ent.dashCooldown -= sdt;
                    if (ent.ringBoostCooldown > 0) ent.ringBoostCooldown -= sdt;
                    ent.kers = Math.min(100, ent.kers + 18 * sdt);

                    // Camera-relative XZ input vector
                    let inX = 0, inZ = 0;
                    if (this.keysDown['a'] || this.keysDown['arrowleft'] || this.gamepadState.dpad.left) inX -= 1;
                    if (this.keysDown['d'] || this.keysDown['arrowright'] || this.gamepadState.dpad.right) inX += 1;
                    if (this.keysDown['w'] || this.keysDown['arrowup'] || this.gamepadState.dpad.up) inZ += 1;
                    if (this.keysDown['s'] || this.keysDown['arrowdown'] || this.gamepadState.dpad.down) inZ -= 1;

                    if (Math.abs(this.touchState.stickX) > 0.1 || Math.abs(this.touchState.stickY) > 0.1) {
                        inX = this.touchState.stickX;
                        inZ = this.touchState.stickY;
                    } else if (Math.abs(this.gamepadState.axisX) > 0.16 || Math.abs(this.gamepadState.axisY) > 0.16) {
                        inX = this.gamepadState.axisX;
                        inZ = this.gamepadState.axisY;
                    }

                    const inLen = Math.hypot(inX, inZ);
                    if (inLen > 1) { inX /= inLen; inZ /= inLen; }

                    const refYaw = this.camera3D.yawOffset;
                    const fwdX = Math.sin(refYaw), fwdZ = Math.cos(refYaw);
                    const rgtX = Math.cos(refYaw), rgtZ = -Math.sin(refYaw);
                    const moveX = fwdX * inZ + rgtX * inX;
                    const moveZ = fwdZ * inZ + rgtZ * inX;

                    if (ent.isDashing) {
                        ent.dashTimer -= sdt;
                        if (Math.random() < 0.45) {
                            this.spawnParticleBurst3D(ent.x, ent.y - 0.2, ent.z, '#00f5d4', 1, 4);
                        }
                        if (ent.dashTimer <= 0) ent.isDashing = false;
                    } else {
                        if (inLen > 0.08) {
                            const accel = ent.grounded ? 9.5 : 5.2;
                            const targetVx = moveX * ent.speed;
                            const targetVz = moveZ * ent.speed;
                            ent.vx += (targetVx - ent.vx) * Math.min(1, accel * sdt);
                            ent.vz += (targetVz - ent.vz) * Math.min(1, accel * sdt);

                            // Smoothly align craft yaw & bank roll into turns
                            const desiredYaw = Math.atan2(moveX, moveZ);
                            let diff = desiredYaw - ent.yaw;
                            while (diff > Math.PI) diff -= Math.PI * 2;
                            while (diff < -Math.PI) diff += Math.PI * 2;
                            ent.yaw += diff * Math.min(1, 11 * sdt);
                            ent.roll += (Math.max(-0.42, Math.min(0.42, -diff * 0.65)) - ent.roll) * Math.min(1, 10 * sdt);
                        } else {
                            const damp = Math.pow(ent.grounded ? this.physics3D.friction : this.physics3D.airDrag, sdt * 60);
                            ent.vx *= damp;
                            ent.vz *= damp;
                            ent.roll += (0 - ent.roll) * Math.min(1, 9 * sdt);
                        }

                        // Jump & Double Jump (Coyote Time + Jump Buffering)
                        if (ent.jumpBufferTimer > 0) {
                            if (ent.coyoteTimer > 0) {
                                ent.vy = ent.jumpForce;
                                ent.grounded = false;
                                ent.coyoteTimer = 0;
                                ent.jumpBufferTimer = 0;
                                ent.doubleJumpAvailable = ent.canDoubleJump;
                                this.playSfx('jump');
                                this.spawnParticleBurst3D(ent.x, ent.y - ent.sy * 0.5, ent.z, '#38bdf8', 12, 8);
                            } else if (ent.doubleJumpAvailable && !ent.grounded) {
                                ent.vy = ent.jumpForce * 0.94;
                                ent.doubleJumpAvailable = false;
                                ent.jumpBufferTimer = 0;
                                this.playSfx('double_jump');
                                this.spawnParticleBurst3D(ent.x, ent.y - ent.sy * 0.4, ent.z, '#c084fc', 16, 10);
                                this.addPopup3D(ent.x, ent.y + 1.5, ent.z, 'DOUBLE BOOST!', '#c084fc');
                            }
                        }

                        // Gravity integration
                        ent.vy += this.physics3D.gravity * sdt;
                    }

                    // Pitch craft slightly with vertical speed
                    const targetPitch = Math.max(-0.35, Math.min(0.35, -ent.vy * 0.016));
                    ent.pitch += (targetPitch - ent.pitch) * Math.min(1, 10 * sdt);

                    const prevY = ent.y;
                    ent.x += ent.vx * sdt;
                    ent.y += ent.vy * sdt;
                    ent.z += ent.vz * sdt;
                    ent.grounded = false;

                    // Infinite floor check (when enabled or no platforms exist)
                    if (useInfiniteFloor) {
                        const minPlayerY = this.scene3D.floorY + ent.sy * 0.5;
                        if (ent.y <= minPlayerY) {
                            ent.y = minPlayerY;
                            if (ent.vy < 0) ent.vy = 0;
                            ent.grounded = true;
                            ent.coyoteTimer = 0.14;
                            ent.doubleJumpAvailable = ent.canDoubleJump;
                        }
                    }

                    // 3D Solid Platform & Entity Collisions
                    let ridingPlatform = null;
                    const phx = ent.sx * 0.42, phy = ent.sy * 0.5, phz = ent.sz * 0.42;

                    for (const other of this.entities3D) {
                        if (other === ent) continue;

                        if (other.isSolid) {
                            const ohx = other.sx * 0.5, ohy = other.sy * 0.5, ohz = other.sz * 0.5;
                            const dx = ent.x - other.x;
                            const dy = ent.y - other.y;
                            const dz = ent.z - other.z;
                            const ox = (phx + ohx) - Math.abs(dx);
                            const oy = (phy + ohy) - Math.abs(dy);
                            const oz = (phz + ohz) - Math.abs(dz);

                            if (ox > 0 && oy > 0 && oz > 0) {
                                const prevBottom = prevY - phy;
                                const platTop = other.y + ohy;

                                if (oy <= ox && oy <= oz) {
                                    if (dy >= 0 || prevBottom >= platTop - 0.65) {
                                        ent.y = platTop + phy;
                                        if (ent.vy < 0) ent.vy = 0;
                                        ent.grounded = true;
                                        ent.coyoteTimer = 0.14;
                                        ent.doubleJumpAvailable = ent.canDoubleJump;
                                        if (other.type === 'moving_platform') ridingPlatform = other;
                                    } else {
                                        ent.y = other.y - ohy - phy;
                                        if (ent.vy > 0) ent.vy = 0;
                                    }
                                } else if (ox < oz) {
                                    ent.x += dx >= 0 ? ox : -ox;
                                    ent.vx = 0;
                                } else {
                                    ent.z += dz >= 0 ? oz : -oz;
                                    ent.vz = 0;
                                }
                            }
                            continue;
                        }

                        const dist = Math.hypot(ent.x - other.x, ent.y - other.y, ent.z - other.z);

                        // Crystal Collectible
                        if (other.type === 'crystal' && !other.collected) {
                            if (dist < ent.radius + other.radius + 0.6) {
                                other.collected = true;
                                this.combo = (this.combo || 0) + 1;
                                this.comboTimer = 4.0;
                                const pts = other.points * Math.min(4, Math.max(1, this.combo));
                                this.score += pts;
                                ent.kers = Math.min(100, ent.kers + 20);
                                this.playSfx('coin');
                                this.spawnParticleBurst3D(other.x, other.y, other.z, '#fbbf24', 18, 11);
                                this.addPopup3D(other.x, other.y + 1.2, other.z, `+${pts}`, '#fbbf24');
                            }
                        }
                        // Heart Health Pack
                        else if (other.type === 'heart' && !other.collected) {
                            if (dist < ent.radius + other.radius + 0.6) {
                                other.collected = true;
                                ent.health = Math.min(ent.maxHealth, ent.health + other.heal);
                                this.playSfx('heal');
                                this.spawnParticleBurst3D(other.x, other.y, other.z, '#10b981', 18, 10);
                                this.addPopup3D(other.x, other.y + 1.2, other.z, `+${other.heal} HP`, '#10b981');
                            }
                        }
                        // 3D Boost Ring
                        else if (other.type === 'ring' && ent.ringBoostCooldown <= 0) {
                            if (dist < other.sx * 0.55) {
                                ent.ringBoostCooldown = 0.55;
                                other.pulse = 1.0;
                                const boost = other.power || 34;
                                ent.vx = Math.sin(ent.yaw) * boost;
                                ent.vz = Math.cos(ent.yaw) * boost;
                                ent.vy = Math.max(ent.vy, 6.5);
                                ent.kers = 100;
                                this.score += other.points || 150;
                                this.camera3D.shake = 0.3;
                                this.playSfx('pad');
                                this.spawnParticleBurst3D(other.x, other.y, other.z, '#00f5d4', 24, 15);
                                this.addPopup3D(other.x, other.y + 2.0, other.z, '🚀 TURBO RING!', '#00f5d4');
                            }
                        }
                        // 3D Jump Pad
                        else if (other.type === 'pad') {
                            const horizDist = Math.hypot(ent.x - other.x, ent.z - other.z);
                            if (horizDist < other.sx * 0.58 && Math.abs(ent.y - other.y) < 1.6 && ent.vy <= 2) {
                                ent.vy = other.power || 25;
                                ent.grounded = false;
                                ent.doubleJumpAvailable = true;
                                other.pulse = 1.0;
                                this.playSfx('pad');
                                this.spawnParticleBurst3D(other.x, other.y + 0.5, other.z, '#fbbf24', 20, 12);
                                this.addPopup3D(other.x, other.y + 1.8, other.z, '⚡ HYPER PAD!', '#fbbf24');
                            }
                        }
                        // 3D Hazard / Spike
                        else if (other.type === 'hazard') {
                            if (dist < ent.radius + other.radius * 0.85 && ent.invulnerableTimer <= 0 && !ent.isDashing) {
                                ent.health -= other.damage;
                                ent.invulnerableTimer = 1.0;
                                ent.vy = 11;
                                this.camera3D.shake = 0.55;
                                this.playSfx('hurt');
                                this.spawnParticleBurst3D(ent.x, ent.y, ent.z, '#ef4444', 20, 12);
                                this.addPopup3D(ent.x, ent.y + 1.6, ent.z, `-${other.damage} HP`, '#ef4444');
                            }
                        }
                        // 3D Checkpoint Beacon
                        else if (other.type === 'checkpoint' && !other.activated) {
                            if (dist < ent.radius + other.sx * 0.9) {
                                other.activated = true;
                                other.color = '#4ade80';
                                other.rgb = this.parseHexRGB('#4ade80');
                                ent.spawnX = other.x;
                                ent.spawnY = other.y + 1.5;
                                ent.spawnZ = other.z;
                                ent.health = Math.min(ent.maxHealth, ent.health + 25);
                                this.playSfx('heal');
                                this.spawnParticleBurst3D(other.x, other.y + 1, other.z, '#4ade80', 24, 12);
                                this.addPopup3D(other.x, other.y + 2.6, other.z, `🚩 ${other.label || 'CHECKPOINT'}`, '#4ade80');
                                this.log(`🚩 [CHECKPOINT 3D] Punto de control guardado en (${other.x}, ${other.y}, ${other.z})`, 'success');
                            }
                        }
                        // 3D Victory Portal
                        else if (other.type === 'portal') {
                            if (dist < other.sx * 0.55) {
                                this.spawnParticleBurst3D(other.x, other.y, other.z, '#c084fc', 36, 16);
                                this.triggerVictory();
                            }
                        }
                        // 3D Enemy / Boss Stomp vs Hit
                        else if ((other.type === 'enemy' || other.type === 'boss') && other.isAlive) {
                            const hitR = ent.radius + other.radius;
                            if (dist < hitR) {
                                const isAbove = ent.vy < -1.0 && (ent.y - other.y) > other.sy * 0.25;
                                if (isAbove || ent.isDashing) {
                                    const dmg = ent.isDashing ? 75 : (other.type === 'boss' ? 95 : other.health);
                                    other.health -= dmg;
                                    other.hitFlash = 1.0;
                                    ent.vy = 14.5;
                                    ent.doubleJumpAvailable = true;
                                    this.combo = (this.combo || 0) + 1;
                                    this.comboTimer = 4.0;
                                    if (this.loopize) {
                                        this.loopize.combo.hits = this.combo;
                                        this.loopize.combo.timer = this.loopize.combo.window;
                                        this.loopize.combo.maxCombo = Math.max(this.loopize.combo.maxCombo, this.combo);
                                    }
                                    this.playSfx('stomp');
                                    if (other.health <= 0) {
                                        other.isAlive = false;
                                        if (this.loopize) {
                                            const ecsMatch = this.loopize.ecs.find(x => x.name === other.name);
                                            if (ecsMatch) { ecsMatch.alive = false; ecsMatch.hp = 0; }
                                        }
                                        const pts = other.type === 'boss' ? 1200 : 300;
                                        this.score += pts;
                                        this.camera3D.shake = other.type === 'boss' ? 0.85 : 0.4;
                                        this.hitstopTimer = Math.max(this.hitstopTimer || 0, other.type === 'boss' ? 0.075 : 0.035);
                                        this.spawnParticleBurst3D(other.x, other.y, other.z, '#ef4444', other.type === 'boss' ? 42 : 24, 15);
                                        this.addPopup3D(other.x, other.y + 2, other.z, `+${pts} DESTROYED!`, '#38bdf8');
                                    } else {
                                        this.camera3D.shake = 0.45;
                                        this.spawnParticleBurst3D(other.x, other.y + 1, other.z, '#fbbf24', 16, 11);
                                        this.addPopup3D(other.x, other.y + 2.2, other.z, `-${dmg} HIT!`, '#fbbf24');
                                    }
                                } else if (ent.invulnerableTimer <= 0) {
                                    const dmg = other.type === 'boss' ? 35 : 25;
                                    ent.health -= dmg;
                                    ent.invulnerableTimer = 1.0;
                                    ent.vy = 10;
                                    ent.vx = -Math.sin(ent.yaw) * 14;
                                    ent.vz = -Math.cos(ent.yaw) * 14;
                                    this.camera3D.shake = 0.55;
                                    this.playSfx('hurt');
                                    this.spawnParticleBurst3D(ent.x, ent.y, ent.z, '#ef4444', 18, 12);
                                    this.addPopup3D(ent.x, ent.y + 1.6, ent.z, `-${dmg} HP`, '#ef4444');
                                }
                            }
                        }
                    }

                    if (ridingPlatform) {
                        ent.x += (ridingPlatform.vxPlatform || 0) * sdt;
                        ent.y += (ridingPlatform.vyPlatform || 0) * sdt;
                        ent.z += (ridingPlatform.vzPlatform || 0) * sdt;
                    }

                    // Abyss Fall or Zero-HP Respawn
                    if (ent.y < -20 || ent.health <= 0) {
                        this.lives--;
                        this.playSfx('hurt');
                        this.camera3D.shake = 0.65;
                        if (this.lives > 0) {
                            ent.health = ent.maxHealth;
                            ent.x = ent.spawnX; ent.y = ent.spawnY + 1.0; ent.z = ent.spawnZ;
                            ent.vx = 0; ent.vy = 0; ent.vz = 0;
                            ent.invulnerableTimer = 1.2;
                            this.spawnParticleBurst3D(ent.x, ent.y, ent.z, '#38bdf8', 22, 12);
                            this.log(`⚠️ Reapareciendo en Checkpoint 3D (${ent.x.toFixed(0)}, ${ent.y.toFixed(0)}, ${ent.z.toFixed(0)}) — Vidas: ${this.lives}`, 'error');
                        } else {
                            this.triggerGameOver();
                        }
                    }

                } else if ((ent.type === 'enemy' || ent.type === 'boss') && ent.isAlive) {
                    const spd = ent.type === 'boss' && ent.enraged ? ent.speed * 1.45 : ent.speed;
                    if (ent.axis === 'z') {
                        ent.z += ent.dir * spd * sdt;
                        if (ent.z >= ent.maxPos) { ent.z = ent.maxPos; ent.dir = -1; }
                        if (ent.z <= ent.minPos) { ent.z = ent.minPos; ent.dir = 1; }
                    } else {
                        ent.x += ent.dir * spd * sdt;
                        if (ent.x >= ent.maxPos) { ent.x = ent.maxPos; ent.dir = -1; }
                        if (ent.x <= ent.minPos) { ent.x = ent.minPos; ent.dir = 1; }
                    }
                    ent.yaw += 1.6 * sdt;

                    if (ent.type === 'boss' && step === 0) {
                        if (!ent.enraged && ent.health <= ent.maxHealth * 0.5) {
                            ent.enraged = true;
                            ent.color = '#f43f5e';
                            ent.rgb = this.parseHexRGB('#f43f5e');
                            this.camera3D.shake = 0.7;
                            this.addPopup3D(ent.x, ent.y + 3.2, ent.z, '🔥 OMEGA ENRAGED!', '#ef4444');
                        }
                        ent.fireTimer -= dt;
                        const pl = this.getPlayer3D();
                        if (ent.fireTimer <= 0 && pl && !this.gameOver && !this.gameWon) {
                            const dx = pl.x - ent.x, dy = pl.y - ent.y, dz = pl.z - ent.z;
                            const dist = Math.hypot(dx, dy, dz);
                            if (dist < 65 && dist > 1) {
                                ent.fireTimer = ent.enraged ? ent.fireRate * 0.62 : ent.fireRate;
                                const spdOrb = ent.enraged ? 34 : 26;
                                this.projectiles3D.push({
                                    x: ent.x, y: ent.y, z: ent.z,
                                    vx: (dx / dist) * spdOrb,
                                    vy: (dy / dist) * spdOrb,
                                    vz: (dz / dist) * spdOrb,
                                    radius: 0.75,
                                    color: '#f43f5e',
                                    isPlayer: false,
                                    damage: ent.enraged ? 30 : 20,
                                    life: 2.8
                                });
                                this.playSfx('shoot');
                            }
                        }
                    }
                }
            }
        }

        // 3. Update 3D Plasma Projectiles
        const pl3 = this.getPlayer3D();
        for (let i = this.projectiles3D.length - 1; i >= 0; i--) {
            const pr = this.projectiles3D[i];
            pr.x += pr.vx * dt;
            pr.y += pr.vy * dt;
            pr.z += pr.vz * dt;
            pr.life -= dt;

            if (pr.isPlayer) {
                for (const other of this.entities3D) {
                    if ((other.type === 'enemy' || other.type === 'boss') && other.isAlive) {
                        const d = Math.hypot(pr.x - other.x, pr.y - other.y, pr.z - other.z);
                        if (d < pr.radius + other.radius + 0.45) {
                            other.health -= pr.damage;
                            other.hitFlash = 1.0;
                            pr.life = 0;
                            this.combo = (this.combo || 0) + 1;
                            this.comboTimer = 4.0;
                            if (this.loopize) {
                                this.loopize.combo.hits = this.combo;
                                this.loopize.combo.timer = this.loopize.combo.window;
                                this.loopize.combo.maxCombo = Math.max(this.loopize.combo.maxCombo, this.combo);
                            }
                            this.playSfx('stomp');
                            this.spawnParticleBurst3D(pr.x, pr.y, pr.z, '#38bdf8', 12, 10);
                            this.addPopup3D(other.x, other.y + 1.8, other.z, `-${pr.damage}`, '#38bdf8');
                            if (other.health <= 0) {
                                other.isAlive = false;
                                if (this.loopize) {
                                    const ecsMatch = this.loopize.ecs.find(x => x.name === other.name);
                                    if (ecsMatch) { ecsMatch.alive = false; ecsMatch.hp = 0; }
                                }
                                const pts = other.type === 'boss' ? 1200 : 250;
                                this.score += pts;
                                this.camera3D.shake = other.type === 'boss' ? 0.85 : 0.35;
                                this.hitstopTimer = Math.max(this.hitstopTimer || 0, other.type === 'boss' ? 0.075 : 0.035);
                                this.spawnParticleBurst3D(other.x, other.y, other.z, '#ef4444', other.type === 'boss' ? 44 : 24, 15);
                                this.addPopup3D(other.x, other.y + 2.4, other.z, `+${pts} SLAIN!`, '#fbbf24');
                            }
                            break;
                        }
                    }
                }
            } else if (pl3 && !this.gameOver && pl3.invulnerableTimer <= 0 && !pl3.isDashing) {
                const d = Math.hypot(pr.x - pl3.x, pr.y - pl3.y, pr.z - pl3.z);
                if (d < pr.radius + pl3.radius) {
                    pl3.health -= pr.damage;
                    pl3.invulnerableTimer = 0.95;
                    pr.life = 0;
                    this.camera3D.shake = 0.5;
                    this.playSfx('hurt');
                    this.spawnParticleBurst3D(pr.x, pr.y, pr.z, '#f43f5e', 16, 11);
                    this.addPopup3D(pl3.x, pl3.y + 1.6, pl3.z, `-${pr.damage} HP`, '#f43f5e');
                }
            }

            if (pr.life <= 0) this.projectiles3D.splice(i, 1);
        }

        // 4. Update 3D Particles & Popups
        for (let i = this.particles3D.length - 1; i >= 0; i--) {
            const pt = this.particles3D[i];
            pt.x += pt.vx * dt;
            pt.y += pt.vy * dt;
            pt.z += pt.vz * dt;
            pt.vy -= 14 * dt;
            pt.alpha -= dt / pt.life;
            if (pt.alpha <= 0) this.particles3D.splice(i, 1);
        }

        for (let i = this.popups3D.length - 1; i >= 0; i--) {
            const pp = this.popups3D[i];
            pp.y += pp.vy * dt;
            pp.alpha -= dt * 1.1;
            if (pp.alpha <= 0) this.popups3D.splice(i, 1);
        }

        // 5. Update Spring-Arm 3D Camera & Dynamic Speed-FOV Warp
        if (pl3) {
            const horizSpd = Math.hypot(pl3.vx, pl3.vz);
            const targetFov = this.camera3D.baseFov + Math.min(16, horizSpd * 0.36) + (pl3.isDashing ? 8 : 0);
            this.camera3D.fov += (targetFov - this.camera3D.fov) * Math.min(1, 8 * dt);

            const camSm = Math.min(1, (this.camera3D.smooth || 0.14) * 60 * dt);
            const mode = this.camera3D.mode;

            if (mode === 'fps') {
                const fx = Math.sin(pl3.yaw), fz = Math.cos(pl3.yaw);
                this.camera3D.x = pl3.x + fx * 0.9;
                this.camera3D.y = pl3.y + 0.75;
                this.camera3D.z = pl3.z + fz * 0.9;
                this.camera3D.targetX = pl3.x + fx * 18;
                this.camera3D.targetY = pl3.y + 0.55 - this.camera3D.pitchOffset * 6;
                this.camera3D.targetZ = pl3.z + fz * 18;
            } else if (mode === 'topdown') {
                const tx = pl3.x - Math.sin(this.camera3D.yawOffset) * 8;
                const ty = pl3.y + 26;
                const tz = pl3.z - Math.cos(this.camera3D.yawOffset) * 8;
                this.camera3D.x += (tx - this.camera3D.x) * camSm;
                this.camera3D.y += (ty - this.camera3D.y) * camSm;
                this.camera3D.z += (tz - this.camera3D.z) * camSm;
                this.camera3D.targetX += (pl3.x - this.camera3D.targetX) * camSm;
                this.camera3D.targetY += (pl3.y - this.camera3D.targetY) * camSm;
                this.camera3D.targetZ += (pl3.z + 4 - this.camera3D.targetZ) * camSm;
            } else {
                // Chase or Free Orbit Camera
                const orbitYaw = mode === 'orbit'
                    ? (this.camera3D.yawOffset + this.lastTime * 0.00035)
                    : this.camera3D.yawOffset;
                const dist = this.camera3D.distance;
                const pitch = this.camera3D.pitchOffset;
                const desiredX = pl3.x - Math.sin(orbitYaw) * Math.cos(pitch) * dist;
                const desiredY = pl3.y + this.camera3D.heightOffset + Math.sin(pitch) * dist * 0.65;
                const desiredZ = pl3.z - Math.cos(orbitYaw) * Math.cos(pitch) * dist;

                this.camera3D.x += (desiredX - this.camera3D.x) * camSm;
                this.camera3D.y += (desiredY - this.camera3D.y) * camSm;
                this.camera3D.z += (desiredZ - this.camera3D.z) * camSm;

                const lookAheadX = pl3.x + Math.sin(orbitYaw) * 6;
                const lookAheadY = pl3.y + 1.4;
                const lookAheadZ = pl3.z + Math.cos(orbitYaw) * 6;
                this.camera3D.targetX += (lookAheadX - this.camera3D.targetX) * Math.min(1, camSm * 1.4);
                this.camera3D.targetY += (lookAheadY - this.camera3D.targetY) * Math.min(1, camSm * 1.4);
                this.camera3D.targetZ += (lookAheadZ - this.camera3D.targetZ) * Math.min(1, camSm * 1.4);
            }
        }

        if (this.camera3D.shake > 0) {
            this.camera3D.shake = Math.max(0, this.camera3D.shake - dt * 2.2);
        }
    }

    // ── Near-Plane Clipping + Blinn-Phong Perspective Rasterizer ──
    render3D() {
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;

        // 1. Camera Basis Matrix (Eye -> Target, Left-Handed View Space where +VZ is Forward)
        const shX = (Math.random() - 0.5) * this.camera3D.shake;
        const shY = (Math.random() - 0.5) * this.camera3D.shake;
        const ex = this.camera3D.x + shX;
        const ey = this.camera3D.y + shY;
        const ez = this.camera3D.z;

        let fx = this.camera3D.targetX - ex;
        let fy = this.camera3D.targetY - ey;
        let fz = this.camera3D.targetZ - ez;
        const fl = Math.hypot(fx, fy, fz) || 1;
        fx /= fl; fy /= fl; fz /= fl;

        // Right = Up(0,1,0) x Forward
        let rx = fz, ry = 0, rz = -fx;
        const rl = Math.hypot(rx, ry, rz) || 1;
        rx /= rl; ry /= rl; rz /= rl;

        // True Up = Forward x Right
        const ux = fy * rz - fz * ry;
        const uy = fz * rx - fx * rz;
        const uz = fx * ry - fy * rx;

        const fovRad = (this.camera3D.fov * Math.PI) / 180;
        const focal = (h * 0.5) / Math.tan(fovRad * 0.5);
        const cxScreen = w * 0.5;
        const cyScreen = h * 0.5;
        const nearZ = this.camera3D.near || 0.25;

        const worldToView = (wx, wy, wz) => {
            const dx = wx - ex, dy = wy - ey, dz = wz - ez;
            return [
                dx * rx + dy * ry + dz * rz,
                dx * ux + dy * uy + dz * uz,
                dx * fx + dy * fy + dz * fz
            ];
        };

        const projectView = (vx, vy, vz) => {
            const invZ = focal / vz;
            return [cxScreen + vx * invZ, cyScreen - vy * invZ];
        };

        const clipPolygonNear = (ptsView) => {
            const out = [];
            const n = ptsView.length;
            for (let i = 0; i < n; i++) {
                const a = ptsView[i];
                const b = ptsView[(i + 1) % n];
                const aIn = a[2] >= nearZ;
                const bIn = b[2] >= nearZ;
                if (aIn && bIn) {
                    out.push(b);
                } else if (aIn && !bIn) {
                    const t = (nearZ - a[2]) / (b[2] - a[2]);
                    out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, nearZ]);
                } else if (!aIn && bIn) {
                    const t = (nearZ - a[2]) / (b[2] - a[2]);
                    out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, nearZ]);
                    out.push(b);
                }
            }
            return out;
        };

        // 2. Skybox & Dynamic Horizon Gradient
        const skyPalettes = {
            cyber_night: { top: '#040714', mid: '#0e1b3d', bot: '#050914', fog: [12, 23, 52], grid: 'rgba(56, 189, 248, 0.20)', sun: '#38bdf8' },
            sunset_synth: { top: '#17082a', mid: '#6d1d5f', bot: '#0d0618', fog: [88, 26, 78], grid: 'rgba(244, 114, 182, 0.24)', sun: '#fb923c' },
            nebula_void: { top: '#03030a', mid: '#1e1040', bot: '#05040d', fog: [24, 14, 52], grid: 'rgba(192, 132, 252, 0.22)', sun: '#c084fc' },
            arctic_holo: { top: '#081c2e', mid: '#154c70', bot: '#071422', fog: [18, 62, 92], grid: 'rgba(34, 211, 238, 0.24)', sun: '#67e8f9' }
        };
        const pal = skyPalettes[this.scene3D.sky] || skyPalettes.cyber_night;
        const horizonY = Math.max(h * 0.12, Math.min(h * 0.88, cyScreen + (fy / (Math.abs(fz) + Math.abs(fx) + 0.2)) * focal * 0.55));

        const skyGrad = ctx.createLinearGradient(0, 0, 0, h);
        skyGrad.addColorStop(0, pal.top);
        skyGrad.addColorStop(Math.max(0.05, Math.min(0.95, horizonY / h)), pal.mid);
        skyGrad.addColorStop(1, pal.bot);
        ctx.fillStyle = skyGrad;
        ctx.fillRect(0, 0, w, h);

        // Starfield & Retro-Cyber Synth Sun on Horizon
        const camYawAngle = Math.atan2(fx, fz);
        ctx.fillStyle = 'rgba(248, 250, 252, 0.7)';
        for (let s = 0; s < 42; s++) {
            const sx = (((s * 137.5 - camYawAngle * 280) % w) + w) % w;
            const sy = ((s * 61.3) % Math.max(40, horizonY * 0.88));
            const szStar = (s % 3 === 0) ? 2 : 1.2;
            ctx.fillRect(sx, sy, szStar, szStar);
        }

        const sunScreenX = cxScreen - camYawAngle * (w * 0.42);
        if (sunScreenX > -120 && sunScreenX < w + 120 && horizonY > 20) {
            const sunGrad = ctx.createRadialGradient(sunScreenX, horizonY - 26, 6, sunScreenX, horizonY - 26, 95);
            sunGrad.addColorStop(0, pal.sun);
            sunGrad.addColorStop(0.35, 'rgba(56, 189, 248, 0.25)');
            sunGrad.addColorStop(1, 'transparent');
            ctx.fillStyle = sunGrad;
            ctx.beginPath();
            ctx.arc(sunScreenX, horizonY - 26, 95, 0, Math.PI * 2);
            ctx.fill();
        }

        // 3. Perspective 3D Cyber-Grid Floor
        if (this.scene3D.showGrid) {
            const gridY = this.scene3D.hasFloorPlane ? this.scene3D.floorY : -2.5;
            const stepG = 8;
            const rangeG = 96;
            const snapX = Math.floor(ex / stepG) * stepG;
            const snapZ = Math.floor(ez / stepG) * stepG;

            ctx.strokeStyle = pal.grid;
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let gx = snapX - rangeG; gx <= snapX + rangeG; gx += stepG) {
                const seg = clipPolygonNear([worldToView(gx, gridY, snapZ - rangeG), worldToView(gx, gridY, snapZ + rangeG)]);
                if (seg.length >= 2) {
                    const p0 = projectView(seg[0][0], seg[0][1], seg[0][2]);
                    const p1 = projectView(seg[1][0], seg[1][1], seg[1][2]);
                    ctx.moveTo(p0[0], p0[1]);
                    ctx.lineTo(p1[0], p1[1]);
                }
            }
            for (let gz = snapZ - rangeG; gz <= snapZ + rangeG; gz += stepG) {
                const seg = clipPolygonNear([worldToView(snapX - rangeG, gridY, gz), worldToView(snapX + rangeG, gridY, gz)]);
                if (seg.length >= 2) {
                    const p0 = projectView(seg[0][0], seg[0][1], seg[0][2]);
                    const p1 = projectView(seg[1][0], seg[1][1], seg[1][2]);
                    ctx.moveTo(p0[0], p0[1]);
                    ctx.lineTo(p1[0], p1[1]);
                }
            }
            ctx.stroke();
        }

        // 4. Lighting Setup
        const dirLight = this.lights3D.find(l => l.type === 'directional') || { dx: -0.42, dy: -0.88, dz: -0.32, intensity: 1.05 };
        const dlLen = Math.hypot(dirLight.dx, dirLight.dy, dirLight.dz) || 1;
        const ldx = -dirLight.dx / dlLen, ldy = -dirLight.dy / dlLen, ldz = -dirLight.dz / dlLen;
        const pointLights = this.lights3D.filter(l => l.type === 'point');
        const fogDensity = this.scene3D.fogDensity || 0.0085;
        const fogR = pal.fog[0], fogG = pal.fog[1], fogB = pal.fog[2];

        // 5. Collect Renderable Polygons, Ground Drop-Shadows, Billboards & Projectiles
        const drawQueue = [];

        // Helper: find highest platform top below (wx, wy, wz) for crisp 3D spatial drop-shadow
        const findShadowSurfaceY = (wx, wy, wz) => {
            let bestY = this.scene3D.hasFloorPlane ? this.scene3D.floorY : null;
            for (const p of this.entities3D) {
                if (!p.isSolid) continue;
                const topY = p.y + p.sy * 0.5;
                if (topY <= wy + 0.25 && Math.abs(wx - p.x) <= p.sx * 0.5 && Math.abs(wz - p.z) <= p.sz * 0.5) {
                    if (bestY === null || topY > bestY) bestY = topY;
                }
            }
            return bestY;
        };

        for (const ent of this.entities3D) {
            if (ent.collected || !ent.isAlive) continue;
            if (ent.isPlayer && this.camera3D.mode === 'fps') continue;
            if (ent.isPlayer && ent.invulnerableTimer > 0 && Math.floor(this.lastTime / 85) % 2 === 0) continue;

            const floatY = (ent.type === 'crystal' || ent.type === 'heart')
                ? ent.y + Math.sin(this.lastTime * 0.0045 + ent.floatSeed) * 0.35
                : ent.y;

            // Camera Near/Far + Lateral Frustum Culling before transforming vertices
            const centerView = worldToView(ent.x, floatY, ent.z);
            const boundR = Math.max(ent.sx, ent.sy, ent.sz) * 0.9 + 1.5;
            const farLimit = this.camera3D.far || 280;
            if (centerView[2] + boundR < nearZ || centerView[2] - boundR > farLimit) continue;
            const maxHoriz = (cxScreen / Math.max(1, focal)) * Math.max(1, centerView[2]) + boundR * 1.4;
            if (Math.abs(centerView[0]) > maxHoriz) continue;

            // Project 3D Drop Shadow onto platform directly beneath dynamic entities
            if (!ent.isSolid && ent.type !== 'portal' && ent.type !== 'ring') {
                const surfY = findShadowSurfaceY(ent.x, floatY, ent.z);
                if (surfY !== null && floatY - surfY < 24) {
                    const sv = worldToView(ent.x, surfY + 0.04, ent.z);
                    if (sv[2] > nearZ + 0.3) {
                        const sp = projectView(sv[0], sv[1], sv[2]);
                        const heightGap = Math.max(0, floatY - surfY);
                        const shRadius = Math.max(0.4, ent.radius * (1 - heightGap / 28)) * (focal / sv[2]);
                        drawQueue.push({
                            kind: 'shadow',
                            sortDepth: sv[2] + 0.15,
                            sx: sp[0],
                            sy: sp[1],
                            rx: shRadius,
                            ry: shRadius * 0.42,
                            alpha: Math.max(0.12, 0.48 * (1 - heightGap / 24))
                        });
                    }
                }
            }

            // Transform Mesh Vertices (Yaw * Pitch * Roll + Translation)
            const cy = Math.cos(ent.yaw), sy = Math.sin(ent.yaw);
            const cp = Math.cos(ent.pitch), sp = Math.sin(ent.pitch);
            const cr = Math.cos(ent.roll), sr = Math.sin(ent.roll);

            const rotVec = (vx, vy, vz) => {
                // Roll (Z) -> Pitch (X) -> Yaw (Y)
                const x1 = vx * cr - vy * sr;
                const y1 = vx * sr + vy * cr;
                const z1 = vz;
                const y2 = y1 * cp - z1 * sp;
                const z2 = y1 * sp + z1 * cp;
                return [
                    x1 * cy + z2 * sy,
                    y2,
                    -x1 * sy + z2 * cy
                ];
            };

            const mesh = ent.mesh;
            if (!mesh) continue;

            const worldVerts = new Array(mesh.vertices.length);
            const viewVerts = new Array(mesh.vertices.length);
            for (let vi = 0; vi < mesh.vertices.length; vi++) {
                const lv = mesh.vertices[vi];
                const rv = rotVec(lv[0], lv[1], lv[2]);
                const wx = ent.x + rv[0], wy = floatY + rv[1], wz = ent.z + rv[2];
                worldVerts[vi] = [wx, wy, wz];
                viewVerts[vi] = worldToView(wx, wy, wz);
            }

            for (let fi = 0; fi < mesh.faces.length; fi++) {
                const face = mesh.faces[fi];
                const idxs = face.indices;

                // Centroid in world space & Backface Culling
                let fcx = 0, fcy = 0, fcz = 0;
                const polyView = [];
                let anyInFront = false;
                for (let k = 0; k < idxs.length; k++) {
                    const id = idxs[k];
                    const wv = worldVerts[id];
                    fcx += wv[0]; fcy += wv[1]; fcz += wv[2];
                    const vv = viewVerts[id];
                    if (vv[2] >= nearZ) anyInFront = true;
                    polyView.push(vv);
                }
                if (!anyInFront) continue;

                fcx /= idxs.length; fcy /= idxs.length; fcz /= idxs.length;
                const wn = rotVec(face.nx, face.ny, face.nz);
                const toCamX = ex - fcx, toCamY = ey - fcy, toCamZ = ez - fcz;

                // Backface Culling (allow double-sided on rings, portals & doubleSided .obj models)
                if (ent.type !== 'ring' && ent.type !== 'portal' && !ent.doubleSided) {
                    if (wn[0] * toCamX + wn[1] * toCamY + wn[2] * toCamZ <= -0.05) continue;
                }

                const clipped = clipPolygonNear(polyView);
                if (clipped.length < 3) continue;

                let avgVZ = 0;
                const screenPts = new Array(clipped.length);
                for (let k = 0; k < clipped.length; k++) {
                    avgVZ += clipped[k][2];
                    screenPts[k] = projectView(clipped[k][0], clipped[k][1], clipped[k][2]);
                }
                avgVZ /= clipped.length;
                const dist3D = Math.hypot(toCamX, toCamY, toCamZ);

                // Blinn-Phong Shading + Point Lights + Rim Glow + Depth Fog
                const baseCol = face.tint ? this.parseHexRGB(face.tint) : ent.rgb;
                const ndotl = Math.max(0, wn[0] * ldx + wn[1] * ldy + wn[2] * ldz);
                let lightFactor = (this.scene3D.ambientIntensity || 0.38) + ndotl * (dirLight.intensity || 1.05) * 0.72;

                // Specular highlight (Blinn half-vector)
                const vLen = dist3D || 1;
                const hxB = ldx + toCamX / vLen, hyB = ldy + toCamY / vLen, hzB = ldz + toCamZ / vLen;
                const hLen = Math.hypot(hxB, hyB, hzB) || 1;
                const spec = Math.pow(Math.max(0, (wn[0] * hxB + wn[1] * hyB + wn[2] * hzB) / hLen), 18) * 0.32;

                let addR = spec * 255, addG = spec * 255, addB = spec * 255;
                for (let li = 0; li < pointLights.length; li++) {
                    const pl = pointLights[li];
                    const pdx = pl.x - fcx, pdy = pl.y - fcy, pdz = pl.z - fcz;
                    const pd = Math.hypot(pdx, pdy, pdz) || 1;
                    if (pd < pl.range) {
                        const att = (1 - pd / pl.range) * pl.intensity;
                        const pDot = Math.max(0.15, (wn[0] * pdx + wn[1] * pdy + wn[2] * pdz) / pd);
                        const lrgb = this.parseHexRGB(pl.color);
                        addR += lrgb.r * att * pDot * 0.42;
                        addG += lrgb.g * att * pDot * 0.42;
                        addB += lrgb.b * att * pDot * 0.42;
                    }
                }

                const bias = face.bias || 1.0;
                const emissiveBoost = (ent.type === 'crystal' || ent.type === 'ring' || ent.type === 'portal') ? 1.28 : 1.0;
                let r = Math.min(255, baseCol.r * lightFactor * bias * emissiveBoost + addR);
                let g = Math.min(255, baseCol.g * lightFactor * bias * emissiveBoost + addG);
                let b = Math.min(255, baseCol.b * lightFactor * bias * emissiveBoost + addB);

                if ((ent.hitFlash || 0) > 0.01) {
                    const hf = Math.min(1, ent.hitFlash);
                    r += (255 - r) * hf;
                    g += (255 - g) * hf;
                    b += (255 - b) * hf;
                }

                // Exponential Atmospheric Fog
                const fogAmt = Math.min(0.86, 1 - Math.exp(-fogDensity * dist3D));
                r = Math.round(r * (1 - fogAmt) + fogR * fogAmt);
                g = Math.round(g * (1 - fogAmt) + fogG * fogAmt);
                b = Math.round(b * (1 - fogAmt) + fogB * fogAmt);

                // Bias solid deck depth slightly behind dynamic actors standing on top so actors never clip into floor
                const depthBias = ent.isSolid ? 1.15 : 0;

                drawQueue.push({
                    kind: 'poly',
                    sortDepth: dist3D + depthBias,
                    pts: screenPts,
                    fill: `rgb(${r},${g},${b})`,
                    stroke: ent.isSolid
                        ? `rgba(129, 140, 248, ${(0.32 * (1 - fogAmt)).toFixed(2)})`
                        : `rgba(255, 255, 255, ${(0.18 * (1 - fogAmt)).toFixed(2)})`
                });
            }

            // Floating 3D World Labels & Damaged Enemy HP Bars
            if (ent.type === 'portal' || ent.type === 'checkpoint' || ent.type === 'boss') {
                const lv = worldToView(ent.x, floatY + ent.sy * 0.65 + 1.1, ent.z);
                if (lv[2] > nearZ + 0.5 && lv[2] < 130) {
                    const lp = projectView(lv[0], lv[1], lv[2]);
                    drawQueue.push({
                        kind: 'label',
                        sortDepth: lv[2] - 0.5,
                        sx: lp[0],
                        sy: lp[1],
                        text: ent.type === 'checkpoint' && ent.activated ? '✔ SAVED' : (ent.label || ent.name),
                        color: ent.type === 'portal' ? '#e879f9' : (ent.type === 'boss' ? '#fbbf24' : ent.color)
                    });
                }
            }
            if ((ent.type === 'enemy' || ent.type === 'boss') && ent.health < ent.maxHealth && ent.maxHealth > 0) {
                const hv = worldToView(ent.x, floatY + ent.sy * 0.65 + 0.55, ent.z);
                if (hv[2] > nearZ + 0.5 && hv[2] < 110) {
                    const hpPt = projectView(hv[0], hv[1], hv[2]);
                    drawQueue.push({
                        kind: 'hpbar',
                        sortDepth: hv[2] - 0.55,
                        sx: hpPt[0],
                        sy: hpPt[1],
                        bw: ent.type === 'boss' ? 76 : 44,
                        ratio: Math.max(0, Math.min(1, ent.health / ent.maxHealth))
                    });
                }
            }
        }

        // Queue 3D Plasma Projectiles
        for (const pr of this.projectiles3D) {
            const pv = worldToView(pr.x, pr.y, pr.z);
            if (pv[2] > nearZ) {
                const sp = projectView(pv[0], pv[1], pv[2]);
                const rad = Math.max(2.5, pr.radius * (focal / pv[2]));
                drawQueue.push({
                    kind: 'orb',
                    sortDepth: pv[2],
                    sx: sp[0], sy: sp[1], r: rad,
                    color: pr.color,
                    alpha: 1.0
                });
            }
        }

        // Queue 3D Particles
        for (const pt of this.particles3D) {
            const pv = worldToView(pt.x, pt.y, pt.z);
            if (pv[2] > nearZ) {
                const sp = projectView(pv[0], pv[1], pv[2]);
                const rad = Math.max(1.4, pt.size * (focal / pv[2]));
                drawQueue.push({
                    kind: 'particle',
                    sortDepth: pv[2],
                    sx: sp[0], sy: sp[1], r: rad,
                    color: pt.color,
                    alpha: Math.max(0, pt.alpha)
                });
            }
        }

        // 6. Painter's Depth Sort (Far -> Near) & Rasterize
        drawQueue.sort((a, b) => b.sortDepth - a.sortDepth);

        for (let i = 0; i < drawQueue.length; i++) {
            const item = drawQueue[i];
            if (item.kind === 'poly') {
                const pts = item.pts;
                ctx.beginPath();
                ctx.moveTo(pts[0][0], pts[0][1]);
                for (let k = 1; k < pts.length; k++) ctx.lineTo(pts[k][0], pts[k][1]);
                ctx.closePath();
                ctx.fillStyle = item.fill;
                ctx.fill();
                ctx.strokeStyle = item.stroke;
                ctx.lineWidth = 0.85;
                ctx.stroke();
            } else if (item.kind === 'shadow') {
                ctx.save();
                ctx.fillStyle = `rgba(2, 6, 23, ${item.alpha.toFixed(2)})`;
                ctx.beginPath();
                ctx.ellipse(item.sx, item.sy, item.rx, item.ry, 0, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            } else if (item.kind === 'orb') {
                ctx.save();
                ctx.fillStyle = item.color;
                ctx.shadowColor = item.color;
                ctx.shadowBlur = 14;
                ctx.beginPath();
                ctx.arc(item.sx, item.sy, item.r, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = '#ffffff';
                ctx.beginPath();
                ctx.arc(item.sx, item.sy, item.r * 0.45, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            } else if (item.kind === 'particle') {
                ctx.globalAlpha = item.alpha;
                ctx.fillStyle = item.color;
                ctx.beginPath();
                ctx.arc(item.sx, item.sy, item.r, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalAlpha = 1.0;
            } else if (item.kind === 'hpbar') {
                const bw = item.bw || 44;
                ctx.fillStyle = 'rgba(2, 6, 23, 0.8)';
                ctx.fillRect(item.sx - bw * 0.5 - 1, item.sy - 3, bw + 2, 6);
                ctx.fillStyle = item.ratio > 0.5 ? '#10b981' : (item.ratio > 0.25 ? '#f59e0b' : '#ef4444');
                ctx.fillRect(item.sx - bw * 0.5, item.sy - 2, bw * item.ratio, 4);
            } else if (item.kind === 'label') {
                ctx.font = 'bold 11px Outfit, monospace, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillStyle = 'rgba(2, 6, 23, 0.72)';
                const tw = ctx.measureText(item.text).width + 12;
                this.roundRect(ctx, item.sx - tw * 0.5, item.sy - 13, tw, 18, 5, true, false);
                ctx.fillStyle = item.color;
                ctx.fillText(item.text, item.sx, item.sy);
                ctx.textAlign = 'left';
            }
        }

        // 7. 3D Floating Damage / Score Popups
        for (const pp of this.popups3D) {
            const pv = worldToView(pp.x, pp.y, pp.z);
            if (pv[2] > nearZ) {
                const sp = projectView(pv[0], pv[1], pv[2]);
                ctx.globalAlpha = Math.max(0, pp.alpha);
                ctx.fillStyle = pp.color;
                ctx.font = 'bold 13px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(pp.text, sp[0], sp[1]);
                ctx.textAlign = 'left';
                ctx.globalAlpha = 1.0;
            }
        }

        // ═══════════════════════════════════════════════════════════════
        //  3D QUANTUM HEADS-UP DISPLAY (HP, KERS, SPEED, RADAR, CAM MODE)
        // ═══════════════════════════════════════════════════════════════

        const pl3 = this.getPlayer3D();
        if (pl3) {
            // Top-Left Telemetry & Vitals Panel
            ctx.fillStyle = 'rgba(8, 13, 28, 0.84)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.42)';
            ctx.lineWidth = 1.2;
            this.roundRect(ctx, 14, 14, 226, 72, 12, true, true);

            // HP Bar
            const hpRatio = Math.max(0, pl3.health / pl3.maxHealth);
            const hpCol = hpRatio > 0.5 ? '#10b981' : (hpRatio > 0.25 ? '#f59e0b' : '#ef4444');
            ctx.fillStyle = '#94a3b8';
            ctx.font = 'bold 10px monospace';
            ctx.fillText('HP', 24, 32);
            ctx.fillStyle = 'rgba(255,255,255,0.10)';
            this.roundRect(ctx, 56, 23, 128, 10, 5, true, false);
            ctx.fillStyle = hpCol;
            if (hpRatio > 0) this.roundRect(ctx, 56, 23, 128 * hpRatio, 10, 5, true, false);

            // Lives pips
            ctx.fillStyle = '#ef4444';
            for (let l = 0; l < this.lives; l++) {
                ctx.beginPath();
                ctx.arc(196 + l * 12, 28, 4, 0, Math.PI * 2);
                ctx.fill();
            }

            // KERS Hyper-Dash Energy Bar
            const kersRatio = Math.max(0, pl3.kers / 100);
            ctx.fillStyle = '#38bdf8';
            ctx.fillText('KERS', 24, 50);
            ctx.fillStyle = 'rgba(255,255,255,0.10)';
            this.roundRect(ctx, 56, 41, 128, 8, 4, true, false);
            ctx.fillStyle = '#00f5d4';
            if (kersRatio > 0) this.roundRect(ctx, 56, 41, 128 * kersRatio, 8, 4, true, false);

            // Speedometer & 3D Coordinates
            const spdKmh = Math.round(Math.hypot(pl3.vx, pl3.vz) * 3.6);
            ctx.fillStyle = '#cbd5e1';
            ctx.font = 'bold 10px monospace';
            ctx.fillText(`${spdKmh} km/h  |  XYZ (${pl3.x.toFixed(0)}, ${pl3.y.toFixed(1)}, ${pl3.z.toFixed(0)})`, 24, 72);
        }

        // Boss 3D Health Bar (Top-Center)
        const boss3 = this.entities3D.find(e => e.type === 'boss' && e.isAlive);
        if (boss3) {
            const bw = Math.min(300, w - 340);
            if (bw > 120) {
                const bx = (w - bw) * 0.5;
                ctx.fillStyle = 'rgba(8, 13, 28, 0.86)';
                ctx.strokeStyle = boss3.enraged ? '#f43f5e' : 'rgba(239, 68, 68, 0.5)';
                this.roundRect(ctx, bx - 10, 14, bw + 20, 34, 9, true, true);
                ctx.fillStyle = boss3.enraged ? '#fbbf24' : '#fca5a5';
                ctx.font = 'bold 10.5px Outfit, monospace';
                ctx.textAlign = 'center';
                ctx.fillText(`👹 ${boss3.name} (${Math.max(0, Math.round(boss3.health))}/${boss3.maxHealth})`, w * 0.5, 28);
                ctx.textAlign = 'left';
                ctx.fillStyle = '#1e293b';
                ctx.fillRect(bx, 34, bw, 6);
                ctx.fillStyle = boss3.enraged ? '#f43f5e' : '#ef4444';
                ctx.fillRect(bx, 34, bw * Math.max(0, boss3.health / boss3.maxHealth), 6);
            }
        }

        // Top-Right Score + Circular 3D Radar Minimap + Camera Switcher Pill
        ctx.fillStyle = 'rgba(8, 13, 28, 0.85)';
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 1.4;
        this.roundRect(ctx, w - 168, 14, 154, 38, 10, true, true);
        ctx.fillStyle = '#fbbf24';
        ctx.font = 'bold 13px Outfit, sans-serif';
        ctx.fillText(`★ SCORE: ${this.score}`, w - 154, 38);

        // Camera Mode Interactive Pill
        const pillX = w - 168, pillY = 58, pillW = 154, pillH = 24;
        this.camPillBounds = { x: pillX, y: pillY, w: pillW, h: pillH };
        ctx.fillStyle = 'rgba(15, 23, 42, 0.86)';
        ctx.strokeStyle = 'rgba(56, 189, 248, 0.5)';
        ctx.lineWidth = 1;
        this.roundRect(ctx, pillX, pillY, pillW, pillH, 7, true, true);
        ctx.fillStyle = '#38bdf8';
        ctx.font = 'bold 10px monospace';
        ctx.textAlign = 'center';
        ctx.fillText(`🎥 CAM [C]: ${this.camera3D.mode.toUpperCase()}`, pillX + pillW * 0.5, pillY + 15);
        ctx.textAlign = 'left';

        // Circular 3D Spatial Radar Minimap
        if (pl3 && h >= 380) {
            const radR = 40;
            const radCX = w - 58;
            const radCY = 132;
            const radarRange = 75;

            ctx.save();
            ctx.fillStyle = 'rgba(6, 11, 25, 0.82)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.45)';
            ctx.lineWidth = 1.4;
            ctx.beginPath();
            ctx.arc(radCX, radCY, radR, 0, Math.PI * 2);
            ctx.fill();
            ctx.stroke();

            ctx.clip();
            // Radar FOV cone
            ctx.fillStyle = 'rgba(56, 189, 248, 0.12)';
            ctx.beginPath();
            ctx.moveTo(radCX, radCY);
            ctx.arc(radCX, radCY, radR, -Math.PI * 0.5 - 0.48, -Math.PI * 0.5 + 0.48);
            ctx.closePath();
            ctx.fill();

            const cosR = Math.cos(camYawAngle), sinR = Math.sin(camYawAngle);
            for (const e of this.entities3D) {
                if (e === pl3 || e.collected || !e.isAlive) continue;
                const dx = e.x - pl3.x, dz = e.z - pl3.z;
                // Rotate into camera-relative radar coords (+Up = Forward)
                const rxMap = dx * cosR - dz * sinR;
                const rzMap = dx * sinR + dz * cosR;
                const mx = radCX + (rxMap / radarRange) * radR;
                const my = radCY - (rzMap / radarRange) * radR;

                if (e.isSolid) {
                    ctx.fillStyle = 'rgba(99, 102, 241, 0.42)';
                    ctx.fillRect(mx - 2.5, my - 2.5, 5, 5);
                } else {
                    ctx.fillStyle = e.type === 'portal' ? '#e879f9'
                        : (e.type === 'crystal' ? '#fbbf24'
                        : (e.type === 'enemy' || e.type === 'boss' ? '#ef4444' : '#00f5d4'));
                    ctx.beginPath();
                    ctx.arc(mx, my, e.type === 'portal' || e.type === 'boss' ? 3.5 : 2.3, 0, Math.PI * 2);
                    ctx.fill();
                }
            }

            // Player center blip
            ctx.fillStyle = '#38bdf8';
            ctx.beginPath();
            ctx.arc(radCX, radCY, 3.2, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }

        // Custom UI Cards & Buttons in renderQueue
        for (const elem of this.renderQueue) {
            if (elem.type === 'card') {
                ctx.fillStyle = 'rgba(15, 23, 42, 0.82)';
                ctx.strokeStyle = 'rgba(255, 255, 255, 0.16)';
                ctx.lineWidth = 1.1;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 12, true, true);
                ctx.fillStyle = '#38bdf8';
                ctx.font = 'bold 13px Outfit, sans-serif';
                ctx.fillText(elem.title, elem.x + 14, elem.y + 24);
                ctx.fillStyle = '#94a3b8';
                ctx.font = '11px Outfit, monospace, sans-serif';
                const lines = String(elem.text || '').replace(/\\n/g, '\n').split('\n');
                for (let li = 0; li < lines.length; li++) {
                    ctx.fillText(lines[li], elem.x + 14, elem.y + 44 + li * 18);
                }
            } else if (elem.type === 'button') {
                ctx.fillStyle = elem.isPressed ? '#4f46e5' : '#6366f1';
                ctx.strokeStyle = '#a5b4fc';
                ctx.lineWidth = 1.3;
                this.roundRect(ctx, elem.x, elem.y, elem.w, elem.h, 9, true, true);
                ctx.fillStyle = '#ffffff';
                ctx.font = 'bold 12px Outfit, sans-serif';
                ctx.textAlign = 'center';
                ctx.fillText(elem.text, elem.x + elem.w * 0.5, elem.y + elem.h * 0.5 + 4);
                ctx.textAlign = 'left';
            }
        }

        if (this.combo > 1 && this.comboTimer > 0) {
            ctx.fillStyle = '#fbbf24';
            ctx.font = 'bold 12px Outfit, monospace, sans-serif';
            ctx.fillText(`⚡ COMBO x${this.combo}`, 20, h - 42);
        }

        // Responsive 3D Virtual Stick & Buttons for Touch / Narrow Screens
        if (this.touchState.hasTouch || w < 720) {
            const stickCX = 78, stickCY = h - 74;
            ctx.fillStyle = 'rgba(15, 23, 42, 0.58)';
            ctx.strokeStyle = 'rgba(56, 189, 248, 0.45)';
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.arc(stickCX, stickCY, 44, 0, Math.PI * 2);
            ctx.fill();
            ctx.stroke();

            ctx.fillStyle = '#38bdf8';
            ctx.beginPath();
            ctx.arc(stickCX + this.touchState.stickX * 26, stickCY - this.touchState.stickY * 26, 16, 0, Math.PI * 2);
            ctx.fill();

            ctx.font = 'bold 14px monospace';
            ctx.textAlign = 'center';
            // X = Dash
            ctx.fillStyle = 'rgba(0, 245, 212, 0.32)';
            ctx.strokeStyle = '#00f5d4';
            this.roundRect(ctx, w - 196, h - 68, 50, 44, 11, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('X', w - 171, h - 41);

            // B = Shoot
            ctx.fillStyle = 'rgba(239, 68, 68, 0.35)';
            ctx.strokeStyle = '#ef4444';
            this.roundRect(ctx, w - 136, h - 68, 50, 44, 11, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('B', w - 111, h - 41);

            // A = Jump
            ctx.fillStyle = 'rgba(56, 189, 248, 0.38)';
            ctx.strokeStyle = '#38bdf8';
            this.roundRect(ctx, w - 76, h - 68, 54, 44, 11, true, true);
            ctx.fillStyle = '#ffffff';
            ctx.fillText('A', w - 49, h - 41);
            ctx.textAlign = 'left';
        }

        // Game Over / Victory Overlays
        if (this.gameOver || this.gameWon) {
            ctx.fillStyle = 'rgba(4, 7, 18, 0.86)';
            ctx.fillRect(0, 0, w, h);
            ctx.textAlign = 'center';
            ctx.fillStyle = this.gameWon ? '#fbbf24' : '#ef4444';
            ctx.shadowColor = ctx.fillStyle;
            ctx.shadowBlur = 22;
            ctx.font = '900 32px Outfit, sans-serif';
            ctx.fillText(this.gameWon ? '¡ODISEA 3D COMPLETADA!' : 'MISIÓN 3D TERMINADA', w * 0.5, h * 0.5 - 30);
            ctx.shadowBlur = 0;
            ctx.fillStyle = '#f8fafc';
            ctx.font = 'bold 17px Outfit, sans-serif';
            ctx.fillText(`PUNTAJE FINAL: ${this.score} PTS`, w * 0.5, h * 0.5 + 12);
            ctx.fillStyle = '#38bdf8';
            ctx.font = 'bold 13.5px Outfit, sans-serif';
            ctx.fillText('Presiona [R] o Haz Clic para Reiniciar el Mundo 3D', w * 0.5, h * 0.5 + 48);
            ctx.textAlign = 'left';
        }

        // Pause Overlay 3D
        if (this.paused && !this.gameOver && !this.gameWon) {
            ctx.fillStyle = 'rgba(4, 7, 18, 0.72)';
            ctx.fillRect(0, 0, w, h);
            ctx.textAlign = 'center';
            ctx.fillStyle = '#38bdf8';
            ctx.font = '900 30px Outfit, sans-serif';
            ctx.fillText('MUNDO 3D EN PAUSA', w * 0.5, h * 0.5 - 16);
            ctx.fillStyle = '#f8fafc';
            ctx.font = 'bold 14px Outfit, sans-serif';
            ctx.fillText('Presiona [P] o [Esc] para continuar', w * 0.5, h * 0.5 + 18);
            ctx.textAlign = 'left';
        }

        // Bottom Telemetry Watermark
        const effHz = 60 * (this.physics3D.substeps || 4);
        ctx.fillStyle = 'rgba(255, 255, 255, 0.48)';
        ctx.font = '900 10.5px monospace';
        ctx.fillText(`SHINE LOOP 3D QUANTUM • ${this.fps} FPS / ${effHz}Hz PHYSICS • WASD Mover | SPACE Saltar | SHIFT Dash | Z Plasma | [P] Pausa | Q/E Órbita`, 18, h - 14);
    }
}
