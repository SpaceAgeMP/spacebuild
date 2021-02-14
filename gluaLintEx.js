const { readFileSync } = require('fs');
const { normalize } = require('path');
const { spawnSync } = require('child_process');
const https = require('https');
const { GITHUB_SHA, GITHUB_EVENT_PATH, GITHUB_TOKEN } = process.env;

const warningsAreErrors = true;

let repo = 'NA';
let owner = 'NA';

if (GITHUB_EVENT_PATH) {
    const githubEvent = require(GITHUB_EVENT_PATH);
    const { repository } = githubEvent;
    owner = repository.owner.login;
    repo = repository.name;
}

async function request(url, options) {
    return new Promise((resolve, reject) => {
        const req = https.request(url, options, res => {
                let data = '';
                res.on('data', chunk => {
                    data += chunk;
                });
                res.on('end', () => {
                    if (res.statusCode >= 400) {
                        const err = new Error(`Received status code ${res.statusCode}`);
                        err.response = res;
                        err.data = data;
                        reject(err);
                    } else {
                        resolve({ res, data: JSON.parse(data) });
                    }
                });
            })
            .on('error', reject);
        if (options.body) {
            req.end(JSON.stringify(options.body));
        } else {
            req.end();
        }
    });
}

const headers = {
    'Content-Type': 'application/json',
    Accept: 'application/vnd.github.antiope-preview+json',
    Authorization: `Bearer ${GITHUB_TOKEN}`,
    'User-Agent': 'glualint-action',
};

async function defineCheck(requestBody, checkId) {
    if (!process.env.CI) {
        return;
    }

    if (checkId && checkId.then) {
        checkId = await checkId;
    }

    const body = {
        ...requestBody,
        name: 'GLuaLint',
        head_sha: GITHUB_SHA,
    };
    const { data } = await request(`https://api.github.com/repos/${owner}/${repo}/check-runs${checkId ? `/${checkId}` : ''}`, {
        method: checkId ? 'PATCH' : 'POST',
        headers,
        body
    });
    const { id } = data;
    return id;
}

const checkId = defineCheck({
    status: 'in_progress',
    started_at: new Date(),
}).catch(e => console.error(e));

let errorCount = 0, warningCount = 0;
const annotations = [];

function endCheck() {
    defineCheck({
        status: 'completed',
        completed_at: new Date(),
        conclusion: (errorCount > 0) ? 'failure' : 'success',
        output: {
            title: 'GLuaLint',
            summary: `${errorCount} error(s), ${warningCount} warning(s)`,
            annotations,
        },
    }, checkId).catch(e => console.error(e));
}

const res = spawnSync('glualint', ['.']);
if (res.status === null) {
    errorCount++;
    console.error('Interrupted');
    endCheck().then(() => process.exit(1));
    return;
}
if (res.status === 0) {
    endCheck().then(() => process.exit(0));
    return;
}

if (res.status !== 1) {
    errorCount++;
    endCheck().then(() => process.exit(res.status));
    return;
}

const errRegExp = /^(.+): \[(Warning|Error)\] line (\d+), column (\d+) - line (\d+), column (\d+): (.+)$/;
const output = res.stdout.toString().split(/\r?\n/).filter(l => !!l).map(l => l.match(errRegExp)).map(m => ({
    file: normalize(m[1]),
    type: m[2].toLowerCase(),
    lineStart: parseInt(m[3], 10),
    columnStart: parseInt(m[4], 10),
    lineEnd: parseInt(m[5], 10),
    columnEnd: parseInt(m[6], 10),
    message: m[7],
}));

const fileCache = {};
for (const o of output) {
    fileCache[o.file] = readFileSync(o.file, 'utf8').split(/\r?\n/);
}

const reportErrors = output.filter(o => {
    const file = fileCache[o.file]
    if (file[0].includes('--glualint:ignore-file')) {
        return false;
    }
    if (file[o.lineStart - 2].includes('--glualint:ignore-next-line')) {
        return false;
    }
    return true;
});

for (const r of reportErrors) {
    switch (r.type) {
        case 'warning':
            if (warningsAreErrors) {
                errorCount++;
                r.type = 'error';
                break;
            }
            warningCount++;
            break;
        case 'error':
            errorCount++;
            break;
    }
    if (process.env.CI) {
        console.log(`::${r.type} file=${r.file},line=${r.lineStart},col=${r.columnStart}::${r.message}`);
        annotations.push({
            path: r.file,
            start_line: r.lineStart,
            end_line: r.lineEnd,
            annotation_level: (r.type == 'warning') ? 'warning' : 'failure',
            message: r.message,
        });
    }
    console.log(`${r.type} ${r.file}:${r.lineStart}:${r.columnStart}-${r.lineEnd}:${r.columnEnd} ${r.message}`);
}

endCheck();
