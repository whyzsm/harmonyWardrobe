import fs from 'node:fs';
import path from 'node:path';

const etsRoot = 'entry/src/main/ets';
const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
const cameraNavPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';

const exemptions = {
  [cameraNavPath]: {
    colors: new Set(['#4578FF', '#56D0FF']),
    namedColors: new Set(),
    shadowLiterals: new Set(),
    reason: '相机入口保留蓝到青蓝渐变。'
  },
  'entry/src/main/ets/pages/ProfilePage.ets': {
    colors: new Set(),
    namedColors: new Set(['Color.Transparent']),
    shadowLiterals: new Set(),
    reason: 'Profile 允许透明系统色；业务颜色和阴影必须走 token。'
  },
  'entry/src/main/ets/pages/CaptureEditPage.ets': {
    colors: new Set(),
    namedColors: new Set(['Color.Transparent']),
    shadowLiterals: new Set(),
    reason: 'CaptureEditPage 不在本批次责任范围内。'
  },
  'entry/src/main/ets/pages/WardrobePage.ets': {
    colors: new Set(),
    namedColors: new Set(['Color.Transparent']),
    shadowLiterals: new Set(),
    reason: 'WardrobePage 不在本批次责任范围内。'
  }
};

function read(file) {
  return fs.readFileSync(file, 'utf8');
}

function collectEtsFiles(directory) {
  const files = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const filePath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectEtsFiles(filePath));
    } else if (entry.name.endsWith('.ets')) {
      files.push(filePath);
    }
  }
  return files;
}

function stripComments(source) {
  return source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '');
}

function findMatches(source, pattern) {
  return [...source.matchAll(pattern)].map((match) => match[0]);
}

function assertExactToken(tokens, tokenName, value) {
  const declaration = new RegExp(`${tokenName}\\s*:\\s*['"]${value}['"]`);
  if (!declaration.test(tokens)) {
    throw new Error(`Tokens.ets must preserve ${tokenName}=${value}`);
  }
}

const tokens = read(tokenPath);
for (const [tokenName, value] of [
  ['bottomNavigationSurface', '#E62D2C2C'],
  ['searchHeaderSurface', '#F2FBF9F9']
]) {
  assertExactToken(tokens, tokenName, value);
}

const files = collectEtsFiles(etsRoot).filter((file) => file !== tokenPath);
const violations = [];
for (const file of files) {
  const source = stripComments(read(file));
  const exemption = exemptions[file] ?? {
    colors: new Set(),
    namedColors: new Set(),
    shadowLiterals: new Set(),
    reason: ''
  };
  for (const color of findMatches(source, /#[0-9A-Fa-f]{3,8}\b/g)) {
    if (!exemption.colors.has(color)) {
      violations.push(`${file}: un-tokenized color ${color}`);
    }
  }
  for (const namedColor of findMatches(source, /\bColor\.(?:Transparent|Black|White|Red|Blue|Gray)\b/g)) {
    if (!exemption.namedColors.has(namedColor)) {
      violations.push(`${file}: un-tokenized color ${namedColor}`);
    }
  }
  for (const shadowLiteral of findMatches(source, /\.shadow\s*\(\s*\{[^}]*\}\s*\)/g)) {
    if (!exemption.shadowLiterals.has(shadowLiteral)) {
      violations.push(`${file}: un-tokenized shadow ${shadowLiteral}`);
    }
  }
}

if (!tokens.includes("bottomNavigationSurface: '#E62D2C2C'")) {
  throw new Error('Tokens.ets is missing the exact bottom navigation surface token');
}
if (!tokens.includes("searchHeaderSurface: '#F2FBF9F9'")) {
  throw new Error('Tokens.ets is missing the exact search header surface token');
}
if (!tokens.includes('cameraGlow: { radius: 18, color:')) {
  throw new Error('Tokens.ets is missing the camera glow shadow token');
}
if (!tokens.includes('appTopBar: { radius: 12, color:')) {
  throw new Error('Tokens.ets is missing the app top bar shadow token');
}
if (!tokens.includes('bottomNavigation: { radius: 16, color:')) {
  throw new Error('Tokens.ets is missing the bottom navigation shadow token');
}
if (!tokens.includes('editorSheet: { radius: 24, color:')) {
  throw new Error('Tokens.ets is missing the editor sheet shadow token');
}
if (!tokens.includes('badge: { radius: 8, color:')) {
  throw new Error('Tokens.ets is missing the badge shadow token');
}
if (!tokens.includes('sheetHandle: { radius: 28, color:')) {
  throw new Error('Tokens.ets is missing the sheet handle shadow token');
}
for (const shadowDeclaration of [
  "appTopBar: { radius: 12, color: '#18000000', offsetX: 0, offsetY: 4 }",
  "bottomNavigation: { radius: 16, color: '#32000000', offsetX: 0, offsetY: 6 }",
  "cameraGlow: { radius: 18, color: '#26000000', offsetX: 0, offsetY: 0 }",
  "editorSheet: { radius: 24, color: '#12000000', offsetX: 0, offsetY: -6 }",
  "badge: { radius: 8, color: '#16000000', offsetX: 0, offsetY: 3 }",
  "sheetHandle: { radius: 28, color: '#29000000', offsetX: 0, offsetY: -8 }"
]) {
  if (!tokens.includes(shadowDeclaration)) {
    throw new Error(`Tokens.ets must preserve exact shadow declaration: ${shadowDeclaration}`);
  }
}

const navigation = read(cameraNavPath);
if (!navigation.includes("colors: [['#4578FF', 0], ['#56D0FF', 1]]")) {
  throw new Error('BottomNavigationBar must keep the explicit camera blue exception');
}
if (!tokens.includes('micro: 4')) {
  throw new Error('Tokens.ets must preserve the exact 4px skeleton radius token');
}

if (violations.length > 0) {
  throw new Error(violations.join('\n'));
}

for (const [file, exemption] of Object.entries(exemptions)) {
  if (exemption.colors.size > 0 || exemption.namedColors.size > 0 || exemption.shadowLiterals.size > 0) {
    console.log(`EXEMPT ${file}: ${exemption.reason}`);
  }
}
console.log('PASS');
