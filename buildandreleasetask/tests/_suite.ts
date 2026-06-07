import assert = require('assert');
import fs = require('fs');
import path = require('path');

describe('IIS Versioned App Deployment task', function () {
    const taskRoot = path.join(__dirname, '..');

    it('task.json declares the expected metadata and inputs', function () {
        const taskJson = JSON.parse(fs.readFileSync(path.join(taskRoot, 'task.json'), 'utf8'));

        assert.ok(taskJson.id, 'task must have an id');
        assert.strictEqual(taskJson.name, 'IISVersionedAppDeployment');
        assert.ok(taskJson.execution && taskJson.execution.Node20_1, 'task must run on the Node20 handler');

        const inputNames: string[] = taskJson.inputs.map((i: { name: string }) => i.name);
        for (const expected of ['WebSiteName', 'AppName', 'SourcePath', 'DestinationPath', 'ReleasePrefix', 'NumberToKeep']) {
            assert.ok(inputNames.includes(expected), `task.json is missing input '${expected}'`);
        }
    });

    it('compiles to the entry point referenced by task.json', function () {
        assert.ok(fs.existsSync(path.join(taskRoot, 'index.js')), 'index.js should exist after build');
    });
});
