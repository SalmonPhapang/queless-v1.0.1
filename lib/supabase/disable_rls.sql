-- Disable Row Level Security and remove all policies
-- This allows unrestricted access to all tables for development

-- Disable RLS on all tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies on users table
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Anyone can insert users" ON public.users;
DROP POLICY IF EXISTS "Service role can manage users" ON public.users;

-- Drop all existing policies on products table
DROP POLICY IF EXISTS "Anyone can view products" ON public.products;
DROP POLICY IF EXISTS "Only authenticated users can insert products" ON public.products;
DROP POLICY IF EXISTS "Only authenticated users can update products" ON public.products;

-- Drop all existing policies on carts table
DROP POLICY IF EXISTS "Users can view own cart" ON public.carts;
DROP POLICY IF EXISTS "Users can manage own cart" ON public.carts;
DROP POLICY IF EXISTS "Users can insert into own cart" ON public.carts;
DROP POLICY IF EXISTS "Users can update own cart" ON public.carts;
DROP POLICY IF EXISTS "Users can delete own cart" ON public.carts;

-- Drop all existing policies on orders table
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;

-- Drop all existing policies on payments table
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can create own payments" ON public.payments;

-- Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'products', 'carts', 'orders', 'payments');

-- Output: rowsecurity should be 'false' for all tables
