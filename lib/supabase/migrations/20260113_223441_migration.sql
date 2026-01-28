-- =============================================
-- ADD STORES AND DUAL-ECOSYSTEM SUPPORT
-- Implement Food & Alcohol marketplace separation
-- =============================================

-- Create stores table for restaurants/food vendors
CREATE TABLE IF NOT EXISTS public.stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    image_url TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'restaurant',
    cuisine_types TEXT[] NOT NULL DEFAULT '{}',
    rating DECIMAL(3, 2) NOT NULL DEFAULT 0.0,
    total_reviews INTEGER NOT NULL DEFAULT 0,
    delivery_time_min INTEGER NOT NULL DEFAULT 30,
    delivery_time_max INTEGER NOT NULL DEFAULT 45,
    delivery_fee DECIMAL(10, 2) NOT NULL DEFAULT 35.0,
    minimum_order DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    is_open BOOLEAN NOT NULL DEFAULT true,
    operating_hours JSONB NOT NULL DEFAULT '{}'::jsonb,
    address TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    tags TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add product_type column to products (food or alcohol)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS product_type TEXT NOT NULL DEFAULT 'alcohol';

-- Add store_id for food products (nullable for alcohol products)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

-- Create indexes for stores
CREATE INDEX IF NOT EXISTS idx_stores_category ON public.stores(category);
CREATE INDEX IF NOT EXISTS idx_stores_is_open ON public.stores(is_open);
CREATE INDEX IF NOT EXISTS idx_stores_rating ON public.stores(rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_product_type ON public.products(product_type);
CREATE INDEX IF NOT EXISTS idx_products_store_id ON public.products(store_id);

-- Enable RLS on stores table
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for stores (read-only for authenticated users)
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

-- =============================================
-- INSERT SAMPLE STORE DATA
-- =============================================

-- Insert sample restaurants/stores
INSERT INTO public.stores (name, description, image_url, category, cuisine_types, rating, total_reviews, delivery_time_min, delivery_time_max, delivery_fee, minimum_order, is_open, address, phone, tags) VALUES
('Steers Burgers', 'Premium flame-grilled burgers and chips. Home of the 100% pure beef burger', '', 'restaurant', ARRAY['Burgers', 'Fast Food'], 4.3, 250, 25, 35, 25.00, 50.00, true, '123 Main Road, Johannesburg', '+27 11 123 4567', ARRAY['Popular', 'Fast Food']),
('Nandos Peri-Peri', 'Legendary flame-grilled PERi-PERi chicken. Made to order with various heat levels', '', 'restaurant', ARRAY['Portuguese', 'Chicken', 'Grills'], 4.6, 350, 30, 40, 30.00, 60.00, true, '45 Market Street, Cape Town', '+27 21 456 7890', ARRAY['Popular', 'Grilled Chicken']),
('Debonairs Pizza', 'The home of Anything Goes pizza. Create your own masterpiece or choose a classic', '', 'restaurant', ARRAY['Pizza', 'Italian'], 4.2, 180, 30, 45, 35.00, 70.00, true, '78 Oxford Road, Durban', '+27 31 789 0123', ARRAY['Pizza', 'Italian']),
('KFC South Africa', 'World-famous fried chicken and sides. Original Recipe or Hot & Crispy', '', 'restaurant', ARRAY['Fried Chicken', 'Fast Food'], 4.1, 400, 20, 30, 25.00, 40.00, true, '12 Church Street, Pretoria', '+27 12 345 6789', ARRAY['Fried Chicken', 'Quick Delivery']),
('Roman''s Pizza', 'Quality pizza at affordable prices. Legendary taste, value for money', '', 'restaurant', ARRAY['Pizza', 'Italian'], 4.4, 200, 25, 35, 30.00, 60.00, true, '56 Long Street, Port Elizabeth', '+27 41 234 5678', ARRAY['Pizza', 'Budget Friendly']),
('Ocean Basket', 'Seafood restaurant chain. Fresh fish, sushi, calamari and Mediterranean cuisine', '', 'restaurant', ARRAY['Seafood', 'Mediterranean', 'Sushi'], 4.5, 280, 35, 50, 40.00, 100.00, true, '89 Beach Road, Cape Town', '+27 21 567 8901', ARRAY['Seafood', 'Fresh Fish']),
('Mugg & Bean', 'All-day dining with generous portions. Breakfast, burgers, salads and coffee', '', 'restaurant', ARRAY['Breakfast', 'Burgers', 'Coffee'], 4.3, 220, 30, 45, 35.00, 80.00, true, '34 Nelson Mandela Avenue, Sandton', '+27 11 678 9012', ARRAY['Breakfast', 'Coffee Shop']),
('Spur Steak Ranches', 'Family restaurant famous for steaks, ribs and burgers. The place families love', '', 'restaurant', ARRAY['Steakhouse', 'Burgers', 'Family'], 4.2, 310, 35, 50, 30.00, 90.00, true, '23 Main Street, Bloemfontein', '+27 51 890 1234', ARRAY['Steakhouse', 'Family Friendly']),
('Wimpy', 'South African institution. All-day breakfast, burgers, waffles and coffee', '', 'restaurant', ARRAY['Breakfast', 'Burgers', 'Coffee'], 4.0, 190, 25, 40, 30.00, 60.00, true, '67 Commissioner Street, Johannesburg', '+27 11 901 2345', ARRAY['Breakfast', 'All Day Dining']),
('Panarottis', 'Italian dining experience. Pizza, pasta and family meals', '', 'restaurant', ARRAY['Pizza', 'Pasta', 'Italian'], 4.3, 160, 30, 45, 35.00, 75.00, true, '90 Green Point, Cape Town', '+27 21 012 3456', ARRAY['Italian', 'Pizza & Pasta']);

-- Insert sample food products for each store (5 products per store)
DO $$
DECLARE
    store_record RECORD;
BEGIN
    -- Steers Burgers products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Steers Burgers' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('King Steer Burger', 'Our signature flame-grilled beef burger with cheese, lettuce, tomato, onion', 65.00, '', 'Burgers', 100, 'food', store_record.id),
        ('BBQ Rib Burger', 'Succulent pork rib patty with BBQ sauce and crispy onion rings', 72.00, '', 'Burgers', 100, 'food', store_record.id),
        ('Chicken Royale', 'Grilled chicken breast with mayo, lettuce and tomato', 58.00, '', 'Burgers', 100, 'food', store_record.id),
        ('Steers Chips', 'Golden crispy chips, perfectly salted', 28.00, '', 'Sides', 100, 'food', store_record.id),
        ('Chocolate Milkshake', 'Rich and creamy chocolate shake', 35.00, '', 'Drinks', 100, 'food', store_record.id);
    END LOOP;

    -- Nandos products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Nandos Peri-Peri' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Quarter Chicken', 'Flame-grilled PERi-PERi chicken - choice of heat level', 68.00, '', 'Mains', 100, 'food', store_record.id),
        ('Full Chicken', 'Whole flame-grilled PERi-PERi chicken with 2 sides', 195.00, '', 'Mains', 100, 'food', store_record.id),
        ('Espetada', 'Chicken skewers flame-grilled to perfection', 85.00, '', 'Mains', 100, 'food', store_record.id),
        ('Peri-Peri Chips', 'Chips tossed in PERi-PERi seasoning', 32.00, '', 'Sides', 100, 'food', store_record.id),
        ('Portuguese Roll', 'Soft roll perfect for dipping in PERi-PERi sauce', 18.00, '', 'Sides', 100, 'food', store_record.id);
    END LOOP;

    -- Debonairs Pizza products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Debonairs Pizza' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Triple-Decker', 'Three layers of cheese and your favorite toppings', 115.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Meaty', 'Loaded with bacon, ham, beef and salami', 105.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Chicken Tikka', 'Indian-spiced chicken with mango atchar', 98.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Margherita', 'Classic tomato and mozzarella cheese', 75.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Garlic Bread', 'Oven-baked garlic bread sticks', 38.00, '', 'Sides', 100, 'food', store_record.id);
    END LOOP;

    -- KFC products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'KFC South Africa' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Streetwise Two', '2 pieces of chicken with chips and a drink', 49.00, '', 'Meals', 100, 'food', store_record.id),
        ('Colonel Burger', 'Original Recipe fillet burger with lettuce and mayo', 55.00, '', 'Burgers', 100, 'food', store_record.id),
        ('Bucket for One', '6 pieces with 2 sides and 500ml drink', 95.00, '', 'Meals', 100, 'food', store_record.id),
        ('Dunked Wings', 'Crispy wings tossed in your choice of sauce', 52.00, '', 'Wings', 100, 'food', store_record.id),
        ('Coleslaw Regular', 'Creamy cabbage and carrot salad', 18.00, '', 'Sides', 100, 'food', store_record.id);
    END LOOP;

    -- Romans Pizza products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Roman''s Pizza' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Chicken & Mushroom', 'Grilled chicken pieces with mushrooms and cheese', 75.00, '', 'Pizza', 100, 'food', store_record.id),
        ('The Meaty Trio', 'Beef, bacon and ham with cheese', 82.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Four Cheeses', 'Mozzarella, cheddar, feta and parmesan', 78.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Veggie Supreme', 'Peppers, mushrooms, olives and onions', 72.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Chicken Wings 6pc', 'Crispy chicken wings with dipping sauce', 48.00, '', 'Sides', 100, 'food', store_record.id);
    END LOOP;

    -- Ocean Basket products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Ocean Basket' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Hake & Chips', 'Grilled or fried hake with crispy chips', 95.00, '', 'Mains', 100, 'food', store_record.id),
        ('Calamari Strips', 'Tender calamari strips fried to perfection', 88.00, '', 'Starters', 100, 'food', store_record.id),
        ('Sushi Platter 20pc', 'Mixed sushi platter with soy and wasabi', 135.00, '', 'Sushi', 100, 'food', store_record.id),
        ('Prawn Rissoto', 'Creamy risotto with queen prawns', 145.00, '', 'Mains', 100, 'food', store_record.id),
        ('Greek Salad', 'Feta, olives, tomato and cucumber', 65.00, '', 'Salads', 100, 'food', store_record.id);
    END LOOP;

    -- Mugg & Bean products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Mugg & Bean' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Big Brekkie', 'Eggs, bacon, sausage, mushrooms and toast', 85.00, '', 'Breakfast', 100, 'food', store_record.id),
        ('Mugg Burger', 'Beef patty with cheese, bacon and BBQ sauce', 98.00, '', 'Burgers', 100, 'food', store_record.id),
        ('Chicken Caesar Salad', 'Grilled chicken on romaine with Caesar dressing', 92.00, '', 'Salads', 100, 'food', store_record.id),
        ('Cappuccino', 'Rich espresso with steamed milk foam', 32.00, '', 'Beverages', 100, 'food', store_record.id),
        ('Chocolate Brownies', 'Warm brownie with ice cream', 55.00, '', 'Desserts', 100, 'food', store_record.id);
    END LOOP;

    -- Spur products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Spur Steak Ranches' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('300g Rump Steak', 'Tender rump steak with your choice of sauce', 145.00, '', 'Steaks', 100, 'food', store_record.id),
        ('Cheese Burger', 'Beef burger with cheese and onion rings', 89.00, '', 'Burgers', 100, 'food', store_record.id),
        ('BBQ Ribs Full Rack', 'Succulent pork ribs with BBQ sauce', 175.00, '', 'Ribs', 100, 'food', store_record.id),
        ('Nachos Grande', 'Tortilla chips with cheese, salsa and guacamole', 78.00, '', 'Starters', 100, 'food', store_record.id),
        ('Chocolate Fudge Cake', 'Rich chocolate cake with ice cream', 62.00, '', 'Desserts', 100, 'food', store_record.id);
    END LOOP;

    -- Wimpy products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Wimpy' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Wimpy Breakfast', '2 eggs, bacon, sausage, chips and toast', 78.00, '', 'Breakfast', 100, 'food', store_record.id),
        ('Quarterpounder', 'Quarter pound beef patty with cheese', 82.00, '', 'Burgers', 100, 'food', store_record.id),
        ('Chicken Schnitzel', 'Crumbed chicken breast with chips', 95.00, '', 'Mains', 100, 'food', store_record.id),
        ('Waffles', 'Belgian waffles with syrup and cream', 58.00, '', 'Desserts', 100, 'food', store_record.id),
        ('Coffee Latte', 'Smooth espresso with steamed milk', 28.00, '', 'Beverages', 100, 'food', store_record.id);
    END LOOP;

    -- Panarottis products
    FOR store_record IN SELECT id FROM public.stores WHERE name = 'Panarottis' LOOP
        INSERT INTO public.products (name, description, price, image_url, category, stock, product_type, store_id) VALUES
        ('Margherita Pizza', 'Classic tomato base with mozzarella', 95.00, '', 'Pizza', 100, 'food', store_record.id),
        ('Bolognese Pasta', 'Traditional beef bolognese with spaghetti', 105.00, '', 'Pasta', 100, 'food', store_record.id),
        ('Chicken Alfredo', 'Creamy alfredo sauce with grilled chicken', 115.00, '', 'Pasta', 100, 'food', store_record.id),
        ('Caprese Salad', 'Fresh tomato, mozzarella and basil', 75.00, '', 'Salads', 100, 'food', store_record.id),
        ('Tiramisu', 'Classic Italian coffee dessert', 65.00, '', 'Desserts', 100, 'food', store_record.id);
    END LOOP;
END $$;
