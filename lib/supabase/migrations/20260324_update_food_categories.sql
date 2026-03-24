-- =============================================
-- UPDATE FOOD CATEGORIES FOR PESOS MARKET
-- =============================================

-- Update Quarter Chicken & Chips
UPDATE public.products 
SET category = 'chicken'
WHERE name = 'Quarter Chicken & Chips' AND brand = 'Pesos Kitchen';

-- Update other potential food items (examples)
UPDATE public.products 
SET category = 'burgers'
WHERE name ILIKE '%burger%' AND product_type = 'food';

UPDATE public.products 
SET category = 'pizza'
WHERE name ILIKE '%pizza%' AND product_type = 'food';

UPDATE public.products 
SET category = 'drinks'
WHERE (name ILIKE '%coke%' OR name ILIKE '%juice%' OR name ILIKE '%water%') AND product_type = 'food';

UPDATE public.products 
SET category = 'groceries'
WHERE (name ILIKE '%milk%' OR name ILIKE '%bread%' OR name ILIKE '%eggs%') AND product_type = 'food';
