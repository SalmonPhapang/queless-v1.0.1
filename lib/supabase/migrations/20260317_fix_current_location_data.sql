-- =============================================
-- FIX TEST DATA FOR CURRENT LOCATION
-- Location: -26.5581994, 27.8652677
-- =============================================

-- 1. Create a "Home Base" Liquor Store exactly at your location for testing
INSERT INTO public.stores (name, description, category, rating, is_open, address, location)
VALUES ('Test Liquor Express', 'Testing store at your exact location', 'liquor', 5.0, true, 'Current Test Location', '-26.5581994, 27.8652677')
ON CONFLICT DO NOTHING;

-- 2. Create a "Home Base" Restaurant exactly at your location for testing
INSERT INTO public.stores (name, description, category, rating, is_open, address, cuisine_types, location)
VALUES ('Test Mzansi Kitchen', 'Testing restaurant at your exact location', 'restaurant', 4.9, true, 'Current Test Location', ARRAY['Local', 'Burgers'], '-26.5581994, 27.8652677')
ON CONFLICT DO NOTHING;

-- 3. Link existing products to these new test stores
DO $$
DECLARE
    liquor_store_id UUID;
    food_store_id UUID;
BEGIN
    SELECT id INTO liquor_store_id FROM public.stores WHERE name = 'Test Liquor Express' LIMIT 1;
    SELECT id INTO food_store_id FROM public.stores WHERE name = 'Test Mzansi Kitchen' LIMIT 1;

    -- Link all alcohol products that don't have a store or are currently linked to others
    -- This ensures you see products immediately
    UPDATE public.products 
    SET store_id = liquor_store_id 
    WHERE product_type = 'alcohol';

    -- Add some food products if none exist, or link existing food ones
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE product_type = 'food' AND store_id = food_store_id) THEN
        INSERT INTO public.products (name, description, price, category, product_type, store_id, image_url)
        VALUES 
        ('Test Quarter Chicken', 'Flame grilled with peri-peri', 65.00, 'Main', 'food', food_store_id, ''),
        ('Test Mega Burger', 'Double patty with cheese', 85.00, 'Burgers', 'food', food_store_id, ''),
        ('Test Chips', 'Large portion of golden chips', 35.00, 'Sides', 'food', food_store_id, '');
    END IF;
END $$;
