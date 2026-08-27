-- Seed a single app_settings row (id is fixed to 1 by the single-row check).
insert into public.app_settings (id, shop_name, address, phone)
values (1, 'Bengkel Serviso', null, null)
on conflict (id) do nothing;
