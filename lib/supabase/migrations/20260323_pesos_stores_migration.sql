-- =============================================
-- MIGRATION SCRIPT: PESOS STORES & PRODUCTS
-- Location: -26.559276, 27.860405
-- Includes: Stores, Products, Store Promo, Product Promos
-- =============================================

DO $$
DECLARE
    liquor_store_id UUID;
    market_store_id UUID;
    promo_code_id UUID;
    product_id_1 UUID;
    product_id_2 UUID;
    product_id_3 UUID;
    product_id_4 UUID;
BEGIN
    -- 1. Insert Pesos Liquor (Alcohol Store)
    INSERT INTO public.stores (
        name, description, image_url, category, cuisine_types, rating, total_reviews, 
        delivery_time_min, delivery_time_max, delivery_fee, minimum_order, is_open, 
        address, phone, tags, location
    ) VALUES (
        'Pesos Liquor', 
        'Premium spirits and local brews. Fast delivery to your doorstep.', 
        'https://images.unsplash.com/photo-1597075687490-8f973322976b?auto=format&fit=crop&q=80', 
        'liquor', 
        ARRAY['Beer', 'Wine', 'Spirits', 'Mixers'], 
        4.8, 42, 15, 30, 25.00, 100.00, true, 
        'Pesos Complex, Unit 4, Evaton West', 
        '+27 16 555 0101', 
        ARRAY['Premium', 'Fast', 'Local'], 
        ST_SetSRID(ST_MakePoint(27.860405, -26.559276), 4326)::geography
    ) RETURNING id INTO liquor_store_id;

    -- 2. Insert Pesos Market (Restaurant/Food Store)
    INSERT INTO public.stores (
        name, description, image_url, category, cuisine_types, rating, total_reviews, 
        delivery_time_min, delivery_time_max, delivery_fee, minimum_order, is_open, 
        address, phone, tags, location
    ) VALUES (
        'Pesos Market', 
        'Freshly prepared local meals and essential groceries.', 
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80', 
        'restaurant', 
        ARRAY['Local', 'Fast Food', 'Groceries'], 
        4.6, 28, 20, 40, 25.00, 65.00, true, 
        'Pesos Complex, Unit 1, Evaton West', 
        '+27 16 555 0102', 
        ARRAY['Fresh', 'Market', 'Food'], 
        ST_SetSRID(ST_MakePoint(27.860405, -26.559276), 4326)::geography
    ) RETURNING id INTO market_store_id;

    -- 3. Insert Store Promo Code (10% off for Pesos stores)
    INSERT INTO public.promo_codes (
        code, description, discount_type, discount_value, min_order_amount, 
        applicable_store_ids, is_active
    ) VALUES (
        'PESOS10', 
        '10% off all orders at Pesos Liquor & Market', 
        'percentage', 10, 150.00, 
        ARRAY[liquor_store_id, market_store_id], 
        true
    ) RETURNING id INTO promo_code_id;

    -- 4. Insert Products for Pesos Liquor
    INSERT INTO public.products (
        name, brand, description, price, category, image_url, volume, 
        alcohol_content, is_local_brand, tags, store_id, product_type
    ) VALUES 
    (
        'Jameson Select Reserve', 'Jameson', 'Triple distilled Irish whiskey with rich spicy and nutty notes.', 
        489.99, 'spirits', 'https://images.unsplash.com/photo-1527281405158-48d7217e549a?auto=format&fit=crop&q=80', 
        '750ml', 40.0, false, ARRAY['whiskey', 'premium'], liquor_store_id, 'alcohol'
    ) RETURNING id INTO product_id_1;

    INSERT INTO public.products (
        name, brand, description, price, category, image_url, volume, 
        alcohol_content, is_local_brand, tags, store_id, product_type
    ) VALUES 
    (
        'Heineken (12 Pack)', 'Heineken', 'World famous premium lager. Crisp and clean finish.', 
        199.99, 'beer', 'https://images.unsplash.com/photo-1618885472179-5e474019f2a9?auto=format&fit=crop&q=80', 
        '12 x 330ml', 5.0, false, ARRAY['beer', 'lager', 'bulk'], liquor_store_id, 'alcohol'
    ) RETURNING id INTO product_id_2;

    -- 5. Insert Products for Pesos Market
    INSERT INTO public.products (
        name, brand, description, price, category, image_url, volume, 
        alcohol_content, is_local_brand, tags, store_id, product_type
    ) VALUES 
    (
        'Quarter Chicken & Chips', 'Pesos Kitchen', 'Flame-grilled quarter chicken with a side of large fries.', 
        75.00, 'food', 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&q=80', 
        'Large', NULL, true, ARRAY['chicken', 'hot meal'], market_store_id, 'food'
    ) RETURNING id INTO product_id_3;

    INSERT INTO public.products (
        name, brand, description, price, category, image_url, volume, 
        alcohol_content, is_local_brand, tags, store_id, product_type
    ) VALUES 
    (
        'Pesos Burger Special', 'Pesos Kitchen', 'Double beef patty, cheese, and our secret pesos sauce.', 
        89.99, 'food', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80', 
        'Standard', NULL, true, ARRAY['burger', 'special'], market_store_id, 'food'
    ) RETURNING id INTO product_id_4;

    -- 6. Insert Product Promotions (Badges/Highlights)
    INSERT INTO public.promotions (
        title, message, target_type, target_id, badge_text, is_active, priority
    ) VALUES 
    (
        'Weekend Special', 'Get the Jameson Select Reserve at a special price this weekend!', 
        'product', product_id_1, 'Hot Deal', true, 10
    );

    INSERT INTO public.promotions (
        title, message, target_type, target_id, badge_text, is_active, priority
    ) VALUES 
    (
        'Lunch Deal', 'Best value lunch in town!', 
        'product', product_id_3, 'Popular', true, 5
    );

    RAISE NOTICE 'Pesos Liquor (ID: %), Pesos Market (ID: %), and Promo Code (ID: %) created successfully.', liquor_store_id, market_store_id, promo_code_id;

END $$;
