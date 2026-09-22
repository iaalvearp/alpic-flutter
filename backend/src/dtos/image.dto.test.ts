import assert from 'node:assert/strict';
import { describe, it } from 'vitest';
import { parseCreateImageDto, parseImageId, parseUpdateImageDto } from './image.dto.js';

const createFormData = (fields: Record<string, string>, file?: File): FormData => {
  const formData = new FormData();
  for (const [key, value] of Object.entries(fields)) {
    formData.append(key, value);
  }
  if (file) {
    formData.append('file', file);
  }
  return formData;
};

const createFile = (name: string, type: string, size: number): File => {
  const buffer = new ArrayBuffer(size);
  return new File([buffer], name, { type });
};

const validFields = {
  name: 'Photo',
  alt: 'Alternative text',
  description: 'Description',
  source: 'gallery',
};

describe('image DTO', () => {
  it('accepts valid coordinates and rejects out-of-range values', async () => {
    const formData = createFormData(
      { ...validFields, latitude: '-0.18', longitude: '-78.48' },
      createFile('photo.png', 'image/png', 3),
    );
    const result = await parseCreateImageDto(formData, 'owner-1');
    assert.equal(result.input.latitude, -0.18);

    const invalidFormData = createFormData(
      { ...validFields, latitude: '91', longitude: '0' },
      createFile('photo.png', 'image/png', 3),
    );
    await assert.rejects(
      () => parseCreateImageDto(invalidFormData, 'owner-1'),
      /latitude must be between -90 and 90/,
    );
  });

  it('rejects incomplete coordinates, invalid media and invalid body shapes', async () => {
    const incompleteCoords = createFormData(
      { ...validFields, latitude: '0' },
      createFile('photo.png', 'image/png', 3),
    );
    await assert.rejects(
      () => parseCreateImageDto(incompleteCoords, 'owner-1'),
      /provided together/,
    );

    const invalidMedia = createFormData(
      validFields,
      createFile('document.txt', 'text/plain', 3),
    );
    await assert.rejects(
      () => parseCreateImageDto(invalidMedia, 'owner-1'),
      /supported image/,
    );
  });

  it('image IDs must be UUIDs before reaching persistence', () => {
    assert.equal(
      parseImageId('11111111-1111-4111-8111-111111111111'),
      '11111111-1111-4111-8111-111111111111',
    );
    assert.throws(() => parseImageId('not-an-id'), /valid UUID/);
  });
});
