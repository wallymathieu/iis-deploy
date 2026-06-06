import tl = require('azure-pipelines-task-lib/task');
import path = require('path');

async function run() {
    try {
        const webSiteName: string = tl.getInput('WebSiteName', true)!;
        const appName: string = tl.getInput('AppName', false) || '';
        const sourcePath: string = tl.getPathInput('SourcePath', true, true)!;
        const destinationPath: string = tl.getPathInput('DestinationPath', true, false)!;
        const numberToKeep: string = tl.getInput('NumberToKeep', false) || '4';

        const scriptPath = path.join(__dirname, 'scripts', 'deploy.ps1');

        const powershell = tl.tool(tl.which('powershell', true))
            .arg('-NonInteractive')
            .arg('-ExecutionPolicy')
            .arg('Bypass')
            .arg('-File')
            .arg(scriptPath)
            .arg('-sourceDir')
            .arg(sourcePath)
            .arg('-siteName')
            .arg(webSiteName)
            .arg('-releaseParentDir')
            .arg(destinationPath)
            .arg('-keep')
            .arg(numberToKeep);

        if (appName) {
            powershell.arg('-appName').arg(appName);
        }

        const exitCode = await powershell.exec();
        if (exitCode !== 0) {
            tl.setResult(tl.TaskResult.Failed, `deploy.ps1 exited with code ${exitCode}`);
        }
    }
    catch (err: any) {
        tl.setResult(tl.TaskResult.Failed, err.message);
    }
}

run();