import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../../auth/change_password_screen.dart';

class ConsumerProfileScreen extends StatelessWidget {
  const ConsumerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();
    final user = provider.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.6),
                ),
                child: Container(
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
                    _initial(user.nama),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8C3B16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nama.trim().isEmpty
                          ? 'Konsumen Kenyangin'
                          : user.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email.isEmpty ? '-' : user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Penyelamat Makanan ðŸŒ±',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB85C2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${provider.savedPortionsThisMonth}',
                label: 'Porsi',
                caption: 'Bulan ini',
                icon: Icons.restaurant_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                value: '${provider.completedOrders.length}',
                label: 'Pesanan',
                caption: 'Selesai',
                icon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                value: provider.savedCo2ThisMonth.toStringAsFixed(1),
                label: 'kg COâ‚‚',
                caption: 'Terselamatkan',
                icon: Icons.eco_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'Nama lengkap',
                value: user.nama.trim().isEmpty ? '-' : user.nama,
              ),
              _DividerLine(),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Nomor HP',
                value: (user.noHp ?? '').trim().isEmpty ? '-' : user.noHp!,
              ),
              _DividerLine(),
              _InfoTile(
                icon: Icons.alternate_email_rounded,
                label: 'Email',
                value: user.email.isEmpty ? '-' : user.email,
              ),
              _DividerLine(),
              _InfoTile(
                icon: Icons.favorite_border_rounded,
                label: 'Menu favorit',
                value: '${provider.favoriteIds.length} menu tersimpan',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.volunteer_activism_outlined,
                label: 'Misi Zero Food Waste',
                onTap: () => _showInfo(
                  context,
                  title: 'Misi Zero Food Waste',
                  message:
                      'Kenyangin menghubungkan konsumen dengan makanan surplus '
                      'dari mitra toko yang masih layak konsumsi. Setiap '
                      'pesanan membantu mengurangi makanan terbuang dan emisi '
                      'karbon dari produksi yang sia-sia.',
                ),
              ),
              _DividerLine(),
              _MenuTile(
                icon: Icons.lock_reset_rounded,
                label: 'Ubah Kata Sandi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _DividerLine(),
              _MenuTile(
                icon: Icons.shield_outlined,
                label: 'Kebijakan Privasi',
                onTap: () => _showInfo(
                  context,
                  title: 'Kebijakan Privasi',
                  message:
                      'Kenyangin hanya menyimpan data yang diperlukan untuk '
                      'layanan: nama, email, nomor HP, dan riwayat pesanan. '
                      'Data disimpan di Supabase dan hanya dapat diakses oleh '
                      'akunmu serta mitra toko terkait pesanan.',
                ),
              ),
              _DividerLine(),
              _MenuTile(
                icon: Icons.description_outlined,
                label: 'Syarat & Ketentuan',
                onTap: () => _showInfo(
                  context,
                  title: 'Syarat & Ketentuan',
                  message:
                      'Pesanan surplus wajib diambil sesuai jadwal yang '
                      'tertera. Pembayaran QRIS dikonfirmasi manual dan '
                      'pesanan yang sudah dibayar tidak dapat dikembalikan. '
                      'Ketersediaan produk mengikuti stok mitra toko.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, size: 17),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.dangerBorder),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Kenyangin â€¢ Selamatkan makanan, hemat budget.',
            style: TextStyle(fontSize: 8.5, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  static String _initial(String? name) {
    final text = (name ?? '').trim();
    if (text.isEmpty) return 'L';
    return text.substring(0, 1).toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final logout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Kamu perlu masuk kembali untuk melihat pesanan dan favorit.',
          style: TextStyle(fontSize: 11.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (logout != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  void _showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String caption;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 9),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 12,
      endIndent: 12,
      color: Color(0xFFF6EEE6),
    );
  }
}

