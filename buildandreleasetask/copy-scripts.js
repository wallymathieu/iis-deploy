// Copies the PowerShell deployment scripts into the task folder so they are
// bundled when the task is packaged. Cross-platform replacement for cp/mkdir.
const fs = require('fs');
const path = require('path');

const sourceDir = path.join(__dirname, '..', 'scripts');
const destDir = path.join(__dirname, 'scripts');
const files = ['deploy.ps1', 'IisDeploy.psm1'];

fs.mkdirSync(destDir, { recursive: true });
for (const file of files) {
    fs.copyFileSync(path.join(sourceDir, file), path.join(destDir, file));
    console.log(`Copied ${file} -> scripts/${file}`);
}
