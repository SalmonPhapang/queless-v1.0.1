do $$
declare
  scenario text := 'store_priority';
  target_store_id uuid := '0163d07e-f227-40fb-b61c-aebd17e57347';
  target_store_name text;
  product_1_id uuid;
  product_1_name text;
  product_2_id uuid;
  product_2_name text;
begin
  select name into target_store_name
  from public.stores
  where id = target_store_id;

  if target_store_name is null then
    raise exception 'Seed failed: store not found with id: %', target_store_id;
  end if;

  select id, name into product_1_id, product_1_name
  from public.products
  where store_id = target_store_id
  limit 1;

  select id, name into product_2_id, product_2_name
  from public.products
  where store_id = target_store_id
  offset 1
  limit 1;

  delete from public.promotions where title like 'Sample:%';

  insert into public.promotions (
    title,
    message,
    target_type,
    target_id,
    badge_text,
    image_url,
    is_active,
    priority,
    starts_at,
    ends_at
  ) values
    (
      'Sample: Product - ' || coalesce(product_1_name, 'Featured Item'),
      'Limited time deal on ' || coalesce(product_1_name, 'this item') || '. Tap to view.',
      'product',
      coalesce(product_1_id, '00000000-0000-0000-0000-000000000000'),
      'Promo',
      '',
      false,
      100,
      now(),
      now() + interval '14 days'
    ),
    (
      'Sample: Store - ' || target_store_name,
      target_store_name || ' promo. Tap to view the store.',
      'store',
      target_store_id,
      'Promo',
      '',
      false,
      10,
      now(),
      now() + interval '14 days'
    ),
    (
      'Sample: Product - ' || coalesce(product_2_name, 'Special Offer'),
      'Product promo for ' || coalesce(product_2_name, 'our special offer') || '. Tap to view.',
      'product',
      coalesce(product_2_id, '00000000-0000-0000-0000-000000000000'),
      'Promo',
      '',
      false,
      999,
      now(),
      now() + interval '14 days'
    );

  update public.promotions set is_active = false where title like 'Sample:%';

  if scenario = 'product_only' then
    update public.promotions
    set is_active = true
    where title like 'Sample: Product%';
  elsif scenario = 'store_only' then
    update public.promotions
    set is_active = true
    where title like 'Sample: Store%';
  elsif scenario = 'store_priority' then
    update public.promotions
    set is_active = true
    where title like 'Sample: Product%' or title like 'Sample: Store%';
  end if;
end $$;
