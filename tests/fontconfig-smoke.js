// SPDX-License-Identifier: GPL-3.0-only
// Reads the bundled fontconfig file with fontconfig itself; the user's own config is untouched.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const conf = path.join(root, 'config/fontconfig/fonts.conf');

// Valid XML with fontconfig's DTD line, or fontconfig ignores the file entirely.
assert.match(fs.readFileSync(conf, 'utf8'), /<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts\.dtd">/);
const parsed = spawnSync('python3', ['-c', 'import sys,xml.etree.ElementTree as e; e.parse(sys.argv[1])', conf], {encoding: 'utf8'});
assert.equal(parsed.status, 0, parsed.stderr);

// fontconfig reads $XDG_CONFIG_HOME/fontconfig/fonts.conf, so point it at the bundle.
const bundled = {...process.env, XDG_CONFIG_HOME: path.join(root, 'config')};
const empty = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-fc-smoke-'));
const without = {...process.env, XDG_CONFIG_HOME: empty};
const families = (pattern, env) => {
    const result = spawnSync('fc-match', ['-s', pattern, 'family'], {encoding: 'utf8', timeout: 20000, env});
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim().split('\n');
};
try {
    // The bug being fixed: Arabic in a generic family resolves to Kufi's display letterforms.
    assert.equal(families('sans-serif:lang=ar', without)[0], 'Noto Kufi Arabic');

    // Latin face first (Latin rendering unchanged), Arabic text face immediately after.
    for (const [generic, latin, arabic] of [
        ['sans-serif', 'Noto Sans', 'Noto Sans Arabic'],
        ['system-ui', 'Noto Sans', 'Noto Sans Arabic'],
        ['serif', 'Noto Serif', 'Noto Naskh Arabic'],
        ['monospace', 'Noto Sans Mono', 'Noto Sans Arabic'],
    ]) {
        assert.deepEqual(families(`${generic}:lang=ar`, bundled).slice(0, 2), [latin, arabic], generic + ' Arabic order');
        assert.equal(families(`${generic}:lang=en`, bundled)[0], latin, generic + ' must keep its Latin face first');
        assert.equal(families(`${generic}:lang=en`, bundled)[0], families(`${generic}:lang=en`, without)[0],
            generic + ' Latin choice must match a system without this file');
    }

    // Sites like YouTube ask for named families, never the generics; Chrome falls back per
    // glyph to the first family covering it, so a Latin-only substitute may come first.
    for (const family of ['Roboto', 'Arial', 'Helvetica', 'Inter']) {
        const order = families(`${family}:lang=ar`, bundled);
        const text = order.indexOf('Noto Sans Arabic');
        const kufi = order.indexOf('Noto Kufi Arabic');
        assert.notEqual(text, -1, family + ' must reach Noto Sans Arabic');
        assert.ok(kufi === -1 || text < kufi, family + ' must prefer Noto Sans Arabic over Noto Kufi Arabic');
    }
} finally {
    fs.rmSync(empty, {recursive: true, force: true});
}

assert.match(fs.readFileSync(path.join(root, 'README.md'), 'utf8'), /~\/\.config\/fontconfig/, 'Document the fontconfig file');

// The desktop configuration bundle must install it; find that prompt without hardcoding order.
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-fc-install-'));
try {
    let bundle;
    for (let position = 0; position < 40 && !bundle; position++) {
        const result = spawnSync('bash', [path.join(root, 'install.sh'), '--dry-run'], {
            encoding: 'utf8', timeout: 20000, env: {...process.env, HOME: home},
            input: Array.from({length: 80}, (_, index) => (index === position ? 'y' : 'n')).join('\n') + '\n',
        });
        if (result.stdout.includes('/config/i3/config ')) bundle = result;
    }
    assert.ok(bundle, 'The desktop configuration bundle prompt must exist');
    assert.match(bundle.stdout, /install -Dm644 -- \S+\/config\/fontconfig\/fonts\.conf \S+\/\.config\/fontconfig\/fonts\.conf/);
    assert.deepEqual(fs.readdirSync(home), [], 'A preview must not create files');
} finally {
    fs.rmSync(home, {recursive: true, force: true});
}
console.log('fontconfig-smoke: all checks passed');
