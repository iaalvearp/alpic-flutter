export const imageSources = ['camera', 'gallery'] as const;
export type ImageSource = (typeof imageSources)[number];

export interface ImageModelProps {
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
  createdAt: Date;
  updatedAt: Date;
  isVisible: boolean;
  deletedAt: Date | null;
}

export interface CreateImageInput {
  ownerId: string;
  name: string;
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
}

export interface ImageFile {
  bytes: Buffer;
  contentType: string;
  extension: string;
}

type ImageRow = Record<string, unknown>;

const requiredString = (row: ImageRow, field: string): string => {
  const value = row[field];
  if (typeof value !== 'string') {
    throw new Error(`Invalid image field: ${field}`);
  }
  return value;
};

const nullableString = (row: ImageRow, field: string): string | null => {
  const value = row[field];
  if (value === null || value === undefined) return null;
  if (typeof value !== 'string') {
    throw new Error(`Invalid image field: ${field}`);
  }
  return value;
};

const nullableNumber = (row: ImageRow, field: string): number | null => {
  const value = row[field];
  if (value === null || value === undefined) return null;
  if (typeof value !== 'number') {
    throw new Error(`Invalid image field: ${field}`);
  }
  return value;
};

const requiredNumber = (row: ImageRow, field: string): number => {
  const value = row[field];
  if (typeof value !== 'number') {
    throw new Error(`Invalid image field: ${field}`);
  }
  return value;
};

const requiredBoolean = (row: ImageRow, field: string): boolean => {
  const value = row[field];
  if (typeof value !== 'boolean') {
    throw new Error(`Invalid image field: ${field}`);
  }
  return value;
};

const requiredDate = (row: ImageRow, field: string): Date => {
  const value = requiredString(row, field);
  const date = new Date(value);
  if (Number.isNaN(date.valueOf())) {
    throw new Error(`Invalid image field: ${field}`);
  }
  return date;
};

const nullableDate = (row: ImageRow, field: string): Date | null => {
  const value = row[field];
  if (value === null || value === undefined) return null;
  return requiredDate(row, field);
};

export class ImageModel {
  readonly id: string;
  readonly ownerId: string;
  readonly name: string;
  readonly src: string | null;
  readonly storagePath: string | null;
  readonly alt: string;
  readonly description: string;
  readonly mimeType: string;
  readonly extension: string;
  readonly sizeBytes: number;
  readonly latitude: number | null;
  readonly longitude: number | null;
  readonly mapsUrl: string | null;
  readonly source: ImageSource;
  readonly originalFilename: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  readonly isVisible: boolean;
  readonly deletedAt: Date | null;

  constructor(props: ImageModelProps) {
    this.id = props.id;
    this.ownerId = props.ownerId;
    this.name = props.name;
    this.src = props.src;
    this.storagePath = props.storagePath;
    this.alt = props.alt;
    this.description = props.description;
    this.mimeType = props.mimeType;
    this.extension = props.extension;
    this.sizeBytes = props.sizeBytes;
    this.latitude = props.latitude;
    this.longitude = props.longitude;
    this.mapsUrl = props.mapsUrl;
    this.source = props.source;
    this.originalFilename = props.originalFilename;
    this.createdAt = props.createdAt;
    this.updatedAt = props.updatedAt;
    this.isVisible = props.isVisible;
    this.deletedAt = props.deletedAt;
  }

  static fromRow(row: ImageRow): ImageModel {
    const source = requiredString(row, 'source');
    if (!imageSources.includes(source as ImageSource)) {
      throw new Error('Invalid image field: source');
    }

    return new ImageModel({
      id: requiredString(row, 'id'),
      ownerId: requiredString(row, 'owner_id'),
      name: requiredString(row, 'name'),
      src: nullableString(row, 'src'),
      storagePath: nullableString(row, 'storage_path'),
      alt: requiredString(row, 'alt'),
      description: requiredString(row, 'description'),
      mimeType: requiredString(row, 'mime_type'),
      extension: requiredString(row, 'extension'),
      sizeBytes: requiredNumber(row, 'size_bytes'),
      latitude: nullableNumber(row, 'latitude'),
      longitude: nullableNumber(row, 'longitude'),
      mapsUrl: nullableString(row, 'maps_url'),
      source: source as ImageSource,
      originalFilename: requiredString(row, 'original_filename'),
      createdAt: requiredDate(row, 'created_at'),
      updatedAt: requiredDate(row, 'updated_at'),
      isVisible: row.is_visible === undefined
        ? true
        : requiredBoolean(row, 'is_visible'),
      deletedAt: nullableDate(row, 'deleted_at'),
    });
  }

  toRow(): Record<string, unknown> {
    return {
      id: this.id,
      owner_id: this.ownerId,
      name: this.name,
      src: this.src,
      storage_path: this.storagePath,
      alt: this.alt,
      description: this.description,
      mime_type: this.mimeType,
      extension: this.extension,
      size_bytes: this.sizeBytes,
      latitude: this.latitude,
      longitude: this.longitude,
      maps_url: this.mapsUrl,
      source: this.source,
      original_filename: this.originalFilename,
      created_at: this.createdAt.toISOString(),
      updated_at: this.updatedAt.toISOString(),
      is_visible: this.isVisible,
      deleted_at: this.deletedAt?.toISOString() ?? null,
    };
  }
}
