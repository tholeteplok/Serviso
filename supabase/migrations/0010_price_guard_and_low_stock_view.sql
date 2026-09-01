-- Serviso 0009: guard harga hanya admin + view low-stock

-- 1. View low-stock untuk filter akurat (ganti client-side 200)
create or replace view public.v_low_stock_parts as
select p.*
from public.parts p
where p.min_stock > 0 and p.stock_qty <= p.min_stock
order by p.stock_qty asc;

grant select on public.v_low_stock_parts to authenticated;

-- 2. Trigger guard harga: cost_price / sell_price hanya boleh diubah admin
create or replace function public.check_price_update_is_admin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (TG_OP = 'UPDATE') then
    if (coalesce(OLD.cost_price, 0) <> coalesce(NEW.cost_price, 0)
        or coalesce(OLD.sell_price, 0) <> coalesce(NEW.sell_price, 0)) then
      if not public.is_admin() then
        raise exception 'Hanya pemilik yang dapat mengubah harga (%)', 'cost_price/sell_price';
      end if;
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_parts_price_guard on public.parts;
create trigger trg_parts_price_guard
before update of cost_price, sell_price on public.parts
for each row execute function public.check_price_update_is_admin();

-- 3. Catatan: GRANT update(parts) tetap ada untuk kompatibilitas, tapi trigger akan blok non-admin
-- Tidak perlu revoke, trigger jadi sumber kebenaran
