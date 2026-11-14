import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../receipt/order_receipt_screen.dart';
import '../shared/consumer_widgets.dart';

class QrisPaymentScreen extends StatefulWidget {
  final ShopOrder order;

  const QrisPaymentScreen({super.key, required this.order});

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  static const Duration _batasBayar = Duration(minutes: 15);

  late final DateTime _mulai = DateTime.now();
  Timer? _timer;
  Duration _sisa = const Duration(minutes: 15);
  bool _checking = false;

  bool get _expired => _sisa.inSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _sisa = _batasBayar;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_mulai);
      final sisa = _batasBayar - elapsed;
      if (!mounted) return;
      setState(() {
        _sisa = sisa.isNegative ? Duration.zero : sisa;
      });
      if (_sisa.inSeconds <= 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final menit = _sisa.inMinutes.toString().padLeft(2, '0');
    final detik = _sisa.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      appBar: AppBar(
        backgroundColor: AppColors.shopBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: ConsumerBackButton(
              onTap: () => _confirmCancel(context),
            ),
          ),
        ),
        leadingWidth: 56,
        title: const Text(
          'Pembayaran QRIS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _confirmCancel(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text(
              'Batalkan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _TimerBanner(
                expired: _expired,
                label: _expired ? 'Waktu pembayaran habis' : 'Selesaikan dalam',
                value: '$menit:$detik',
              ),
              const SizedBox(height: 12),
              _QrCard(order: order, expired: _expired),
              const SizedBox(height: 12),
              _PaymentGuide(order: order),
              const SizedBox(height: 12),
              const _ManualNote(),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _expired || _checking
                      ? null
                      : () => _checkStatus(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined, size: 17),
                            SizedBox(width: 7),
                            Text(
                              'Periksa Status Pembayaran',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _checking ? null : () => _switchToCash(context),
                icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                label: const Text(
                  'Ubah ke Tunai di Kasir',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkStatus(BuildContext context) async {
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Pastikan pembayaran QRIS sudah berhasil di aplikasi e-wallet atau '
          'm-banking kamu. Kenyangin belum terhubung ke payment gateway, jadi '
          'status pembayaran dikonfirmasi secara manual.',
          style: TextStyle(fontSize: 11.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Belum'),
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
              'Sudah Dibayar',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (lanjut != true || !mounted) return;

    setState(() => _checking = true);

    try {
      final provider = context.read<ConsumerProvider>();
      await provider.confirmPayment(widget.order);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: OrderReceiptScreen(
              order: _withPaidStatus(widget.order),
              fromCheckout: true,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ConsumerProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _switchToCash(BuildContext context) async {
    final ubah = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Ubah Metode Pembayaran',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Pesananmu akan dibayar tunai di kasir saat pengambilan. Lanjutkan?',
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
              'Ya, Ubah',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (ubah != true || !mounted) return;

    setState(() => _checking = true);

    try {
      final provider = context.read<ConsumerProvider>();
      await provider.changePaymentMethod(widget.order, 'tunai');
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: OrderReceiptScreen(
              order: _withMethod('tunai'),
              fromCheckout: true,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ConsumerProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
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
        content: const Text(
          'Pesanan akan dibatalkan dan stok makanan dikembalikan ke toko.',
          style: TextStyle(fontSize: 11.5, height: 1.5),
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

    if (batal != true || !mounted) return;

    setState(() => _checking = true);

    try {
      final provider = context.read<ConsumerProvider>();
      await provider.cancelOrder(widget.order);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ConsumerProvider.friendlyError(error)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  ShopOrder _withPaidStatus(ShopOrder order) {
    return ShopOrder(
      orderId: order.orderId,
      userId: order.userId,
      storeId: order.storeId,
      tanggalPesan: order.tanggalPesan,
      totalHarga: order.totalHarga,
      statusPesanan: order.statusPesanan,
      batasPengambilan: order.batasPengambilan,
      waktuPengambilan: order.waktuPengambilan,
      qrToken: order.qrToken,
      items: order.items,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      storeNama: order.storeNama,
      storeAlamat: order.storeAlamat,
      storePhone: order.storePhone,
      metodePembayaran: 'qris',
      statusPembayaran: 'lunas',
    );
  }

  ShopOrder _withMethod(String metode) {
    return ShopOrder(
      orderId: widget.order.orderId,
      userId: widget.order.userId,
      storeId: widget.order.storeId,
      tanggalPesan: widget.order.tanggalPesan,
      totalHarga: widget.order.totalHarga,
      statusPesanan: widget.order.statusPesanan,
      batasPengambilan: widget.order.batasPengambilan,
      waktuPengambilan: widget.order.waktuPengambilan,
      qrToken: widget.order.qrToken,
      items: widget.order.items,
      customerName: widget.order.customerName,
      customerPhone: widget.order.customerPhone,
      storeNama: widget.order.storeNama,
      storeAlamat: widget.order.storeAlamat,
      storePhone: widget.order.storePhone,
      metodePembayaran: metode,
      statusPembayaran: 'belum_lunas',
    );
  }
}

class _TimerBanner extends StatelessWidget {
  final String label;
  final String value;
  final bool expired;

  const _TimerBanner({
    required this.label,
    required this.value,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: expired ? AppColors.dangerSoft : const Color(0xFFFFF3DC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: expired ? AppColors.dangerBorder : const Color(0xFFF3DFB7),
        ),
      ),
      child: Row(
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 18,
            color: expired ? AppColors.primary : AppColors.textAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: expired ? AppColors.primary : AppColors.textAmber,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: expired ? AppColors.primary : AppColors.textAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final ShopOrder order;
  final bool expired;

  const _QrCard({required this.order, required this.expired});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          const Text(
            'Scan QRIS untuk membayar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            order.storeDisplayName,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: Opacity(
              opacity: expired ? 0.35 : 1,
              child: QrImageView(
                data: 'Kenyangin|${order.orderId}|${order.qrToken}',
                version: QrVersions.auto,
                size: 196,
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
          ),
          const SizedBox(height: 14),
          Text(
            Formats.rupiah(order.totalHarga),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Total yang harus dibayar',
            style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const DottedDivider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.displayCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nota Digital',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentGuide extends StatelessWidget {
  final ShopOrder order;

  const _PaymentGuide({required this.order});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara Membayar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const _GuideStep(
            number: '1',
            text: 'Buka aplikasi e-wallet atau m-banking yang mendukung QRIS.',
          ),
          const _GuideStep(
            number: '2',
            text: 'Pilih menu Scan QR, lalu arahkan kamera ke kode di atas.',
          ),
          _GuideStep(
            number: '3',
            text:
                'Periksa nominal ${Formats.rupiah(order.totalHarga)} dan '
                'selesaikan pembayaran.',
          ),
          const _GuideStep(
            number: '4',
            text:
                'Kembali ke Kenyangin lalu tekan â€œPeriksa Status Pembayaranâ€.',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;
  final bool last;

  const _GuideStep({
    required this.number,
    required this.text,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE1D9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualNote extends StatelessWidget {
  const _ManualNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textMuted),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'QR ini hanya simulasi pembayaran. Status lunas dicatat setelah '
              'kamu menekan tombol konfirmasi.',
              style: TextStyle(
                fontSize: 9.5,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

