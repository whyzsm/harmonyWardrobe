export function userFacingError(error: Error, fallback: string): string {
  const rawMessage = error.message.trim();
  if (rawMessage.length === 0) {
    return fallback;
  }

  const normalizedMessage = rawMessage.toLowerCase();
  if (normalizedMessage.includes('permission') || normalizedMessage.includes('access denied')) {
    return '无法访问本地资源，请检查权限后重试。';
  }
  if (normalizedMessage.includes('sqlite') || normalizedMessage.includes('database') || normalizedMessage.includes('resultset')) {
    return '本地数据暂时不可用，请重试。';
  }
  if (normalizedMessage.includes('storage') || normalizedMessage.includes('local uri')) {
    return '本地照片暂时不可用，请重新选择照片。';
  }

  return rawMessage.length <= 80 ? rawMessage : fallback;
}
