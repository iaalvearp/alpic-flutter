import { AppError } from '../models/app-error.model.js';
import type { AuthSessionModel, UserModel } from '../models/user.model.js';
import type { UserRole } from '../models/user.model.js';

export interface CredentialsDto {
  email: string;
  password: string;
}

export interface UserResponseDto {
  id: string;
  email: string;
  createdAt: string | null;
  role: UserRole;
}

export interface AuthResponseDto {
  user: UserResponseDto;
  accessToken: string;
  tokenType: 'Bearer';
  expiresAt: number | null;
}

const validationError = (message: string): AppError =>
  new AppError(message, 400, 'VALIDATION_ERROR');

const recordBody = (body: unknown): Record<string, unknown> => {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    throw validationError('request body must be a JSON object');
  }
  return body as Record<string, unknown>;
};

const parseEmail = (value: unknown): string => {
  if (typeof value !== 'string' || value.trim() === '') {
    throw validationError('email is required');
  }

  const email = value.trim().toLowerCase();
  if (email.length > 320) throw validationError('email is invalid');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw validationError('email is invalid');
  }
  return email;
};

const parsePassword = (value: unknown): string => {
  if (typeof value !== 'string' || value.length < 8 || value.length > 256) {
    throw validationError('password must contain between 8 and 256 characters');
  }
  return value;
};

export const parseCredentialsDto = (
  body: unknown,
): CredentialsDto => {
  const values = recordBody(body);
  return {
    email: parseEmail(values.email),
    password: parsePassword(values.password),
  };
};

export const toUserResponseDto = (user: UserModel): UserResponseDto => ({
  id: user.id,
  email: user.email,
  createdAt: user.createdAt?.toISOString() ?? null,
  role: user.role,
});

export const toAuthResponseDto = (
  session: AuthSessionModel,
): AuthResponseDto => ({
  user: toUserResponseDto(session.user),
  accessToken: session.accessToken,
  tokenType: 'Bearer',
  expiresAt: session.expiresAt,
});
