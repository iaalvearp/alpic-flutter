import assert from 'node:assert/strict';
import { test } from 'node:test';
import { ImageModel } from './image.model.js';

test('ImageModel maps the existing images row shape', () => {
  const image = ImageModel.fromRow({
    id: 'image-1',
    owner_id: 'owner-1',
    name: 'AlPics_20260921_120000',
    src: 'https://example.test/image.png',
    storage_path: 'owner-1/image-1.png',
    alt: 'Alt de la imagen',
    description: 'Descripción de la imagen',
    mime_type: 'image/png',
    extension: 'png',
    size_bytes: 128,
    latitude: -2.1,
    longitude: -79.9,
    maps_url: 'https://www.google.com/maps?q=-2.1,-79.9',
    source: 'gallery',
    original_filename: 'foto.png',
    created_at: '2026-09-21T12:00:00.000Z',
    updated_at: '2026-09-21T12:00:00.000Z',
    is_visible: true,
    deleted_at: null,
  });

  assert.equal(image.ownerId, 'owner-1');
  assert.equal(image.source, 'gallery');
  assert.equal(image.latitude, -2.1);
  assert.equal(image.toRow().storage_path, 'owner-1/image-1.png');
});
