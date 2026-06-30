import fs from 'node:fs';

const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
const tokenSource = fs.readFileSync(tokenPath, 'utf8');

function fail(message) {
  console.error(message);
  process.exit(1);
}

function requireIncludes(source, value, label) {
  if (!source.includes(value)) {
    fail(`${label} missing: ${value}`);
  }
}

function forbidIncludes(source, value, label) {
  if (source.includes(value)) {
    fail(`${label} still contains forbidden value: ${value}`);
  }
}

requireIncludes(tokenSource, "primary: '#4894FE'", 'primary token');
requireIncludes(tokenSource, "primaryPressed: '#246BFE'", 'primary pressed token');
requireIncludes(tokenSource, "primarySoft: '#EAF3FF'", 'primary soft token');
requireIncludes(tokenSource, "surfaceMuted: '#F6F8FC'", 'app background token');
requireIncludes(tokenSource, "success: '#22C55E'", 'success token');
requireIncludes(tokenSource, "warning: '#FFB020'", 'warning token');
requireIncludes(tokenSource, "danger: '#EF4444'", 'danger token');
requireIncludes(tokenSource, "accent: '#FF7A90'", 'fashion accent token');
forbidIncludes(tokenSource, "'#0F766E'", 'old teal primary');
forbidIncludes(tokenSource, "'#115E59'", 'old teal primaryStrong');
