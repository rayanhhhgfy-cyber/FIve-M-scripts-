// Real Lua syntax checker using luaparse.
// Usage: npm i luaparse  (run once)  then:  node check-syntax.js
const fs = require('fs');
const path = require('path');

let luaparse;
try {
    luaparse = require('luaparse');
} catch (e) {
    console.error('luaparse not installed. Run:  npm install luaparse');
    process.exit(1);
}

function walk(dir) {
    let results = [];
    try {
        fs.readdirSync(dir).forEach(f => {
            let fp = path.join(dir, f);
            try {
                let s = fs.statSync(fp);
                if (s.isDirectory()) results = results.concat(walk(fp));
                else if (f.endsWith('.lua')) results.push(fp);
            } catch {}
        });
    } catch {}
    return results;
}

const files = walk('resources');
console.log('Checking ' + files.length + ' Lua files...\n');

const ERRORS = [];

for (const fp of files) {
    let c;
    try { c = fs.readFileSync(fp, 'utf8'); } catch { continue; }
    try {
        // luaX = LuaJIT/Lua 5.4-ish; FiveM uses CfxLua (5.4 features + goto etc.)
        luaparse.parse(c, { luaVersion: '5.3', comments: false });
    } catch (err) {
        ERRORS.push({ file: fp, message: err.message });
    }
}

if (ERRORS.length === 0) {
    console.log('No syntax errors detected.');
} else {
    console.log(ERRORS.length + ' file(s) with syntax errors:\n');
    for (const e of ERRORS) {
        console.log(e.file);
        console.log('  -> ' + e.message + '\n');
    }
}
