export class PersistenceError extends Error {
  constructor(operation: string, cause?: unknown) {
    super(`Persistence operation failed: ${operation}`);
    this.name = 'PersistenceError';
    this.cause = cause;
  }

  readonly cause?: unknown;
}
