import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { config } from '../src/config.js';

describe('WI-000', () => {
  const app = createApp();

  it('AC1: GET /health returns HTTP 200', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
  });

  it('AC2: body is {"status":"ok","version":X} where X equals config version', async () => {
    const res = await request(app).get('/health');
    expect(res.body).toEqual({ status: 'ok', version: config.version });
  });
});
