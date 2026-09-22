import assert from 'node:assert/strict';
import { describe, it } from 'vitest';
import { parseCredentialsDto } from './auth.dto.js';

describe('auth DTO', () => {
  it('rejects null, array and oversized credential bodies', () => {
    assert.throws(() => parseCredentialsDto(null), /JSON object/);
    assert.throws(() => parseCredentialsDto([]), /JSON object/);
    assert.throws(
      () => parseCredentialsDto({ email: 'user@example.com', password: 'x'.repeat(257) }),
      /between 8 and 256/,
    );
  });

  it('normalizes email without altering password', () => {
    assert.deepEqual(
      parseCredentialsDto({ email: ' User@Example.COM ', password: ' 12345678 ' }),
      { email: 'user@example.com', password: ' 12345678 ' },
    );
  });
});
