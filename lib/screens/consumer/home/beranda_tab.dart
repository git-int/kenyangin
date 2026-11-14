import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/shop_models.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../shared/consumer_widgets.dart';

class BerandaTab extends StatefulWidget {
  final ValueChanged<SurplusProduct> onOpenProduct;
  final VoidCallback onOpenOrders;

  const BerandaTab({
    super.key,
    required this.onOpenProduct,
    required this.onOpenOrders,
  });

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();
    final products = provider.filteredProducts;
    final featured = products.isNotEmpty ? products.first : null;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _Header(
            name: provider.firstName,
            onNotification: () => _showNotification(context),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7DFC4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 13,
                  color: Color(0xFF8C5A2B),
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Ambil Sendiri di Toko',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C5A2B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderCard),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: provider.setSearchQuery,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Cari makanan favoritmu...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openFilterSheet(context, provider),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderCard),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PromoBanner(product: featured),
          const SizedBox(height: 10),
          _ImpactBanner(
            portions: provider.savedPortionsThisMonth,
            onTap: widget.onOpenOrders,
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Kategori Surplus',
            trailing: TextButton(
              onPressed: () => provider.setCategory(null),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryChip(
                  label: 'Semua',
                  icon: Icons.restaurant_menu_rounded,
                  selected: provider.selectedCategoryId == null,
                  onTap: () => provider.setCategory(null),
                ),
                const SizedBox(width: 8),
                ...provider.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: category.namaKategori,
                      icon: _categoryIcon(category.namaKategori),
                      selected:
                          provider.selectedCategoryId == category.categoryId,
                      onTap: () => provider.setCategory(category.categoryId),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      'Urutkan:',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                FilterChipSmall(
                  label: 'Terdekat',
                  icon: Icons.near_me_outlined,
                  selected: provider.sortMode == 'terdekat',
                  onTap: () => provider.setSortMode('terdekat'),
                ),
                const SizedBox(width: 8),
                FilterChipSmall(
                  label: 'Diskon Terbesar',
                  selected: provider.sortMode == 'diskon',
                  onTap: () => provider.setSortMode('diskon'),
                ),
                const SizedBox(width: 8),
                FilterChipSmall(
                  label: 'Harga Terendah',
                  selected: provider.sortMode == 'harga',
                  onTap: () => provider.setSortMode('harga'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _LocationStatusBanner(provider: provider),
          const SizedBox(height: 14),
          SectionHeader(
            title: 'Bungkus Sebelum Habis',
            trailing: Text(
              '${provider.openStoreCount} Toko Buka',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (products.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Belum ada surplus tersedia',
              message:
                  'Menu surplus dari mitra toko akan muncul di sini secara '
                  'otomatis. Coba muat ulang beberapa saat lagi.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 262,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductGridCard(
                  product: product,
                  isFavorite: provider.isFavorite(product.productId),
                  distanceLabel: provider.distanceLabelTo(product),
                  onTap: () => widget.onOpenProduct(product),
                  onOrder: () => widget.onOpenProduct(product),
                  onFavorite: () => _toggleFavorite(context, provider, product),
                );
              },
            ),
          const SizedBox(height: 16),
          const ImpactCard(
            title: 'Misi Zero Food Waste',
            message:
                'Setiap pesananmu membantu mengurangi emisi karbon CO₂ '
                'di kotamu.',
            icon: Icons.volunteer_activism_outlined,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    ConsumerProvider provider,
    SurplusProduct product,
  ) async {
    try {
      await provider.toggleFavorite(product.productId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ConsumerProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showNotification(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada notifikasi baru. Info stok surplus dan pesanan akan '
              'muncul di sini.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    ConsumerProvider provider,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: SingleChildScrollView(
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
                    const Text(
                      'Filter Katalog',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Urutkan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _sheetChip(
                          'Terdekat',
                          provider.sortMode == 'terdekat',
                          () {
                            provider.setSortMode('terdekat');
                            setSheetState(() {});
                          },
                        ),
                        _sheetChip(
                          'Diskon Terbesar',
                          provider.sortMode == 'diskon',
                          () {
                            provider.setSortMode('diskon');
                            setSheetState(() {});
                          },
                        ),
                        _sheetChip(
                          'Harga Terendah',
                          provider.sortMode == 'harga',
                          () {
                            provider.setSortMode('harga');
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _sheetChip(
                          'Semua',
                          provider.selectedCategoryId == null,
                          () {
                            provider.setCategory(null);
                            setSheetState(() {});
                          },
                        ),
                        ...provider.categories.map(
                          (category) => _sheetChip(
                            category.namaKategori,
                            provider.selectedCategoryId == category.categoryId,
                            () {
                              provider.setCategory(category.categoryId);
                              setSheetState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Tampilkan ${provider.filteredProducts.length} Menu',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.softGrey,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String name) {
    final text = name.toLowerCase();
    if (text.contains('minum') || text.contains('kopi')) {
      return Icons.local_cafe_outlined;
    }
    if (text.contains('kue') || text.contains('dessert')) {
      return Icons.cake_outlined;
    }
    if (text.contains('berat') || text.contains('nasi')) {
      return Icons.rice_bowl_outlined;
    }
    if (text.contains('surprise') || text.contains('paket')) {
      return Icons.card_giftcard_outlined;
    }
    return Icons.bakery_dining_outlined;
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onNotification;

  const _Header({required this.name, required this.onNotification});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $name! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onNotification,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 19,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.4),
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
            child: const Text(
              'S',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8C3B16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final SurplusProduct? product;

  const _PromoBanner({this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA24C), Color(0xFFD6472D)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.bolt,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'SURPLUS HARI INI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selamatkan Makanan\nLezat Hari Ini!',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Diskon ekstra 30% - 50% OFF\nsebelum toko tutup.',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FoodPhoto(
                    url: product?.fotoUrl,
                    width: 96,
                    height: 96,
                    radius: 16,
                    category: product?.namaKategori,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactBanner extends StatelessWidget {
  final int portions;
  final VoidCallback onTap;

  const _ImpactBanner({required this.portions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = portions > 0
        ? 'Kamu sudah menyelamatkan $portions porsi bulan ini!'
        : 'Setiap pesananmu membantu mengurangi food waste.';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF5EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD3E5D3)),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEEDC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 15,
                color: AppColors.textGreen,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.textGreen,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textGreen,
            ),
          ],
        ),
      ),
    );
  }
}

/// Strip kecil berisi status lokasi perangkat: jarak real-time aktif,
/// sedang dideteksi, atau izin lokasi ditolak.
class _LocationStatusBanner extends StatelessWidget {
  final ConsumerProvider provider;

  const _LocationStatusBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hasLocation = provider.hasLocation;
    final error = provider.locationMessage;

    if (!hasLocation && error == null && !provider.isLocating) {
      return const SizedBox.shrink();
    }

    final background = hasLocation
        ? AppColors.badgeGreenBg
        : AppColors.orangeSoft;
    final foreground = hasLocation
        ? AppColors.textGreen
        : AppColors.textAmber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation
                ? Icons.gps_fixed_rounded
                : provider.isLocating
                ? Icons.location_searching_rounded
                : Icons.location_off_outlined,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasLocation
                  ? 'Jarak toko dihitung real-time dari lokasi kamu saat ini.'
                  : provider.isLocating
                  ? 'Mendeteksi lokasi kamu...'
                  : error!,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: foreground,
              ),
            ),
          ),
          if (!hasLocation && !provider.isLocating)
            TextButton(
              onPressed: provider.needsLocationSettings
                  ? provider.openLocationSettings
                  : provider.retryLocation,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                provider.needsLocationSettings ? 'Pengaturan' : 'Aktifkan',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
