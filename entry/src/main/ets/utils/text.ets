export function normalizeSearchText(input: string): string {
  return input.trim().toLowerCase().replace(/\s+/g, ' ');
}
