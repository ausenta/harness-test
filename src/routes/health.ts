import { Router } from 'express';
import { config } from '../config.js';

// WI-000: liveness/version probe. Version is read from config (see AC2) so it
// tracks the deployed build rather than a literal baked into the handler.
export const healthRouter = Router();

healthRouter.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', version: config.version });
});
