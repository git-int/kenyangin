import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../shared/consumer_widgets.dart';

class ConsumerOrdersScreen extends StatefulWidget {
  final ValueChanged<SurplusProduct> onOpenProduct;
  final ValueChanged<ShopOrder> onOpenReceipt;

  const ConsumerOrdersScreen({
    super.key,
    required this.onOpenProduct,
    required this.onOpenReceipt,
  });

  @override
  State<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends State<ConsumerOrdersScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();
    final active = provider.activeOrders;
    final history = provider.orders
        .where((order) => !order.isAktif)
        .toList()
      ..sort((a, b) => b.tanggalPesan.compareTo(a.tanggalPesan));
    final list = _segment == 0 ? active : history;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan Saya',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pantau pesanan surplus dan nota digitalmu.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: provider.refresh,
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
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SegmentSwitch(
            selected: _segment,
            activeCount: active.length,
            historyCount: history.length,
            onChanged: (value) => setState(() => _segment = value),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            EmptyState(
              icon: _segment == 0
                  ? Icons.shopping_bag_outlined
                  : Icons.history_rounded,
              title: _segment == 0
                  ? 'Belum ada pesanan aktif'
                  : 'Belum ada riwayat pesanan',
              message: _segment == 0
                  ? 'Yuk selamatkan makanan surplus hari ini. Pesanan yang '
                        'sedang berjalan akan muncul di sini.'
                  : 'Pesanan yang sudah selesai atau dibatalkan akan tampil '
                        'di sini.',
            )
          else
            ...list.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _segment == 0
                    ? _ActiveOrderCard(
                        order: order,
                        onOpenReceipt: () => widget.onOpenReceipt(order),
                        onCancel: () => _confirmCancel(context, provider, order),
                      )
                    : _HistoryOrderCard(
                        order: order,
                        onOpenReceipt: () => widget.onOpenReceipt(order),
                        onReorder: () => _reorder(context, provider, order),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    ConsumerProvider provider,
    ShopOrder order,
  ) async {
    final batal = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Batalkan Pesanan?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Pesanan ${order.displayCode} akan dibatalkan dan stok makanan '
          'dikembalikan ke toko.',
          style: const TextStyle(fontSize: 11.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Tidak'),
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
              'Ya, Batalkan',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (batal != true || !context.mounted) return;

    try {
      await provider.cancelOrder(order);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  void _reorder(
    BuildContext context,
    ConsumerProvider provider,
    ShopOrder order,
  ) {
    if (order.items.isEmpty) {
      _showUnavailable(context);
      return;
    }

    final productId = order.items.first.productId;
    SurplusProduct? product;
    for (final item in provider.products) {
      if (item.productId == productId) {
        product = item;
        break;
      }
    }

    if (product == null || product.stok <= 0) {
      _showUnavailable(context);
      return;
    }

    widget.onOpenProduct(product);
  }

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu ini sedang tidak tersedia di katalog surplus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  final int selected;
  final int activeCount;
  final int historyCount;
  final ValueChanged<int> onChanged;

  const _SegmentSwitch({
    required this.selected,
    required this.activeCount,
    required this.historyCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        children: [
          _segment('Aktif', activeCount, 0),
          _segment('Riwayat', historyCount, 1),
        ],
      ),
    );
  }

  Widget _segment(String label, int count, int index) {
    final active = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.softGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final ShopOrder order;
  final VoidCallback onOpenReceipt;
  final VoidCallback onCancel;

  const _ActiveOrderCard({
    required this.order,
    required this.onOpenReceipt,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final sisa = order.sisaWaktu;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order.storeDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                StatusBadge(
                  label: order.customerStatusLabel,
                  foreground: order.isPending
                      ? AppColors.textAmber
                      : AppColors.textGreen,
                  background: order.isPending
                      ? AppColors.badgeAmberBg
                      : AppColors.badgeGreenBg,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              order.ringkasanProduk,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  pickupWindowForOrder(order),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  Formats.rupiah(order.totalHarga),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF5E3C9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 15,
                    color: Color(0xFFB2731C),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      sisa.inSeconds <= 0
                          ? 'Batas pengambilan sudah lewat. Hubungi toko segera.'
                          : 'Ambil sebelum ${Formats.time(order.batasPengambilan)} '
                                'WIB • sisa ${Formats.countdown(sisa)}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A5A12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderCard),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Batalkan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: onOpenReceipt,
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: const Text(
                        'Lihat Nota Digital',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
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

class _HistoryOrderCard extends StatelessWidget {
  final ShopOrder order;
  final VoidCallback onOpenReceipt;
  final VoidCallback onReorder;

  const _HistoryOrderCard({
    required this.order,
    required this.onOpenReceipt,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final selesai = order.isSelesai;

    return SurfaceCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.storeDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              StatusBadge(
                label: selesai ? 'Selesai' : 'Dibatalkan',
                foreground: selesai ? AppColors.textGreen : AppColors.textMuted,
                background: selesai
                    ? AppColors.badgeGreenBg
                    : AppColors.softGrey,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.ringkasanProduk,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Formats.date(order.tanggalPesan)} • ${order.totalPorsi} porsi',
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                Formats.rupiah(order.totalHarga),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenReceipt,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Nota',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onReorder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.orangeBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Pesan Lagi',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
