-- =============================================
-- ADD DISCOUNT COLUMN TO ORDERS TABLE
-- =============================================

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS discount NUMERIC NOT NULL DEFAULT 0;
