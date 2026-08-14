'use strict';

/**
 * Shared helper for the local-dependency workflow.
 *
 * Why this exists: this project lives on a Google Drive virtual filesystem,
 * which cannot host node_modules (npm's many small-file writes fail with
 * EBADF/EPERM, and junctions are rejected). So dependencies are installed on
 * local disk instead, and Node is pointed at them via NODE_PATH. The source
 * stays in Drive for git; node_modules never does (it is gitignored anyway).
 */
const os = require('os');
const path = require('path');
const fs = require('fs');

/** Local-disk directory that holds this project's node_modules. */
const depsDir = path.join(os.homedir(), '.swe3090xa', 'backend');
const nodeModulesDir = path.join(depsDir, 'node_modules');

/** Read the dependency map from the project's own package.json. */
function readDependencies() {
  const pkg = JSON.parse(
    fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8')
  );
  return pkg.dependencies || {};
}

/** True once the deps have been installed to the local-disk directory. */
function isInstalled() {
  return fs.existsSync(path.join(nodeModulesDir, 'express'));
}

/**
 * True when an ordinary `npm install` has already put the dependencies inside
 * the project. Off Google Drive — a fresh clone, or the submitted copy on a
 * marker's machine — that is the normal way to install, and it should just
 * work without the Drive workaround.
 */
function isInstalledInProject() {
  return fs.existsSync(
    path.join(__dirname, '..', 'node_modules', 'express', 'package.json')
  );
}

module.exports = {
  depsDir,
  nodeModulesDir,
  readDependencies,
  isInstalled,
  isInstalledInProject,
};
