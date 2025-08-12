# UniFood — IEEE Software Requirements Specification (SRS)
Version: 1.0 • Date: 2025-08-12

Document Status: Draft for Review

Authoring Org: UniFood Engineering

Approvers: Product Lead, Engineering Lead, Campus Operations Lead

---

Table of Contents
1. Introduction
   1.1 Purpose
   1.2 Scope
   1.3 Definitions, Acronyms, Abbreviations
   1.4 References
   1.5 Overview of Document Structure
2. Overall Description
   2.1 Product Perspective
   2.2 Product Functions
   2.3 User Classes and Characteristics
   2.4 Operating Environment
   2.5 Design and Implementation Constraints
   2.6 Assumptions and Dependencies
3. Specific Requirements
   3.1 External Interface Requirements
   3.2 System Features (Functional Requirements)
   3.3 Nonfunctional Requirements (Quality Attributes)
4. System Architecture and Design Constraints
   4.1 Architectural Overview
   4.2 Component Interactions
   4.3 Data Model Summary
   4.4 API Surface (Initial)
5. Data Requirements
   5.1 Entities and Attributes
   5.2 Data Validation and Integrity Rules
   5.3 Security and Access Control (RLS)
6. Use Cases and User Flows
   6.1 Primary Use Cases
   6.2 State Machines (Order Lifecycle)
7. Requirements Traceability Matrix (RTM)
8. Risk Analysis and Mitigations
9. Deployment and DevOps
10. Future Roadmap
11. Appendices (Glossary, Compliance, Standards)

---

1. Introduction

1.1 Purpose
- Define functional and nonfunctional requirements for UniFood, a campus-focused food pre-order and pickup platform.
- Target audiences: engineering, product, operations, and external stakeholders.

1.2 Scope
- Students: discover active menus, order and pay, receive token, track readiness, provide feedback.
- Canteen managers: manage menus and inventory, view and process orders, update statuses, review feedback.
- Admins: oversight and reporting (post-MVP).

1.3 Definitions, Acronyms, Abbreviations
- MVP: Minimum Viable Product
- RLS: Row Level Security (PostgreSQL/Supabase)
- SRS/SRC: Software Requirements Specification / Requirements Contract
- PSP: Payment Service Provider (e.g., Stripe)
- BFF: Backend-for-Frontend service (Express API) 

1.4 References
- Repository: blueprint-to-life-maker
- Tech stack: React (Vite, TypeScript), Node.js (Express), Supabase (Postgres, Auth, Realtime, Storage)
- IEEE Std 830-1998 (superseded by ISO/IEC/IEEE 29148, used here as guidance)
- Current schema and policies: see `supabase/migrations/*.sql` and `src/integrations/supabase/types.ts`

1.5 Overview of Document Structure
- Sections 2–7 enumerate system context, features, constraints, and testable requirements using FR/NFR identifiers.

---

2. Overall Description

2.1 Product Perspective
- Greenfield SaaS product for universities and colleges.
- Existing codebase: React SPA with Supabase auth integration and a complete relational schema for canteens, menus, orders, order items, and feedback.
- Planned addition: Node/Express backend to orchestrate payments, webhooks, and transactional operations.

2.2 Product Functions
- Authentication and session management.
- Active menu browsing and item details.
- Cart, checkout, payment, and token generation.
- Real-time order status updates and pickup readiness.
- Inventory decrement and out-of-stock management.
- Feedback per dish; order history and reorder.
- Manager console for daily menu prep, item CRUD, quantities, and order queue.

2.3 User Classes and Characteristics
- Student: frequent, mobile-first usage; time-constrained; expects transparency.
- Canteen Manager: console usage during service; needs simple, low-latency operations.
- Admin (future): oversight and reporting; rare but privileged usage.

2.4 Operating Environment
- Client: modern browsers, mobile and desktop (latest Chrome, Safari, Edge, Firefox).
- Server: Node 18+ on Linux containers; Supabase managed Postgres region.
- Network: HTTPS only; Webhooks for PSP; WebSocket (Supabase Realtime) or SSE.

2.5 Design and Implementation Constraints
- Payments-first visibility: orders shown to canteens only after successful payment.
- Security: enforce RLS and least-privilege tokens; no card data storage.
- Performance: queue times peak at class breaks; must remain responsive.
- Accessibility: WCAG AA via shadcn/ui + Radix primitives.

2.6 Assumptions and Dependencies
- Universities permit on-campus ordering and pickup.
- PSP availability in jurisdiction (Stripe or regional equivalent).
- SSO for staff may be added later.

---

3. Specific Requirements

3.1 External Interface Requirements
- User Interface
  - SPA with responsive layout (Tailwind). 
  - Components: buttons, tabs, dialogs, lists, forms (shadcn/ui).
- Software Interfaces
  - Supabase: Auth, Postgres, Realtime, Storage.
  - Payments: Stripe (payment intents + webhooks).
  - Email: Supabase email verification (default) or SMTP provider.
- Communication Interfaces
  - HTTPS REST between client and Express API.
  - Webhooks from PSP to Express.
  - Realtime channels from Supabase to clients.

3.2 System Features (Functional Requirements)

FR-1 Authentication & Profile
- Description: Users sign up/sign in with email/password; verified sessions. Profiles auto-provisioned.
- Stimulus/Response: Submit credentials → session created; profile row ensured.
- Constraints: Email verification required before ordering.
- Acceptance: Given valid credentials, session persists and RLS permits user-only data access.

FR-2 Menu Browsing (Active Items)
- Description: Students view only items marked available under active categories of a canteen.
- Rules: `menu_items.is_available = true` and `menu_categories.is_active = true` and `canteens.is_active = true`.
- Acceptance: List excludes inactive/out-of-stock items.

FR-3 Cart & Checkout
- Description: Add items with quantity and special instructions; compute totals; select pickup estimate.
- Acceptance: Cart total equals sum(order_items.total_price); instructions persisted per line.

FR-4 Payments-First Order Creation
- Description: Create payment intent; upon PSP confirmation, create order and order_items in a DB transaction.
- Rules: Idempotency key per checkout; order visible to canteen only after success.
- Acceptance: No order persists if payment fails/cancels.

FR-5 Token Generation
- Description: Unique token_number for each paid order (per canteen per day); `orders.order_number` auto-generated.
- Acceptance: Tokens are monotonic within canteen day and visible to both parties.

FR-6 Inventory Decrement & Availability
- Description: Decrement item quantities on successful payment; mark unavailable at zero.
- Constraints: Prevent oversell via row-level locks in transaction.
- Acceptance: After last unit sold, item not listed for new carts.

FR-7 Order Status Lifecycle
- Description: `pending → confirmed → preparing → ready → completed | cancelled`.
- Stimulus/Response: Manager updates; student UI reflects realtime.
- Acceptance: State transitions audited; only allowed transitions occur.

FR-8 Feedback per Dish
- Description: Rate (1–5) and comment per dish after completion.
- Acceptance: Feedback visible to managers for their canteens; students see own feedback.

FR-9 Order History & Reorder
- Description: Students view past orders and add items back to cart.
- Acceptance: Reorder replicates items with current availability/prices.

FR-10 Manager Console
- Description: CRUD for items, daily menu bulk select/deselect, quantity updates, orders queue with tokens, mark served/ready.
- Acceptance: Managers affect only their canteens (RLS enforced).

3.3 Nonfunctional Requirements (NFR)
- NFR-1 Performance: P95 API < 300 ms (read) / < 600 ms (write) under peak campus load.
- NFR-2 Availability: 99.5% monthly for ordering core.
- NFR-3 Security: OAuth-equivalent session hardening; HTTPS; CSP; secure cookie for backend session (if used); signed webhooks.
- NFR-4 Privacy: Store minimum PII; GDPR/CCPA alignment.
- NFR-5 Usability: Mobile-first; keyboard accessible; ARIA compliant.
- NFR-6 Observability: Centralized logs, metrics, and error tracking; unique order and checkout ids for correlation.
- NFR-7 Maintainability: Typed APIs (TypeScript), lint/format, modular architecture.
- NFR-8 Portability: Cloud-agnostic hosting for Express; Supabase-managed DB.

---

4. System Architecture and Design Constraints

4.1 Architectural Overview
```
[React SPA] --HTTPS--> [Express API (BFF)] --JWT--> [Supabase Auth]
                                         \--SQL--> [Supabase Postgres (RLS)]
                                          \-Obj--> [Supabase Storage]
[PSP/Stripe] --Webhook--> [Express Webhook Handler] --Txn--> [Postgres]
[Supabase Realtime] <----------------------------> [Clients]
```

4.2 Component Interactions
- Client calls Express for checkout creation and manager operations.
- Express validates stock, creates payment intents, and handles idempotent webhook callbacks to finalize orders.
- Supabase Realtime broadcasts order status changes to subscribed clients.

4.3 Data Model Summary (existing)
- Profiles, Canteens, Menu Categories, Menu Items, Orders, Order Items, Feedback; triggers for `order_number`.

4.4 API Surface (Initial)
- POST `/api/checkout` → Creates payment intent for cart.
- POST `/api/webhooks/stripe` → Validates and finalizes paid orders (idempotent).
- GET `/api/canteens/:id/menu` → Public active menu.
- Auth Manager-only: CRUD `/api/manager/menu-items`, PATCH `/api/manager/orders/:id/status`.
- Auth Student: GET `/api/student/orders`, POST `/api/feedback`.

---

5. Data Requirements

5.1 Entities and Attributes
- Align with Supabase schema in `supabase/migrations/*.sql` and generated types in `src/integrations/supabase/types.ts`.
- Add operational fields (future): `menu_items.quantity` (if inventory tracked per item) or separate stock table.

5.2 Data Validation and Integrity Rules
- Price: DECIMAL(10,2) > 0.
- Rating: 1–5 inclusive.
- Order totals: sum(order_items) = orders.total_amount.
- Foreign key integrity: enforced as per schema.

5.3 Security and Access Control (RLS)
- Students can select/insert/view only their own orders and feedback.
- Managers can manage only resources tied to their canteens.
- Public read for active canteens and available items.

---

6. Use Cases and User Flows

6.1 Primary Use Cases
- UC-1 Sign Up / Sign In: Student creates account, verifies email, gains session.
- UC-2 Browse Menu: Student views canteen, categories, items (available only).
- UC-3 Checkout & Pay: Student pays; webhook finalizes order; token displayed.
- UC-4 Track Order: Student sees status updates; notified when ready.
- UC-5 Provide Feedback: Student rates completed order items.
- UC-6 Manager: Prepare Daily Menu: Bulk activate/deactivate items.
- UC-7 Manager: Fulfill Orders: Update statuses; clear served items.

6.2 State Machines (Order Lifecycle)
```
[pending] -> [confirmed] -> [preparing] -> [ready] -> [completed]
   \------------------------------------------------------> [cancelled]
Rules: only managers can transition except cancellation on payment failure.
```

---

7. Requirements Traceability Matrix (excerpt)
- FR-2 → UI: Menu pages; DB: `menu_items`, `menu_categories`; Policies: public select.
- FR-4 → API: `/api/checkout`, `/api/webhooks/stripe`; DB txn; PSP: Stripe.
- FR-6 → API: webhook handler; DB: inventory fields; UI: availability badges.
- FR-7 → API: manager status endpoint; Realtime: status channel; UI: order tracker.

---

8. Risk Analysis and Mitigations
- Oversell due to race conditions → Postgres row locks in webhook transaction; cart validation on checkout.
- Webhook duplication → Idempotency keys; processed-event ledger.
- Misconfigured RLS → Defense-in-depth; integration tests for policies; service role used only server-side.
- Realtime failures → Fallback polling; reconcile on navigation.
- Adoption friction → Manager-first UX, minimal required fields, keyboard-friendly.

---

9. Deployment and DevOps
- Environments: local, staging, production.
- Hosting: Frontend (Vercel/Netlify); Backend (Fly.io/Render/Railway); DB/Storage/Auth (Supabase).
- CI/CD: Lint, type-check, build; apply DB migrations (Supabase CLI); deploy.
- Secrets: managed via environment variables; webhook secrets rotated.
- Monitoring: logs, metrics, error tracking; database backups enabled.

---

10. Future Roadmap (12–18 months)
- v1: Payments-first flow, manager console, realtime status, feedback, order history, QR pickup v1, push notifications.
- v2: Analytics, promotions, loyalty, scheduled orders, multi-canteen baskets.
- v3: Mobile apps, ML wait-time estimates, kiosk/printer integrations, enterprise admin.

---

11. Appendices

A. Glossary
- Token: Short alphanumeric used for pickup.
- Cart: Client-side collection of intended order items prior to payment.
- Daily Menu: Subset of items activated for a given day/service window.

B. Compliance
- PCI: Delegated to PSP (Stripe). UniFood stores no card PAN.
- Privacy: GDPR/CCPA-aligned practices; minimal data retention.

C. Technology Choices (Justification)
- React + Vite + shadcn/ui: rapid accessible UI; already present.
- Node + Express: orchestration layer for payments and transactions.
- Supabase: managed Postgres with Auth, Realtime, Storage, and RLS.

D. Developer Notes
- Current repo contains React app, Supabase client/types, Tailwind, and a full Postgres schema with RLS and triggers for `orders.order_number`.
- Next steps: add `/server` Express service, define `.env`, integrate Stripe, and implement cart/checkout and manager pages with React Query.
