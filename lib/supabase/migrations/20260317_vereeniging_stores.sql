-- =============================================
-- VEREENIGING LIQUOR STORES MIGRATION
-- Setup stores for location-based discovery
-- =============================================

-- Ensure stores table exists (it should from previous migrations)
-- DO NOT RECREATE, JUST INSERT

-- 1. Insert Vereeniging Liquor Stores
-- We use ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography for location

INSERT INTO public.stores (name, description, image_url, category, cuisine_types, rating, total_reviews, delivery_time_min, delivery_time_max, delivery_fee, minimum_order, is_open, address, phone, tags, location) VALUES
('V-Town Liquor', 'Your local Vereeniging liquor specialist. Fast delivery in the CBD.', '', 'liquor', ARRAY['Beer', 'Wine', 'Spirits'], 4.7, 120, 15, 25, 25.00, 50.00, true, '15 Voortrekker St, Vereeniging', '+27 16 421 1234', ARRAY['CBD', 'Fast Delivery'], ST_SetSRID(ST_MakePoint(27.9310, -26.6745), 4326)::geography),

('Three Rivers Drinks', 'Premium selection in the heart of Three Rivers.', '', 'liquor', ARRAY['Wine', 'Craft Beer'], 4.5, 85, 20, 35, 30.00, 100.00, true, 'Three Rivers Mall, Nile Dr', '+27 16 454 5678', ARRAY['Premium', 'Three Rivers'], ST_SetSRID(ST_MakePoint(27.9650, -26.6650), 4326)::geography),

('Meyerton Express', 'Express delivery from Meyerton to surrounding areas.', '', 'liquor', ARRAY['Bulk', 'Party Supplies'], 4.2, 45, 45, 60, 35.00, 200.00, true, '52 Galloway St, Meyerton', '+27 16 362 9012', ARRAY['Bulk', 'Meyerton'], ST_SetSRID(ST_MakePoint(28.0100, -26.5800), 4326)::geography),

('Arcon Park Alcohol', 'Curated craft spirits and local favorites.', '', 'liquor', ARRAY['Craft Spirits', 'Local'], 4.8, 30, 25, 40, 30.00, 75.00, true, 'Arcon Park Shopping Centre', '+27 16 428 3456', ARRAY['Craft', 'Local'], ST_SetSRID(ST_MakePoint(27.9400, -26.6500), 4326)::geography);

-- 2. Link existing alcohol products to V-Town Liquor
-- First, get the ID of V-Town Liquor
DO $$
DECLARE
    vtown_id UUID;
    threerivers_id UUID;
    arcon_id UUID;
BEGIN
    SELECT id INTO vtown_id FROM public.stores WHERE name = 'V-Town Liquor' LIMIT 1;
    SELECT id INTO threerivers_id FROM public.stores WHERE name = 'Three Rivers Drinks' LIMIT 1;
    SELECT id INTO arcon_id FROM public.stores WHERE name = 'Arcon Park Alcohol' LIMIT 1;

    -- Update all existing products to be alcohol and linked to V-Town by default
    UPDATE public.products 
    SET product_type = 'alcohol', store_id = vtown_id
    WHERE product_type = 'alcohol' OR store_id IS NULL;

    -- Also link some to Three Rivers
    INSERT INTO public.products (name, brand, description, price, category, image_url, volume, alcohol_content, is_local_brand, tags, product_type, store_id)
    SELECT name, brand, description, price + 5, category, image_url, volume, alcohol_content, is_local_brand, tags, 'alcohol', threerivers_id
    FROM public.products 
    WHERE store_id = vtown_id AND category IN ('wine', 'beer') LIMIT 5;

    -- 3. Create unique products for Arcon Park Alcohol
    INSERT INTO public.products (name, brand, description, price, category, image_url, volume, alcohol_content, is_local_brand, tags, product_type, store_id) VALUES
    ('Inverroche Amber', 'Inverroche', 'Handcrafted fynbos gin from Still Bay. Rich and complex.', 549.99, 'spirits', 'assets/placeholder.png', '750ml', 43.0, true, ARRAY['gin', 'fynbos', 'premium'], 'alcohol', arcon_id),
    ('Jack Black Atlantic Weiss', 'Jack Black', 'Traditional Belgian-style wheat beer. Zesty and refreshing.', 42.99, 'beer', 'assets/placeholder.png', '330ml', 4.7, true, ARRAY['craft beer', 'weiss', 'local'], 'alcohol', arcon_id),
    ('Cape Town Gin Rooibos Red', 'Cape Town Gin', 'Infused with organic rooibos. Uniquely South African.', 489.99, 'spirits', 'assets/placeholder.png', '750ml', 43.0, true, ARRAY['gin', 'rooibos', 'local'], 'alcohol', arcon_id),
    ('Stellenbrau Jonkers Weiss', 'Stellenbrau', 'Award-winning wheat beer from Stellenbosch.', 39.99, 'beer', 'assets/placeholder.png', '330ml', 4.5, true, ARRAY['craft beer', 'local'], 'alcohol', arcon_id);

END $$;
