export function buildSearchNgrams(input: string, minGram = 1, maxGram = 3): string[] {
  if (minGram > maxGram) {
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

  for (let size = minGram; size <= maxGram; size += 1) {
    for (const token of tokens) {
      if (token.length < size) {
        continue;
      }

      for (let start = 0; start <= token.length - size; start += 1) {
        const gram = token.substring(start, start + size);
        if (!seen.has(gram)) {
          seen.add(gram);
          grams.push(gram);
        }
      }
    }
  }

  return grams;
}
