export class EntityNotFoundError extends Error {
  constructor(entity: string) {
    super(`${entity} not found`);
    this.name = 'EntityNotFoundError';
  }
}
