-- =============================================
-- UPDATE PROMOTIONS TO SUPPORT MULTIPLE PRODUCTS
-- =============================================

-- 1. Add the new target_ids column (only for products)
ALTER TABLE public.promotions ADD COLUMN IF NOT EXISTS target_ids UUID[];

-- 2. Migrate the data from target_id to target_ids for product-type promotions
UPDATE public.promotions
SET target_ids = ARRAY[target_id]
WHERE target_id IS NOT NULL 
AND target_type = 'product';

-- Note: We keep target_id for store-type promotions as requested.
