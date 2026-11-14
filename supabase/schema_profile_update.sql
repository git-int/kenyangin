-- ============================================================================
-- Kenyangin - Update profil akun mitra (nama & nomor HP)
-- Opsional: jalankan di Supabase SQL Editor hanya jika tombol "Edit Profil"
-- gagal menyimpan dengan pesan akses ditolak (RLS).
-- Aman dijalankan berulang kali.
-- ============================================================================

alter table public.users enable row level security;

drop policy if exists "Pengguna dapat memperbarui profilnya" on public.users;
create policy "Pengguna dapat memperbarui profilnya"
  on public.users for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Batasi kolom yang boleh diubah sendiri supaya role tidak bisa dinaikkan.
revoke update on public.users from authenticated, anon;
grant update (nama, no_hp) on public.users to authenticated;
