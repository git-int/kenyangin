import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../payment/qris_payment_screen.dart';
import '../receipt/order_receipt_screen.dart';
import '../shared/consumer_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  final SurplusProduct product;
  final int jumlah;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.jumlah,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _metode = 'qris';
  bool _submitting = false;

  double get _total => widget.product.hargaSurplus * widget.jumlah;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      appBar: AppBar(
        backgroundColor: AppColors.shopBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(child: ConsumerBackButton()),
        ),
        leadingWidth: 56,
        title: const Text(
          'Konfirmasi Pesanan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _StepStrip(),
              const SizedBox(height: 14),
              _StoreCard(product: product),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Detail Pesanan',
                child: Column(
                  children: [
                    _OrderItemRow(
                      product: product,
                      jumlah: widget.jumlah,
                    ),
                    const SizedBox(height: 12),
                    const DottedDivider(),
                    const SizedBox(height: 12),
                    _PriceRow(
                      label: 'Harga satuan',
                      value: Formats.rupiah(product.hargaSurplus),
                    ),
                    const SizedBox(height: 6),
                    _PriceRow(
                      label: 'Jumlah',
                      value: '${widget.jumlah} porsi',
                    ),
                    const SizedBox(height: 6),
                    _PriceRow(
                      label: 'Harga asli',
                      value: Formats.rupiah(product.hargaAsli * widget.jumlah),
                      strike: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Jadwal Pengambilan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE1D9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hari ini, ${pickupWindowLabel(product)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Ambil sendiri di toko sebelum batas waktu.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Metode Pembayaran',
                child: Column(
                  children: [
                    _PaymentOption(
                      icon: Icons.qr_code_2_rounded,
                      title: 'QRIS',
                      subtitle: 'Scan & bayar dengan e-wallet atau m-banking',
                      selected: _metode == 'qris',
                      onTap: () => setState(() => _metode = 'qris'),
                    ),
                    const SizedBox(height: 8),
                    _PaymentOption(
                      icon: Icons.payments_outlined,
                      title: 'Tunai di Kasir',
                      subtitle: 'Bayar langsung saat mengambil pesanan',
                      selected: _metode == 'tunai',
                      onTap: () => setState(() => _metode = 'tunai'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Ringkasan Pembayaran',
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Subtotal (${widget.jumlah} porsi)',
                      value: Formats.rupiah(_total),
                    ),
                    const SizedBox(height: 6),
                    const _PriceRow(label: 'Biaya layanan', value: 'Gratis'),
                    const SizedBox(height: 10),
                    const DottedDivider(),
                    const SizedBox(height: 10),
                    _PriceRow(
                      label: 'Total Bayar',
                      value: Formats.rupiah(_total),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ImpactCard(
                title: 'Dampak baikmu',
                message:
                    'Pesanan ini menyelamatkan ${widget.jumlah} porsi makanan '
                    'dan mengurangi Â±${(0.32 * widget.jumlah).toStringAsFixed(1)} '
                    'kg emisi COâ‚‚.',
              ),
              const SizedBox(height: 8),
              const _AgreementNote(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _CheckoutBar(
        total: _total,
        metode: _metode,
        loading: _submitting,
        onConfirm: _submit,
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final provider = context.read<ConsumerProvider>();
    final navigator = Navigator.of(context);

    try {
      final order = await provider.placeOrder(
        product: widget.product,
        jumlah: widget.jumlah,
        metodePembayaran: _metode,
      );

      if (!mounted) return;

      if (_metode == 'qris') {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: QrisPaymentScreen(order: order),
            ),
          ),
        );
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: OrderReceiptScreen(order: order, fromCheckout: true),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ConsumerProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _StepStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StepDot(label: 'Pilih Menu', done: true),
        _StepLine(done: true),
        _StepDot(label: 'Konfirmasi', active: true),
        _StepLine(),
        _StepDot(label: 'Bayar'),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StepDot({required this.label, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final highlight = done || active;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: highlight ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlight ? AppColors.primary : AppColors.borderCard,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : active
              ? const Center(
                  child: SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;

  const _StepLine({this.done = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.4,
        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
        color: done ? AppColors.primary : AppColors.borderCard,
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final SurplusProduct product;

  const _StoreCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 20,
              color: Color(0xFFB85C2E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.storeDisplayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (product.storeAlamat ?? '').trim().isEmpty
                      ? 'Alamat toko belum diisi mitra.'
                      : product.storeAlamat!,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: AppColors.textMuted,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final SurplusProduct product;
  final int jumlah;

  const _OrderItemRow({required this.product, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FoodPhoto(
          url: product.fotoUrl,
          width: 52,
          height: 52,
          radius: 11,
          category: product.namaKategori,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.namaProduk,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$jumlah porsi Ã— ${Formats.rupiah(product.hargaSurplus)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          Formats.rupiah(product.hargaSurplus * jumlah),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDF1EE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderCard,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.softGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.35,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 5 : 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool strike;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.strike = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 12 : 10.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 14 : 10.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: bold ? AppColors.primary : AppColors.textPrimary,
            decoration: strike ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}

class _AgreementNote extends StatelessWidget {
  const _AgreementNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        'Dengan membuat pesanan, kamu menyetujui syarat layanan Kenyangin. '
        'Pesanan yang sudah dibayar tidak dapat dikembalikan.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 8.5,
          height: 1.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double total;
  final String metode;
  final bool loading;
  final VoidCallback onConfirm;

  const _CheckoutBar({
    required this.total,
    required this.metode,
    required this.loading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderCard)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Bayar',
                  style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  Formats.rupiah(total),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: loading ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                metode == 'qris'
                                    ? 'Bayar dengan QRIS'
                                    : 'Buat Pesanan',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
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

