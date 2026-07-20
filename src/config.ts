// Application configuration. Values come from the environment, never literals
// baked into request handlers (see WI-000 AC2).
export const config = {
  version: process.env.APP_VERSION ?? '0.1.0',
} as const;
