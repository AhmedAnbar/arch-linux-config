// SPDX-License-Identifier: GPL-3.0-only
// Parses the bundled kitty config with kitty itself and previews the installer in a scratch HOME.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const dir = path.join(root, 'config/kitty');

// Only real config: no macOS AppleDouble files or "XSym" pseudo-symlinks copied from a Mac.
assert.deepEqual(fs.readdirSync(dir).sort(), ['current-theme.conf', 'kitty.conf']);
for (const file of fs.readdirSync(dir)) {
    assert.doesNotMatch(fs.readFileSync(path.join(dir, file), 'utf8'), /^XSym$/m, file + ' must be a real config file');
}

const probe = spawnSync('kitty', ['+runpy', [
    'from kitty.config import load_config',
    'o = load_config("kitty.conf")',
    'print(o.font_family, o.font_size, o.bold_italic_font, o.background, o.foreground, sep="|")',
].join('\n')], {cwd: dir, encoding: 'utf8', timeout: 20000});
if (!probe.error) {
    assert.equal(probe.status, 0, probe.stderr);
    // kitty logs skipped lines instead of failing, so a broken include only shows up here.
    assert.doesNotMatch(probe.stdout + probe.stderr, /Ignoring invalid config line|Could not find/);
    const [family, size, boldItalic, background, foreground] = probe.stdout.trim().split('\n').at(-1).split('|');
    assert.match(family, /JetBrains Mono Nerd Font/);
    assert.equal(size, '12.0');
    assert.equal(boldItalic, 'auto');
    // The Catppuccin Mocha theme must actually apply, not fall back to kitty's black default.
    assert.equal(background, 'Color(30, 30, 46)', 'Catppuccin Mocha background #1e1e2e');
    assert.equal(foreground, 'Color(205, 214, 244)', 'Catppuccin Mocha foreground #cdd6f4');
}

const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
assert.match(readme, /~\/\.config\/kitty/, 'Document the kitty configuration');

// The desktop configuration bundle must install both kitty files; find its prompt without hardcoding order.
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-kitty-smoke-'));
try {
    const preview = (yesAt) => spawnSync('bash', [path.join(root, 'install.sh'), '--dry-run'], {
        encoding: 'utf8', timeout: 20000, env: {...process.env, HOME: home},
        input: Array.from({length: 80}, (_, index) => (index === yesAt ? 'y' : 'n')).join('\n') + '\n',
    });
    let bundle;
    for (let position = 0; position < 40 && !bundle; position++) {
        const result = preview(position);
        if (result.stdout.includes('/config/i3/config ')) bundle = result;
    }
    assert.ok(bundle, 'The desktop configuration bundle prompt must exist');
    assert.equal(bundle.status, 0, bundle.stderr);
    for (const file of ['kitty.conf', 'current-theme.conf']) {
        assert.match(bundle.stdout, new RegExp(`install -Dm644 -- \\S+/config/kitty/${file.replace('.', '\\.')} \\S+/\\.config/kitty/${file.replace('.', '\\.')}`));
    }
    assert.deepEqual(fs.readdirSync(home), [], 'A preview must not create files');
} finally {
    fs.rmSync(home, {recursive: true, force: true});
}
console.log('kitty-smoke: all checks passed');
