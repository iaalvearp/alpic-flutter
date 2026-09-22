import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { AppEnv } from './env.js';

export const createSupabaseClient = (env: AppEnv): SupabaseClient =>
  createClient(env.supabaseUrl, env.supabaseServiceRoleKey);
