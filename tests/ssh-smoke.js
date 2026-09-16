// SPDX-License-Identifier: GPL-3.0-only
// Preview tests never connect, read keys, or modify the user's configuration.
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const path = require('node:path');
const setup = path.resolve(__dirname, '../setup-ssh.sh');
const run = (args, answers) => spawnSync('bash', [setup, ...args], {
    encoding: 'utf8', input: answers.join('\n') + '\n', timeout: 10000,
});

// A missing Git mode, wrong default user, or unscoped rewrite fails this preview.
const gitAnswers = ['gitlab', 'gitlab.example.test', '', '2222', '/example/private-key', 'y'];
const git = run(['--git', '--dry-run'], gitAnswers);
assert.equal(git.status, 0, git.stderr);
assert.match(git.stdout, /git@gitlab\.example\.test on port 2222/);
assert.match(git.stdout, /https:\/\/gitlab\.example\.test\/ -> ssh:\/\/git@gitlab\.example\.test\//);
assert.match(git.stdout, /Preview only: no files, permissions or connections changed/);
assert.doesNotMatch(git.stdout, /load ~\/\.ssh\/aliases\.sh/);

const reverseFlags = run(['--dry-run', '--git'], gitAnswers);
assert.equal(reverseFlags.status, 0, reverseFlags.stderr);
assert.equal(reverseFlags.stdout, git.stdout);

// Changing SSH usernames must not silently retain an earlier conflicting URL user.
const conflict = spawnSync('bash', [setup, '--git', '--dry-run'], {
    encoding: 'utf8', input: gitAnswers.join('\n') + '\n', timeout: 10000,
    env: {...process.env, GIT_CONFIG_COUNT: '1',
        GIT_CONFIG_KEY_0: 'url.ssh://olduser@gitlab.example.test/.insteadOf',
        GIT_CONFIG_VALUE_0: 'https://gitlab.example.test/'},
});
assert.notEqual(conflict.status, 0, 'Conflicting existing username rewrite must be rejected');
assert.match(conflict.stderr, /conflicting Git URL rewrite/);
assert.doesNotMatch(conflict.stdout, /Would save/);

const declined = run(['--git', '--dry-run'], [...gitAnswers.slice(0, -1), '']);
assert.equal(declined.status, 0, declined.stderr);
assert.doesNotMatch(declined.stdout, /Would save| -> /);

for (const [index, value] of [[1, 'host.test/extra'], [1, 'host.test:2222'], [3, '65536'], [4, '/key%h']]) {
    const answers = [...gitAnswers];
    answers[index] = value;
    const invalid = run(['--git', '--dry-run'], answers);
    assert.notEqual(invalid.status, 0, `Unsafe input accepted: ${value}`);
    assert.doesNotMatch(invalid.stdout, /Would save/);
}

// Existing private server alias behavior must remain available.
const legacy = run(['--dry-run'], ['vps', '192.0.2.10', 'root', '2022', '/example/private-key', 'y']);
assert.equal(legacy.status, 0, legacy.stderr);
assert.match(legacy.stdout, /load ~\/\.ssh\/aliases\.sh/);
assert.doesNotMatch(legacy.stdout, / -> ssh:/);
// The main installer must propagate dry-run mode to the new opt-in step.
const main = spawnSync('bash', [path.resolve(__dirname, '../install.sh'), '--dry-run'], {
    encoding: 'utf8', timeout: 10000,
    input: [...Array(28).fill('n'), 'y', ...gitAnswers, ...Array(10).fill('n')].join('\n') + '\n',
});
assert.equal(main.status, 0, main.stderr);
assert.match(main.stdout, /Git URL rewrite: https:\/\/gitlab\.example\.test\/ -> ssh:\/\/git@gitlab\.example\.test\//);
assert.match(main.stdout, /Preview only: no files, permissions or connections changed/);
console.log('SSH setup previews passed: Git defaults, scoped rewrite, opt-in, validation and legacy mode.');
