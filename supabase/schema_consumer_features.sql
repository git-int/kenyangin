-- Jalankan skrip ini di Supabase SQL Editor agar fitur konsumen
-- (pesanan, nota digital, favorit) berfungsi penuh.
-- Aman dijalankan berulang kali (idempotent).

-- 1. Kolom pembayaran pada tabel orders -------------------------------
alter table public.orders
  add column if not exists metode_pembayaran text
    check (metode_pembayaran in ('qris', 'tunai'));
alter table public.orders
  add column if not exists status_pembayaran text
    check (status_pembayaran in ('menunggu', 'belum_lunas', 'lunas'));

-- 2. RLS tabel categories ---------------------------------------------
alter table public.categories enable row level security;

drop policy if exists "Pengguna dapat melihat kategori" on public.categories;
create policy "Pengguna dapat melihat kategori"
  on public.categories for select
  to authenticated
  using (true);

-- 3. RLS tabel favorites ----------------------------------------------
alter table public.favorites enable row level security;

drop policy if exists "Konsumen dapat melihat favoritnya" on public.favorites;
create policy "Konsumen dapat melihat favoritnya"
  on public.favorites for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Konsumen dapat menambah favorit" on public.favorites;
create policy "Konsumen dapat menambah favorit"
  on public.favorites for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Konsumen dapat menghapus favoritnya" on public.favorites;
create policy "Konsumen dapat menghapus favoritnya"
  on public.favorites for delete
  to authenticated
  using (user_id = auth.uid());

-- 4. RLS tabel order_details ------------------------------------------
alter table public.order_details enable row level security;

drop policy if exists "Pembeli & toko dapat membaca rincian pesanan"
  on public.order_details;
create policy "Pembeli & toko dapat membaca rincian pesanan"
  on public.order_details for select
  to authenticated
  using (
    exists (
      select 1
      from public.orders o
      where o.order_id = order_details.order_id
        and (
          o.user_id = auth.uid()
          or o.store_id in (
            select s.store_id
            from public.stores s
            where s.user_id = auth.uid()
          )
        )
    )
  );

drop policy if exists "Konsumen dapat menambah rincian pesanannya"
  on public.order_details;
create policy "Konsumen dapat menambah rincian pesanannya"
  on public.order_details for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.orders o
      where o.order_id = order_details.order_id
        and o.user_id = auth.uid()
    )
  );

-- 5. Fungsi stok (SECURITY DEFINER) -----------------------------------
-- Konsumen tidak diberi izin UPDATE langsung ke tabel products.
-- Perubahan stok hanya lewat fungsi berikut agar kolom lain tetap aman.
create or replace function public.decrement_product_stock(
  p_product_id uuid,
  p_jumlah integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_jumlah is null or p_jumlah <= 0 then
    raise exception 'Jumlah tidak valid';
  end if;

  update public.products
  set stok = greatest(stok - p_jumlah, 0),
      status = case
        when greatest(stok - p_jumlah, 0) = 0 then 'habis'
        else 'tersedia'
      end
  where product_id = p_product_id;
end;
$$;

create or replace function public.restore_product_stock(
  p_product_id uuid,
  p_jumlah integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_jumlah is null or p_jumlah <= 0 then
    return;
  end if;

  update public.products
  set stok = stok + p_jumlah,
      status = 'tersedia'
  where product_id = p_product_id;
end;
$$;

revoke all on function public.decrement_product_stock(uuid, integer)
  from public, anon;
revoke all on function public.restore_product_stock(uuid, integer)
  from public, anon;
grant execute on function public.decrement_product_stock(uuid, integer)
  to authenticated;
grant execute on function public.restore_product_stock(uuid, integer)
  to authenticated;
