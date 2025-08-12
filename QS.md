# Project Q&A

### Which development model are you using and why?
> We are using an iterative-incremental (Scrum-lite) approach because it gives us short feedback loops that fit weekly reviews, while still letting us plan milestones for MVP, Beta, and Final.

### What is your high-level architecture?
> A `React` + `Vite` SPA frontend, a `Node/Express` BFF for orchestration and payments/webhooks, and `Supabase` for `Postgres`, Auth, Realtime, and Storage. Clients talk to `Express` over HTTPS; `Express` talks to `Supabase` and handles `Stripe` webhooks.

### Why choose Supabase instead of rolling your own auth and database?
> `Supabase` gives us managed `Postgres` with Row Level Security, built-in Auth, Realtime, and Storage, which reduces our MVP risk and accelerates delivery while keeping a relational model and `SQL` we understand.

### What frontend libraries and patterns will you follow?
> `React` + `TypeScript` with `TanStack Query` for server state, `Tailwind` + `shadcn/ui` for accessible components, `React Router` for routing, and functional components with hooks. We already wired `QueryClientProvider` and UI providers.

### Why add an Express BFF if the client can call Supabase directly?
> We need server-side orchestration for secure payments, idempotent webhook handling, transactional order creation with inventory decrement, and to keep service-role keys off the client.

### What is your domain model and how does it map to tables?
> Core entities are `profiles`, `canteens`, `menu_categories`, `menu_items`, `orders`, `order_items`, and `feedback`. The current migration aligns with these; `orders` have a `status` enum and auto-generated `order_number`, and we’ll add `token_number` sequencing in the BFF flow.

### How will you ensure security and data isolation?
> We rely on `Supabase` RLS policies already defined: students access only their data, managers access only their canteen resources, and public can read active items. The BFF uses the service role on the server only; the client uses anon keys.

### What did you accomplish this week?
> We set up the `React` app with `Vite` and `TypeScript`, configured `Tailwind` and `shadcn/ui`, added routing and auth pages, integrated `Supabase Auth` with session handling, defined the database schema and RLS via migration, and produced IEEE SRS and an SRC plan.

### What’s your MVP feature set?
> Auth with email verification, browse active menus, cart and checkout, payments-first order creation, token generation, inventory decrement/out-of-stock handling, order status updates, feedback per dish, and order history.

### What risks do you foresee and how will you mitigate them?
> Overselling stock (mitigate with `Postgres` row locks in a transaction during webhook), duplicate webhooks (idempotency keys and processed-event ledger), RLS misconfigurations (tests and least-privilege tokens), and realtime reliability (polling fallback).

### How will you handle payments and when do you persist orders?
> We create a payment intent first; on `payment_succeeded` webhook we run a transaction to insert order and items, decrement inventory, assign a `token_number`, and publish a realtime event. Orders are visible to managers only after payment success.

### What is your testing strategy at this stage?
> Start with unit tests for BFF utilities and order orchestration, integration tests against a test `Supabase` project, and contract tests for endpoints. Later add e2e flows for checkout and status tracking.

### What environment variables and secrets do you require?
> On client: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` (we’ll move from hard-coded values). On server: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, and `APP_URL`. Service role keys remain server-only.

### What is your branching and CI/CD plan?
> Trunk-based with short-lived feature branches, PR reviews, and a CI pipeline for lint/type-check/build and migrations in staging. Deploy frontend to `Vercel/Netlify`, backend to `Fly.io/Render/Railway`, and `Supabase` manages DB.

### How will you validate usability with stakeholders?
> Early clickable flows for Browse, cart, and manager queue; short demos to a representative canteen manager; collect feedback on daily menu toggles and order status actions; iterate weekly.

### What are your next two sprints’ goals?
> **Sprint 1:** Implement menu Browse pages, cart skeleton, move `Supabase` config to env, and stand up the `Express` service scaffold.
>
> **Sprint 2:** Integrate `Stripe` test mode, implement webhook-driven order creation with inventory decrement and token assignment, and build basic manager order queue.