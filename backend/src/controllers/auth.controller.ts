import type { RequestHandler } from 'express';
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

  register: RequestHandler = async (request, response, next) => {
    try {
      const credentials = parseCredentialsDto(request.body);
      const session = await this.service.register(
        credentials.email,
        credentials.password,
      );
      response.status(201).json({ data: toAuthResponseDto(session) });
    } catch (error) {
      next(error);
    }
  };

  login: RequestHandler = async (request, response, next) => {
    try {
      const credentials = parseCredentialsDto(request.body);
      const session = await this.service.login(
        credentials.email,
        credentials.password,
      );
      response.json({ data: toAuthResponseDto(session) });
    } catch (error) {
      next(error);
    }
  };

  me: RequestHandler = (request, response, next) => {
    try {
      const user = request.user;
      if (!user) {
        throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
      }
      response.json({
        data: toUserResponseDto({
          id: user.sub,
          email: user.email ?? '',
          createdAt: null,
          role: user.role ?? UserRole.USER,
        }),
      });
    } catch (error) {
      next(error);
    }
  };
}
