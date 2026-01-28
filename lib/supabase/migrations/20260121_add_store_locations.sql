-- =============================================
-- ADD LOCATION SUPPORT FOR STORES
-- Enable PostGIS and add coordinates
-- =============================================

-- Enable PostGIS extension if not enabled
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add location column to stores table
ALTER TABLE public.stores
ADD COLUMN IF NOT EXISTS location geography(POINT);

-- Create index for location queries
CREATE INDEX IF NOT EXISTS idx_stores_location ON public.stores USING GIST (location);

-- Create RPC function to find nearby stores
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

-- Update existing stores with sample coordinates (Johannesburg area)
-- Ocean Basket (Sandton City)
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.0567, -26.1076), 4326)::geography
WHERE name = 'Ocean Basket';

-- Mugg & Bean (Sandton City)
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.0570, -26.1073), 4326)::geography
WHERE name = 'Mugg & Bean';

-- Spur (Sandton City)
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.0560, -26.1080), 4326)::geography
WHERE name = 'Spur Steak Ranches';

-- Wimpy (Rosebank - slightly further)
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.0416, -26.1458), 4326)::geography
WHERE name = 'Wimpy';

-- Fournos (Bedfordview - far away > 5km)
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.1345, -26.1764), 4326)::geography
WHERE name = 'Fournos Bakery';

-- Pizza Hut (Sandton)
UPDATE public.stores 
SET location = ST_SetSRID(ST_MakePoint(28.0555, -26.1070), 4326)::geography
WHERE name = 'Pizza Hut';
