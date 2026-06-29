export class DatabaseError extends Error {
  readonly cause?: Error;
  readonly rollbackCause?: Error;

  constructor(message: string, cause?: Error, rollbackCause?: Error) {
    super(message);
    this.name = 'DatabaseError';
    this.cause = cause;
    this.rollbackCause = rollbackCause;
  }
}
