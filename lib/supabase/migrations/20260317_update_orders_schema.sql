-- =============================================
-- UPDATE ORDERS TABLE FOR PROMO CODES
-- Add promo_code_id and type columns
-- =============================================

-- 1. Add promo_code_id column with foreign key to promo_codes table
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS promo_code_id UUID REFERENCES public.promo_codes(id);

-- 2. Add type column for Liquor/Food differentiation
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS type TEXT;

-- 3. Update existing orders to have a default type based on store_id if possible
UPDATE public.orders 
SET type = 'Liquor' 
WHERE type IS NULL AND store_id IS NOT NULL;

UPDATE public.orders 
SET type = 'Food' 
WHERE type IS NULL;

-- 4. Create index for performance
CREATE INDEX IF NOT EXISTS idx_orders_promo_code_id ON public.orders(promo_code_id);
CREATE INDEX IF NOT EXISTS idx_orders_type ON public.orders(type);
