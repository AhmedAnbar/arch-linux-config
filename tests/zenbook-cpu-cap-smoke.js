// SPDX-License-Identifier: GPL-3.0-only
// Preview tests only: the fix is never written to /etc, and no initramfs is rebuilt.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const setup = path.resolve(__dirname, '../setup-zenbook-cpu-cap.sh');
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'anbar-zenbook-smoke-'));
const modelFile = (name) => {
    const file = path.join(scratch, `model-${Buffer.from(name).toString('hex')}`);
    fs.writeFileSync(file, `${name}\n`);
    return file;
};
const conf = path.join(scratch, 'zenbook-um5606-cpu-cap.conf');
const run = (args, answers, model = 'ASUS Zenbook S 16 UM5606WA_UM5606WA') => spawnSync('bash', [setup, ...args], {
    encoding: 'utf8', input: answers.join('\n') + '\n', timeout: 10000,
    env: {...process.env, ZENBOOK_CPU_CAP_DMI_FILE: modelFile(model), ZENBOOK_CPU_CAP_CONF: conf},
});

try {
    // The matching laptop gets the three blacklist lines and nothing else.
    const preview = run(['--dry-run'], ['y', 'y']);
    assert.equal(preview.status, 0, preview.stderr);
    for (const module of ['amd_pmf', 'amdxdna', 'asus_armoury']) {
        assert.match(preview.stdout, new RegExp(`^\\s+blacklist ${module}$`, 'm'));
    }
    assert.match(preview.stdout, /sudo install -Dm644/);
    assert.match(preview.stdout, /sudo mkinitcpio -P/);
    assert.match(preview.stdout, /Preview only: no files were written/);
    assert.equal(fs.existsSync(conf), false, 'A preview must never write the file');

    // Declining leaves the system untouched, including the initramfs.
    const declined = run(['--dry-run'], ['n']);
    assert.equal(declined.status, 0, declined.stderr);
    assert.doesNotMatch(declined.stdout, /sudo install|sudo mkinitcpio/);

    // Other hardware must not be blacklisted by accident, and must say why.
    const other = run(['--dry-run'], ['y', 'y'], 'ThinkPad X1 Carbon Gen 12');
    assert.notEqual(other.status, 0, 'Non-matching hardware must be refused');
    assert.match(other.stderr, /specific to the ASUS Zenbook S 16 \(UM5606\)/);
    assert.doesNotMatch(other.stdout, /blacklist amd_pmf/);

    // --force stays available for the same fault on a different model name.
    const forced = run(['--dry-run', '--force'], ['y', 'y'], 'ASUS Vivobook S 16 M5606WA');
    assert.equal(forced.status, 0, forced.stderr);
    assert.match(forced.stdout, /blacklist amd_pmf/);

    // Removal previews the delete and warns that the cap comes back.
    fs.writeFileSync(conf, 'blacklist amd_pmf\n');
    const removal = run(['--dry-run', '--remove'], ['y']);
    assert.equal(removal.status, 0, removal.stderr);
    assert.match(removal.stdout, /bring back the ~605 MHz CPU cap/);
    assert.match(removal.stdout, new RegExp(`sudo rm -f -- ${conf}`));
    assert.equal(fs.readFileSync(conf, 'utf8'), 'blacklist amd_pmf\n', 'A preview must not delete the file');
    fs.rmSync(conf);

    const absent = run(['--dry-run', '--remove'], ['y']);
    assert.equal(absent.status, 0, absent.stderr);
    assert.match(absent.stdout, /Not present/);

    // An unchanged file is reported, never rewritten.
    const expected = run(['--dry-run'], ['n']).stdout
        .split('\n').filter((line) => line.startsWith('    ')).map((line) => line.slice(4)).join('\n') + '\n';
    fs.writeFileSync(conf, expected);
    const unchanged = run(['--dry-run'], ['y', 'y']);
    assert.equal(unchanged.status, 0, unchanged.stderr);
    assert.match(unchanged.stdout, /Unchanged:/);
    assert.doesNotMatch(unchanged.stdout, /sudo install/);

    const badFlag = run(['--nope'], ['y']);
    assert.equal(badFlag.status, 2);
    assert.match(badFlag.stderr, /Unknown argument/);

    console.log('zenbook-cpu-cap-smoke: all checks passed');
} finally {
    fs.rmSync(scratch, {recursive: true, force: true});
}
