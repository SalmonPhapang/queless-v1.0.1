-- =============================================
-- SHOW CLOSED AND UNAPPROVED STORES IN NEARBY SEARCH
-- Correctly handles text-based location column
-- =============================================

-- Recreate the function without any filters (is_open or is_approved)
DROP FUNCTION IF EXISTS nearby_stores(double precision, double precision, double precision);

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
      WHEN location = '' OR location IS NULL THEN false
      ELSE ST_DWithin(
        ST_SetSRID(ST_MakePoint(
          split_part(location, ',', 2)::double precision, 
          split_part(location, ',', 1)::double precision
        ), 4326)::geography,
        ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
        radius_meters
      )
    END
  ORDER BY 
    CASE 
      WHEN location = '' OR location IS NULL THEN NULL
      ELSE ST_SetSRID(ST_MakePoint(
          split_part(location, ',', 2)::double precision, 
          split_part(location, ',', 1)::double precision
        ), 4326)::geography <-> ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography
    END;
$$;
