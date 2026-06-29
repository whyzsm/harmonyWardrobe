import fs from 'node:fs';

const schema = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchIndexSchema.ets', 'utf8');
for (const needle of ['CREATE VIRTUAL TABLE', 'USING fts5', 'search_index_fts', 'ngrams']) {
  if (!schema.includes(needle)) throw new Error(`Search schema missing ${needle}`);
}

const capability = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchCapability.ets', 'utf8');
for (const needle of ['detectSearchCapability', 'fts5', 'fallback']) {
  if (!capability.includes(needle)) throw new Error(`Search capability missing ${needle}`);
}
