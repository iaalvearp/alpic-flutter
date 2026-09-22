import type { Context } from 'hono';
import { AppError } from '../models/app-error.model.js';
import {
  parseCredentialsDto,
  toAuthResponseDto,
  toUserResponseDto,
} from '../dtos/auth.dto.js';
import type { AuthServicePort } from '../services/auth.service.js';
import { UserRole } from '../models/user.model.js';

export class AuthController {
  constructor(private readonly service: AuthServicePort) {}

  register = async (c: Context) => {
    const body = await c.req.json();
    const credentials = parseCredentialsDto(body);
    const session = await this.service.register(
      credentials.email,
      credentials.password,
    );
    return c.json({ data: toAuthResponseDto(session) }, 201);
  };

  login = async (c: Context) => {
    const body = await c.req.json();
    const credentials = parseCredentialsDto(body);
    const session = await this.service.login(
      credentials.email,
      credentials.password,
    );
    return c.json({ data: toAuthResponseDto(session) });
  };

  me = (c: Context) => {
    const user = c.get('user');
    if (!user) {
      throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
    }
    return c.json({
      data: toUserResponseDto({
        id: user.sub,
        email: user.email ?? '',
        createdAt: null,
        role: user.role ?? UserRole.USER,
      }),
    });
  };
}
