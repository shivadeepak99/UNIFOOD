# UniFood – Software Requirements and Concept (SRC) Document
Version: 0.1 • Date: 2025-08-12

---

## Executive Summary

- Product: UniFood is a campus-focused, pre-order and pickup food ordering platform connecting students with on-campus canteens. Students browse active menus, place and pay for orders, receive a token, and get real-time readiness updates. Canteen managers manage menus, inventory, and fulfill orders efficiently.
- Target Users:
  - Students: Fast, reliable, queue-free ordering with transparent wait times.
  - Canteen Managers: Digital menu and inventory control, streamlined order processing, and feedback insights.
  - University Admins: Oversight, compliance, and reporting.
- Market Potential: Large TAM across universities and colleges. Strong product-market fit in high-density, time-sensitive environments (breaks between classes). Monetization through SaaS + per-order fees with potential for cross-campus scale.

---

## Problem Statement

- Long queues and unpredictable wait times during peak hours.
- Manual processes for menu updates, stock tracking, and order handling.
- Low transparency: students cannot see item availability or order readiness.
- No unified feedback loop from students to canteens for quality improvement.
- Fragmented payments and reconciliation; managers lack real-time dashboards.

---

## Solution Overview

- Student app: authenticated access, real-time active menu, cart + payment, tokenized pickup, order status visibility, and feedback per dish.
- Manager console: add/edit dishes, daily menu selection (bulk select/deselect), live order queue with tokens, status updates (pending → confirmed → preparing → ready → completed), inventory updates.
- System-level: payments-first flow (orders visible to canteen only after successful payment), automatic token generation per order, inventory decrement on purchase, out-of-stock logic.

---

## Feature Breakdown

### MVP
- Authentication: email/password sign-in/up (Supabase Auth). Email verification.
- Menu browsing: view only active items; item details with price, image, allergens, prep time.
- Cart + checkout: quantity selection, special instructions, payment, and expected pickup time.
- Token generation: unique token per order; order_number auto-generated; token displayed to both parties.
- Inventory management: decrement on purchase; auto mark item unavailable when quantity reaches zero.
- Order status: live updates (pending/confirmed/preparing/ready/completed/cancelled); student visibility for “ready”.
- Feedback: per-dish feedback with rating and comments.
- Order history: student can reorder from history quickly.
- Manager operations: add dishes, update quantities, prepare daily menu (select all + deselect), view orders and tokens, mark served/ready, clear served.

### Nice-to-Have (Future)
- Push notifications (web/app) for status changes.
- QR code pickup verification (scan token).
- Scheduled orders and time slots.
- Promotions/coupons; campus-specific offers.
- Multi-canteen basket (single payment split).
- Analytics dashboards (popular items, peak times).
- Wait-time estimation ML based on historical prep times and load.
- Manager mobile app and kiosk mode.

### Monetization Opportunities
- SaaS subscription per canteen/location.
- Per-order transaction fee (percentage or fixed).
- Featured placement/promotions for canteens or items.
- Paid analytics tier for managers/universities.
- Add-on modules: loyalty, subscriptions/meals plans.

---

## User Flow

### Student
1. Sign up → email verification → sign in.
2. Browse canteens → select a canteen → view active menu.
3. Add items to cart → specify quantity and special instructions.
4. Select pickup slot (or auto estimate) → pay.
5. Receive order token and status updates → pickup when “ready”.
6. Leave feedback on items.

### Canteen Manager
1. Sign in → access manager console.
2. Add/edit dishes; attach images; update prices and allergens.
3. Prepare daily menu (bulk select/deselect).
4. Monitor live orders queue (with tokens and statuses).
5. Update status, mark ready, and complete orders.
6. Review feedback and adjust menu or operations.

---

## System Architecture

### High-Level Components
- Frontend (React + Vite + Tailwind + shadcn/ui)
  - Student UI: browse, cart, payment, tracking.
  - Manager UI: menu, inventory, order queue, feedback.
  - State: TanStack Query for server state; React Hook Form for forms.
- Backend (Node.js + Express)
  - REST API gateway (BFF) to Supabase.
  - Stripe (or preferred PSP) webhook handler for payment events.
  - Business logic: atomic order creation, inventory decrement, token issuance.
  - Optional: Redis for rate limiting, queues (BullMQ) for async tasks.
- Database (Supabase Postgres)
  - Auth, RLS policies, real-time channels, storage for images.
  - Existing schema aligns to canteens, menu categories/items, orders, order items, feedback, profiles.
- Payment Provider (Stripe/UPI aggregator)
  - Payment intent creation, secure redirects, webhook confirmation.
- Realtime
  - Supabase Realtime channels for status updates to clients.

### Text Architecture Diagram
```
[Client: React SPA]
  |  (HTTPS)
  v
[Express API]
  |--(JWT)--> [Supabase Auth]
  |--(PG)-->  [Supabase Postgres (RLS)]
  |--(Storage)-> Images
  |<--(Realtime)--> Clients (status updates)
  |
  |<--(Webhook)-- [Stripe/PSP]
  v
[Queues/Workers (optional: BullMQ + Redis)]
```

---

## Core Data Model (from current repo)

- profiles(id, user_id, full_name, email, role, phone, student_id, timestamps)
- canteens(id, name, description, location, manager_id(FK profiles), opening_hours, is_active, timestamps)
- menu_categories(id, canteen_id, name, description, sort_order, is_active, timestamps)
- menu_items(id, category_id, name, description, price, image_url, is_available, preparation_time, nutritional_info, allergens[], timestamps)
- orders(id, order_number, student_id(FK profiles), canteen_id(FK canteens), status, total_amount, special_instructions, est/actual pickup time, token_number, timestamps)
- order_items(id, order_id, menu_item_id, quantity, unit_price, total_price, special_requests, created_at)
- feedback(id, order_id, student_id, canteen_id, rating, comment, created_at)
- Functions: generate_order_number(), set_order_number() trigger

---

## Key Sequences

### Place Order (payments-first)
1. Client creates cart → calls Express “create checkout”.
2. Express validates items + availability → creates Payment Intent.
3. On payment success webhook:
   - Create order + order_items in a DB transaction.
   - Decrement item quantities; if 0, mark as unavailable.
   - Generate token_number (per canteen per day).
   - Publish realtime event to manager and student.

### Update Status
- Manager updates order status via UI → Express → Supabase (RLS enforced).
- Realtime update broadcasts to student UI.

---

## Tech Stack Justification

- React + Vite + Tailwind + shadcn/ui: Fast development, strong DX, accessible components, responsive UI. Already used in repo.
- Express (Node): Flexible BFF layer to orchestrate payments, webhooks, and DB transactions beyond simple client-to-DB calls. Allows vendor-agnostic payments and integrations.
- Supabase (Postgres + Auth + Realtime + Storage): Managed relational DB with RLS, built-in auth, real-time channels, and file storage; speeds up MVP with production-grade primitives.
- TanStack Query: Server state management and caching with request deduplication and retries.
- Stripe (or regional PSP): PCI-compliant payments with webhooks and dispute handling.
- Redis + BullMQ (optional): Rate limiting, queues for spikes and async jobs.
- TypeScript: Type safety across the stack; existing DB types are generated in repo.

---

## Feasibility Analysis

- Technical: High. Current repo already has auth, routing, UI kit, and a robust DB schema and RLS. Remaining complexity is payments-first ordering and atomic inventory logic.
- Operational: Moderate. Requires onboarding canteens, staff training for order console, configuring menus and inventory practices.
- Legal/Compliance: Payments (PCI via Stripe), data privacy (GDPR/CCPA-like), food safety disclaimers, refund policies, and campus agreements.

---

## Challenges & Risks

- Concurrency: Overselling when multiple students buy the last unit.
- Payments: Handling failed/intents, refunds, chargebacks; idempotency around webhooks.
- RLS & Security: Misconfigured policies could expose or block data.
- Realtime Reliability: Network issues or stale UI state during peaks.
- Adoption: Canteen staff may resist process changes; training required.
- Regulatory: Data retention policies and consumer protection laws.

---

## Proposed Solutions to Risks

- Concurrency: Use Postgres transactions with row-level locks (SELECT ... FOR UPDATE) in an RPC/Express transaction. Validate stock at webhook time, not only at checkout.
- Payments: Enforce idempotent keys; verify webhook signatures; only create orders after confirmed payment events.
- RLS: Defense-in-depth—service-role keys only in backend; thorough policy tests; least-privilege tokens on client.
- Realtime: Fallback to polling; optimistic UI guarded by server reconciliation; exponential backoff.
- Adoption: Simple, role-driven UI; clear “Ready” workflows; tooltips and quick guides; pilot with one canteen.
- Compliance: Use Stripe-hosted components; privacy policy and ToS; secure secret management and audit logs.

---

## Scalability Plan

- Database:
  - Proper indexes (already present), partition orders by month/semester if needed.
  - Read replicas for dashboards; caching for menus.
- Backend:
  - Horizontal scaling for Express behind a load balancer; stateless services; queue workers for webhooks/spikes.
  - Rate limiting and circuit breakers; graceful degradation.
- Frontend:
  - Code-splitting; CDN assets; partial hydration.
- Observability:
  - Centralized logging, metrics, tracing (OpenTelemetry), SLOs, alerting.
- Data:
  - Event-driven architecture later (order_created, status_changed) for analytics.

---

## Deployment Plan

### Environments
- Local: Vite dev server (port 8080), Express on 4000, Supabase project env vars.
- Staging: Feature flags, test cards, small pilot canteens.
- Production: Separate Supabase project, rotated keys, backups enabled.

### Suggested Hosting
- Frontend: Vercel/Netlify/Cloudflare Pages.
- Backend: Fly.io/Railway/Render (auto-deploy from main).
- Database/Storage/Auth: Supabase managed service.
- Payments: Stripe live mode with restricted API keys.
- CDN: Supabase Storage CDN/Cloudflare R2 if needed.

### Secrets & CI/CD
- GitHub Actions: lint, type-check, build, run migrations (Supabase CLI), deploy.
- Env Vars: SUPABASE_URL, SUPABASE_ANON_KEY (client), SUPABASE_SERVICE_ROLE (server), STRIPE_SECRET, STRIPE_WEBHOOK_SECRET, APP_URL, etc.
- Backups: Daily automatic DB backups; restore tests quarterly.

---

## Future Roadmap (12–18 Months)

### 0–3 Months (MVP)
- Payments-first order flow; token generation; inventory decrement; manager console; feedback.
- Push notifications; QR pickup v1.

### 3–6 Months
- Analytics dashboards; scheduled orders; promotions/coupons; loyalty/stamp cards.
- Multi-canteen support; bulk menu tools; CSV import.

### 6–12 Months
- Mobile apps (React Native/Capacitor) for managers/students.
- ML wait-time estimates; recommendation engine.
- Kiosk mode; printer integrations for order tickets.

### 12–18 Months
- Multi-campus rollout; enterprise admin portal; SSO for staff.
- Data warehouse + BI; SLA-backed support; marketplace partnerships.

---

## Appendix

### A) Glossary
- Token: Short numeric identifier for pickup.
- RLS: Row Level Security; DB-level per-user access control.
- PSP: Payment Service Provider (e.g., Stripe).
- BFF: Backend-for-Frontend; Express layer for orchestration.

### B) Roles & Permissions (from schema + policies)
- Student (profiles.role = student): view active menu, create orders for self, view own orders and order items, create feedback for own orders.
- Canteen Manager (profiles.role = canteen_manager): manage own canteen, categories, items; view/update orders for their canteen; view feedback for their canteen.
- Admin: elevated management (reserved for future).

### C) API Endpoints (proposed, Express)
- POST `/api/checkout`
  - Input: `canteenId`, `items[{menuItemId, qty, specialRequests}]`, `pickupTime`
  - Output: `paymentIntent` client secret or redirect URL
- POST `/api/webhooks/stripe`
  - Validates event; on payment_success: create order + items (transaction), decrement stock, set token_number, emit realtime
- GET `/api/canteens/:id/menu` (public)
- POST `/api/manager/menu-items` (auth: manager)
- PATCH `/api/manager/menu-items/:id` (auth: manager)
- PATCH `/api/manager/orders/:id/status` (auth: manager)
- GET `/api/student/orders` (auth: student)
- POST `/api/feedback` (auth: student)

### D) Inventory & Token Logic
- Inventory decrement happens only after confirmed payment (webhook).
- If quantity reaches zero, set `menu_items.is_available = false`.
- `token_number`: per-canteen, per-day incremental counter (store `last_token_number` in a small `canteen_daily_state` table or derive via a transactional function).
- `order_number`: already generated by `generate_order_number()`.

### E) Alignment with Current Repo
- Frontend app, routing, and auth hook exist.
- Supabase schema covers canteens, menus, orders, feedback, and policies.
- Next engineering tasks:
  - Build Express API and wire payments/webhooks.
  - Connect UI to Supabase via the API (React Query).
  - Implement cart, checkout, order tracking, manager console pages.
  - Add images to each dish (supabase storage) and feedback UIs.
  - Realtime channels for order status.

### F) Legal & Policy Notes
- Payments: rely on PSP for PCI scope; store no card data.
- Data Privacy: explicit privacy policy; encrypted transport; minimal PII.
- Food Safety: disclaimers for allergens and nutritional info accuracy.
- Refunds: well-defined policy; admin tools for adjustments.

---

## Text-Based Sequence: “Create Order (Successful)”

Student → Frontend → Express: `POST /api/checkout` (cart)

Express → Supabase: validate stock (read-only)

Express → Stripe: create payment intent

Stripe → Student: pay (redirect or hosted form)

Stripe → Express (webhook): `payment_succeeded`

Express (txn):
- Insert order, order_items
- Decrement inventory with row lock; mark unavailable if 0
- Assign `token_number`
- Publish realtime “order_created/confirmed”

Express → Frontend (students/managers): realtime update rendered
