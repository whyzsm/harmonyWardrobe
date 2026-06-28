export function toIsoDate(date: Date): string {
  return date.toISOString().substring(0, 10);
}

export function toIsoDateTime(date: Date): string {
  return date.toISOString();
}

export function monthKey(date: Date): string {
  return toIsoDate(date).substring(0, 7);
}
