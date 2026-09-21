import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SupabaseImageRepository } from './repositories/image.repository.js';

const canRun =
  process.env.RUN_SUPABASE_INTEGRATION === 'true' &&
  Boolean(process.env.SUPABASE_URL) &&
  Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY);

test('Supabase connection can query the existing images table', {
  skip: canRun ? false : 'Supabase integration variables are not configured',
}, async () => {
  const repository = new SupabaseImageRepository();
  await repository.checkConnection();
  const images = await repository.findVisibleByOwner(
    '00000000-0000-0000-0000-000000000000',
  );
  assert.ok(Array.isArray(images));
});
