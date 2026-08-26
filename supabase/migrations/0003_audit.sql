-- Serviso 0003: audit trail generik untuk semua tabel operasional.
-- SECURITY DEFINER agar bisa menulis audit_logs meski RLS menutup INSERT bagi client.

create or replace function public.audit_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_action public.audit_action;
begin
  if tg_op = 'INSERT' then
    v_action := 'insert';
    v_old := null;
    v_new := to_jsonb(new);
  elsif tg_op = 'UPDATE' then
    v_action := 'update';
    -- Abaikan perubahan yang hanya menyentuh updated_at: bandingkan tanpa kolom tsb,
    -- dan simpan payload tanpa updated_at agar diff di penampil audit bersih.
    v_old := to_jsonb(old) - 'updated_at';
    v_new := to_jsonb(new) - 'updated_at';
    if v_old = v_new then
      return null;
    end if;
  else
    v_action := 'delete';
    v_old := to_jsonb(old);
    v_new := null;
  end if;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (
    auth.uid(),
    v_action,
    tg_table_name,
    coalesce(v_old ->> 'id', v_new ->> 'id'),
    v_old,
    v_new
  );
  return null;
end;
$$;

revoke execute on function public.audit_trigger() from public, anon, authenticated;

create trigger audit_customers
after insert or update or delete on public.customers
for each row execute function public.audit_trigger();

create trigger audit_vehicles
after insert or update or delete on public.vehicles
for each row execute function public.audit_trigger();

create trigger audit_parts
after insert or update or delete on public.parts
for each row execute function public.audit_trigger();

create trigger audit_part_movements
after insert or update or delete on public.part_movements
for each row execute function public.audit_trigger();

create trigger audit_work_orders
after insert or update or delete on public.work_orders
for each row execute function public.audit_trigger();

create trigger audit_wo_items
after insert or update or delete on public.wo_items
for each row execute function public.audit_trigger();

create trigger audit_profiles
after insert or update or delete on public.profiles
for each row execute function public.audit_trigger();
