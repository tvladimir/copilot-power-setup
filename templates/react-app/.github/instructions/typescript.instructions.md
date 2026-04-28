---
applyTo: "**/*.ts,**/*.tsx"
---
# TypeScript Rules

## Types
- Strict mode: no `any` (use `unknown` + type guards)
- Interface for object shapes, type for unions/intersections
- Use `as const` for literal types
- Prefer discriminated unions over optional fields
- Generic constraints: `<T extends Record<string, unknown>>`

## Imports
- Relative imports for project files
- Barrel exports (index.ts) for public API of a module
- Type-only imports: `import type { Foo } from './types'`

## Null Safety
- Use optional chaining: `obj?.prop?.nested`
- Use nullish coalescing: `value ?? defaultValue`
- Never use `!` non-null assertion (fix the type instead)

## Naming
- Components: PascalCase (`UserProfile.tsx`)
- Hooks: camelCase with `use` prefix (`useAuth.ts`)
- Utils: camelCase (`formatDate.ts`)
- Types/Interfaces: PascalCase (`UserProfile`, `ApiResponse`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`)
- Enums: PascalCase members (`Status.Active`)
