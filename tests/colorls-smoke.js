// SPDX-License-Identifier: GPL-3.0-only
// Stubbed colorls/yay/sudo in a scratch HOME: no packages, real dotfiles or shells are changed.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const setup = path.join(root, 'setup-colorls.sh');
const aliases = path.join(root, 'config/shell/colorls.sh');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const run = (command, args, options = {}) => spawnSync(command, args, {
    encoding: 'utf8', timeout: 15000, ...options,
});
const check = (result) => assert.equal(result.status, 0, result.stderr || result.error?.message);

check(run('bash', ['-n', setup]));
check(run('sh', ['-n', aliases]));

const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-colorls-smoke-'));
const bin = path.join(scratch, 'bin');
const home = path.join(scratch, 'home');
fs.mkdirSync(bin);
fs.mkdirSync(home);
const log = path.join(scratch, 'calls.log');
const mock = (name, body) => fs.writeFileSync(path.join(bin, name), '#!/bin/sh\n' + body + '\n', {mode: 0o755});
mock('colorls', `printf 'colorls %s\\n' "$*" >> "${log}"`);
const withColorls = {...process.env, PATH: `${bin}:${process.env.PATH}`, HOME: home};
// An empty PATH: the real /usr/bin/colorls must not leak in once it is installed.
const emptyBin = path.join(scratch, 'empty-bin');
fs.mkdirSync(emptyBin);
const withoutColorls = {...process.env, PATH: emptyBin, HOME: home};

// Aliases as an interactive shell sees them; alias expansion needs its own line.
const aliasCheck = (env, extra = '') => run('/usr/bin/bash', ['-c',
    `shopt -s expand_aliases\nalias ls='ls --color=auto'\nsource ${JSON.stringify(aliases)}\nalias ls ll la 2>&1\n${extra}`], {env});

try {
    const defined = aliasCheck(withColorls, 'ls /etc\nll\nla /tmp');
    assert.match(defined.stdout, /alias ls='colorls -l'/);
    assert.match(defined.stdout, /alias ll='colorls -la'/);
    assert.match(defined.stdout, /alias la='colorls -A'/);
    assert.deepEqual(fs.readFileSync(log, 'utf8').trim().split('\n'),
        ['colorls -l /etc', 'colorls -la', 'colorls -A /tmp'], 'ls, ll and la must run colorls');

    // Without colorls the previous ls alias stays, so a shell never loses a working ls.
    const fallback = aliasCheck(withoutColorls);
    assert.match(fallback.stdout, /alias ls='ls --color=auto'/);
    assert.doesNotMatch(fallback.stdout, /colorls/);

    // GNU ls stays reachable for scripts and huge directories.
    fs.rmSync(log);
    const escaped = run('bash', ['-c', `shopt -s expand_aliases\nsource ${JSON.stringify(aliases)}\ncommand ls / > /dev/null\n\\ls / > /dev/null`], {env: withColorls});
    check(escaped);
    assert.equal(fs.existsSync(log), false, 'command ls and \\ls must bypass colorls');

    // Preview: shows every step, writes nothing.
    fs.writeFileSync(path.join(home, '.bashrc'), '# existing bashrc\nalias ls=\'ls --color=auto\'\n');
    fs.writeFileSync(path.join(home, '.zshrc'), '# existing zshrc\n');
    mock('yay', `printf 'yay %s\\n' "$*" >> "${log}"`);
    mock('sudo', `printf 'sudo %s\\n' "$*" >> "${log}"`);
    const snapshot = () => fs.readdirSync(home, {recursive: true}).sort().join();
    const before = snapshot();
    const preview = run('bash', [setup, '--dry-run'], {input: 'y\n'.repeat(20), env: withColorls});
    check(preview);
    assert.match(preview.stdout, /sudo pacman -Syu --needed ruby ttf-jetbrains-mono-nerd/);
    assert.match(preview.stdout, /yay -S --needed ruby-colorls/);
    assert.match(preview.stdout, /install -Dm644 -- \S+\/config\/shell\/colorls\.sh \S+\/home\/\.config\/shell\/colorls\.sh/);
    assert.match(preview.stdout, /Would append the colorls aliases to \S+\/\.bashrc/);
    assert.match(preview.stdout, /Would append the colorls aliases to \S+\/\.zshrc/);
    assert.match(preview.stdout, /Preview only/);
    assert.equal(snapshot(), before, 'A preview must not create or change files');
    assert.equal(fs.existsSync(log), false, 'A preview must not run sudo or yay');

    // Real run with packages declined: aliases installed, both rc files wired once, with backups.
    const answers = ['n', 'n', 'y', 'y', 'y'];
    const applied = run('bash', [setup], {input: answers.join('\n') + '\n', env: withColorls});
    check(applied);
    assert.equal(fs.readFileSync(path.join(home, '.config/shell/colorls.sh'), 'utf8'), fs.readFileSync(aliases, 'utf8'));
    for (const rc of ['.bashrc', '.zshrc']) {
        const content = fs.readFileSync(path.join(home, rc), 'utf8');
        assert.match(content, /^# existing/, rc + ' must keep its existing content');
        assert.equal(content.match(/\.config\/shell\/colorls\.sh/g).length, 2, rc + ' needs one guarded source line');
    }
    const backups = fs.readdirSync(path.join(home, '.local/state/arch-desktop-setup'), {recursive: true});
    assert.ok(backups.some((file) => file.endsWith('.bashrc')), 'bashrc must be backed up before appending');
    assert.equal(fs.existsSync(log), false, 'Declined package steps must not run sudo or yay');

    // The appended bashrc really switches ls to colorls.
    fs.writeFileSync(log, '');
    const interactive = run('bash', ['-c', `shopt -s expand_aliases\nsource ${JSON.stringify(path.join(home, '.bashrc'))}\nls ~`], {env: withColorls});
    check(interactive);
    assert.match(fs.readFileSync(log, 'utf8'), /^colorls -l /m);

    // Rerunning never appends twice or asks again about wired rc files.
    const rerun = run('bash', [setup], {input: 'n\nn\ny\n', env: withColorls});
    check(rerun);
    assert.match(rerun.stdout, /Unchanged: \S+\/colorls\.sh/);
    for (const rc of ['.bashrc', '.zshrc']) {
        const content = fs.readFileSync(path.join(home, rc), 'utf8');
        assert.equal(content.match(/\.config\/shell\/colorls\.sh/g).length, 2, rc + ' must not be appended twice');
    }

    // Without yay the AUR step explains what to do instead of failing.
    // /bin links to /usr/bin on Arch, so hide the real yay with a PATH of only the needed tools.
    fs.rmSync(path.join(bin, 'yay'));
    const bare = path.join(scratch, 'bare-bin');
    fs.mkdirSync(bare);
    for (const tool of ['dirname', 'date', 'cmp', 'grep']) fs.symlinkSync(`/usr/bin/${tool}`, path.join(bare, tool));
    const noYay = run('/usr/bin/bash', [setup, '--dry-run'], {input: 'y\n'.repeat(20), env: {...withColorls, PATH: `${bin}:${bare}`}});
    check(noYay);
    assert.match(noYay.stdout, /yay is not installed/);
    assert.doesNotMatch(noYay.stdout, /yay -S/);
} finally {
    fs.rmSync(scratch, {recursive: true, force: true});
}

check(run('bash', [setup, '--help']));
assert.equal(run('bash', [setup, '--invalid']).status, 2);
// The bundled zshrc must load the shared aliases after its own ls aliases.
const zshrc = read('zsh/zshrc');
assert.ok(zshrc.indexOf('.config/shell/colorls.sh') > zshrc.indexOf("alias la='ls -A'"),
    'zshrc must source colorls.sh after its default ls aliases');
for (const pkg of ['ruby', 'ruby-colorls']) assert.ok(read('README.md').includes('`' + pkg + '`'), 'Document ' + pkg);
console.log('colorls-smoke: all checks passed');
