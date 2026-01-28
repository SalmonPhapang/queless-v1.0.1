# 🗄️ Database Setup Instructions

## Step 1: Insert Product Data

Your products table is empty. You need to populate it with sample data.

1. Open your **Supabase Dashboard** → SQL Editor
2. Copy and paste the contents of `lib/supabase/insert_products.sql`
3. Click **Run** to insert 15 South African beverage products

This will add products including:
- Castle Lager, Black Label, Windhoek (Beers)
- Nederburg Cabernet, KWV Chenin Blanc, Amarula (Wines)
- KWV Brandy, Jägermeister, Johnnie Walker (Spirits)
- Coca-Cola, Ginger Ale, Tonic Water (Mixers)
- Simba Chips, Biltong (Snacks)

## Step 2: Check Database Connection

The app now includes automatic database testing on launch. Check your **Debug Console** for:

```
🔍 Starting Database Connection Tests...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Testing public.products table...
✅ Products table: ACCESSIBLE
   Schema: public.products
   Records found: 15
   Sample product: Castle Lager
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Database Tests Completed!
```

## Expected Test Results

After inserting the products, you should see:
- ✅ Products table: 15 records
- ✅ Users table: Accessible (empty)
- ✅ Carts table: Accessible (empty)
- ✅ Orders table: Accessible (empty)
- ✅ Payments table: Accessible (empty)

## Troubleshooting

If you see errors like "Could not find the table in the schema cache":
1. Verify tables exist in Supabase Dashboard → Table Editor
2. Ensure all tables are in the **public** schema (not a different schema)
3. Check that RLS (Row Level Security) policies allow reading data
4. Run the SQL migrations in `lib/supabase/supabase_tables.sql` if tables don't exist

## What's New

- **database_test.dart**: Comprehensive database connection testing utility
- **insert_products.sql**: SQL script to populate products with South African beverages
- **Automatic testing**: App now runs database tests on launch
- **Detailed logging**: All service operations now log to Debug Console

The app will now load products from your Supabase database instead of using local data!
