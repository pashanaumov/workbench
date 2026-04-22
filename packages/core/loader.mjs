// Minimal loader: maps .js specifiers to .ts counterparts so that
// `node --experimental-strip-types --import ./loader.mjs --test src/foo.test.ts` works.
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export async function resolve(specifier, context, nextResolve) {
  if (specifier.endsWith('.js')) {
    const tsSpecifier = specifier.slice(0, -3) + '.ts';
    try {
      const result = await nextResolve(tsSpecifier, context);
      return result;
    } catch {
      // fall through
    }
  }
  return nextResolve(specifier, context);
}
