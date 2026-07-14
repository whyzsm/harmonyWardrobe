import assert from 'node:assert/strict';
import fs from 'node:fs';

const repositories = [
  {
    file: 'entry/src/main/ets/data/repositories/ClothingRepository.ets',
    className: 'ClothingRepository',
    createOrUpdateMethods: ['createClothing', 'updateClothing'],
    deleteMethod: 'deleteClothing',
    entityType: 'Clothing',
    searchBuilder: 'buildClothingSearchDocument',
    photoTable: 'clothing_photos',
    photoOwnerColumn: 'clothing_id'
  },
  {
    file: 'entry/src/main/ets/data/repositories/OutfitRepository.ets',
    className: 'OutfitRepository',
    createOrUpdateMethods: ['createOutfit', 'updateOutfit'],
    deleteMethod: 'deleteOutfit',
    entityType: 'Outfit',
    searchBuilder: 'buildOutfitSearchDocument',
    photoTable: 'outfit_photos',
    photoOwnerColumn: 'outfit_id'
  },
  {
    file: 'entry/src/main/ets/data/repositories/WearLogRepository.ets',
    className: 'WearLogRepository',
    createOrUpdateMethods: ['createWearLog', 'updateWearLog'],
    deleteMethod: 'deleteWearLog',
    entityType: 'WearLog',
    searchBuilder: 'buildWearLogSearchDocument',
    photoTable: 'wear_log_photos',
    photoOwnerColumn: 'wear_log_id'
  },
  {
    file: 'entry/src/main/ets/data/repositories/WishlistRepository.ets',
    className: 'WishlistRepository',
    createOrUpdateMethods: ['createWishlistItem', 'updateWishlistItem'],
    deleteMethod: 'deleteWishlistItem',
    entityType: 'Wishlist',
    searchBuilder: 'buildWishlistSearchDocument',
    photoTable: 'wishlist_photos',
    photoOwnerColumn: 'wishlist_id'
  }
];

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function assertMatches(source, pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(message);
  }
}

function assertNoUnsafeTypes(path, source) {
  const unsafeType = source.match(/(?:^|[\s<(:,=|&])(?:unknown|any)(?=\b|[>\s,;)|&])/m);
  if (unsafeType) {
    throw new Error(`${path} must not use unsafe type ${unsafeType[0].trim()}`);
  }
}

function findMatchingBrace(source, openBraceIndex) {
  let depth = 0;
  let quote = '';
  let isLineComment = false;
  let isBlockComment = false;
  let isEscaped = false;

  for (let index = openBraceIndex; index < source.length; index += 1) {
    const char = source[index];
    const nextChar = source[index + 1] ?? '';

    if (isLineComment) {
      if (char === '\n') {
        isLineComment = false;
      }
      continue;
    }

    if (isBlockComment) {
      if (char === '*' && nextChar === '/') {
        isBlockComment = false;
        index += 1;
      }
      continue;
    }

    if (quote.length > 0) {
      if (isEscaped) {
        isEscaped = false;
        continue;
      }
      if (char === '\\') {
        isEscaped = true;
        continue;
      }
      if (char === quote) {
        quote = '';
      }
      continue;
    }

    if (char === '/' && nextChar === '/') {
      isLineComment = true;
      index += 1;
      continue;
    }

    if (char === '/' && nextChar === '*') {
      isBlockComment = true;
      index += 1;
      continue;
    }

    if (char === '"' || char === "'" || char === '`') {
      quote = char;
      continue;
    }

    if (char === '{') {
      depth += 1;
      continue;
    }

    if (char === '}') {
      depth -= 1;
      if (depth === 0) {
        return index;
      }
    }
  }

  throw new Error('Could not find matching brace.');
}

function extractBlockFromOpenBrace(source, openBraceIndex) {
  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

function extractMethodBody(source, methodName, file) {
  const methodMatch = new RegExp(`^\\s*(?:private\\s+|public\\s+|protected\\s+)?(?:async\\s+)?${methodName}\\s*\\(`, 'm').exec(source);
  if (methodMatch === null) {
    throw new Error(`${file} missing method ${methodName}`);
  }

  const openBraceIndex = source.indexOf('{', methodMatch.index);
  if (openBraceIndex < 0) {
    throw new Error(`${file} ${methodName} missing method body`);
  }

  return extractBlockFromOpenBrace(source, openBraceIndex);
}

function extractTransactionBody(methodBody, file, methodName) {
  const transactionIndex = methodBody.indexOf('this.database.transaction');
  if (transactionIndex < 0) {
    throw new Error(`${file} ${methodName} must call this.database.transaction`);
  }

  const transactionPrefix = stripCommentsAndStrings(methodBody.slice(0, transactionIndex)).trimEnd();
  if (!/(?:return|await)\s*$/.test(transactionPrefix)) {
    throw new Error(`${file} ${methodName} must await or return this.database.transaction`);
  }

  const openBraceIndex = methodBody.indexOf('{', transactionIndex);
  if (openBraceIndex < 0) {
    throw new Error(`${file} ${methodName} transaction call must use a callback body`);
  }

  return extractBlockFromOpenBrace(methodBody, openBraceIndex);
}

function stripCommentsAndStrings(source) {
  let output = '';
  let quote = '';
  let isLineComment = false;
  let isBlockComment = false;
  let isEscaped = false;

  for (let index = 0; index < source.length; index += 1) {
    const char = source[index];
    const nextChar = source[index + 1] ?? '';

    if (isLineComment) {
      output += char === '\n' ? '\n' : ' ';
      if (char === '\n') {
        isLineComment = false;
      }
      continue;
    }

    if (isBlockComment) {
      output += char === '\n' ? '\n' : ' ';
      if (char === '*' && nextChar === '/') {
        output += ' ';
        isBlockComment = false;
        index += 1;
      }
      continue;
    }

    if (quote.length > 0) {
      output += char === '\n' ? '\n' : ' ';
      if (isEscaped) {
        isEscaped = false;
        continue;
      }
      if (char === '\\') {
        isEscaped = true;
        continue;
      }
      if (char === quote) {
        quote = '';
      }
      continue;
    }

    if (char === '/' && nextChar === '/') {
      output += '  ';
      isLineComment = true;
      index += 1;
      continue;
    }

    if (char === '/' && nextChar === '*') {
      output += '  ';
      isBlockComment = true;
      index += 1;
      continue;
    }

    if (char === '"' || char === "'" || char === '`') {
      output += ' ';
      quote = char;
      continue;
    }

    output += char;
  }

  return output;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function hasAwaitedOrReturnedCall(source, callName) {
  const callPattern = new RegExp(
    `(?:^|[;{}\\n])\\s*(?:await|return)\\s+(?:this\\.)?(?:[A-Za-z_$][\\w$]*\\.)*${escapeRegExp(callName)}\\s*\\(`
  );
  return callPattern.test(source);
}

for (const repository of repositories) {
  const source = readRequired(repository.file);

  assertNoUnsafeTypes(repository.file, source);
  assertMatches(source, new RegExp(`export\\s+class\\s+${repository.className}\\b`), `${repository.file} must export ${repository.className}`);
  assertMatches(source, /constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*,\s*photoStorage\?:\s*PhotoStorage\s*\)/, `${repository.file} must accept shared database, search index mode, and optional photo storage`);
  assertMatches(source, /new\s+SearchRepository\s*\(\s*database\s*,\s*searchIndexMode\s*\)/, `${repository.file} must construct SearchRepository from the same MigrationDatabase`);
  assertMatches(source, /new\s+DeleteCleanupService\s*\([\s\S]*photoStorage\s*\)/, `${repository.file} must pass PhotoStorage to DeleteCleanupService`);

  for (const method of repository.createOrUpdateMethods) {
    const methodBody = extractMethodBody(source, method, repository.file);
    const transactionBody = extractTransactionBody(methodBody, repository.file, method);
    const transactionCode = stripCommentsAndStrings(transactionBody);
    const delegatesToUpsertHelper = hasAwaitedOrReturnedCall(transactionCode, 'upsertSearchDocument');
    const directlyUpsertsSearchDocument = hasAwaitedOrReturnedCall(transactionCode, 'upsertDocumentInTransaction');

    if (!directlyUpsertsSearchDocument && !delegatesToUpsertHelper) {
      throw new Error(`${repository.file} ${method} must upsert search documents inside the transaction`);
    }

    if (!transactionCode.includes(repository.searchBuilder) && !delegatesToUpsertHelper) {
      throw new Error(`${repository.file} ${method} must build or delegate the ${repository.searchBuilder} document inside the transaction`);
    }
  }

  if (stripCommentsAndStrings(source).includes('upsertSearchDocument')) {
    const upsertHelperBody = extractMethodBody(source, 'upsertSearchDocument', repository.file);
    const upsertHelperCode = stripCommentsAndStrings(upsertHelperBody);
    if (!hasAwaitedOrReturnedCall(upsertHelperCode, 'upsertDocumentInTransaction')) {
      throw new Error(`${repository.file} upsertSearchDocument helper must upsert inside the caller transaction`);
    }
    if (!upsertHelperCode.includes(repository.searchBuilder)) {
      throw new Error(`${repository.file} upsertSearchDocument helper must build ${repository.searchBuilder}`);
    }
  }

  const deleteMethodBody = extractMethodBody(source, repository.deleteMethod, repository.file);
  const deleteTransactionBody = extractTransactionBody(deleteMethodBody, repository.file, repository.deleteMethod);
  const deleteTransactionCode = stripCommentsAndStrings(deleteTransactionBody);
  if (!hasAwaitedOrReturnedCall(deleteTransactionCode, 'deleteDocumentInTransaction')) {
    throw new Error(`${repository.file} ${repository.deleteMethod} must delete search documents inside the transaction`);
  }
  if (!deleteTransactionCode.includes(`SearchEntityType.${repository.entityType}`)) {
    throw new Error(`${repository.file} ${repository.deleteMethod} must delete the ${repository.entityType} search document`);
  }

  assertMatches(source, new RegExp(`INSERT\\s+INTO\\s+${repository.photoTable}`, 'i'), `${repository.file} must insert photo URI rows`);
  assertMatches(source, new RegExp(`DELETE\\s+FROM\\s+${repository.photoTable}\\s+WHERE\\s+${repository.photoOwnerColumn}\\s*=\\s*\\?`, 'i'), `${repository.file} must replace photo rows by owner id`);
  assertMatches(source, /local_uri/i, `${repository.file} must persist local photo URIs`);
  assertMatches(source, /ORDER\s+BY\s+sort_order/i, `${repository.file} must read photo rows by sort order`);

  assert.equal(source.includes('@ohos.net'), false, `${repository.file} must not import network APIs`);
  assert.equal(/\bfetch\s*\(/.test(stripCommentsAndStrings(source)), false, `${repository.file} must not use fetch`);
  assert.equal(source.includes('http://'), false, `${repository.file} must not hard-code http URLs`);
  assert.equal(source.includes('https://'), false, `${repository.file} must not hard-code https URLs`);
  assert.equal(/photoStorage\.(copy|save|persist|import|write|ensure)/.test(source), false, `${repository.file} must not copy photo files directly`);
  assert.equal(source.includes('BLOB'), false, `${repository.file} must not store image blobs`);
}

console.log('PASS');
