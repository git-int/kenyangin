import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../shared/shop_dialogs.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final TextEditingController _codeController = TextEditingController();
  int _selectedTab = 0;
  bool _verifying = false;

  String get _shiftLabel {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Shift Pagi';
    if (hour >= 12 && hour < 17) return 'Shift Siang';
    if (hour >= 17 && hour < 21) return 'Shift Sore';
    return 'Shift Malam';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted || code == null) return;
    _codeController.text = code;
    await _validate(code);
  }

  Future<void> _validate(String code) async {
    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode nota konsumen terlebih dahulu.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _verifying = true);
    final result = await context.read<ShopProvider>().validateOrder(code);
    if (!mounted) return;
    setState(() => _verifying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? AppColors.textGreen
            : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result.success) {
      _codeController.clear();
      if (mounted) setState(() => _selectedTab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final store = provider.store;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (store != null)
            _OrdersStoreHeader(store: store, isOpen: provider.isStoreOpen),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: const Text(
                  'Pesanan Konsumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _shiftLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Perlu Validasi',
                  count: provider.needActionCount,
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  label: 'Selesai Hari Ini',
                  count: provider.completedToday.length,
                  selected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Scan QR Nota Konsumen',
            icon: Icons.qr_code_scanner,
            colors: AppColors.orangeGradient,
            onTap: _scanQr,
          ),
          const SizedBox(height: 12),
          _ManualCodeCard(
            controller: _codeController,
            loading: _verifying,
            onVerify: () => _validate(_codeController.text),
          ),
          const SizedBox(height: 18),
          if (_selectedTab == 0) ...[
            SectionHeader(
              icon: Icons.pending_actions_outlined,
              title: 'Menunggu Pengambilan',
              trailing: const Text(
                'Prioritas Waktu',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (provider.activeOrders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Tidak ada pesanan aktif',
                message:
                    'Pesanan baru dari konsumen akan muncul di sini '
                    'secara otomatis.',
              )
            else
              ...List.generate(provider.activeOrders.length, (index) {
                final order = provider.activeOrders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActiveOrderCard(
                    order: order,
                    urgent: index == 0,
                    onValidate: () => showManualValidationDialog(
                      context,
                      initialCode: order.qrToken,
                    ),
                    onComplete: () => completeOrderWithFeedback(context, order),
                  ),
                );
              }),
            const SizedBox(height: 10),
            SectionHeader(
              icon: Icons.history_rounded,
              title: 'Riwayat Validasi Terakhir',
              trailing: const Text(
                'Hari Ini',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
            if (provider.completedToday.isEmpty)
              const EmptyState(
                icon: Icons.history_toggle_off_rounded,
                title: 'Belum ada riwayat hari ini',
                message:
                    'Pesanan yang selesai divalidasi akan tercatat di sini.',
              )
            else
              ...provider.completedToday
                  .take(4)
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HistoryTile(order: order),
                    ),
                  ),
          ] else
            _CompletedPanel(provider: provider),
        ],
      ),
    );
  }
}

class _OrdersStoreHeader extends StatelessWidget {
  final ShopStore store;
  final bool isOpen;

  const _OrdersStoreHeader({required this.store, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4D3B8), Color(0xFFE7A97C)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              store.initial,
              style: const TextStyle(
                fontSize: 18,
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
                Text(
                  store.namaToko,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
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
                    Text(
                      isOpen ? 'Kasir Aktif • Siap Pickup' : 'Kasir Tutup',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOpen
                            ? AppColors.textGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.location_on_outlined,
            background: AppColors.softGrey,
            foreground: AppColors.textSecondary,
            size: 32,
            tooltip: 'Lokasi toko',
            onTap: () => showStoreLocationDialog(context, store),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderCard,
          ),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ManualCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onVerify;

  const _ManualCodeCard({
    required this.controller,
    required this.loading,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atau Masukkan Kode Manual Konsumen',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => onVerify(),
                  decoration: InputDecoration(
                    hintText: 'LB-8829-JKT',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFDFAF7),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 43,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onVerify,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_outlined, size: 16),
                  label: const Text(
                    'Verifikasi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

class _ActiveOrderCard extends StatelessWidget {
  final ShopOrder order;
  final bool urgent;
  final VoidCallback onValidate;
  final VoidCallback onComplete;

  const _ActiveOrderCard({
    required this.order,
    required this.urgent,
    required this.onValidate,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isWaiting = order.isDiproses;
    final visibleItems = order.items.take(2).toList();

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      radius: 17,
      borderColor: urgent ? AppColors.primary : AppColors.borderCard,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order ID',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      order.displayCode,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (urgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 11, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Batas 40 mnt lagi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sudah Dibayar App',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.softGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Konsumen',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    urgent ? 'Batas Ambil' : 'Jadwal Ambil',
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    Formats.pickupWindow(
                      order.mulaiPengambilan,
                      order.batasPengambilan,
                    ),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...List.generate(visibleItems.length, (index) {
            final item = visibleItems[index];
            final isLast = index == visibleItems.length - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumb(
                    fotoUrl: item.fotoUrl,
                    size: 32,
                    radius: 8,
                    category: item.namaProduk,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.jumlah}x ${item.namaProduk}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isLast && isWaiting) ...[
                          const SizedBox(height: 4),
                          StatusBadge.grey('Bayar di Kasir'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Formats.rupiah(item.subtotal),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          if (urgent || isWaiting)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                label: const Text(
                  'Selesaikan Pesanan & Berikan Makanan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 110,
                child: OutlinedButton.icon(
                  onPressed: onValidate,
                  icon: const Icon(Icons.verified_outlined, size: 15),
                  label: const Text(
                    'Validasi',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.softGrey,
                    side: const BorderSide(color: AppColors.borderCard),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _HistoryTile extends StatelessWidget {
  final ShopOrder order;

  const _HistoryTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final waktu = order.waktuPengambilan ?? order.batasPengambilan;

    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      radius: 14,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.badgeGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: AppColors.textGreen,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.displayCode,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    StatusBadge.green('Selesai'),
                    const Spacer(),
                    Text(
                      Formats.timeWib(waktu),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.ringkasanProduk} • ${Formats.rupiah(order.totalHarga)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
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

class _CompletedPanel extends StatelessWidget {
  final ShopProvider provider;

  const _CompletedPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.completedToday.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt_rounded,
        title: 'Belum ada pesanan selesai',
        message:
            'Pesanan yang sudah diserahkan ke konsumen hari ini akan '
            'muncul di sini.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.badgeGreenBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCDE8CF)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 24,
                color: AppColors.textGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.savedPortionsToday} porsi diselamatkan hari ini',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pendapatan ${Formats.rupiah(provider.revenueToday)} • '
                      '± ${provider.savedCo2Today.toStringAsFixed(1)} kg CO₂',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionHeader(
          icon: Icons.task_alt_rounded,
          title: 'Daftar Selesai Hari Ini',
          trailing: StatusBadge.green(
            '${provider.completedToday.length} pesanan',
          ),
        ),
        ...provider.completedToday.map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              padding: const EdgeInsets.all(11),
              radius: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.displayCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge.green('Selesai'),
                      const Spacer(),
                      Text(
                        Formats.timeWib(
                          order.waktuPengambilan ?? order.tanggalPesan,
                        ),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${order.totalPorsi} porsi',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.ringkasanProduk,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        Formats.pickupWindow(
                          order.mulaiPengambilan,
                          order.batasPengambilan,
                        ),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formats.rupiah(order.totalHarga),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
