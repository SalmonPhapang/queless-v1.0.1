-- Migration to populate order_number for existing orders
-- This uses a PostgreSQL equivalent of our Snowflake ID generation logic

CREATE OR REPLACE FUNCTION public.generate_order_number_v1(created_at_timestamp TIMESTAMPTZ, row_id UUID) 
RETURNS TEXT AS $$
DECLARE
  epoch BIGINT := 1735689600000; -- 2026-01-01
  timestamp_ms BIGINT;
  worker_id BIGINT := 1;
  datacenter_id BIGINT := 1;
  -- Use a stable part of the UUID to simulate the sequence/entropy
  -- This ensures that even if two orders have the same created_at, they get unique order numbers
  entropy BIGINT;
  snowflake_id BIGINT;
  base36_chars TEXT := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  res TEXT := '';
  val BIGINT;
BEGIN
  -- 1. Calculate timestamp in ms since our epoch
  timestamp_ms := (EXTRACT(EPOCH FROM created_at_timestamp) * 1000)::BIGINT - epoch;
  
  -- 2. Extract 12 bits of entropy from the UUID (similar to our 12-bit sequence)
  entropy := ('x' || left(replace(row_id::text, '-', ''), 3))::bit(12)::bigint;

  -- 3. Construct the Snowflake ID (timestamp << 22 | datacenter << 17 | worker << 12 | sequence)
  snowflake_id := (timestamp_ms << 22) | (datacenter_id << 17) | (worker_id << 12) | entropy;

  -- 4. Convert to Base36
  val := snowflake_id;
  WHILE val > 0 LOOP
    res := substr(base36_chars, (val % 36)::integer + 1, 1) || res;
    val := val / 36;
  END LOOP;

  -- 5. Pad and prefix
  RETURN 'QLE-' || LPAD(res, 8, '0');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update existing orders that don't have an order_number
UPDATE public.orders
SET order_number = generate_order_number_v1(created_at, id)
WHERE order_number IS NULL OR order_number = '';

-- Clean up helper function
DROP FUNCTION public.generate_order_number_v1(TIMESTAMPTZ, UUID);
