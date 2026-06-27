'use strict';

/**
 * Launches a Node command (the server or the test runner) with NODE_PATH
 * pointed at the locally-installed dependencies. NODE_PATH is read by Node at
 * startup, so any child processes the test runner spawns inherit it too.
 *
 * Usage (via package.json scripts):
 *   node scripts/run.js src/server.js     # start the server
 *   node scripts/run.js --test            # run the test suite
 */
const { spawn } = require('child_process');
const path = require('path');
const { nodeModulesDir, isInstalled } = require('./deps');

if (!isInstalled()) {
  console.error(
    'Dependencies are not installed locally yet.\n' +
      'Run "npm run setup" first (this project cannot keep node_modules on Google Drive).'
  );
  process.exit(1);
}

const env = { ...process.env };
env.NODE_PATH = env.NODE_PATH
  ? `${nodeModulesDir}${path.delimiter}${env.NODE_PATH}`
  : nodeModulesDir;

const args = process.argv.slice(2);
const child = spawn(process.execPath, args, { stdio: 'inherit', env });
child.on('exit', (code) => process.exit(code ?? 0));
