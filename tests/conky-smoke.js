// SPDX-License-Identifier: GPL-3.0-only
// Stubbed conky/rofi only: no real panel, compositor, package install or user config is touched.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const run = (command, args, options = {}) => spawnSync(command, args, {
    encoding: 'utf8', timeout: 15000, ...options,
});
const check = (result) => assert.equal(result.status, 0, result.stderr || result.error?.message);
const themes = ['catppuccin', 'dracula', 'nord'];

check(run('bash', ['-n', path.join(root, 'setup-conky.sh')]));
for (const script of ['start.sh', 'switch.sh']) check(run('sh', ['-n', path.join(root, 'config/conky', script)]));
assert.deepEqual(fs.readdirSync(path.join(root, 'config/conky/themes')).sort(), themes.map((name) => name + '.conf'));

// Evaluate every theme the way conky does: a Lua chunk filling the global conky table.
const evaluate = (theme, environment) => {
    const probe = `
        conky = {}
        dofile(${JSON.stringify(path.join(root, 'config/conky/themes', theme + '.conf'))})
        local c = conky.config
        print(c.alignment, tostring(c.out_to_wayland), tostring(c.out_to_x), tostring(c.own_window),
            tostring(c.own_window_argb_value), tostring(c.own_window_argb_visual), c.own_window_colour, c.color1, c.default_color)
        io.write(conky.text)`;
    const result = run('lua', ['-e', probe], {env: {...environment, XDG_CONFIG_HOME: path.join(root, 'config')}});
    check(result);
    const [header, ...text] = result.stdout.split('\n');
    return {fields: header.split('\t'), text: text.join('\n')};
};
const palettes = new Set();
for (const theme of themes) {
    const base = {PATH: process.env.PATH, HOME: os.tmpdir()};
    const wayland = evaluate(theme, {...base, WAYLAND_DISPLAY: 'wayland-1'});
    // Conky 1.24 creates no Wayland surface without own_window, so the panel silently never appears.
    assert.deepEqual(wayland.fields.slice(0, 4), ['top_right', 'true', 'false', 'true'], theme + ' must draw a Wayland surface under sway');
    const x11 = evaluate(theme, {...base, DISPLAY: ':0'});
    assert.deepEqual(x11.fields.slice(0, 4), ['top_right', 'false', 'true', 'true'], theme + ' must use an X11 window under i3');
    // Removed/deprecated in Conky 1.24: opacity now lives in own_window_colour as #AARRGGBB.
    assert.deepEqual(wayland.fields.slice(4, 6), ['nil', 'nil'], theme + ' must not use the removed ARGB settings');
    assert.match(wayland.fields[6], /^#[0-9a-f]{8}$/i, theme + ' window colour needs an alpha channel');
    assert.match(wayland.fields[7], /^[0-9a-f]{6}$/i, theme + ' needs hex colours without #');
    palettes.add(wayland.fields.slice(6).join());
    // One core's frequency is misleading on a mostly idle hybrid CPU; show the fastest core.
    assert.doesNotMatch(wayland.text, /\$\{freq/, theme + ' must not show a single core frequency');
    assert.match(wayland.text, /\$\{execi 2 awk .*?\/sys\/devices\/system\/cpu\/cpu\*\/cpufreq\/scaling_cur_freq\} GHz max/);
    for (const variable of ['time', 'cpu cpu0', 'hwmon', 'cpugraph', 'membar', 'swapbar', 'fs_bar']) {
        assert.ok(wayland.text.includes('${' + variable), `${theme} panel is missing \${${variable}}`);
    }
    // Lua/Cairo drawing is unreliable on Wayland; the panel must not depend on it.
    assert.doesNotMatch(wayland.text, /\$\{lua|cairo/);
}
assert.equal(palettes.size, themes.length, 'Each theme needs its own palette');

const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-conky-smoke-'));
const bin = path.join(scratch, 'bin');
const bare = path.join(scratch, 'bare-bin');
const configHome = path.join(scratch, 'config');
const runtime = path.join(scratch, 'runtime');
for (const dir of [bin, bare, runtime]) fs.mkdirSync(dir);
fs.cpSync(path.join(root, 'config/conky'), path.join(configHome, 'conky'), {recursive: true});
fs.cpSync(path.join(root, 'config/rofi'), path.join(configHome, 'rofi'), {recursive: true});
const log = path.join(scratch, 'conky.log');
const mock = (name, body) => fs.writeFileSync(path.join(bin, name), '#!/bin/sh\n' + body + '\n', {mode: 0o755});
// Named "conky" so /proc/<pid>/comm matches, as it would for the real binary.
mock('conky', `printf '%s\\n' "$*" >> "${log}"; trap 'exit 0' TERM; while :; do sleep 0.1; done`);
mock('rofi', 'cat > /dev/null; test "${TEST_ROFI_CANCEL:-0}" = 0 || exit 1; printf "%s\\n" "$TEST_ROFI_CHOICE"');
// Utilities only, so start.sh can prove it does nothing when conky is absent.
for (const tool of ['setsid', 'mkdir', 'rm', 'cat', 'sleep']) fs.symlinkSync(`/usr/bin/${tool}`, path.join(bare, tool));
const environment = {
    PATH: `${bin}:${process.env.PATH}`, HOME: scratch, XDG_CONFIG_HOME: configHome,
    XDG_RUNTIME_DIR: runtime, WAYLAND_DISPLAY: 'wayland-1',
};
const start = (env = environment) => run('/bin/sh', [path.join(configHome, 'conky/start.sh')], {env});
const switchTo = (args, env = environment) => run('/bin/sh', [path.join(configHome, 'conky/switch.sh'), ...args], {env});
const pidFile = path.join(runtime, 'arch-desktop-conky.pid');
const selected = () => fs.readFileSync(path.join(configHome, 'conky/theme'), 'utf8').trim();
const alive = (pid) => { try { process.kill(pid, 0); return true; } catch { return false; } };
const waitFor = (condition, what) => {
    const deadline = Date.now() + 3000;
    while (!condition()) {
        if (Date.now() > deadline) assert.fail('Timed out waiting for ' + what);
        spawnSync('sleep', ['0.05']);
    }
};
const lastStart = () => {
    waitFor(() => fs.existsSync(log) && fs.readFileSync(log, 'utf8').trim(), 'conky to start');
    return fs.readFileSync(log, 'utf8').trim().split('\n').at(-1);
};
const runningPid = () => Number(fs.readFileSync(pidFile, 'utf8'));

try {
    // Missing conky is a quiet no-op, so autostart lines are safe before the package is installed.
    const absent = start({...environment, PATH: bare});
    check(absent);
    assert.equal(fs.existsSync(pidFile), false);

    // A fresh setup starts the default Catppuccin theme.
    check(start());
    assert.match(lastStart(), /-c \S+\/conky\/themes\/catppuccin\.conf$/);
    const first = runningPid();
    assert.ok(alive(first));

    // Starting again replaces the panel instead of stacking a second one.
    fs.rmSync(log);
    check(start());
    lastStart();
    waitFor(() => !alive(first), 'the previous panel to stop');
    const second = runningPid();
    assert.notEqual(second, first);

    // Named switch saves the choice and restarts with it.
    fs.rmSync(log);
    check(switchTo(['nord']));
    assert.equal(selected(), 'nord');
    assert.match(lastStart(), /themes\/nord\.conf$/);
    waitFor(() => !alive(second), 'the Catppuccin panel to stop');

    // Unknown names are rejected and keep the current theme.
    const bogus = switchTo(['solarized']);
    assert.notEqual(bogus.status, 0);
    assert.match(bogus.stderr, /Unknown theme: solarized/);
    assert.match(bogus.stderr, /catppuccin.*dracula.*nord/s);
    assert.equal(selected(), 'nord');

    const listed = switchTo(['--list']);
    check(listed);
    assert.deepEqual(listed.stdout.trim().split('\n'), [...themes, 'off']);

    // The Rofi picker selects a theme; cancelling it changes nothing.
    fs.rmSync(log);
    check(switchTo([], {...environment, TEST_ROFI_CHOICE: 'dracula'}));
    assert.equal(selected(), 'dracula');
    assert.match(lastStart(), /themes\/dracula\.conf$/);
    const dracula = runningPid();
    check(switchTo([], {...environment, TEST_ROFI_CANCEL: '1'}));
    assert.equal(selected(), 'dracula');
    assert.ok(alive(dracula), 'Cancelling the picker must keep the panel running');

    // Off stops the panel and survives the next login's autostart.
    check(switchTo(['off']));
    assert.equal(selected(), 'off');
    waitFor(() => !alive(dracula), 'the panel to stop');
    assert.equal(fs.existsSync(pidFile), false);
    fs.rmSync(log);
    check(start());
    spawnSync('sleep', ['0.3']);
    assert.equal(fs.existsSync(log), false, 'Autostart must respect the off choice');

    // A stale or hand-edited selection falls back to the default rather than failing login.
    fs.writeFileSync(path.join(configHome, 'conky/theme'), 'missing-theme\n');
    const fallback = start();
    check(fallback);
    assert.match(fallback.stderr, /missing-theme.*catppuccin/);
    assert.match(lastStart(), /themes\/catppuccin\.conf$/);

    // A PID file left by an unrelated process must never be killed.
    const bystander = spawnSync('sh', ['-c', 'sleep 30 >/dev/null 2>&1 & echo $!'], {encoding: 'utf8'});
    const bystanderPid = Number(bystander.stdout.trim());
    const panel = runningPid();
    process.kill(panel, 'SIGTERM');
    waitFor(() => !alive(panel), 'the panel to stop');
    fs.writeFileSync(pidFile, String(bystanderPid));
    check(start());
    assert.ok(alive(bystanderPid), 'Only a conky process may be stopped');
    process.kill(bystanderPid, 'SIGKILL');
} finally {
    if (fs.existsSync(pidFile)) { try { process.kill(runningPid(), 'SIGTERM'); } catch {} }
    fs.rmSync(scratch, {recursive: true, force: true});
}

// Desktop wiring: one autostart and one Alt+Shift+T picker per session.
const swayDropIn = read('sway/config/sway/config.d/30-conky.conf');
assert.match(swayDropIn, /^exec sh ~\/\.config\/conky\/start\.sh$/m);
assert.match(swayDropIn, /^bindsym \$mod\+Shift\+t exec sh ~\/\.config\/conky\/switch\.sh$/m);
const i3 = read('config/i3/config');
assert.match(i3, /^exec --no-startup-id sh ~\/\.config\/conky\/start\.sh$/m);
assert.match(i3, /^bindsym \$mod\+Shift\+t exec --no-startup-id sh ~\/\.config\/conky\/switch\.sh$/m);
for (const config of [read('sway/config/sway/config') + swayDropIn, i3]) {
    assert.equal(config.match(/^bindsym (--\S+ )*\$mod\+Shift\+t /gm).length, 1, 'Alt+Shift+T must stay unique');
}
assert.ok(read('README.md').includes('`conky`'), 'Document the conky package');

// Installer preview never runs sudo or writes configuration.
check(run('bash', [path.join(root, 'setup-conky.sh'), '--help']));
assert.equal(run('bash', [path.join(root, 'setup-conky.sh'), '--invalid']).status, 2);
const previewHome = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-conky-preview-'));
try {
    const preview = run('bash', [path.join(root, 'setup-conky.sh'), '--dry-run'], {
        input: 'y\n'.repeat(40), env: {...process.env, HOME: previewHome, XDG_CONFIG_HOME: ''},
    });
    check(preview);
    assert.match(preview.stdout, /sudo pacman -Syu --needed conky/);
    assert.match(preview.stdout, /install -Dm644 -- \S+\/config\/conky\/themes\/nord\.conf \S+\/\.config\/conky\/themes\/nord\.conf/);
    assert.match(preview.stdout, /sway\/config\.d\/30-conky\.conf/);
    assert.match(preview.stdout, /Preview only/);
    assert.deepEqual(fs.readdirSync(previewHome), [], 'A preview must not create files');
} finally {
    fs.rmSync(previewHome, {recursive: true, force: true});
}
console.log('conky-smoke: all checks passed');
