import type { SupabaseClient } from '@supabase/supabase-js';
import { ImageModel } from '../models/image.model.js';
import { PersistenceError } from '../models/persistence-error.model.js';

const imageColumns = [
  'id',
  'owner_id',
  'name',
  'src',
  'storage_path',
  'alt',
  'description',
  'mime_type',
  'extension',
  'size_bytes',
  'latitude',
  'longitude',
  'maps_url',
  'source',
  'original_filename',
  'created_at',
  'updated_at',
  'is_visible',
  'deleted_at',
].join(',');

export interface ImageRepository {
  checkConnection(): Promise<void>;
  findVisibleByOwner(ownerId: string): Promise<ImageModel[]>;
  findAllVisible(): Promise<ImageModel[]>;
  findById(id: string, ownerId?: string): Promise<ImageModel | null>;
  create(image: ImageModel): Promise<ImageModel>;
  updateMetadata(
    id: string,
    values: Pick<ImageModel, 'name' | 'alt' | 'description' | 'updatedAt'>,
    ownerId?: string,
  ): Promise<ImageModel | null>;
  softDelete(id: string, deletedAt: Date, ownerId?: string): Promise<boolean>;
  uploadFile(path: string, bytes: Uint8Array, contentType: string): Promise<void>;
  removeFile(path: string): Promise<void>;
  publicUrl(path: string): string;
}

export class SupabaseImageRepository implements ImageRepository {
  constructor(
    private readonly client: SupabaseClient,
    private readonly bucketName: string,
  ) {}

  async checkConnection(): Promise<void> {
    const { error } = await this.client.from('images').select('id').limit(1);
    if (error) throw new PersistenceError('check Supabase connection', error);
  }

  async findVisibleByOwner(ownerId: string): Promise<ImageModel[]> {
    const { data, error } = await this.client
      .from('images')
      .select(imageColumns)
      .eq('owner_id', ownerId)
      .eq('is_visible', true)
      .order('created_at', { ascending: false });

    if (error) throw new PersistenceError('list images', error);
    return (data ?? []).map((row) =>
      ImageModel.fromRow(row as unknown as Record<string, unknown>),
    );
  }

  async findAllVisible(): Promise<ImageModel[]> {
    const { data, error } = await this.client
      .from('images')
      .select(imageColumns)
      .eq('is_visible', true)
      .order('created_at', { ascending: false });

    if (error) throw new PersistenceError('list all images', error);
    return (data ?? []).map((row) =>
      ImageModel.fromRow(row as unknown as Record<string, unknown>),
    );
  }

  async findById(id: string, ownerId?: string): Promise<ImageModel | null> {
    let query = this.client
      .from('images')
      .select(imageColumns)
      .eq('id', id)
      .eq('is_visible', true);
    if (ownerId) query = query.eq('owner_id', ownerId);
    const { data, error } = await query.maybeSingle();

    if (error) throw new PersistenceError('get image', error);
    return data
      ? ImageModel.fromRow(data as unknown as Record<string, unknown>)
      : null;
  }

  async create(image: ImageModel): Promise<ImageModel> {
    const { data, error } = await this.client
      .from('images')
      .insert(image.toRow())
      .select(imageColumns)
      .single();

    if (error || !data) throw new PersistenceError('create image', error);
    return ImageModel.fromRow(data as unknown as Record<string, unknown>);
  }

  async updateMetadata(
    id: string,
    values: Pick<ImageModel, 'name' | 'alt' | 'description' | 'updatedAt'>,
    ownerId?: string,
  ): Promise<ImageModel | null> {
    let query = this.client
      .from('images')
      .update({
        name: values.name,
        alt: values.alt,
        description: values.description,
        updated_at: values.updatedAt.toISOString(),
      })
      .eq('id', id)
      .eq('is_visible', true);
    if (ownerId) query = query.eq('owner_id', ownerId);
    const { data, error } = await query.select(imageColumns).maybeSingle();

    if (error) throw new PersistenceError('update image metadata', error);
    return data
      ? ImageModel.fromRow(data as unknown as Record<string, unknown>)
      : null;
  }

  async softDelete(
    id: string,
    deletedAt: Date,
    ownerId?: string,
  ): Promise<boolean> {
    let query = this.client
      .from('images')
      .update({
        is_visible: false,
        deleted_at: deletedAt.toISOString(),
        updated_at: deletedAt.toISOString(),
      })
      .eq('id', id)
      .eq('is_visible', true);
    if (ownerId) query = query.eq('owner_id', ownerId);
    const { data, error } = await query.select('id').maybeSingle();

    if (error) throw new PersistenceError('soft delete image', error);
    return data !== null;
  }

  async uploadFile(
    path: string,
    bytes: Uint8Array,
    contentType: string,
  ): Promise<void> {
    console.log(`Storage upload: path=${path}, bytes=${bytes.length}, type=${contentType}`);
    const { data, error } = await this.client.storage
      .from(this.bucketName)
      .upload(path, bytes, { contentType, upsert: false });

    if (error) {
      console.error('Storage upload error:', JSON.stringify(error));
      throw new PersistenceError('upload image file', error);
    }
    console.log('Storage upload success:', JSON.stringify(data));
  }

  async removeFile(path: string): Promise<void> {
    const { error } = await this.client.storage
      .from(this.bucketName)
      .remove([path]);

    if (error) throw new PersistenceError('remove image file', error);
  }

  publicUrl(path: string): string {
    return this.client.storage.from(this.bucketName).getPublicUrl(path).data
      .publicUrl;
  }
}
