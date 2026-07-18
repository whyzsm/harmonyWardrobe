export const MAX_USER_PHOTOS: number = 5;

export function remainingPhotoSlots(photoUris: string[]): number {
  return Math.max(0, MAX_USER_PHOTOS - photoUris.length);
}

export function appendPhotoUris(currentPhotoUris: string[], incomingPhotoUris: string[]): string[] {
  const nextPhotoUris: string[] = [...currentPhotoUris];
  for (const photoUri of incomingPhotoUris) {
    if (photoUri.length === 0 || nextPhotoUris.length >= MAX_USER_PHOTOS || nextPhotoUris.includes(photoUri)) {
      continue;
    }
    nextPhotoUris.push(photoUri);
  }
  return nextPhotoUris;
}
