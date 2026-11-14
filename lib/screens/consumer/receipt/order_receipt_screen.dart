import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../theme/app_colors.dart';
import '../shared/consumer_tabs.dart';
import '../shared/consumer_widgets.dart';

class OrderReceiptScreen extends StatelessWidget {
  final ShopOrder order;
  final bool fromCheckout;

  const OrderReceiptScreen({
    super.key,
    required this.order,
    this.fromCheckout = false,
  });

  void _finish(BuildContext context, int tab) {
    ConsumerTabs.open(tab);
    if (fromCheckout) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = order.isPaid;

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 26),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConsumerBackButton(
                    onTap: () => _finish(context, 1),
                  ),
                ),
                const SizedBox(height: 14),
                const _SuccessHeader(),
                const SizedBox(height: 16),
                _ReceiptCard(order: order, paid: paid),
                const SizedBox(height: 12),
                ImpactCard(
                  title: 'Terima kasih! ðŸŒ±',
                  message:
                      'Kamu menyelamatkan ${order.totalPorsi} porsi makanan '
                      'dan mengurangi Â±${(order.totalPorsi * 0.32).toStringAsFixed(1)} '
                      'kg emisi COâ‚‚.',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _finish(context, 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 17),
                        SizedBox(width: 7),
                        Text(
                          'Lihat Pesanan Saya',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _finish(context, 0),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: AppColors.badgeGreenBg,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              size: 38,
              color: AppColors.textGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pesanan Berhasil Dibuat!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tunjukkan nota digital ini ke kasir saat mengambil pesanan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final ShopOrder order;
  final bool paid;

  const _ReceiptCard({required this.order, required this.paid});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                const Text(
                  'KODE PENGAMBILAN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.displayCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderCard),
                  ),
                  child: QrImageView(
                    data: 'Kenyangin|${order.orderId}|${order.qrToken}',
                    version: QrVersions.auto,
                    size: 148,
                    gapless: true,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.textPrimary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tunjukkan QR ini ke kasir ${order.storeDisplayName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const _ReceiptDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  label: 'Toko',
                  value: order.storeDisplayName,
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: (order.storeAlamat ?? '').trim().isEmpty
                      ? 'Alamat toko belum diisi mitra.'
                      : order.storeAlamat!,
                ),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Waktu Ambil',
                  value: pickupWindowForOrder(order),
                ),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Tanggal',
                  value: Formats.date(order.tanggalPesan),
                ),
                const SizedBox(height: 4),
                const DottedDivider(),
                const SizedBox(height: 10),
                const Text(
                  'Rincian Pesanan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  const Text(
                    'Detail produk tidak tersedia.',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  )
                else
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.jumlah}x ${item.namaProduk}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
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
                    ),
                  ),
                const SizedBox(height: 6),
                const DottedDivider(),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Pembayaran',
                  value: order.metodeLabel,
                ),
                _ReceiptStatus(paid: paid),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Bayar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      Formats.rupiah(order.totalHarga),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomPaint(painter: _PerforationPainter()),
            ),
          ),
          Positioned(
            left: -9,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.shopBackground,
            ),
          ),
          Positioned(
            right: -9,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.shopBackground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8C6B8)
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.4,
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

class _ReceiptStatus extends StatelessWidget {
  final bool paid;

  const _ReceiptStatus({required this.paid});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 21),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: paid ? AppColors.badgeGreenBg : AppColors.badgeAmberBg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          paid ? 'LUNAS' : 'BAYAR DI KASIR',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: paid ? AppColors.textGreen : AppColors.textAmber,
          ),
        ),
      ),
    );
  }
}

