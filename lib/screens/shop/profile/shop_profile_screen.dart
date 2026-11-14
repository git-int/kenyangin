import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_user.dart';
import '../../../models/shop_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../../auth/change_password_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final auth = context.watch<AuthProvider>();
    final store = provider.store;
    final user = auth.user ?? provider.user;
    final kategori = _kategoriToko(provider.products);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 16),
        const Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Kelola informasi akun dan toko Anda',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        _AccountCard(
          user: user,
          onEdit: () => _openAccountSheet(context, user),
        ),
        const SizedBox(height: 12),
        if (store == null)
          const EmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: 'Profil toko belum tersedia',
            message: 'Muat ulang halaman untuk menyiapkan profil toko mitra.',
          )
        else
          _StoreInfoCard(
            store: store,
            isOpen: provider.isStoreOpen,
            kategori: kategori,
            onEdit: () => _openEditSheet(context, provider, store),
          ),
        const SizedBox(height: 18),
        const _SectionLabel('Pengaturan Utama'),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profil',
                subtitle: 'Nama, email, dan nomor HP',
                onTap: () => _openAccountSheet(context, user),
              ),
              const Divider(height: 1, color: AppColors.borderCard),
              _MenuTile(
                icon: Icons.storefront_outlined,
                title: 'Pengaturan Toko',
                subtitle: 'Nama gerai, alamat, WhatsApp, jam operasional',
                onTap: store == null
                    ? null
                    : () => _openEditSheet(context, provider, store),
              ),
              const Divider(height: 1, color: AppColors.borderCard),
              _MenuTile(
                icon: Icons.lock_outline_rounded,
                title: 'Keamanan Akun',
                subtitle: 'Kata sandi & reset akses akun',
                onTap: () => _showSecurity(context, user),
              ),
              const Divider(height: 1, color: AppColors.borderCard),
              _MenuTile(
                icon: Icons.password_rounded,
                title: 'Ubah Kata Sandi',
                subtitle: 'Ganti kata sandi akun mitra sekarang',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.dangerBorder),
              backgroundColor: const Color(0xFFFFFBFA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Kenyangin Mitra • v1.0.0',
            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  List<String> _kategoriToko(List<SurplusProduct> products) {
    final result = <String>[];
    for (final product in products) {
      final nama = product.namaKategori?.trim();
      if (nama == null || nama.isEmpty) continue;
      if (!result.contains(nama)) result.add(nama);
    }
    return result;
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Kamu perlu login kembali untuk mengakses dashboard mitra.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  Future<void> _openAccountSheet(BuildContext context, AppUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditAccountSheet(user: user),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    ShopProvider provider,
    ShopStore store,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditStoreSheet(provider: provider, store: store),
    );
  }

  Future<void> _showSecurity(BuildContext context, AppUser user) async {
    final email = user.email.trim();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
            SizedBox(width: 7),
            Text(
              'Keamanan Akun',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          email.isEmpty
              ? 'Email akun belum tersedia, jadi tautan reset kata sandi '
                    'tidak bisa dikirim.'
              : 'Kami akan mengirim tautan reset kata sandi ke:\n\n$email',
          style: const TextStyle(fontSize: 12.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Batal'),
          ),
          if (email.isNotEmpty)
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kirim Tautan'),
            ),
        ],
      ),
    );

    if (confirmed != true || email.isEmpty) return;

    try {
      await auth.sendPasswordReset(email);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Tautan reset kata sandi dikirim ke $email'),
          backgroundColor: AppColors.textGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ShopProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Baris merek + badge status mitra di bagian paling atas tab profil.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFBE3D5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'K',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Kenyangin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _BadgePill(
              icon: Icons.storefront_outlined,
              label: 'Mitra Toko',
              background: Color(0xFFF3FAF1),
              foreground: AppColors.textGreen,
              borderColor: Color(0xFFDDEFD9),
            ),
            SizedBox(height: 4),
            _BadgePill(
              icon: Icons.verified_rounded,
              label: 'Mitra Terverifikasi',
              background: AppColors.badgeGreenBg,
              foreground: AppColors.textGreen,
              borderColor: Color(0xFFCFE8CE),
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;

  const _BadgePill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit;

  const _AccountCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final nama = user.nama.trim().isEmpty ? 'Mitra Kenyangin' : user.nama.trim();
    final inisial = nama.substring(0, 1).toUpperCase();
    final email = user.email.trim().isEmpty ? 'Email belum diisi' : user.email.trim();
    final nomorHp = (user.noHp ?? '').trim();
    final hp = nomorHp.isEmpty ? 'Nomor HP belum diisi' : nomorHp;

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF4D3B8), Color(0xFFE7A97C)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      inisial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8C3B16),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -1,
                    bottom: -1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.textGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        _RolePill(
                          label: user.isToko
                              ? 'Owner / Store Admin'
                              : 'Konsumen',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _ContactRow(
                      icon: Icons.mail_outline_rounded,
                      value: email,
                    ),
                    const SizedBox(height: 3),
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      value: hp,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _TonalButton(
              icon: Icons.edit_outlined,
              label: 'Edit Profil',
              onTap: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;

  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF6C9BF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TonalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TonalButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerSoft,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  final ShopStore store;
  final bool isOpen;
  final List<String> kategori;
  final VoidCallback onEdit;

  const _StoreInfoCard({
    required this.store,
    required this.isOpen,
    required this.kategori,
    required this.onEdit,
  });

  String get _whatsapp {
    final nomor = (store.noWhatsapp ?? '').trim();
    return nomor.isEmpty ? 'Belum diisi' : nomor;
  }

  String get _koordinat {
    final lat = store.latitude;
    final lng = store.longitude;
    if (lat == null || lng == null) return 'Belum diisi';
    return 'Lat: ${lat.toStringAsFixed(4)}, '
        'Long: ${lng.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Toko',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Data sinkron tabel stores (Supabase)',
                      style: TextStyle(
                        fontSize: 7.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Toko',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderCard),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  store.namaToko,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Jam Operasional',
                    style: TextStyle(
                      fontSize: 7.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    store.jamOperasional,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...kategori.take(2).map((nama) => _TagChip(label: nama)),
              _StatusChip(isOpen: isOpen),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.softGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat Lengkap Gerai',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        store.alamat,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  icon: Icons.chat_outlined,
                  iconColor: AppColors.textGreen,
                  label: 'WhatsApp Toko',
                  value: _whatsapp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoBox(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.primary,
                  label: 'Titik Koordinat',
                  value: _koordinat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orangeBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.textAmber,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;

  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.textGreen : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.badgeGreenBg : AppColors.softGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Buka' : 'Tutup',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: AppColors.softGrey,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditAccountSheet extends StatefulWidget {
  final AppUser user;

  const _EditAccountSheet({required this.user});

  @override
  State<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends State<_EditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _hpController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.user.nama);
    _hpController = TextEditingController(text: widget.user.noHp ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ShopProvider>();
    final auth = context.read<AuthProvider>();

    try {
      await provider.updateAccountProfile(
        nama: _namaController.text.trim(),
        noHp: _hpController.text.trim(),
      );
      await auth.loadUser();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profil akun berhasil diperbarui.'),
          backgroundColor: AppColors.textGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ShopProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email.trim();

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Perbarui data akun mitra kamu',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              const FieldLabel(text: 'Nama Lengkap', required: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Nama lengkap'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              const FieldLabel(text: 'Email'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGrey,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email.isEmpty ? 'Email belum diisi' : email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const FieldLabel(text: 'Nomor HP / WhatsApp'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _hpController,
                keyboardType: TextInputType.phone,
                decoration: _decoration('08xxxxxxxxxx'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _saving ? 'Menyimpan...' : 'Simpan Profil',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorStyle: const TextStyle(fontSize: 10, color: AppColors.primary),
    );
  }
}

class _EditStoreSheet extends StatefulWidget {
  final ShopProvider provider;
  final ShopStore store;

  const _EditStoreSheet({required this.provider, required this.store});

  @override
  State<_EditStoreSheet> createState() => _EditStoreSheetState();
}

class _EditStoreSheetState extends State<_EditStoreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  late final TextEditingController _namaController;
  late final TextEditingController _alamatController;
  late final TextEditingController _waController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late TimeOfDay _jamBuka;
  late TimeOfDay _jamTutup;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.store.namaToko);
    _alamatController = TextEditingController(text: widget.store.alamat);
    _waController = TextEditingController(text: widget.store.noWhatsapp ?? '');
    _latController = TextEditingController(
      text: _formatCoordinate(widget.store.latitude),
    );
    _lngController = TextEditingController(
      text: _formatCoordinate(widget.store.longitude),
    );
    _jamBuka = _parseTime(
      widget.store.jamBuka,
      const TimeOfDay(hour: 8, minute: 0),
    );
    _jamTutup = _parseTime(
      widget.store.jamTutup,
      const TimeOfDay(hour: 21, minute: 0),
    );
  }

  static String _formatCoordinate(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(6);
  }

  static double? _parseCoordinate(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    if (value == null) return fallback;
    final parts = value.split(':');
    if (parts.length < 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _waController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _jamBuka : _jamTutup,
      builder: (pickerContext, child) => Theme(
        data: Theme.of(pickerContext).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _jamBuka = picked;
      } else {
        _jamTutup = picked;
      }
    });
  }

  String? _validateLatitude(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = _parseCoordinate(text);
    if (parsed == null) return 'Gunakan angka, contoh -6.238200';
    if (parsed < -90 || parsed > 90) return 'Latitude harus di antara -90 dan 90';
    return null;
  }

  String? _validateLongitude(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = _parseCoordinate(text);
    if (parsed == null) return 'Gunakan angka, contoh 106.856700';
    if (parsed < -180 || parsed > 180) {
      return 'Longitude harus di antara -180 dan 180';
    }
    return null;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final readiness = await _locationService.ensureReady();
      if (!mounted) return;
      if (readiness != LocationReadiness.ready) {
        _showMessage(
          _locationService.errorMessage ?? 'Lokasi perangkat tidak tersedia.',
        );
        return;
      }

      final position = await _locationService.currentPosition();
      if (!mounted) return;
      if (position == null) {
        _showMessage(
          _locationService.errorMessage ??
              'Posisi toko tidak terbaca. Coba lagi di area terbuka.',
        );
        return;
      }

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
      _showMessage(
        'Koordinat diambil dari lokasi perangkat saat ini.',
        success: true,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.textGreen : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final latitude = _parseCoordinate(_latController.text);
    final longitude = _parseCoordinate(_lngController.text);
    if ((latitude == null) != (longitude == null)) {
      _showMessage(
        'Isi latitude dan longitude sekaligus, atau kosongkan keduanya.',
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.provider.updateStoreProfile(
        namaToko: _namaController.text.trim(),
        alamat: _alamatController.text.trim(),
        noWhatsapp: _waController.text.trim().isEmpty
            ? null
            : _waController.text.trim(),
        jamBuka: _formatTime(_jamBuka),
        jamTutup: _formatTime(_jamTutup),
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profil toko berhasil diperbarui.'),
          backgroundColor: AppColors.textGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ShopProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Edit Profil Toko',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              const FieldLabel(text: 'Nama Toko', required: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _namaController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Nama toko'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama toko wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              const FieldLabel(text: 'Alamat Lengkap', required: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Alamat titik penjemputan'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Alamat wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              const FieldLabel(text: 'Titik Koordinat Toko'),
              const SizedBox(height: 4),
              const Text(
                'Dipakai konsumen untuk menghitung jarak toko secara real-time '
                '(± akurat hingga beberapa meter).',
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latitude',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: _decoration('-6.238200'),
                          validator: _validateLatitude,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Longitude',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: _decoration('106.856700'),
                          validator: _validateLongitude,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.orangeBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: AppColors.textAmber,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cara cepat: buka Google Maps, tekan lama titik gerai, '
                        'lalu salin angka koordinat (contoh: -6.238200, '
                        '106.856700). Boleh pakai koma atau titik desimal.',
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 14),
                  label: Text(
                    _locating ? 'Mendeteksi lokasi...' : 'Gunakan lokasi saya',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.dangerBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const FieldLabel(text: 'Nomor WhatsApp'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _waController,
                keyboardType: TextInputType.phone,
                decoration: _decoration('08xxxxxxxxxx'),
              ),
              const SizedBox(height: 12),
              const FieldLabel(text: 'Jam Operasional'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Buka',
                      time: _jamBuka,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeField(
                      label: 'Tutup',
                      time: _jamTutup,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _saving ? 'Menyimpan...' : 'Simpan Profil Toko',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorStyle: const TextStyle(fontSize: 10, color: AppColors.primary),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:'
                      '${time.minute.toString().padLeft(2, '0')} WIB',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
