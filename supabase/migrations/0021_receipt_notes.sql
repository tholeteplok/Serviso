-- Serviso 0021: Tambah kolom receipt_notes untuk catatan garansi / kebijakan struk

alter table if exists public.shops add column if not exists receipt_notes text;
alter table if exists public.app_settings add column if not exists receipt_notes text;
