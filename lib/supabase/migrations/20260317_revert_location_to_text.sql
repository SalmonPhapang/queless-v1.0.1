-- =============================================
-- REVERT STORES LOCATION TO TEXT
-- Change geography column back to comma-separated string
-- =============================================

-- 1. Drop the geography column
ALTER TABLE public.stores DROP COLUMN IF EXISTS location;

-- 2. Add the location column back as normal text
ALTER TABLE public.stores ADD COLUMN location TEXT NOT NULL DEFAULT '';

-- 3. Update the RPC function to handle the text-based location strings
-- This will parse "lat, long" from the text column into geography for spatial comparison
CREATE OR REPLACE FUNCTION nearby_stores(
  lat double precision,
  long double precision,
  radius_meters double precision DEFAULT 50000
)
RETURNS SETOF public.stores
LANGUAGE sql
AS $$
  SELECT *
  FROM public.stores
  WHERE 
    CASE 
      WHEN location = '' THEN false
      ELSE ST_DWithin(
        ST_SetSRID(ST_MakePoint(
          split_part(location, ',', 2)::double precision, 
          split_part(location, ',', 1)::double precision
        ), 4326)::geography,
        ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
        radius_meters
      )
    END
  AND is_open = true
  ORDER BY 
    CASE 
      WHEN location = '' THEN NULL
      ELSE ST_SetSRID(ST_MakePoint(
          split_part(location, ',', 2)::double precision, 
          split_part(location, ',', 1)::double precision
        ), 4326)::geography <-> ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography
    END;
$$;

-- 4. Re-insert the Vereeniging store coordinates as "lat, long" strings
UPDATE public.stores SET location = '-26.6745, 27.9310' WHERE name = 'V-Town Liquor';
UPDATE public.stores SET location = '-26.6650, 27.9650' WHERE name = 'Three Rivers Drinks';
UPDATE public.stores SET location = '-26.5800, 28.0100' WHERE name = 'Meyerton Express';
UPDATE public.stores SET location = '-26.6500, 27.9400' WHERE name = 'Arcon Park Alcohol';

-- 5. Update other sample stores if they exist
UPDATE public.stores SET location = '-26.1076, 28.0567' WHERE name = 'Ocean Basket';
UPDATE public.stores SET location = '-26.1073, 28.0570' WHERE name = 'Mugg & Bean';
UPDATE public.stores SET location = '-26.1080, 28.0560' WHERE name = 'Spur Steak Ranches';
UPDATE public.stores SET location = '-26.1458, 28.0416' WHERE name = 'Wimpy';
UPDATE public.stores SET location = '-26.1764, 28.1345' WHERE name = 'Fournos Bakery';
UPDATE public.stores SET location = '-26.1070, 28.0555' WHERE name = 'Pizza Hut';
