-- ============================================================================
-- Kenyangin - Titik koordinat toko (jarak real-time ke konsumen)
-- Jalankan di Supabase SQL Editor bila tabel stores belum punya kolom
-- latitude / longitude. Script idempotent (aman dijalankan berulang).
-- ============================================================================

alter table public.stores
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

comment on column public.stores.latitude  is 'Latitude gerai (-90 s.d. 90), diisi mitra dari form profil toko';
comment on column public.stores.longitude is 'Longitude gerai (-180 s.d. 180), diisi mitra dari form profil toko';

-- Opsional: pastikan nilai koordinat selalu masuk akal.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'stores_latitude_range'
  ) then
    alter table public.stores
      add constraint stores_latitude_range
      check (latitude is null or (latitude between -90 and 90));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'stores_longitude_range'
  ) then
    alter table public.stores
      add constraint stores_longitude_range
      check (longitude is null or (longitude between -180 and 180));
  end if;
end $$;
