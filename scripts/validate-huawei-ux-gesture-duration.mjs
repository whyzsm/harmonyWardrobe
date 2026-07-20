import fs from 'node:fs';
import path from 'node:path';

const ETS_ROOT = 'entry/src/main/ets';
const LONG_PRESS_MIN_MS = 400;
const LONG_PRESS_DEFAULT_MS = 500;
const LONG_PRESS_MAX_MS = 650;

function listEtsFiles(dir) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listEtsFiles(fullPath));
    } else if (entry.isFile() && fullPath.endsWith('.ets')) {
      files.push(fullPath);
    }
  }
  return files;
}

function findCalls(source, name) {
  const calls = [];
  let offset = 0;
  const needle = `${name}(`;

  while (offset < source.length) {
    const start = source.indexOf(needle, offset);
    if (start === -1) {
      break;
    }

    let depth = 0;
    let end = -1;
    for (let index = start + name.length; index < source.length; index += 1) {
      const char = source[index];
      if (char === '(') {
        depth += 1;
      } else if (char === ')') {
        depth -= 1;
        if (depth === 0) {
          end = index + 1;
          break;
        }
      }
    }

    if (end === -1) {
      throw new Error(`Unclosed ${name} call near offset ${start}`);
    }

    calls.push(source.slice(start, end));
    offset = end;
  }

  return calls;
}

for (const file of listEtsFiles(ETS_ROOT)) {
  const source = fs.readFileSync(file, 'utf8');

  for (const call of findCalls(source, 'LongPressGesture')) {
    const durationMatch = /duration:\s*(\d+)/.exec(call);
    const duration = durationMatch === null ? LONG_PRESS_DEFAULT_MS : Number.parseInt(durationMatch[1], 10);
    if (duration < LONG_PRESS_MIN_MS || duration > LONG_PRESS_MAX_MS) {
      throw new Error(`${file} LongPressGesture duration must be ${LONG_PRESS_MIN_MS}-${LONG_PRESS_MAX_MS}ms, found ${duration}ms`);
    }
  }

  for (const call of findCalls(source, 'TapGesture')) {
    if (/count:\s*2/.test(call) && /duration:\s*\d+/.test(call)) {
      throw new Error(`${file} must not configure double-tap interval directly; ArkUI TapGesture does not expose a compliant interval setting`);
    }
  }
}

console.log('PASS');
