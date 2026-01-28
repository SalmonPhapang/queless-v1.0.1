-- =============================================
-- INSERT SAMPLE STORE AND FOOD PRODUCT DATA
-- =============================================

-- Add missing stock column to products table if it doesn't exist
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS stock INTEGER NOT NULL DEFAULT 0;

-- Add missing brand column for food products if it doesn't exist
ALTER TABLE public.products 
ALTER COLUMN brand DROP NOT NULL;

-- Enable RLS on stores table (idempotent)
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then recreate them
DROP POLICY IF EXISTS "Allow authenticated users to view stores" ON public.stores;
DROP POLICY IF EXISTS "Allow authenticated users to insert stores" ON public.stores;
DROP POLICY IF EXISTS "Allow authenticated users to update stores" ON public.stores;
DROP POLICY IF EXISTS "Allow authenticated users to delete stores" ON public.stores;

-- Create RLS policies for stores
CREATE POLICY "Allow authenticated users to view stores"
ON public.stores FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to insert stores"
ON public.stores FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update stores"
ON public.stores FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to delete stores"
ON public.stores FOR DELETE
TO authenticated
USING (true);

-- Insert sample restaurants/stores (only if they don't exist)
INSERT INTO public.stores (name, description, image_url, category, cuisine_types, rating, total_reviews, delivery_time_min, delivery_time_max, delivery_fee, minimum_order, is_open, address, phone, tags)
SELECT * FROM (VALUES
  ('Steers Burgers', 'Premium flame-grilled burgers and chips. Home of the 100% pure beef burger', '', 'restaurant', ARRAY['Burgers', 'Fast Food'], 4.3, 250, 25, 35, 25.00, 50.00, true, '123 Main Road, Johannesburg', '+27 11 123 4567', ARRAY['Popular', 'Fast Food']),
  ('Nandos Peri-Peri', 'Legendary flame-grilled PERi-PERi chicken. Made to order with various heat levels', '', 'restaurant', ARRAY['Portuguese', 'Chicken', 'Grills'], 4.6, 350, 30, 40, 30.00, 60.00, true, '45 Market Street, Cape Town', '+27 21 456 7890', ARRAY['Popular', 'Grilled Chicken']),
  ('Debonairs Pizza', 'The home of Anything Goes pizza. Create your own masterpiece or choose a classic', '', 'restaurant', ARRAY['Pizza', 'Italian'], 4.2, 180, 30, 45, 35.00, 70.00, true, '78 Oxford Road, Durban', '+27 31 789 0123', ARRAY['Pizza', 'Italian']),
  ('KFC South Africa', 'World-famous fried chicken and sides. Original Recipe or Hot & Crispy', '', 'restaurant', ARRAY['Fried Chicken', 'Fast Food'], 4.1, 400, 20, 30, 25.00, 40.00, true, '12 Church Street, Pretoria', '+27 12 345 6789', ARRAY['Fried Chicken', 'Quick Delivery']),
  ('Roman''s Pizza', 'Quality pizza at affordable prices. Legendary taste, value for money', '', 'restaurant', ARRAY['Pizza', 'Italian'], 4.4, 200, 25, 35, 30.00, 60.00, true, '56 Long Street, Port Elizabeth', '+27 41 234 5678', ARRAY['Pizza', 'Budget Friendly']),
  ('Ocean Basket', 'Seafood restaurant chain. Fresh fish, sushi, calamari and Mediterranean cuisine', '', 'restaurant', ARRAY['Seafood', 'Mediterranean', 'Sushi'], 4.5, 280, 35, 50, 40.00, 100.00, true, '89 Beach Road, Cape Town', '+27 21 567 8901', ARRAY['Seafood', 'Fresh Fish']),
  ('Mugg & Bean', 'All-day dining with generous portions. Breakfast, burgers, salads and coffee', '', 'restaurant', ARRAY['Breakfast', 'Burgers', 'Coffee'], 4.3, 220, 30, 45, 35.00, 80.00, true, '34 Nelson Mandela Avenue, Sandton', '+27 11 678 9012', ARRAY['Breakfast', 'Coffee Shop']),
  ('Spur Steak Ranches', 'Family restaurant famous for steaks, ribs and burgers. The place families love', '', 'restaurant', ARRAY['Steakhouse', 'Burgers', 'Family'], 4.2, 310, 35, 50, 30.00, 90.00, true, '23 Main Street, Bloemfontein', '+27 51 890 1234', ARRAY['Steakhouse', 'Family Friendly']),
  ('Wimpy', 'South African institution. All-day breakfast, burgers, waffles and coffee', '', 'restaurant', ARRAY['Breakfast', 'Burgers', 'Coffee'], 4.0, 190, 25, 40, 30.00, 60.00, true, '67 Commissioner Street, Johannesburg', '+27 11 901 2345', ARRAY['Breakfast', 'All Day Dining']),
  ('Panarottis', 'Italian dining experience. Pizza, pasta and family meals', '', 'restaurant', ARRAY['Pizza', 'Pasta', 'Italian'], 4.3, 160, 30, 45, 35.00, 75.00, true, '90 Green Point, Cape Town', '+27 21 012 3456', ARRAY['Italian', 'Pizza & Pasta'])
) AS v(name, description, image_url, category, cuisine_types, rating, total_reviews, delivery_time_min, delivery_time_max, delivery_fee, minimum_order, is_open, address, phone, tags)
WHERE NOT EXISTS (SELECT 1 FROM public.stores WHERE stores.name = v.name);

-- Insert sample food products for each store (5 products per store)
DO $$
DECLARE
    store_record RECORD;
BEGIN
    -- Steers Burgers products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Steers Burgers' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('King Steer Burger', 'Our signature flame-grilled beef burger with cheese, lettuce, tomato, onion', 65.00, '', 'Burgers', 100, 'food', store_record.id, 'Steers'),
        ('BBQ Rib Burger', 'Succulent pork rib patty with BBQ sauce and crispy onion rings', 72.00, '', 'Burgers', 100, 'food', store_record.id, 'Steers'),
        ('Chicken Royale', 'Grilled chicken breast with mayo, lettuce and tomato', 58.00, '', 'Burgers', 100, 'food', store_record.id, 'Steers'),
        ('Steers Chips', 'Golden crispy chips, perfectly salted', 28.00, '', 'Sides', 100, 'food', store_record.id, 'Steers'),
        ('Chocolate Milkshake', 'Rich and creamy chocolate shake', 35.00, '', 'Drinks', 100, 'food', store_record.id, 'Steers')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Nandos products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Nandos Peri-Peri' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Quarter Chicken', 'Flame-grilled PERi-PERi chicken - choice of heat level', 68.00, '', 'Mains', 100, 'food', store_record.id, 'Nandos'),
        ('Full Chicken', 'Whole flame-grilled PERi-PERi chicken with 2 sides', 195.00, '', 'Mains', 100, 'food', store_record.id, 'Nandos'),
        ('Espetada', 'Chicken skewers flame-grilled to perfection', 85.00, '', 'Mains', 100, 'food', store_record.id, 'Nandos'),
        ('Peri-Peri Chips', 'Chips tossed in PERi-PERi seasoning', 32.00, '', 'Sides', 100, 'food', store_record.id, 'Nandos'),
        ('Portuguese Roll', 'Soft roll perfect for dipping in PERi-PERi sauce', 18.00, '', 'Sides', 100, 'food', store_record.id, 'Nandos')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Debonairs Pizza products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Debonairs Pizza' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Triple-Decker', 'Three layers of cheese and your favorite toppings', 115.00, '', 'Pizza', 100, 'food', store_record.id, 'Debonairs'),
        ('Meaty', 'Loaded with bacon, ham, beef and salami', 105.00, '', 'Pizza', 100, 'food', store_record.id, 'Debonairs'),
        ('Chicken Tikka', 'Indian-spiced chicken with mango atchar', 98.00, '', 'Pizza', 100, 'food', store_record.id, 'Debonairs'),
        ('Margherita', 'Classic tomato and mozzarella cheese', 75.00, '', 'Pizza', 100, 'food', store_record.id, 'Debonairs'),
        ('Garlic Bread', 'Oven-baked garlic bread sticks', 38.00, '', 'Sides', 100, 'food', store_record.id, 'Debonairs')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- KFC products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'KFC South Africa' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Streetwise Two', '2 pieces of chicken with chips and a drink', 49.00, '', 'Meals', 100, 'food', store_record.id, 'KFC'),
        ('Colonel Burger', 'Original Recipe fillet burger with lettuce and mayo', 55.00, '', 'Burgers', 100, 'food', store_record.id, 'KFC'),
        ('Bucket for One', '6 pieces with 2 sides and 500ml drink', 95.00, '', 'Meals', 100, 'food', store_record.id, 'KFC'),
        ('Dunked Wings', 'Crispy wings tossed in your choice of sauce', 52.00, '', 'Wings', 100, 'food', store_record.id, 'KFC'),
        ('Coleslaw Regular', 'Creamy cabbage and carrot salad', 18.00, '', 'Sides', 100, 'food', store_record.id, 'KFC')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Romans Pizza products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Roman''s Pizza' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Chicken & Mushroom', 'Grilled chicken pieces with mushrooms and cheese', 75.00, '', 'Pizza', 100, 'food', store_record.id, 'Romans'),
        ('The Meaty Trio', 'Beef, bacon and ham with cheese', 82.00, '', 'Pizza', 100, 'food', store_record.id, 'Romans'),
        ('Four Cheeses', 'Mozzarella, cheddar, feta and parmesan', 78.00, '', 'Pizza', 100, 'food', store_record.id, 'Romans'),
        ('Veggie Supreme', 'Peppers, mushrooms, olives and onions', 72.00, '', 'Pizza', 100, 'food', store_record.id, 'Romans'),
        ('Chicken Wings 6pc', 'Crispy chicken wings with dipping sauce', 48.00, '', 'Sides', 100, 'food', store_record.id, 'Romans')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Ocean Basket products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Ocean Basket' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Hake & Chips', 'Grilled or fried hake with crispy chips', 95.00, '', 'Mains', 100, 'food', store_record.id, 'Ocean Basket'),
        ('Calamari Strips', 'Tender calamari strips fried to perfection', 88.00, '', 'Starters', 100, 'food', store_record.id, 'Ocean Basket'),
        ('Sushi Platter 20pc', 'Mixed sushi platter with soy and wasabi', 135.00, '', 'Sushi', 100, 'food', store_record.id, 'Ocean Basket'),
        ('Prawn Rissoto', 'Creamy risotto with queen prawns', 145.00, '', 'Mains', 100, 'food', store_record.id, 'Ocean Basket'),
        ('Greek Salad', 'Feta, olives, tomato and cucumber', 65.00, '', 'Salads', 100, 'food', store_record.id, 'Ocean Basket')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Mugg & Bean products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Mugg & Bean' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Big Brekkie', 'Eggs, bacon, sausage, mushrooms and toast', 85.00, '', 'Breakfast', 100, 'food', store_record.id, 'Mugg & Bean'),
        ('Mugg Burger', 'Beef patty with cheese, bacon and BBQ sauce', 98.00, '', 'Burgers', 100, 'food', store_record.id, 'Mugg & Bean'),
        ('Chicken Caesar Salad', 'Grilled chicken on romaine with Caesar dressing', 92.00, '', 'Salads', 100, 'food', store_record.id, 'Mugg & Bean'),
        ('Cappuccino', 'Rich espresso with steamed milk foam', 32.00, '', 'Beverages', 100, 'food', store_record.id, 'Mugg & Bean'),
        ('Chocolate Brownies', 'Warm brownie with ice cream', 55.00, '', 'Desserts', 100, 'food', store_record.id, 'Mugg & Bean')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Spur products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Spur Steak Ranches' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('300g Rump Steak', 'Tender rump steak with your choice of sauce', 145.00, '', 'Steaks', 100, 'food', store_record.id, 'Spur'),
        ('Cheese Burger', 'Beef burger with cheese and onion rings', 89.00, '', 'Burgers', 100, 'food', store_record.id, 'Spur'),
        ('BBQ Ribs Full Rack', 'Succulent pork ribs with BBQ sauce', 175.00, '', 'Ribs', 100, 'food', store_record.id, 'Spur'),
        ('Nachos Grande', 'Tortilla chips with cheese, salsa and guacamole', 78.00, '', 'Starters', 100, 'food', store_record.id, 'Spur'),
        ('Chocolate Fudge Cake', 'Rich chocolate cake with ice cream', 62.00, '', 'Desserts', 100, 'food', store_record.id, 'Spur')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Wimpy products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Wimpy' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Wimpy Breakfast', '2 eggs, bacon, sausage, chips and toast', 78.00, '', 'Breakfast', 100, 'food', store_record.id, 'Wimpy'),
        ('Quarterpounder', 'Quarter pound beef patty with cheese', 82.00, '', 'Burgers', 100, 'food', store_record.id, 'Wimpy'),
        ('Chicken Schnitzel', 'Crumbed chicken breast with chips', 95.00, '', 'Mains', 100, 'food', store_record.id, 'Wimpy'),
        ('Waffles', 'Belgian waffles with syrup and cream', 58.00, '', 'Desserts', 100, 'food', store_record.id, 'Wimpy'),
        ('Coffee Latte', 'Smooth espresso with steamed milk', 28.00, '', 'Beverages', 100, 'food', store_record.id, 'Wimpy')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Panarottis products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Panarottis' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id, brand) VALUES
        ('Margherita Pizza', 'Classic tomato base with mozzarella', 95.00, '', 'Pizza', 100, 'food', store_record.id, 'Panarottis'),
        ('Bolognese Pasta', 'Traditional beef bolognese with spaghetti', 105.00, '', 'Pasta', 100, 'food', store_record.id, 'Panarottis'),
        ('Chicken Alfredo', 'Creamy alfredo sauce with grilled chicken', 115.00, '', 'Pasta', 100, 'food', store_record.id, 'Panarottis'),
        ('Caprese Salad', 'Fresh tomato, mozzarella and basil', 75.00, '', 'Salads', 100, 'food', store_record.id, 'Panarottis'),
        ('Tiramisu', 'Classic Italian coffee dessert', 65.00, '', 'Desserts', 100, 'food', store_record.id, 'Panarottis')
        ON CONFLICT DO NOTHING;
    END LOOP;
END $$;
