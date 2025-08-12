# UniFood – Current State Report
Date: 2025-08-12

This document summarizes the project status, what is implemented, what is integrated, what requires environment configuration, and what remains pending as of today.

---

## 1) Snapshot Overview

- App Type: React + Vite + TypeScript SPA
- UI: Tailwind CSS + shadcn/ui (Radix primitives)
- Routing: react-router-dom
- State/Async: TanStack React Query (provider wired)
- Backend/DB: Supabase (Auth, Postgres, Realtime, Storage). No Node/Express server added yet.
- Auth: Supabase email/password sign up & sign in flows working via client SDK
- Docs: IEEE-style SRS in `README.md`; SRC plan in `PLAN.md`

---

## 2) Implemented To Date

Frontend
- App bootstrap with Vite (`vite.config.ts`) and TypeScript (`tsconfig*.json`).
- Global styles and design tokens with Tailwind (`src/index.css`, `tailwind.config.ts`).
- shadcn/ui component library installed with many ready components under `src/components/ui/*`.
- Routing skeleton: `src/App.tsx` + `react-router-dom` with routes: `/`, `/auth`, and catch-all `*`.
- Pages:
  - `Index.tsx`: Landing + authenticated home state (shows user email and sign-out).
  - `Auth.tsx`: Tabbed Sign In / Sign Up forms using Supabase Auth.
  - `NotFound.tsx`: 404 page.
- Toasts and tooltips providers wired (`Toaster`, `Sonner`, `TooltipProvider`).
- React Query provider configured (`QueryClientProvider`).

Supabase Integration
- Client SDK initialized in `src/integrations/supabase/client.ts` with URL and anon key (currently hard-coded constants).
- Auth hook `src/hooks/useAuth.tsx`:
  - Listens to session changes; persists session; exposes `user`, `session`, `loading`, and `signOut()`.
- Database TypeScript types generated at `src/integrations/supabase/types.ts` (aligned to current schema).

Database Schema & Security
- Migration at `supabase/migrations/*` provisions:
  - Enums: `user_role`, `order_status`.
  - Tables: `profiles`, `canteens`, `menu_categories`, `menu_items`, `orders`, `order_items`, `feedback`.
  - RLS policies for students and canteen managers.
  - Functions and triggers: `generate_order_number()`, `set_order_number()`, and `update_updated_at` triggers.
  - Indexes on key FKs and status columns.

Developer Experience
- ESLint config present; path aliases (`@/*`) configured.
- Lovable tagger and dev server on port 8080 configured in `vite.config.ts`.

Documentation
- IEEE SRS in `README.md` (investor/engineering-ready).
- SRC plan in `PLAN.md` (strategy, flows, tech choices, roadmap).

---

## 3) Integrations Present

- Supabase JS client (`@supabase/supabase-js`): Auth + Postgres access.
- TanStack React Query: wired with a `QueryClient` (no queries yet).
- shadcn/ui + Radix: comprehensive UI component set available.
- Lucide icons, date-fns, day-picker, etc. installed and ready.

Not Yet Integrated
- Node/Express backend (BFF) – not created.
- Payments (Stripe/PSP) – not integrated.
- Realtime channels usage in UI – not wired yet.
- Supabase Storage for item images – not wired in UI yet.

---

## 4) Features Status (vs. SRC/SRS)

Student
- Auth (email/password): Implemented with Supabase (Sign Up / Sign In / Sign Out).
- View active menu: Not implemented in UI yet (DB supports it).
- Cart & checkout: Not implemented.
- Payment & token issuance: Not implemented.
- Order tracking (status changes): Not implemented (schema supports lifecycle).
- Feedback per dish: Not implemented in UI (table exists).
- Order history & reorder: Not implemented.

Manager
- Add dishes / daily menu / update quantities: Not implemented in UI.
- View orders and tokens; update statuses: Not implemented in UI.
- View feedback: Not implemented in UI.

Platform
- Database schema, RLS, triggers: Implemented.
- React app shell and auth flow: Implemented.
- Express API, payments, webhooks, transactional logic: Not started.

---

## 5) Environment Variables and Secrets

Current Behavior
- `src/integrations/supabase/client.ts` contains hard-coded constants for `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (anon key). This works for development but should be moved to `.env` for portability and security hygiene.

Recommended `.env` (client, Vite)
- `VITE_SUPABASE_URL=<your_supabase_url>`
- `VITE_SUPABASE_ANON_KEY=<your_supabase_anon_key>`

Recommended `.env` (future server, Express)
- `SUPABASE_URL=<your_supabase_url>`
- `SUPABASE_SERVICE_ROLE=<service_role_key>` (server-side only)
- `STRIPE_SECRET_KEY=<stripe_live_or_test_key>`
- `STRIPE_WEBHOOK_SECRET=<stripe_webhook_signing_secret>`
- `APP_URL=<https://your.app>`

Other Considerations
- Configure Supabase Auth redirect URLs in project settings for production domains.
- Do not expose service role keys to the client. Keep all secret keys server-side only.

---

## 6) How to Run (Today)

- Requirements: Node.js LTS.
- Install: `npm install`
- Dev: `npm run dev` (Vite on port 8080)
- Build: `npm run build`; Preview: `npm run preview`

Note: With the current hard-coded Supabase credentials, the app connects to the configured Supabase project immediately. For your own project, switch to `.env`-driven config and update `client.ts` accordingly.

---

## 7) Known Gaps / Tech Debt

- Supabase keys hard-coded in repo (anon key only): move to env for all environments.
- No inventory quantity field/table yet in schema; only `is_available` flag exists. Inventory tracking requires either a `menu_items.quantity` column or a separate stock table and transactional decrement logic.
- No Express backend layer for payments, webhooks, and atomic operations.
- No Realtime subscription wiring in UI for order status updates.
- No manager or menu pages; no cart state; no payment UI.
- No tests configured (unit, integration, or e2e).
- Error boundaries and advanced error handling not implemented.

---

## 8) In-Progress / Recent Changes (as of today)

- Documentation overhaul:
  - Added IEEE-style SRS to `README.md`.
  - Added `PLAN.md` with the SRC document.
- No active server-side development tasks in repo.

---

## 9) Immediate Next Steps (Execution-Ready)

1. Config hygiene: move Supabase URL/anon key to Vite env and update `client.ts` to read from `import.meta.env`.
2. Pages: implement Canteen → Categories → Items browsing using `menu_items`/`menu_categories` (RLS allows public selects of active items).
3. Cart & checkout UX (client-side only initially).
4. Stand up Express API service for payments and webhooks; add Stripe in test mode.
5. Add inventory model (column or table) and implement transactional decrement in webhook handler.
6. Realtime: subscribe to order status channels for student and manager views.
7. Storage: upload/display item images via Supabase Storage.
8. Add lint/type-check CI; basic Vitest setup.

---

## 10) File Map (Key Files)

- App shell: `src/App.tsx`, `src/main.tsx`
- Pages: `src/pages/{Index,Auth,NotFound}.tsx`
- Auth hook: `src/hooks/useAuth.tsx`
- Supabase: `src/integrations/supabase/{client.ts,types.ts}`
- DB schema: `supabase/migrations/*.sql`
- Styles: `src/index.css`, `tailwind.config.ts`
- UI components: `src/components/ui/*`
- Docs: `README.md` (SRS), `PLAN.md` (SRC), `CURRENTSTATE.md`
