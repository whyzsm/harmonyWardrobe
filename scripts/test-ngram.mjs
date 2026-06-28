import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const sourcePath = 'entry/src/main/ets/utils/ngram.ets';

if (!fs.existsSync(sourcePath)) {
  console.error(`${sourcePath} does not exist`);
  process.exit(1);
}

const source = fs.readFileSync(sourcePath, 'utf8');
if (!source.includes('buildSearchNgrams')) {
  console.error('Missing buildSearchNgrams');
  process.exit(1);
}
if (!source.includes('minGram') || !source.includes('maxGram')) {
  console.error('Tokenizer must support configurable gram sizes');
  process.exit(1);
}

const runnableSource = source
  .replace(/\bexport\s+/g, '')
  .replace(/new Set<string>\(/g, 'new Set(')
  .replace(/: string\[\]/g, '')
  .replace(/: string/g, '')
  .replace(/: number/g, '')
  .replace(/\bconst\s+(\w+):\s*string\[\]\s*=/g, 'const $1 =')
  .replace(/\bconst\s+(\w+):\s*Set<string>\s*=/g, 'const $1 =');

const context = {};
vm.createContext(context);
vm.runInContext(`${runnableSource}\nthis.buildSearchNgrams = buildSearchNgrams;`, context);

const { buildSearchNgrams } = context;
const ngrams = (...args) => Array.from(buildSearchNgrams(...args));

assert.deepEqual(ngrams('  外套  CoAt  2026  '), [
  '外',
  '套',
  'c',
  'o',
  'a',
  't',
  '2',
  '0',
  '6',
  '外套',
  'co',
  'oa',
  'at',
  '20',
  '02',
  '26',
  'coa',
  'oat',
  '202',
  '026'
]);

assert.deepEqual(ngrams('ＡＢ１２ 雨衣!!', 2, 3), ['ab', 'b1', '12', '雨衣', 'ab1', 'b12']);
assert.deepEqual(ngrams('aa aa', 1, 2), ['a', 'aa']);
assert.deepEqual(ngrams('a b', 3, 1), []);

console.log('PASS');
