import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/shop_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../repositories/shop_repository.dart';
import '../../../theme/app_colors.dart';
import '../catalog/shop_catalog_screen.dart';
import '../dashboard/shop_dashboard_screen.dart';
import '../orders/shop_orders_screen.dart';
import '../product_form/product_form_screen.dart';
import '../profile/shop_profile_screen.dart';
import '../reports/shop_reports_screen.dart';

class ShopHomeScreen extends StatelessWidget {
  final ShopRepository? repository;

  const ShopHomeScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider(
      create: (_) =>
          ShopProvider(user: user, repository: repository)..load(),
      child: const _ShopShell(),
    );
  }
}

class _ShopShell extends StatefulWidget {
  const _ShopShell();

  @override
  State<_ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<_ShopShell> {
  int _index = 0;

  void _goTo(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  Future<void> _openProductForm({SurplusProduct? product}) async {
    final provider = context.read<ShopProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ProductFormScreen(product: product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            // Wajib expand: tanpa ini IndexedStack (StackFit.loose) menyusut
            // ke tinggi 0 dan seluruh konten tab jadi tidak terlihat.
            child: SizedBox.expand(
              child: _buildBody(context, provider),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ShopBottomNav(
        index: _index,
        badgeCount: provider.pendingOrders.length,
        onChanged: _goTo,
      ),
    );
  }

  Widget _buildBody(BuildContext context, ShopProvider provider) {
    if (provider.isLoading && provider.store == null) {
      return const _LoadingView();
    }

    if (provider.store == null) {
      return _ErrorView(
        message: provider.errorMessage ?? 'Profil toko belum tersedia. Pastikan akun terdaftar sebagai mitra toko.',
        onRetry: () => provider.load(),
      );
    }

    return IndexedStack(
      index: _index,
      sizing: StackFit.expand,
      children: [
        DashboardTab(
          onAddProduct: () => _openProductForm(),
          onOpenCatalog: () => _goTo(1),
          onOpenOrders: () => _goTo(2),
          onEditProduct: (product) =>
              _openProductForm(product: product),
        ),
        CatalogTab(
          onBack: () => _goTo(0),
          onAddProduct: () => _openProductForm(),
          onEditProduct: (product) =>
              _openProductForm(product: product),
        ),
        const OrdersTab(),
        const ReportsTab(),
        const ProfileTab(),
      ],
    );
  }
}

class _ShopBottomNav extends StatelessWidget {
  final int index;
  final int badgeCount;
  final ValueChanged<int> onChanged;

  const _ShopBottomNav({
    required this.index,
    required this.badgeCount,
    required this.onChanged,
  });

  static const List<({IconData icon, IconData activeIcon, String label})>
  _items = [
    (
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
      label: 'Dashboard',
    ),
    (
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Katalog',
    ),
    (
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Pesanan',
    ),
    (
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Laporan',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderCard)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Row(
                children: List.generate(_items.length, (itemIndex) {
                  final item = _items[itemIndex];
                  final active = itemIndex == index;

                  return Expanded(
                    child: InkWell(
                      onTap: () => onChanged(itemIndex),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                active ? item.activeIcon : item.icon,
                                size: 21,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              if (itemIndex == 2 && badgeCount > 0)
                                Positioned(
                                  right: -7,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 13,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      badgeCount > 9 ? '9+' : '$badgeCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Menyiapkan dashboard toko...',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Gagal memuat dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
              child: const Text('Keluar dari akun'),
            ),
          ],
        ),
      ),
    );
  }
}
