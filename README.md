# MaterialsJRS62 — JRS Wholesale

Responsive, text-only wholesale catalogue starter using a navy, gold and white theme.

## Included
- Category navigation: Plywood, Hardware, Laminate, False Ceiling
- Product search and rate sorting
- Product rate, unit and available stock display
- Cart quantity controls and order total
- WhatsApp order draft to 7894531187
- Business phone: 9861762376

## Product data
products.json is intentionally an empty array until the original Excel workbook is supplied and verified. Do not publish invented rates or stock.

Each product record uses: id, name, category, rate (number), stock (number), unit.

## Not production-ready
- No Supabase database or secure admin authentication
- No stock IN/OUT ledger or immutable movement history
- No Excel import/export or backup system
- No deployment configuration

Production stock must use append-only movement records and calculate:
Opening Stock + Stock IN - Stock OUT = Closing Balance.

## Preview
Serve this folder with a static web server. Some browsers block fetch() from file:// URLs.

Call: 9861762376
WhatsApp: 7894531187
