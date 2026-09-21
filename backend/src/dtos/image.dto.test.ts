import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseCreateImageDto, parseImageId, parseUpdateImageDto } from './image.dto.js';

const validFile = (overrides: Partial<Express.Multer.File> = {}): Express.Multer.File => ({
  fieldname: 'file',
  originalname: 'photo.png',
  encoding: '7bit',
  mimetype: 'image/png',
  size: 3,
  destination: '',
  filename: '',
  path: '',
  buffer: Buffer.from([1, 2, 3]),
  stream: undefined as never,
  ...overrides,
});

const validBody = {
  name: 'Photo',
  alt: 'Alternative text',
  description: 'Description',
  source: 'gallery',
};

test('image DTO accepts valid coordinates and rejects out-of-range values', () => {
  const result = parseCreateImageDto(
    { ...validBody, latitude: '-0.18', longitude: '-78.48' },
    validFile(),
    'owner-1',
  );
  assert.equal(result.input.latitude, -0.18);
  assert.throws(
    () => parseCreateImageDto(
      { ...validBody, latitude: '91', longitude: '0' },
      validFile(),
      'owner-1',
    ),
    /latitude must be between -90 and 90/,
  );
});

test('image DTO rejects incomplete coordinates, invalid media and invalid body shapes', () => {
  assert.throws(
    () => parseCreateImageDto(
      { ...validBody, latitude: '0' },
      validFile(),
      'owner-1',
    ),
    /provided together/,
  );
  assert.throws(
    () => parseCreateImageDto(validBody, validFile({ mimetype: 'text/plain' }), 'owner-1'),
    /supported image/,
  );
  assert.throws(() => parseUpdateImageDto(null), /request body must be an object/);
});

test('image IDs must be UUIDs before reaching persistence', () => {
  assert.equal(
    parseImageId('11111111-1111-4111-8111-111111111111'),
    '11111111-1111-4111-8111-111111111111',
  );
  assert.throws(() => parseImageId('not-an-id'), /valid UUID/);
});
