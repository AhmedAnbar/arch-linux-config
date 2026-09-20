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

    // The workspace tab row: the sidebar keys and the status command entry.
    const statusScript = path.join(root, 'config/herdr/workspaces-status.sh');
    const applyUi = (file) => spawnSync('bash', [
        path.join(root, 'scripts/configure-herdr-ui.sh'), file, herdr, statusScript,
    ], {encoding: 'utf8', timeout: 10000});
    for (const source of [
        'onboarding = false\n[theme]\nname = "catppuccin"\n',
        // A [ui] table that already carries unrelated keys must keep them.
        '[ui]\naccent = "mauve"\nconfirm_close = true\n[theme]\nname = "catppuccin"\n',
        // Only [ui.toast] exists: the parent table may still be appended.
        '[ui.toast]\ndelivery = "system"\n',
        // Stale values of the managed keys are replaced, not duplicated.
        '[ui]\nsidebar_collapsed_mode = "compact"\nsidebar_start_collapsed = false\n',
        // An existing [keys] table keeps its prefix and gains the navigation keys.
        '[keys]\nprefix = "ctrl+a"\n\n[theme]\nname = "catppuccin"\n',
        null,
    ]) {
        const file = fixture(source);
        const result = applyUi(file);
        assert.equal(result.status, 0, result.stderr + result.stdout);
        const updated = fs.readFileSync(file, 'utf8');
        assert.match(updated, /^sidebar_start_collapsed = true$/m);
        assert.match(updated, /^sidebar_collapsed_mode = "hidden"$/m);
        assert.match(updated, /^tab_bar_right = \[\{ type = "command", command = "\S+workspaces-status\.sh"/m);
        assert.equal(updated.match(/^\[ui\]$/gm).length, 1, 'One [ui] table only');
        assert.equal(updated.match(/^sidebar_collapsed_mode/gm).length, 1, 'No duplicated keys');
        if (source && source.includes('accent')) {
            assert.match(updated, /accent = "mauve"/);
            assert.match(updated, /confirm_close = true/);
        }
        if (source && source.includes('catppuccin')) assert.match(updated, /name = "catppuccin"/);
        if (source && source.includes('delivery')) assert.match(updated, /delivery = "system"/);
        // prefix+1..9 belongs to tabs, so workspaces must not steal it.
        assert.match(updated, /^switch_workspace = "prefix\+shift\+1\.\.9"$/m);
        assert.match(updated, /^next_workspace = "prefix\+alt\+n"$/m);
        assert.match(updated, /^previous_workspace = "prefix\+alt\+p"$/m);
        assert.equal(updated.match(/^\[keys\]$/gm).length, 1, 'One [keys] table only');
        assert.equal(updated.match(/^next_workspace/gm).length, 1, 'No duplicated keys');
        assert.doesNotMatch(updated, /^switch_workspace = "prefix\+1/m);
        if (source && source.includes('prefix = "ctrl+a"')) assert.match(updated, /prefix = "ctrl\+a"/);
        const beforeSecondRun = fs.readdirSync(scratch).sort();
        assert.equal(applyUi(file).status, 0);
        assert.equal(fs.readFileSync(file, 'utf8'), updated, 'A second run must change nothing');
        assert.deepEqual(fs.readdirSync(scratch).sort(), beforeSecondRun, 'Unchanged files need no new backup');
    }
    // A multi-line array of a managed key is left for the user instead of being mangled.
    const multiline = '[ui]\ntab_bar_right = [\n  { type = "zoom" },\n]\n';
    const spilled = fixture(multiline);
    const refused = applyUi(spilled);
    assert.notEqual(refused.status, 0);
    assert.match(refused.stderr, /multi-line/i);
    assert.equal(fs.readFileSync(spilled, 'utf8'), multiline);
    const uiOriginal = fixture('[theme]\nname = "catppuccin"\n');
    const uiLink = path.join(scratch, 'ui-symlink.toml');
    fs.symlinkSync(uiOriginal, uiLink);
    assert.notEqual(applyUi(uiLink).status, 0);
    assert.equal(fs.readFileSync(uiOriginal, 'utf8'), '[theme]\nname = "catppuccin"\n');

    // The prefix step and the workspace-tab step must not undo each other.
    const both = fixture('onboarding = false\n');
    assert.equal(applyUi(both).status, 0);
    assert.equal(apply(both).status, 0);
    const combined = fs.readFileSync(both, 'utf8');
    for (const expected of [/prefix = "ctrl\+a"/, /next_workspace = "prefix\+alt\+p"|previous_workspace = "prefix\+alt\+p"/,
        /sidebar_collapsed_mode = "hidden"/, /tab_bar_right = \[\{ type = "command"/]) {
        assert.match(combined, expected);
    }
    // The prefix step appends its key after ours, so one more pass reorders them once.
    assert.equal(applyUi(both).status, 0);
    const settled = fs.readFileSync(both, 'utf8');
    assert.match(settled, /prefix = "ctrl\+a"\nswitch_workspace/);
    for (const step of [applyUi, apply, applyUi, apply]) {
        assert.equal(step(both).status, 0);
        assert.equal(fs.readFileSync(both, 'utf8'), settled, 'Both steps must leave a settled config alone');
    }

    // The status line itself: one plain line, tmux-style, with the focused workspace starred.
    const sample = JSON.stringify({result: {workspaces: [
        {number: 1, label: 'Projects', focused: true},
        {number: 2, label: 'nuvora', focused: false},
    ]}});
    const stub = path.join(scratch, 'stub');
    fs.mkdirSync(stub);
    fs.writeFileSync(path.join(stub, 'herdr'), `#!/bin/sh\ncat <<'JSON'\n${sample}\nJSON\n`, {mode: 0o755});
    const status = spawnSync('sh', [statusScript], {
        encoding: 'utf8', timeout: 10000, env: {...process.env, PATH: `${stub}:${process.env.PATH}`},
    });
    assert.equal(status.status, 0, status.stderr);
    assert.equal(status.stdout, '1:Projects*  2:nuvora', 'Herdr keeps only the last line');

    console.log('Herdr smoke tests passed: prefix and workspace-tab edits, preservation, idempotence, validation and symlink safety.');
} finally {
    // Only remove the private fixture directory created by this test.
    fs.rmSync(scratch, {recursive: true, force: true});
}
