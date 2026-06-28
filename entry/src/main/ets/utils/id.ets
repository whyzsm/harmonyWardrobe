export function createId(prefix: string): string {
  const cleanPrefix = prefix.trim().toLowerCase();
  const timestamp = Date.now().toString(36);
  const randomSuffix = Math.random().toString(36).substring(2, 10);

  return `${cleanPrefix}_${timestamp}_${randomSuffix}`;
}
