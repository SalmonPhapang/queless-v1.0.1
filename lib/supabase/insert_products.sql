-- Insert sample products data for Queless (South African beverages)
-- Run this in your Supabase SQL Editor

INSERT INTO public.products (name, brand, description, price, category, image_url, volume, alcohol_content, is_local_brand, tags, created_at, updated_at) VALUES
-- Beers
('Castle Lager', 'Castle', 'South Africa''s premium lager beer. Crisp, refreshing, and perfectly balanced.', 35.99, 'beer', 'assets/placeholder.png', '330ml', 5.0, true, ARRAY['lager', 'south african', 'beer'], now(), now()),
('Black Label', 'Carling', 'Bold and full-bodied beer with a distinctive taste. A South African favorite.', 32.99, 'beer', 'assets/placeholder.png', '330ml', 5.5, true, ARRAY['lager', 'south african', 'beer'], now(), now()),
('Carling Black Label (6-pack)', 'Carling', 'South Africa''s champion beer. Perfect for sharing with friends.', 89.99, 'beer', 'assets/placeholder.png', '6 x 330ml', 5.5, true, ARRAY['lager', 'south african', 'beer', '6-pack'], now(), now()),
('Windhoek Lager', 'Windhoek', 'Premium Namibian lager brewed according to German purity laws.', 38.99, 'beer', 'assets/placeholder.png', '330ml', 4.0, false, ARRAY['lager', 'namibian', 'beer'], now(), now()),

-- Wines
('Nederburg Cabernet Sauvignon', 'Nederburg', 'Full-bodied red wine with rich berry flavors and smooth tannins.', 89.99, 'wine', 'assets/placeholder.png', '750ml', 14.0, true, ARRAY['red wine', 'south african', 'cabernet'], now(), now()),
('KWV Chenin Blanc', 'KWV', 'Crisp white wine with tropical fruit notes. Perfect for warm weather.', 79.99, 'wine', 'assets/placeholder.png', '750ml', 13.0, true, ARRAY['white wine', 'south african', 'chenin blanc'], now(), now()),
('Amarula Cream', 'Amarula', 'Smooth cream liqueur made from the marula fruit. Uniquely South African.', 149.99, 'wine', 'assets/placeholder.png', '750ml', 17.0, true, ARRAY['liqueur', 'south african', 'cream'], now(), now()),

-- Spirits
('KWV 3 Year Brandy', 'KWV', 'Premium South African brandy with a smooth, refined taste.', 189.99, 'spirits', 'assets/placeholder.png', '750ml', 43.0, true, ARRAY['brandy', 'south african', 'spirits'], now(), now()),
('Jägermeister', 'Jägermeister', 'Herbal liqueur with 56 botanicals. Perfect for shots or cocktails.', 279.99, 'spirits', 'assets/placeholder.png', '700ml', 35.0, false, ARRAY['liqueur', 'german', 'herbal'], now(), now()),
('Johnnie Walker Red Label', 'Johnnie Walker', 'World-famous blended Scotch whisky with bold, spicy flavors.', 299.99, 'spirits', 'assets/placeholder.png', '750ml', 40.0, false, ARRAY['whisky', 'scotch', 'spirits'], now(), now()),

-- Mixers
('Coca-Cola (2L)', 'Coca-Cola', 'Classic Coca-Cola for mixing or enjoying on its own.', 24.99, 'mixers', 'assets/placeholder.png', '2L', null, false, ARRAY['mixer', 'soft drink', 'cola'], now(), now()),
('Ginger Ale (6-pack)', 'Schweppes', 'Crisp ginger ale perfect for whisky and cocktails.', 45.99, 'mixers', 'assets/placeholder.png', '6 x 330ml', null, false, ARRAY['mixer', 'soft drink', 'ginger ale'], now(), now()),
('Tonic Water (1L)', 'Schweppes', 'Premium tonic water for gin and tonics.', 19.99, 'mixers', 'assets/placeholder.png', '1L', null, false, ARRAY['mixer', 'tonic', 'soft drink'], now(), now()),

-- Snacks
('Simba Chips (Assorted)', 'Simba', 'South Africa''s favorite chips in assorted flavors.', 15.99, 'snacks', 'assets/placeholder.png', '125g', null, true, ARRAY['snacks', 'chips', 'south african'], now(), now()),
('Biltong (200g)', 'Local Biltong', 'Traditional South African dried meat snack.', 89.99, 'snacks', 'assets/placeholder.png', '200g', null, true, ARRAY['snacks', 'biltong', 'south african', 'meat'], now(), now())

ON CONFLICT DO NOTHING;
