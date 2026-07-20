import express, { type Express } from 'express';
// NOTE: ./routes/health is intentionally absent from the scaffold. It is the
// deliverable of work item WI-000 — the build agent creates it, which is what
// turns this app (and `main`) green.
import { healthRouter } from './routes/health.js';

export function createApp(): Express {
  const app = express();
  app.use(healthRouter);
  return app;
}
