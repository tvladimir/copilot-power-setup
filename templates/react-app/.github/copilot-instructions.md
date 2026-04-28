# React + TypeScript Application

## Stack
- React 19 + TypeScript strict
- Vitest + React Testing Library + MSW
- ESLint flat config + Prettier

## Commands
- Dev: `npm run dev`
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

## Components
- Functional components only — no class components
- Named exports only — default exports break refactor tools
- Props as `interface`, not type alias
- Destructure props in the function signature
- Co-locate `.test.tsx` next to the component

## Hooks
- Custom hooks in `src/hooks/`, prefix with `use`
- Always return a cleanup function from `useEffect` when subscribing
- Memoize only when the React profiler shows a need — not preemptively (Why: unnecessary `useMemo` adds overhead and obscures intent)

## State
- Local: `useState` / `useReducer`
- Server: TanStack Query (React Query)
- Global: Zustand for cross-cutting state; Context only for stable identity (theme, auth)
- Don't prop-drill beyond 2 levels — lift to context or use composition

## Testing
- Test behaviour, not implementation
- `screen.getByRole()` first, then `getByLabelText`, `getByTestId` last (Why: role-based queries enforce a11y)
- `userEvent` for interactions, not `fireEvent`
- Mock at the network boundary (MSW) — not internal modules

## Accessibility
- Semantic HTML first (`button`, `nav`, `main`, `article`)
- ARIA only when semantic HTML is insufficient
- Keyboard navigation must work without a mouse
- Run axe in tests for components that render interactive UI

## Don'ts
- No `any` — use `unknown` + a type guard (Why: `any` opts out of all type safety)
- No `!` non-null assertion — fix the type
- No `getByTestId` as a first choice — it bypasses accessibility testing
- No new state managers without team discussion
- No styled-components in new code — use CSS Modules or Tailwind
- No `useEffect` for derived state — compute it in render
