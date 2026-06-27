'use strict';

/**
 * One-time setup: installs the backend's dependencies onto local disk
 * (outside Google Drive) so the server and tests can run. Re-run it whenever
 * dependencies in package.json change.
 *
 *   npm run setup
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { depsDir, readDependencies, nodeModulesDir } = require('./deps');

fs.mkdirSync(depsDir, { recursive: true });

// A minimal package.json in the local deps dir keeps npm happy.
const localPkgPath = path.join(depsDir, 'package.json');
if (!fs.existsSync(localPkgPath)) {
  fs.writeFileSync(
    localPkgPath,
    JSON.stringify({ name: 'swe3090xa-backend-deps', private: true }, null, 2)
  );
}

const deps = readDependencies();
const specs = Object.entries(deps).map(([name, version]) => `${name}@${version}`);

console.log(`Installing backend dependencies to ${nodeModulesDir} ...`);
console.log(`  ${specs.join(', ')}`);

const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const result = spawnSync(
  npmCmd,
  ['install', '--no-audit', '--no-fund', ...specs],
  { cwd: depsDir, stdio: 'inherit' }
);

if (result.status !== 0) {
  console.error('\nDependency installation failed.');
  process.exit(result.status || 1);
}
console.log('\nDone. You can now run "npm start" or "npm test".');
