// SPDX-License-Identifier: GPL-3.0-only
// No compositor, package installation, GUI, real screenshots or clipboard access.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const run = (command, args, options = {}) => spawnSync(command, args, {
    encoding: 'utf8', timeout: 10000, ...options,
});
const check = (result) => assert.equal(result.status, 0, result.stderr || result.error?.message);

check(run('bash', ['-n', path.join(root, 'setup-sway.sh')]));
check(run('bash', ['-n', path.join(root, 'install.sh')]));
for (const file of fs.readdirSync(path.join(root, 'sway/config/sway'))) {
    if (file.endsWith('.sh')) check(run('sh', ['-n', path.join(root, 'sway/config/sway', file)]));
}
const bar = JSON.parse(read('sway/config/waybar/config.jsonc'));
assert.equal(bar.position, 'top');
assert.ok(bar['modules-right'].includes('sway/language'));
assert.ok(!bar['modules-right'].includes('pulseaudio'), 'Keep the removed volume applet absent');
const packages = read('sway/packages.txt').trim().split('\n');
assert.equal(new Set(packages).size, packages.length, 'No duplicate packages');
for (const pkg of packages) {
    assert.match(pkg, /^[a-z0-9][a-z0-9+_.-]*$/);
    assert.ok(read('README.md').includes('`' + pkg + '`'), 'Missing package documentation: ' + pkg);
}
const config = read('sway/config/sway/config');
assert.match(config, /xkb_layout us,ara/);
assert.match(config, /xkb_options grp:shift_caps_toggle/);
assert.match(config, /scroll_method two_finger/);
assert.match(config, /gaps inner 6/);
assert.match(config, /gaps outer 4/);
assert.ok(!/^[^#\n]*(?:exec|exec_always)\s+(?:picom|xrandr|xinput|setxkbmap|xss-lock|flameshot)\b/m.test(config));
check(run('bash', [path.join(root, 'setup-sway.sh'), '--help']));
assert.equal(run('bash', [path.join(root, 'setup-sway.sh'), '--invalid']).status, 2);
// Enough yes answers for existing-file prompts too; dry-run must never invoke sudo.
const preview = run('bash', [path.join(root, 'setup-sway.sh'), '--dry-run'], {input: 'y\n'.repeat(100)});
check(preview);
assert.match(preview.stdout, /sudo pacman -Syu --needed/);
assert.match(preview.stdout, /Would check package availability/);

const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-sway-smoke-'));
const bin = path.join(scratch, 'bin');
fs.mkdirSync(bin);
const mock = (name, body) => fs.writeFileSync(path.join(bin, name), '#!/bin/sh\nset -eu\n' + body + '\n', {mode: 0o755});
try {
    mock('slurp', 'test "${TEST_CANCEL:-0}" = 0 || exit 1; printf "0,0 50x50\\n"');
    mock('xdg-user-dir', 'printf "%s\\n" "$TEST_PICTURES"');
    mock('grim', 'test "${TEST_CAPTURE_FAIL:-0}" = 0 || exit 1; printf "test PNG fixture" > "$3"');
    mock('wl-copy', 'test "$1" = --type; test "$2" = image/png; test "${TEST_COPY_FAIL:-0}" = 0 || exit 1; cat > "$TEST_CLIPBOARD"');
    mock('notify-send', 'exit 0');
    const captureScript = path.join(root, 'sway/config/sway/screenshot.sh');
    const environment = {
        ...process.env, PATH: bin + ':' + process.env.PATH,
        TEST_PICTURES: path.join(scratch, 'Pictures with spaces'),
        TEST_CLIPBOARD: path.join(scratch, 'clipboard'),
    };
    const screenshots = path.join(environment.TEST_PICTURES, 'Screenshots');
    check(run('sh', [captureScript], {env: {...environment, TEST_CANCEL: '1'}}));
    assert.ok(!fs.existsSync(screenshots), 'Cancellation must not create a screenshot directory');
    check(run('sh', [captureScript], {env: environment}));
    check(run('sh', [captureScript], {env: environment}));
    let captures = fs.readdirSync(screenshots);
    assert.equal(captures.length, 2, 'Repeated captures must have distinct filenames');
    for (const capture of captures) {
        assert.equal(fs.statSync(path.join(screenshots, capture)).mode & 0o777, 0o600);
    }
    assert.equal(fs.readFileSync(environment.TEST_CLIPBOARD, 'utf8'), 'test PNG fixture');
    assert.equal(run('sh', [captureScript], {env: {...environment, TEST_CAPTURE_FAIL: '1'}}).status, 1);
    assert.equal(fs.readdirSync(screenshots).length, 2, 'Failed captures leave no empty file');
    assert.equal(run('sh', [captureScript], {env: {...environment, TEST_COPY_FAIL: '1'}}).status, 1);
    assert.equal(fs.readdirSync(screenshots).length, 3, 'Clipboard failure must retain the saved PNG');
    console.log('Sway smoke tests passed: syntax, package docs, preview, screenshots and cancellation.');
} finally {
    // Only remove the private, uniquely named test fixture created above.
    fs.rmSync(scratch, {recursive: true, force: true});
}
