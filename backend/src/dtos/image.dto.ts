import { extname } from 'node:path';
import { AppError } from '../models/app-error.model.js';
import {
  imageSources,
  type CreateImageInput,
  type ImageModel,
  type ImageSource,
} from '../models/image.model.js';

export interface UpdateImageDto {
  name: string;
  alt: string;
  description: string;
}

export interface ImageResponseDto {
  id: string;
  ownerId: string;
  name: string;
  src: string | null;
  storagePath: string | null;
  alt: string;
  description: string;
  mimeType: string;
  extension: string;
  sizeBytes: number;
  latitude: number | null;
  longitude: number | null;
  mapsUrl: string | null;
  source: ImageSource;
  originalFilename: string;
  createdAt: string;
  updatedAt: string;
  isVisible: boolean;
  deletedAt: string | null;
}

const badRequest = (message: string): AppError =>
  new AppError(message, 400, 'VALIDATION_ERROR');

const supportedExtensions = new Set([
  'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif', 'bmp', 'tif', 'tiff',
]);

const recordBody = (body: unknown): Record<string, unknown> => {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    throw badRequest('request body must be an object');
  }
  return body as Record<string, unknown>;
};

const requiredString = (
  value: unknown,
  field: string,
  maxLength = 5000,
): string => {
  if (typeof value !== 'string' || value.trim() === '') {
    throw badRequest(`${field} is required`);
  }
  const normalized = value.trim();
  if (normalized.length > maxLength) throw badRequest(`${field} is too long`);
  return normalized;
};

const optionalString = (
  value: unknown,
  field: string,
  maxLength = 5000,
): string | null => {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string') throw badRequest(`${field} must be a string`);
  const normalized = value.trim();
  if (normalized.length > maxLength) throw badRequest(`${field} is too long`);
  return normalized || null;
};

const optionalNumber = (value: unknown, field: string): number | null => {
  if (value === undefined || value === null || value === '') return null;
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed)) throw badRequest(`${field} must be a number`);
  return parsed;
};

const validateCoordinates = (
  latitude: number | null,
  longitude: number | null,
): void => {
  if ((latitude === null) !== (longitude === null)) {
    throw badRequest('latitude and longitude must be provided together');
  }
  if (latitude !== null && (latitude < -90 || latitude > 90)) {
    throw badRequest('latitude must be between -90 and 90');
  }
  if (longitude !== null && (longitude < -180 || longitude > 180)) {
    throw badRequest('longitude must be between -180 and 180');
  }
};

const imageSource = (value: unknown): ImageSource => {
  const source = requiredString(value, 'source');
  if (!imageSources.includes(source as ImageSource)) {
    throw badRequest('source must be camera or gallery');
  }
  return source as ImageSource;
};

export const parseImageId = (value: unknown): string => {
  const id = requiredString(value, 'id', 36);
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id)) {
    throw badRequest('id must be a valid UUID');
  }
  return id;
};

export const parseCreateImageDto = (
  body: unknown,
  file: Express.Multer.File | undefined,
  ownerId: string,
): { input: CreateImageInput; file: { bytes: Buffer; contentType: string; extension: string } } => {
  if (!file) throw badRequest('file is required');

  const values = recordBody(body);
  if (!/^image\/(jpeg|png|webp|gif|heic|heif|bmp|tiff)$/i.test(file.mimetype)) {
    throw badRequest('file must be a supported image');
  }

  const extension = extname(file.originalname).replace('.', '').toLowerCase();
  if (!supportedExtensions.has(extension)) {
    throw badRequest('file must have a valid extension');
  }
  if (file.originalname.length > 255) {
    throw badRequest('original filename is too long');
  }

  const latitude = optionalNumber(values.latitude, 'latitude');
  const longitude = optionalNumber(values.longitude, 'longitude');
  validateCoordinates(latitude, longitude);
  const mapsUrl = optionalString(values.mapsUrl, 'mapsUrl', 2048);
  if (mapsUrl) {
    let url: URL;
    try {
      url = new URL(mapsUrl);
    } catch {
      throw badRequest('mapsUrl must be a valid URL');
    }
    if (!['http:', 'https:'].includes(url.protocol)) {
      throw badRequest('mapsUrl must use HTTP or HTTPS');
    }
  }

  return {
    input: {
      ownerId,
      name: requiredString(values.name, 'name', 255),
      alt: requiredString(values.alt, 'alt', 255),
      description: requiredString(values.description, 'description', 5000),
      mimeType: file.mimetype,
      extension,
      sizeBytes: file.size,
      latitude,
      longitude,
      mapsUrl,
      source: imageSource(values.source),
      originalFilename: file.originalname,
    },
    file: {
      bytes: file.buffer,
      contentType: file.mimetype,
      extension,
    },
  };
};

export const parseUpdateImageDto = (
  body: unknown,
): UpdateImageDto => {
  const values = recordBody(body);
  return {
    name: requiredString(values.name, 'name', 255),
    alt: requiredString(values.alt, 'alt', 255),
    description: requiredString(values.description, 'description', 5000),
  };
};

export const toImageResponseDto = (image: ImageModel): ImageResponseDto => ({
  id: image.id,
  ownerId: image.ownerId,
  name: image.name,
  src: image.src,
  storagePath: image.storagePath,
  alt: image.alt,
  description: image.description,
  mimeType: image.mimeType,
  extension: image.extension,
  sizeBytes: image.sizeBytes,
  latitude: image.latitude,
  longitude: image.longitude,
  mapsUrl: image.mapsUrl,
  source: image.source,
  originalFilename: image.originalFilename,
  createdAt: image.createdAt.toISOString(),
  updatedAt: image.updatedAt.toISOString(),
  isVisible: image.isVisible,
  deletedAt: image.deletedAt?.toISOString() ?? null,
});
