export interface AppResult<T> {
  isOk: boolean;
  value?: T;
  error?: string;
}

export function ok<T>(value: T): AppResult<T> {
  return {
    isOk: true,
    value
  };
}

export function err<T>(error: string): AppResult<T> {
  return {
    isOk: false,
    error
  };
}
