export const UserRole = {
  USER: 'USER',
  ADMIN: 'ADMIN',
} as const;

export type UserRole = (typeof UserRole)[keyof typeof UserRole];

export interface UserModel {
  id: string;
  email: string;
  createdAt: Date | null;
  role: UserRole;
}

export interface AuthSessionModel {
  user: UserModel;
  accessToken: string;
  expiresAt: number | null;
}

export interface ImageActor {
  id: string;
  role: UserRole;
}
