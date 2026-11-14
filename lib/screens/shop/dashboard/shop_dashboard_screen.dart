import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../shared/shop_dialogs.dart';

class DashboardTab extends StatelessWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenOrders;
  final ValueChanged<SurplusProduct> onEditProduct;

  const DashboardTab({
    super.key,
    required this.onAddProduct,
    required this.onOpenCatalog,
    required this.onOpenOrders,
    required this.onEditProduct,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final store = provider.store;
    final nextOrder = provider.nextPickupOrder;
    final needAction = provider.needActionCount;
    final savedPortions = provider.savedPortionsToday;
    final growth = provider.revenueGrowthPercent;
    final maxStock = provider.products.fold<int>(
      0,
      (max, product) => product.stok > max ? product.stok : max,
    );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _DashboardTopBar(onRefresh: provider.refresh),
          const SizedBox(height: 10),
          if (store != null) _StoreHeader(provider: provider, store: store),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Tambah Produk Surplus',
            icon: Icons.add,
            onTap: onAddProduct,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Stok Malam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Ringkasan Hari Ini',
            trailing: _RealtimeChip(onTap: provider.refresh),
          ),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Stok Aktif',
                  value: '${provider.stockPortions}',
                  unit: 'Porsi',
                  subtitle:
                      '${provider.availableProducts.length} jenis menu surplus',
                  icon: Icons.inventory_2_outlined,
                  iconBackground: AppColors.dangerSoft,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Perlu Diambil',
                  value: '$needAction',
                  unit: 'Pesanan',
                  subtitle: needAction > 0
                      ? '● Butuh verifikasi'
                      : '✓ Semua tertangani',
                  icon: Icons.access_time_filled_rounded,
                  iconBackground: AppColors.orangeSoft,
                  iconColor: AppColors.orange,
                  subtitleColor: needAction > 0
                      ? AppColors.orange
                      : AppColors.textGreen,
                  borderColor: needAction > 0
                      ? const Color(0xFFFF914D)
                      : null,
                  onTap: onOpenOrders,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Diselamatkan',
                  value: '$savedPortions',
                  unit: 'Porsi',
                  subtitle:
                      '🌱 ${provider.savedCo2Today.toStringAsFixed(1)} kg jejak CO₂',
                  icon: Icons.eco_rounded,
                  iconBackground: AppColors.badgeGreenBg,
                  iconColor: AppColors.textGreen,
                  subtitleColor: AppColors.textGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Pendapatan',
                  value: Formats.rupiah(provider.revenueToday),
                  subtitle: growth == null
                      ? 'Hari ini'
                      : '${growth >= 0 ? '📈 +' : '📉 '}${growth.abs()}% dr kemarin',
                  icon: Icons.payments_outlined,
                  iconBackground: AppColors.primary.withOpacity(0.08),
                  iconColor: AppColors.primary,
                  subtitleColor: growth != null && growth < 0
                      ? AppColors.primary
                      : AppColors.textGreen,
                  valueSize: 16.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DeadlineSection(order: nextOrder, onOpenOrders: onOpenOrders),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Katalog Surplus Hari Ini',
            trailing: TextButton(
              onPressed: onOpenCatalog,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Kelola (${provider.products.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (provider.products.isEmpty)
            EmptyState(
              icon: Icons.bakery_dining_outlined,
              title: 'Belum ada menu surplus',
              message:
                  'Tambahkan menu pertama untuk mulai menyelamatkan '
                  'makanan hari ini.',
              actionLabel: 'Tambah Produk Surplus',
              onAction: onAddProduct,
            )
          else
            ...provider.products
                .take(3)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DashboardProductTile(
                      product: product,
                      maxStock: maxStock,
                      onEdit: () => onEditProduct(product),
                      onAdd: onAddProduct,
                    ),
                  ),
                ),
          if (provider.products.length > 3)
            Center(
              child: TextButton(
                onPressed: onOpenCatalog,
                child: Text(
                  'Lihat semua ${provider.products.length} menu',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const _TipsCard(),
        ],
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _DashboardTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'Dashboard Mitra Toko',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.refresh_rounded,
          background: Colors.white,
          foreground: AppColors.textSecondary,
          size: 32,
          tooltip: 'Muat ulang data',
          onTap: onRefresh,
        ),
      ],
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final ShopProvider provider;
  final ShopStore store;

  const _StoreHeader({required this.provider, required this.store});

  @override
  Widget build(BuildContext context) {
    final isOpen = provider.isStoreOpen;

    return SurfaceCard(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4D3B8), Color(0xFFE7A97C)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              store.initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8C3B16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        store.namaToko,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: AppColors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.textGreen
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isOpen
                            ? 'Toko Buka (Menerima Pesanan)'
                            : 'Toko Tutup (Tidak Menerima Pesanan)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOpen
                              ? AppColors.textGreen
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.alamatSingkat} • ${store.jamOperasional}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppToggle(
            value: isOpen,
            onChanged: (value) async {
              try {
                await provider.setStoreOpen(value);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Toko dibuka. Kamu siap menerima pesanan.'
                          : 'Toko ditutup. Pesanan baru tidak ditampilkan.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ShopProvider.friendlyError(error)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _RealtimeChip extends StatelessWidget {
  final VoidCallback onTap;

  const _RealtimeChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderCard),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 11, color: AppColors.textSecondary),
            SizedBox(width: 4),
            Text(
              'Real-time',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color? subtitleColor;
  final VoidCallback? onTap;
  final double valueSize;
  final Color? borderColor;
  final String? trailingBadge;

  const _StatCard({
    required this.label,
    required this.value,
    this.unit,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.subtitleColor,
    this.onTap,
    this.valueSize = 22,
    this.borderColor,
  }) : trailingBadge = null;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      radius: 15,
      borderColor: borderColor,
      child: SizedBox(
        height: 94,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (trailingBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orangeSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trailingBadge!,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 13, color: iconColor),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      unit!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: subtitleColor ?? AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineSection extends StatelessWidget {
  final ShopOrder? order;
  final VoidCallback onOpenOrders;

  const _DeadlineSection({required this.order, required this.onOpenOrders});

  @override
  Widget build(BuildContext context) {
    final current = order;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.alarm,
          title: 'Mendekati Batas Waktu',
          trailing: current == null
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sisa ${Formats.countdown(current.batasPengambilan.difference(DateTime.now()))}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ),
        if (current == null)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Tidak ada pesanan mendesak',
            message:
                'Semua pesanan sudah tertangani. Terus pantau pesanan '
                'baru dari konsumen.',
          )
        else
          SurfaceCard(
            borderColor: AppColors.dangerBorder,
            color: const Color(0xFFFFFBFA),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      current.displayCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• Pelanggan: ${current.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textMuted,
                      ),
                      onSelected: (value) {
                        if (value == 'validate') {
                          showManualValidationDialog(
                            context,
                            initialCode: current.qrToken,
                          );
                        } else if (value == 'complete') {
                          completeOrderWithFeedback(context, current);
                        } else if (value == 'all') {
                          onOpenOrders();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'validate',
                          child: Text('Validasi kode / QR'),
                        ),
                        if (current.isDiproses)
                          const PopupMenuItem(
                            value: 'complete',
                            child: Text('Selesaikan pesanan'),
                          ),
                        const PopupMenuItem(
                          value: 'all',
                          child: Text('Lihat semua pesanan'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ProductThumb(
                      fotoUrl: current.items.isNotEmpty ? current.items.first.fotoUrl : null,
                      size: 46,
                      radius: 10,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.ringkasanProduk,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Batas Ambil: ${Formats.time(current.batasPengambilan)} WIB',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECE8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF3C5BB)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => showManualValidationDialog(
                            context,
                            initialCode: current.qrToken,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 17,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Validasi QR / Kode',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderCard),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Chat dengan ${current.customerName}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DashboardProductTile extends StatelessWidget {
  final SurplusProduct product;
  final int maxStock;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  const _DashboardProductTile({
    required this.product,
    required this.maxStock,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isHabis = product.isHabis;

    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      radius: 16,
      onTap: onEdit,
      child: Row(
        children: [
          Stack(
            children: [
              ProductThumb(
                fotoUrl: product.fotoUrl,
                size: 58,
                radius: 12,
                category: product.namaKategori,
              ),
              if (product.diskonPersen > 0 && !isHabis)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${product.diskonPersen}%',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (isHabis)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'HABIS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.namaProduk,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isHabis) ...[
                      const SizedBox(width: 6),
                      StatusBadge.grey('Habis Terjual'),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      Formats.rupiah(product.hargaSurplus),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        Formats.rupiah(product.hargaAsli),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (!isHabis)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    widthFactor: maxStock <= 0
                                        ? 0
                                        : (product.stok / maxStock).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Sisa ${product.stok} porsi',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.softGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 15,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: onEdit,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderCard),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.primary,
                          ),
                          onPressed: onAdd,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBE0C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 18,
            color: Color(0xFFE8722A),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Operasional Sore:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pesanan surplus biasanya melonjak 65% antara jam 19.00 - 20.30 WIB. Pastikan stok etalase sudah diupdate sebelum toko tutup!',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
