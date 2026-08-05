import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }

  return fs.readFileSync(file, 'utf8');
}

function mustInclude(text, file, needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(text, file, needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const debugScriptPath = 'scripts/emulator-debug.sh';
const readmePath = 'README.md';
const qaPath = 'docs/qa/manual-test-script.md';
const deliveryPath = 'docs/delivery/first-release-verification.md';

const debugScript = read(debugScriptPath);
const readme = read(readmePath);
const qa = read(qaPath);
const delivery = read(deliveryPath);

for (const needle of [
  'assembleHap',
  'product=default',
  'module=entry@default',
  'HDC_TARGET',
  'DEVECO_COMMAND_LINE_TOOLS',
  'DEVECO_SDK_HOME',
  'SKIP_BUILD',
  'RESET_APP_ON_SIGN_MISMATCH',
  'install -r',
  'sign info inconsistent',
  'aa start',
  'snapshot_display'
]) {
  mustInclude(debugScript, debugScriptPath, needle);
}

const forbiddenSigningFields = [
  ['signing', 'Configs'].join(''),
  ['key', 'Password'].join(''),
  ['store', 'Password'].join(''),
  ['/', 'Users', '/'].join('')
];
for (const forbidden of forbiddenSigningFields) {
  mustNotInclude(debugScript, debugScriptPath, forbidden);
}

for (const [file, text] of [
  [readmePath, readme],
  [qaPath, qa],
  [deliveryPath, delivery]
]) {
  mustInclude(text, file, 'scripts/emulator-debug.sh');
  mustInclude(text, file, '模拟机调试环境');
}

console.log('PASS');
