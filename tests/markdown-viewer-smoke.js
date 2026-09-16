// SPDX-License-Identifier: GPL-3.0-only
// Installer previews only, in a scratch HOME: no desktop entries or MIME defaults are changed.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');

// The entry must open files rendered, claim Markdown, and stay out of the app launcher.
const entryPath = path.join(root, 'applications/retext-preview.desktop');
const entry = Object.fromEntries(read('applications/retext-preview.desktop').split('\n')
    .filter((line) => line.includes('=')).map((line) => [line.slice(0, line.indexOf('=')), line.slice(line.indexOf('=') + 1)]));
assert.equal(entry.Exec, 'retext --preview %F', 'Double-click must open the rendered preview, not the editor');
assert.ok(entry.MimeType.split(';').includes('text/markdown'));
assert.equal(entry.NoDisplay, 'true', 'Keep a single ReText entry in Rofi');
const validator = spawnSync('desktop-file-validate', [entryPath], {encoding: 'utf8'});
if (!validator.error) assert.equal(validator.status, 0, validator.stdout + validator.stderr);

assert.match(read('install.sh'), /^group 'Browser and file utilities' .*\bretext\b/m, 'ReText belongs to the file utilities group');
assert.ok(read('README.md').includes('`retext`'), 'Document the retext package');

// Find the viewer prompt by answering yes at one position at a time, without hardcoding prompt order.
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-markdown-smoke-'));
try {
    const preview = (yesAt) => spawnSync('bash', [path.join(root, 'install.sh'), '--dry-run'], {
        encoding: 'utf8', timeout: 20000, env: {...process.env, HOME: home},
        input: Array.from({length: 80}, (_, index) => (index === yesAt ? 'y' : 'n')).join('\n') + '\n',
    });
    const none = preview(-1);
    assert.equal(none.status, 0, none.stderr);
    assert.doesNotMatch(none.stdout, /retext-preview/, 'Declining must not touch the Markdown default');

    const hits = [];
    for (let position = 0; position < 60; position++) {
        const result = preview(position);
        if (result.stdout.includes('retext-preview.desktop')) hits.push({position, result});
    }
    assert.equal(hits.length, 1, 'Exactly one installer prompt sets up the Markdown viewer');
    const {result} = hits[0];
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /install -Dm644 -- \S+\/applications\/retext-preview\.desktop \S+\/\.local\/share\/applications\/retext-preview\.desktop/);
    assert.match(result.stdout, /xdg-mime default retext-preview\.desktop text\/markdown/);
    assert.deepEqual(fs.readdirSync(home), [], 'A preview must not create files');
} finally {
    fs.rmSync(home, {recursive: true, force: true});
}
console.log('markdown-viewer-smoke: all checks passed');
