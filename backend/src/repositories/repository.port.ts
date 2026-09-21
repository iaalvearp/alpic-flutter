/**
 * Common persistence boundary. Concrete repositories will be added with the
 * domain slices and must keep Supabase details outside controllers/services.
 */
export interface Repository<TEntity, TCreateInput, TUpdateInput> {
  findById(id: string): Promise<TEntity | null>;
  create(input: TCreateInput): Promise<TEntity>;
  update(id: string, input: TUpdateInput): Promise<TEntity>;
}
