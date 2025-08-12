# UniFood —  Software Requirements Specification (SRS)



## 1. Introduction

- Purpose: Define the services and constraints for UniFood, a campus food pre-order and pickup platform, to ensure we build what stakeholders actually need.
- Scope: Student ordering (browse → cart → pay → token → pickup), canteen management (menu, inventory, orders), feedback loop.
- Definitions: RLS = Row Level Security; PSP = Payment Service Provider; BFF = Backend-for-Frontend (Express API).
- References: IEEE SRS guidance; Project README (IEEE-style SRS), PLAN.md (SRC), CURRENTSTATE.md; Supabase schema and policies in `supabase/migrations/*`.

## 2. Overall Description

- Product Perspective: React SPA + Express BFF + Supabase (Postgres/Auth/Realtime/Storage) + Stripe. Orders become visible to canteens only after confirmed payment.
- Users: Students (place orders), Canteen Managers (fulfill/manage), Admins (future oversight).
- Operating Environment: Modern browsers; Node 18+ server; Supabase managed Postgres.
- Assumptions/Dependencies: Campus permission; PSP availability; images via Supabase Storage; RLS enforces access.

## 3. Functional Requirements (Black-box)

FR-1 Authentication & Profile
- Input: email, password. Output: session; profile row exists. Rule: email verification before ordering.

FR-2 View Active Canteens and Menus
- Only `is_active=true` canteens/categories/items are listed; unavailable items are hidden or marked.

FR-3 Cart Management
- Add/remove items; set quantity; optional special requests per line; compute totals.

FR-4 Checkout (Payments-First)
- Create payment intent. Only on PSP confirmation is an order persisted.

FR-5 Order Creation (Webhook Transaction)
- On `payment_succeeded`: insert order + items, decrement inventory, assign token_number, publish realtime event.

FR-6 Order Status Lifecycle
- States: pending → confirmed → preparing → ready → completed | cancelled. Students see live status.

FR-7 Feedback per Item
- After completion, student submits rating (1–5) and optional comment; managers can read feedback for their canteen.

FR-8 Order History & Reorder
- Students can view past orders and re-add available items to cart with current prices.

FR-9 Manager Menu & Inventory
- Managers can create/update items, toggle daily availability, and adjust quantities.

FR-10 Manager Order Queue
- View paid orders with tokens; update statuses and mark served/complete.

All FRs are governed by RLS: students see only their data; managers only their canteen’s.

## 4. Non-functional Requirements (Verifiable)

- NFR-1 Performance: P95 API read < 300 ms; write < 600 ms under peak.
- NFR-2 Availability: 99.5% monthly for ordering core.
- NFR-3 Security/Privacy: HTTPS, signed webhooks, least-privilege keys, RLS; no card data stored.
- NFR-4 Usability/Accessibility: Mobile-first; WCAG AA via Radix/shadcn.
- NFR-5 Maintainability: TypeScript across stack; lint/CI; modular code; documented APIs.
- NFR-6 Scalability: Stateless BFF; DB indexes; realtime with polling fallback.

## 5. External Interface Requirements

- UI: React + Tailwind + shadcn/ui components; router-based navigation.
- API: Express endpoints (initial): `POST /api/checkout`, `POST /api/webhooks/stripe`, `GET /api/canteens/:id/menu`, manager CRUD, student orders, feedback.
- Data: Supabase Postgres (tables per schema), Storage for images.
- External Systems: Stripe/PSP (payment intents + webhooks); Email (verification via Supabase).

## 6. Constraints

- Tech stack fixed: React/Express/Supabase/Stripe.
- Payments-first visibility to canteens.
- Enforce RLS; service-role keys server-side only.

## 7. Requirements Engineering (Week 1 Summary)

- Elicitation: Notes from stakeholders (students/managers), campus constraints, Week 1 planning.
- Specification: This SRS + detailed IEEE SRS in README; domain captured in schema.
- Validation: Professor review; peer review; small UI prototype walkthrough.
- Change: Versioned docs; RTM seeds; issues tracked with clear FR/NFR IDs.

## 8. Decision Model (Example)

Decision Table: Show order to manager queue

| Rule | Payment succeeded | Inventory decremented | Canteen matches manager | Action                  |
|-----:|-------------------|------------------------|-------------------------|-------------------------|
| R1   | Yes               | Yes                    | Yes                     | Display in live queue   |
| R2   | Yes               | No                     | Any                     | Log error; hold display |
| R3   | No                | Any                    | Any                     | Do not display          |
| R4   | Yes               | Yes                    | No                      | Hide; deny access       |

## 9. Traceability Seeds (Sample)

- FR-4/FR-5 → Endpoints `/api/checkout`, `/api/webhooks/stripe`; Tables `orders`, `order_items`; Event: realtime.
- FR-6 → Column `orders.status`; Realtime subscription; Manager UI.
- FR-7 → Table `feedback`; RLS policies.

## 10. Acceptance & Change Control

- Acceptance: Feature demos against FR/NFR checklists; walkthrough with canteen rep.
- Change Control: Requests logged with rationale; SRS updated with version/date and impacted FR/NFR.

---

Short, complete, and verifiable: this SRS defines what the system must do in Week 1 planning without prescribing implementation details.
