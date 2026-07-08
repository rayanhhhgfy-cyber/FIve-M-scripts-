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

function preprocessCfxLua(code) {
    return code
        // Replace backtick hash strings: `SOME_HASH` -> "HASH_SOME_HASH"
        .replace(/`([a-zA-Z0-9_]+)`/g, '"HASH_$1"')

        // Remove ? from ?. and ?[ (safe navigation) -> turns into . and [
        .replace(/\?\./g, '.')
        .replace(/\?\[/g, '[')
        // Handle any remaining stray ? that isn't in a string (ternary)
        // but NOTE: Lua uses 'and/or' for ternary, not ?, so stray ? is likely safe to remove
        .replace(/\?/g, '')

        // Replace compound assignments with no-op valid syntax for parsing purposes
        .replace(/\s*\+=/g, ' = 0 +')
        .replace(/\s*-=/g, ' = 0 -')
        .replace(/\s*\*=/g, ' = 0 *')
        .replace(/\s*\/=/g, ' = 0 /')

        // Remove <close> and other variable attributes: local x <close> = ...
        .replace(/<[a-z_]+>/g, '');
}

const files = walk('resources');
console.log('Checking ' + files.length + ' Lua files...\n');

const ERRORS = [];

for (const fp of files) {
    let c;
    try { c = fs.readFileSync(fp, 'utf8'); } catch { continue; }
    try {
        const preprocessed = preprocessCfxLua(c);
        luaparse.parse(preprocessed, { luaVersion: '5.3', comments: false });
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
