-- =============================================
-- PROMO CODES SCHEMA
-- Support for Free Delivery, % Discounts, and Store-specific promos
-- =============================================

CREATE TABLE IF NOT EXISTS public.promo_codes (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL, -- 'percentage', 'fixed', 'free_delivery'
    discount_value NUMERIC DEFAULT 0,
    min_order_amount NUMERIC DEFAULT 0,
    max_discount_amount NUMERIC,
    
    -- Validation Rules
    is_first_order_only BOOLEAN DEFAULT false,
    applicable_store_ids UUID[] DEFAULT NULL, -- Null means all stores
    applicable_order_types TEXT[] DEFAULT NULL, -- ['Liquor', 'Food'] or Null for all
    
    -- Limits
    usage_limit_total INTEGER,
    usage_limit_per_user INTEGER DEFAULT 1,
    current_usage_total INTEGER DEFAULT 0,
    
    -- Validity
    start_date TIMESTAMPTZ DEFAULT now(),
    end_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast code lookups
CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON public.promo_codes(code);

-- Sample Data for testing
INSERT INTO public.promo_codes (code, description, discount_type, is_first_order_only)
VALUES ('WELCOME25', 'Free delivery on your first order', 'free_delivery', true)
ON CONFLICT DO NOTHING;

INSERT INTO public.promo_codes (code, description, discount_type, applicable_order_types)
VALUES ('FOODIE', 'Free delivery on all food orders', 'free_delivery', ARRAY['Food'])
ON CONFLICT DO NOTHING;

INSERT INTO public.promo_codes (code, description, discount_type, applicable_order_types)
VALUES ('CHEERS', 'Free delivery on all liquor orders', 'free_delivery', ARRAY['Liquor'])
ON CONFLICT DO NOTHING;
