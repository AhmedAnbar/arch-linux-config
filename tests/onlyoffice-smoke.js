// SPDX-License-Identifier: GPL-3.0-only
// Stubbed yay in a scratch HOME: previews only, no package is downloaded or installed.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const install = fs.readFileSync(path.join(root, 'install.sh'), 'utf8');

// The source package build-depends on nodejs-lts-iron, which replaces nodejs.
assert.match(install, /for package in [^\n]*\bonlyoffice-bin\b/, 'Offer the prebuilt package');
assert.doesNotMatch(install, /\bonlyoffice\b(?!-bin)/, 'Never offer the source package');
const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
assert.ok(readme.includes('`onlyoffice-bin`'), 'Document onlyoffice-bin');
assert.match(readme, /nodejs-lts-iron/, 'Explain why the source package is not used');

const home = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-onlyoffice-smoke-'));
try {
    const bin = path.join(home, 'bin');
    fs.mkdirSync(bin);
    // A stub keeps the AUR branch reachable on machines without an AUR helper.
    fs.writeFileSync(path.join(bin, 'yay'), '#!/bin/sh\nexit 1\n', {mode: 0o755});
    // Bash hides read -p prompts when stdin is not a terminal, so locate the AUR
    // section by its printed yay command: y for the gate and its own prompts only.
    const preview = (gate) => spawnSync('bash', [path.join(root, 'install.sh'), '--dry-run'], {
        encoding: 'utf8', timeout: 20000,
        env: {...process.env, HOME: home, PATH: `${bin}:${process.env.PATH}`},
        input: Array.from({length: 80}, (_, index) =>
            (index >= gate && index < gate + 13 ? 'y' : 'n')).join('\n') + '\n',
    });
    let aur;
    for (let gate = 0; gate < 40 && !aur; gate++) {
        const result = preview(gate);
        if (/yay -S --needed/.test(result.stdout)) aur = result;
    }
    assert.ok(aur, 'The AUR section must run yay');
    assert.equal(aur.status, 0, aur.stderr);
    const command = aur.stdout.split('\n').find((line) => line.includes('yay -S --needed'));
    assert.match(command, /\bonlyoffice-bin\b/, 'Offer onlyoffice-bin');
    assert.doesNotMatch(command, /\bonlyoffice\b(?!-bin)/, 'Never install the source package');
    // Google Chrome stays a separate prompt, so both must survive in the same section.
    assert.match(command, /\bgoogle-chrome\b/);
    assert.deepEqual(fs.readdirSync(home), ['bin'], 'A preview must not create files');
} finally {
    fs.rmSync(home, {recursive: true, force: true});
}
console.log('onlyoffice-smoke: all checks passed');
