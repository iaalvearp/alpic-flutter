import { AppError } from '../models/app-error.model.js';
import type { JwtUser, JwtVerifier } from '../middleware/auth.middleware.js';
import type { AuthRepository } from '../repositories/auth.repository.js';
import {
  AuthRepositoryError,
  SupabaseAuthRepository,
} from '../repositories/auth.repository.js';
import type { AuthSessionModel, UserModel } from '../models/user.model.js';
import { UserRole } from '../models/user.model.js';

export interface AuthServicePort {
  register(email: string, password: string): Promise<AuthSessionModel>;
  login(email: string, password: string): Promise<AuthSessionModel>;
  verifyToken(token: string): Promise<JwtUser>;
}

export class AuthService implements AuthServicePort {
  constructor(private readonly repository: AuthRepository) {}

  async register(email: string, password: string): Promise<AuthSessionModel> {
    try {
      await this.repository.register(email, password);
      return await this.repository.login(email, password);
    } catch (error) {
      if (error instanceof AuthRepositoryError) {
        throw new AppError(
          'Unable to register user',
          400,
          'REGISTRATION_FAILED',
        );
      }
      throw error;
    }
  }

  async login(email: string, password: string): Promise<AuthSessionModel> {
    try {
      return await this.repository.login(email, password);
    } catch (error) {
      if (error instanceof AuthRepositoryError) {
        throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
      }
      throw error;
    }
  }

  async verifyToken(token: string): Promise<JwtUser> {
    try {
      const user = await this.repository.getUserFromToken(token);
      return this.toJwtUser(user);
    } catch (error) {
      if (error instanceof AuthRepositoryError) {
        throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
      }
      throw error;
    }
  }

  private toJwtUser(user: UserModel): JwtUser {
    return {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
  }
}

export class SupabaseJwtVerifier implements JwtVerifier {
  constructor(private readonly service: AuthServicePort) {}

  verify(token: string): Promise<JwtUser> {
    return this.service.verifyToken(token);
  }
}

export const createDefaultAuthService = (): AuthService =>
  new AuthService(new SupabaseAuthRepository());
