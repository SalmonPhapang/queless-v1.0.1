-- =============================================
-- FIX NEARBY STORES RPC FUNCTION
-- Address type casting issues with geography
-- =============================================

-- Ensure PostGIS is active
CREATE EXTENSION IF NOT EXISTS postgis;

-- Recreate the function with explicit casts to ensure it matches the geography type
CREATE OR REPLACE FUNCTION nearby_stores(
  lat double precision,
  long double precision,
  radius_meters double precision DEFAULT 5000
)
RETURNS SETOF public.stores
LANGUAGE sql
AS $$
  SELECT *
  FROM public.stores
  WHERE ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
    radius_meters
  )
  AND is_open = true
  ORDER BY 
    location <-> ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography;
$$;

-- Verify existing stores have valid geography points
-- V-Town Liquor
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(27.9310, -26.6745), 4326)::geography
WHERE name = 'V-Town Liquor';

-- Three Rivers Drinks
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(27.9650, -26.6650), 4326)::geography
WHERE name = 'Three Rivers Drinks';

-- Meyerton Express
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.0100, -26.5800), 4326)::geography
WHERE name = 'Meyerton Express';

-- Arcon Park Alcohol
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(27.9400, -26.6500), 4326)::geography
WHERE name = 'Arcon Park Alcohol';
