export function normalizeSearchText(input: string): string {
  return input.normalize('NFKC').trim().toLowerCase().replace(/\s+/g, ' ');
}
