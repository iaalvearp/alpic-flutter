import assert from 'node:assert/strict';
import { test } from 'node:test';
import { parseCredentialsDto } from './auth.dto.js';

test('auth DTO rejects null, array and oversized credential bodies', () => {
  assert.throws(() => parseCredentialsDto(null), /JSON object/);
  assert.throws(() => parseCredentialsDto([]), /JSON object/);
  assert.throws(
    () => parseCredentialsDto({ email: 'user@example.com', password: 'x'.repeat(257) }),
    /between 8 and 256/,
  );
});

test('auth DTO normalizes email without altering password', () => {
  assert.deepEqual(
    parseCredentialsDto({ email: ' User@Example.COM ', password: ' 12345678 ' }),
    { email: 'user@example.com', password: ' 12345678 ' },
  );
});
