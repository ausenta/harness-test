import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: ['node_modules', 'coverage', 'dist'],
  },
  ...tseslint.configs.recommended,
  {
    files: ['**/*.ts'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
    },
  },
);
