-- =============================================
-- QUELESS ROW LEVEL SECURITY POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- =============================================
-- USERS TABLE POLICIES
-- =============================================

-- Drop existing policies if they exist (for clean re-runs)
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "users_delete_own" ON public.users;

-- Users can read their own profile
CREATE POLICY "users_select_own" ON public.users
    FOR SELECT
    USING (auth.uid() = id);

-- Users can insert their own profile (for signup)
CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT
    WITH CHECK (true);

-- Users can update their own profile
CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (true);

-- Users can delete their own profile
CREATE POLICY "users_delete_own" ON public.users
    FOR DELETE
    USING (auth.uid() = id);

-- =============================================
-- PRODUCTS TABLE POLICIES
-- =============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "products_select_all" ON public.products;
DROP POLICY IF EXISTS "products_insert_authenticated" ON public.products;
DROP POLICY IF EXISTS "products_update_authenticated" ON public.products;
DROP POLICY IF EXISTS "products_delete_authenticated" ON public.products;

-- Anyone can view products (public catalog)
CREATE POLICY "products_select_all" ON public.products
    FOR SELECT
    USING (true);

-- Only authenticated users can manage products (for admin)
CREATE POLICY "products_insert_authenticated" ON public.products
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "products_update_authenticated" ON public.products
    FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "products_delete_authenticated" ON public.products
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- =============================================
-- CARTS TABLE POLICIES
-- =============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "carts_select_own" ON public.carts;
DROP POLICY IF EXISTS "carts_insert_own" ON public.carts;
DROP POLICY IF EXISTS "carts_update_own" ON public.carts;
DROP POLICY IF EXISTS "carts_delete_own" ON public.carts;

-- Users can read their own cart
CREATE POLICY "carts_select_own" ON public.carts
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own cart
CREATE POLICY "carts_insert_own" ON public.carts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own cart
CREATE POLICY "carts_update_own" ON public.carts
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own cart
CREATE POLICY "carts_delete_own" ON public.carts
    FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================
-- ORDERS TABLE POLICIES
-- =============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "orders_select_own" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_own" ON public.orders;
DROP POLICY IF EXISTS "orders_update_own" ON public.orders;
DROP POLICY IF EXISTS "orders_delete_own" ON public.orders;

-- Users can read their own orders
CREATE POLICY "orders_select_own" ON public.orders
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own orders
CREATE POLICY "orders_insert_own" ON public.orders
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own orders
CREATE POLICY "orders_update_own" ON public.orders
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own orders
CREATE POLICY "orders_delete_own" ON public.orders
    FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================
-- PAYMENTS TABLE POLICIES
-- =============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "payments_select_own" ON public.payments;
DROP POLICY IF EXISTS "payments_insert_own" ON public.payments;
DROP POLICY IF EXISTS "payments_update_own" ON public.payments;
DROP POLICY IF EXISTS "payments_delete_own" ON public.payments;

-- Users can read their own payments
CREATE POLICY "payments_select_own" ON public.payments
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own payments
CREATE POLICY "payments_insert_own" ON public.payments
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own payments
CREATE POLICY "payments_update_own" ON public.payments
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own payments
CREATE POLICY "payments_delete_own" ON public.payments
    FOR DELETE
    USING (auth.uid() = user_id);
