export function buildSearchNgrams(input: string, minGram = 1, maxGram = 3): string[] {
  if (!Number.isFinite(minGram) || !Number.isFinite(maxGram)) {
    return [];
  }

  if (!Number.isSafeInteger(minGram) || !Number.isSafeInteger(maxGram)) {
    return [];
  }

  if (minGram < 1 || maxGram < 1 || minGram > maxGram) {
    return [];
  }

  const tokens = input
    .normalize('NFKC')
    .toLowerCase()
    .trim()
    .split(/\s+/)
    .map((token) => token.replace(/[^\p{Script=Han}\p{Letter}\p{Number}]+/gu, ''))
    .filter((token) => token.length > 0);

  const grams: string[] = [];
  const seen = new Set<string>();
  const longestTokenLength = tokens.reduce((maxLength, token) => Math.max(maxLength, Array.from(token).length), 0);
  const effectiveMaxGram = Math.min(maxGram, longestTokenLength);

  for (let size = minGram; size <= effectiveMaxGram; size += 1) {
    for (const token of tokens) {
      const characters = Array.from(token);
      if (characters.length < size) {
        continue;
      }

      for (let start = 0; start <= characters.length - size; start += 1) {
        const gram = characters.slice(start, start + size).join('');
        if (!seen.has(gram)) {
          seen.add(gram);
          grams.push(gram);
        }
      }
    }
  }

  return grams;
}
