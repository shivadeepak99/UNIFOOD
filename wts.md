# Week 1 Team Contributions (Software Architecture Project)

- Member 1
  - Bootstrapped the React + Vite + TypeScript workspace, configured path aliases in `tsconfig.json`, and set up Tailwind with the design tokens in `src/index.css`. Integrated shadcn/ui components and verified the dev server and hot reload work reliably. Added ESLint config and npm scripts to standardize local development.

- Member 2
  - Set up Supabase connectivity by implementing `src/integrations/supabase/client.ts` and generating typed database definitions in `src/integrations/supabase/types.ts`. Built the reusable `useAuth` hook with session listeners and sign-out, then validated basic sign-up/sign-in flows. Authored an `.env.example` plan (to replace hard-coded keys next sprint) and documented required env variables.

- Member 3
  - Implemented the application shell with `QueryClientProvider`, `TooltipProvider`, and toast providers, and wired routing in `App.tsx` (`/`, `/auth`, `*`). Created `Auth.tsx` with tabbed Sign In/Sign Up using shadcn/ui components, and added `Index.tsx` (guest and authenticated views) plus `NotFound.tsx`. Ensured UI states (loading, error toasts) are consistent and accessible.

- Member 4
  - Authored the initial database migration defining `profiles`, `canteens`, `menu_categories`, `menu_items`, `orders`, `order_items`, and `feedback`, with enums, RLS policies, triggers, and `generate_order_number()` function. Produced the IEEE-style SRS in `README.md` and the SRC plan in `PLAN.md`, and summarized status in `CURRENTSTATE.md`. Outlined the API surface and proposed Express BFF + Stripe webhook flow to guide upcoming sprints.
