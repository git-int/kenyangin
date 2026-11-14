-- ============================================================================
-- LastBite - Fitur Dashboard Mitra Toko
-- Jalankan file ini di Supabase SQL Editor setelah schema Bab 3 dibuat.
-- Script bersifat idempotent (aman dijalankan berulang kali).
-- ============================================================================

-- 1. Master kategori untuk dropdown form produk.
insert into public.categories (nama_kategori, deskripsi) values
  ('Roti & Pastry', 'Aneka croissant, roti tawar artisan, pastry gurih, dan roti manis berkualitas'),
  ('Kue & Dessert', 'Cake potong, tart mini, donat artisan, dan aneka kue basah'),
  ('Makanan Berat', 'Rice bowl, pasta, bento, dan hidangan utama siap santap'),
  ('Minuman', 'Kopi cold brew, jus buah murni segar, dan aneka minuman artisan'),
  ('Surprise Bag', 'Paket misteri aneka surplus lezat akhir hari dengan diskon 50-60%')
on conflict (nama_kategori) do nothing;

-- 2. Status buka/tutup toko yang dapat diubah mitra dari dashboard.
alter table public.stores
  add column if not exists is_open boolean not null default true;

-- 3. Kategori harus bisa dibaca aplikasi tanpa sesi login (halaman publik).
alter table public.categories enable row level security;

drop policy if exists "Semua pengguna dapat membaca kategori" on public.categories;
create policy "Semua pengguna dapat membaca kategori"
  on public.categories for select
  to anon, authenticated
  using (true);

-- 4. Mitra toko perlu melihat nama konsumen yang memesan di tokonya.
--    Tanpa policy ini, join profil konsumen pada halaman Pesanan akan kosong.
drop policy if exists "Toko dapat membaca profil konsumen pemesan" on public.users;
create policy "Toko dapat membaca profil konsumen pemesan"
  on public.users for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      join public.stores s on s.store_id = o.store_id
      where o.user_id = users.user_id
        and s.user_id = auth.uid()
    )
  );

-- 5. Bucket foto produk surplus.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public Access product-images" on storage.objects;
create policy "Public Access product-images"
  on storage.objects for select
  using (bucket_id = 'product-images');

drop policy if exists "Authenticated Store Upload product-images" on storage.objects;
create policy "Authenticated Store Upload product-images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and exists (
      select 1 from public.users
      where user_id = auth.uid() and role = 'toko'
    )
  );

drop policy if exists "Store can update own product images" on storage.objects;
create policy "Store can update own product images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1 from public.stores
      where user_id = auth.uid()
        and (storage.foldername(name))[1] = store_id::text
    )
  );

drop policy if exists "Store can delete own product images" on storage.objects;
create policy "Store can delete own product images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1 from public.stores
      where user_id = auth.uid()
        and (storage.foldername(name))[1] = store_id::text
    )
  );
