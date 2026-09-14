// SPDX-License-Identifier: GPL-3.0-only
// Test config edits against Herdr's validator, never a running server/session.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const herdr = process.argv[2] || 'herdr';
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-herdr-smoke-'));
let index = 0;
const fixture = (content) => {
    const file = path.join(scratch, `config-${index++}.toml`);
    if (content !== null) fs.writeFileSync(file, content);
    return file;
};
const apply = (file) => spawnSync('bash', [
    path.join(root, 'scripts/configure-herdr-prefix.sh'), file, herdr,
], {encoding: 'utf8', timeout: 10000});
try {
    for (const source of [
        'onboarding = false\n[theme]\nname = "catppuccin"\n',
        '[keys]\nprefix = "ctrl+b"\nnew_tab = "prefix+c"\n[theme]\nname = "catppuccin"\n',
        '[keys]\nnew_tab = "prefix+c"\n[theme]\nname = "catppuccin"\n',
        '[theme]\nname = "catppuccin"\n[keys]\n# prefix is customized below\nprefix = \'ctrl+b\'\n',
        '[keys]\nprefix = "ctrl+a" # keep this comment\n[theme]\nname = "catppuccin"\n',
        null,
    ]) {
        const file = fixture(source);
        const result = apply(file);
        assert.equal(result.status, 0, result.stderr + result.stdout);
        const updated = fs.readFileSync(file, 'utf8');
        assert.match(updated, /prefix = "ctrl\+a"/);
        if (source) {
            assert.match(updated, /name = "catppuccin"/);
            if (source.includes('new_tab')) assert.match(updated, /new_tab = "prefix\+c"/);
            if (source.includes('keep this comment')) assert.equal(updated, source);
        }
        const beforeSecondRun = fs.readdirSync(scratch).sort();
        assert.equal(apply(file).status, 0);
        assert.equal(fs.readFileSync(file, 'utf8'), updated);
        assert.deepEqual(fs.readdirSync(scratch).sort(), beforeSecondRun, 'Unchanged files need no new backup');
    }
    // Unsupported structures must not overwrite the existing file.
    for (const source of [
        '[keys]\n"prefix" = "ctrl+b"\n',
        '# Triple-quoted strings require manual editing: """\n[theme]\nname = "catppuccin"\n',
        '[keys\nprefix = "ctrl+b"\n',
    ]) {
        const file = fixture(source);
        assert.notEqual(apply(file).status, 0);
        assert.equal(fs.readFileSync(file, 'utf8'), source);
    }
    const original = fixture('[keys]\nprefix = "ctrl+b"\n');
    const link = path.join(scratch, 'symlink.toml');
    fs.symlinkSync(original, link);
    assert.notEqual(apply(link).status, 0);
    assert.equal(fs.readFileSync(original, 'utf8'), '[keys]\nprefix = "ctrl+b"\n');
    console.log('Herdr smoke tests passed: prefix edits, preservation, idempotence, validation and symlink safety.');
} finally {
    // Only remove the private fixture directory created by this test.
    fs.rmSync(scratch, {recursive: true, force: true});
}
