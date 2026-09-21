import type { SupabaseClient, User } from '@supabase/supabase-js';
import { getSupabaseClient } from '../config/supabase.js';
import type { AuthSessionModel, UserModel } from '../models/user.model.js';
import { UserRole } from '../models/user.model.js';

export type AuthRepositoryErrorCode =
  | 'REGISTRATION_FAILED'
  | 'INVALID_CREDENTIALS'
  | 'INVALID_TOKEN';

export class AuthRepositoryError extends Error {
  constructor(
    public readonly code: AuthRepositoryErrorCode,
    cause?: unknown,
  ) {
    super(code);
    this.name = 'AuthRepositoryError';
    this.cause = cause;
  }

  readonly cause?: unknown;
}

export interface AuthRepository {
  register(email: string, password: string): Promise<UserModel>;
  login(email: string, password: string): Promise<AuthSessionModel>;
  getUserFromToken(token: string): Promise<UserModel>;
}

const toUserModel = (user: User): UserModel => ({
  id: user.id,
  email: user.email ?? '',
  createdAt: user.created_at ? new Date(user.created_at) : null,
  role: user.app_metadata?.role === UserRole.ADMIN
    ? UserRole.ADMIN
    : UserRole.USER,
});

export class SupabaseAuthRepository implements AuthRepository {
  private client?: SupabaseClient;

  constructor(client?: SupabaseClient) {
    this.client = client;
  }

  private get supabase(): SupabaseClient {
    this.client ??= getSupabaseClient();
    return this.client;
  }

  async register(email: string, password: string): Promise<UserModel> {
    const { data, error } = await this.supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { role: UserRole.USER },
    });

    if (error || !data.user) {
      throw new AuthRepositoryError('REGISTRATION_FAILED', error);
    }

    return toUserModel(data.user);
  }

  async login(email: string, password: string): Promise<AuthSessionModel> {
    const { data, error } = await this.supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.user || !data.session) {
      throw new AuthRepositoryError('INVALID_CREDENTIALS', error);
    }

    return {
      user: toUserModel(data.user),
      accessToken: data.session.access_token,
      expiresAt: data.session.expires_at ?? null,
    };
  }

  async getUserFromToken(token: string): Promise<UserModel> {
    const { data, error } = await this.supabase.auth.getUser(token);
    if (error || !data.user) {
      throw new AuthRepositoryError('INVALID_TOKEN', error);
    }
    return toUserModel(data.user);
  }
}
