-- =============================================
-- ADD STORE LINK TO ORDERS
-- Link food orders to specific stores
-- =============================================

-- Add store_id to orders table (nullable, as alcohol orders might not have it)
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE SET NULL;

-- Create index for faster queries by store
CREATE INDEX IF NOT EXISTS idx_orders_store_id ON public.orders(store_id);
