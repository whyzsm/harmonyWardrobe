export type AppResult<T> = OkResult<T> | ErrResult;

export interface OkResult<T> {
  isOk: true;
  value: T;
}

export interface ErrResult {
  isOk: false;
  error: string;
}

export function ok<T>(value: T): AppResult<T> {
  return {
    isOk: true,
    value
  };
}

export function err<T = never>(error: string): AppResult<T> {
  return {
    isOk: false,
    error
  };
}
