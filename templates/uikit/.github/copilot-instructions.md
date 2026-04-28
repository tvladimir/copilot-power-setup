# UIKit — Component Library

## Stack
- React + TypeScript strict
- Vite for builds
- Storybook for development & docs
- CSS Modules / PostCSS
- Vitest

## Commands
- Storybook: `npm run storybook`
- Build library: `npm run build`
- Build Storybook static: `npm run build-storybook`
- Test: `npm test`

## Component Layout
```
components/Button/
  Button.tsx
  Button.module.css
  Button.stories.tsx
  Button.test.tsx
  index.ts          ← barrel export
```

## Rules
- Every component MUST have a Storybook story (Why: the story is the contract for consumers)
- Every component MUST export its props interface
- Support a `className` prop for style overrides
- Use `forwardRef` for components wrapping a DOM element
- Theme via CSS custom properties — no hardcoded colours / spacing
- RTL: logical properties only (`margin-inline-start`, not `margin-left`) (Why: physical properties break right-to-left layouts)
- Tests cover: renders, props applied, events fire, axe a11y

## Story template
```tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
  title: 'Components/Button',
  tags: ['autodocs'],
};
export default meta;

type Story = StoryObj<typeof Button>;
export const Primary: Story = { args: { variant: 'primary', children: 'Click' } };
export const Disabled: Story = { args: { variant: 'primary', children: 'Disabled', disabled: true } };
```

## Don'ts
- No hardcoded colours / spacing — use design tokens
- No physical CSS properties (`margin-left`, `padding-right`) — breaks RTL
- No `any` in the public API surface — consumers depend on types
- No `default` exports — barrel exports break otherwise
- No coupling to consumer state libraries (Redux, Zustand) inside the kit
- No DOM `id` attributes you don't accept as props — they collide on multi-instance pages
