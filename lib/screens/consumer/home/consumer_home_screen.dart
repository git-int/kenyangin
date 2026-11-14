import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/shop_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../favorites/consumer_favorites_screen.dart';
import '../orders/consumer_orders_screen.dart';
import '../product_detail/product_detail_screen.dart';
import '../profile/consumer_profile_screen.dart';
import '../receipt/order_receipt_screen.dart';
import '../shared/consumer_tabs.dart';
import 'beranda_tab.dart';

class ConsumerHomeScreen extends StatelessWidget {
  final ConsumerProvider provider;

  const ConsumerHomeScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: _ConsumerShell(provider: provider),
    );
  }
}

class _ConsumerShell extends StatefulWidget {
  final ConsumerProvider provider;

  const _ConsumerShell({required this.provider});

  @override
  State<_ConsumerShell> createState() => _ConsumerShellState();
}

class _ConsumerShellState extends State<_ConsumerShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = ConsumerTabs.index.value;
    ConsumerTabs.index.addListener(_handleTabRequest);
    WidgetsBinding.instance.addObserver(this);
    widget.provider.load();
    widget.provider.startLocationUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConsumerTabs.index.removeListener(_handleTabRequest);
    widget.provider.stopLocationUpdates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat pengguna kembali dari Pengaturan lokasi, coba deteksi ulang.
    if (state != AppLifecycleState.resumed) return;
    final provider = widget.provider;
    if (!provider.hasLocation && provider.needsLocationSettings) {
      provider.retryLocation();
    }
  }

  void _handleTabRequest() {
    if (!mounted || _index == ConsumerTabs.index.value) return;
    setState(() => _index = ConsumerTabs.index.value);
  }

  void _goTo(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    ConsumerTabs.index.value = index;
  }

  void _openProduct(SurplusProduct product) {
    final provider = context.read<ConsumerProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ProductDetailScreen(product: product),
        ),
      ),
    );
  }

  void _openReceipt(ShopOrder order) {
    final provider = context.read<ConsumerProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: OrderReceiptScreen(order: order),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox.expand(
              child: _buildBody(provider),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ConsumerBottomNav(
        index: _index,
        badgeCount: provider.activeOrders.length,
        onChanged: _goTo,
      ),
    );
  }

  Widget _buildBody(ConsumerProvider provider) {
    if (provider.isLoading && provider.products.isEmpty) {
      return const _LoadingView();
    }

    if (provider.errorMessage != null && provider.products.isEmpty) {
      return _ErrorView(
        message: provider.errorMessage!,
        onRetry: () => provider.load(),
      );
    }

    return IndexedStack(
      index: _index,
      sizing: StackFit.expand,
      children: [
        BerandaTab(
          onOpenProduct: _openProduct,
          onOpenOrders: () => _goTo(1),
        ),
        ConsumerOrdersScreen(
          onOpenProduct: _openProduct,
          onOpenReceipt: _openReceipt,
        ),
        ConsumerFavoritesScreen(onOpenProduct: _openProduct),
        const ConsumerProfileScreen(),
      ],
    );
  }
}

class _ConsumerBottomNav extends StatelessWidget {
  final int index;
  final int badgeCount;
  final ValueChanged<int> onChanged;

  const _ConsumerBottomNav({
    required this.index,
    required this.badgeCount,
    required this.onChanged,
  });

  static const List<({IconData icon, IconData activeIcon, String label})>
  _items = [
    (
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Beranda',
    ),
    (
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Pesanan',
    ),
    (
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favorit',
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
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
                                size: 22,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              if (itemIndex == 1 && badgeCount > 0)
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
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 9.5,
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
            'Menyiapkan katalog surplus...',
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
              'Gagal memuat katalog',
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
