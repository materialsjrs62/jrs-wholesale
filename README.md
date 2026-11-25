# MaterialsJRS62 — JRS Wholesale

Mobile-first, text-only wholesale catalogue in navy, gold and white.

## Customer catalogue
- Plywood, Hardware, Laminate and False Ceiling categories
- Search and rate sorting
- Product rate, size, unit and available stock
- Cart, quantity controls, order total and WhatsApp order draft
- Business phone: 9861762376
- WhatsApp: 7894531187

## Verified source import
The supplied workbook `DOC-20261124-WA0006.xlsx` contains one sheet, `Plywood Final List`, with 8 plywood records, 8×4 size, unit Nos, total quantity 289 and total value ₹10,48,297. The eight records are in `products.json`.

The workbook title says JRS BUILDING MATERIALS — PLYWOOD FIRST FINAL LIST. The other categories are present in the navigation but no records for them were supplied in this workbook.

## Admin dashboard
Open `admin.html` after configuring Supabase:
- Email/password sign-in
- Product create/edit and activate/deactivate
- Stock IN and OUT movements
- Append-only movement history
- Inventory and movement Excel exports, plus inventory CSV
- Stock valuation report by category

Stock is never edited directly in the admin product form. The ledger applies:
Opening Stock + Stock IN − Stock OUT = Closing Balance.
Stock OUT that would make stock negative is rejected. Movement rows have no update/delete policy.

## Supabase setup
1. Create a Supabase project.
2. In Supabase SQL Editor, run the complete script at `supabase/schema.sql`.
3. In Supabase Authentication settings, enable email/password sign-in. Create the owner's user in Authentication > Users.
4. In SQL Editor, promote that exact account:
   `update public.profiles set role = 'admin' where email = 'YOUR_LOGIN_EMAIL';`
5. Copy the Project URL and anon/publishable key into `supabase-config.js`.
6. Never use or publish the Supabase service_role/secret key in browser code.
7. Test login at `/admin.html`, product edits, stock IN, stock OUT, history, and Excel exports.

The SQL script seeds the eight imported plywood products and their opening stock. The opening movement insert is idempotent using a source key. Run the SQL script once on a new project; if rerun, it will not duplicate the opening movement rows.

## Security notes
- Public users can read active products only.
- Only authenticated users with a profile role of admin or staff can use admin data actions.
- New auth users receive the least-privilege staff role automatically. Grant admin role only to the owner.
- Stock movement history is append-only through Row Level Security.
- The anon key is designed for browser use with RLS. Never expose service_role credentials.

## Current deployment state
GitHub source is committed. Supabase is not connected until the owner creates a project and supplies its public Project URL and anon/publishable key. GitHub Pages hosting has not yet been enabled or verified. Do not treat this as a live production website.

Call: 9861762376
WhatsApp: 7894531187
