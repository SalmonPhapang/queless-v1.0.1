-- =============================================
-- ADD 20% OFF ALCOHOL PROMO
-- =============================================

INSERT INTO public.promo_codes (code, description, discount_type, discount_value, applicable_order_types)
VALUES ('CHEERS20', '20% off all liquor orders', 'percentage', 20, ARRAY['Liquor'])
ON CONFLICT DO NOTHING;
