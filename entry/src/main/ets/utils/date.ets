export function toIsoDate(date: Date): string {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');

  return `${year}-${month}-${day}`;
}

export function toIsoDateTime(date: Date): string {
  return date.toISOString();
}

export function monthKey(date: Date): string {
  return toIsoDate(date).substring(0, 7);
}
