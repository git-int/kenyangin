import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_colors.dart';
import '../qr_scanner/qr_scanner_screen.dart';

Future<void> showManualValidationDialog(
  BuildContext context, {
  String? initialCode,
}) {
  final provider = context.read<ShopProvider>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: _ValidationDialog(initialCode: initialCode),
    ),
  );
}

class _ValidationDialog extends StatefulWidget {
  final String? initialCode;

  const _ValidationDialog({this.initialCode});

  @override
  State<_ValidationDialog> createState() => _ValidationDialogState();
}

class _ValidationDialogState extends State<_ValidationDialog> {
  late final TextEditingController _controller;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.initialCode ?? '').replaceAll('#', ''),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted || code == null) return;
    _controller.text = code;
    await _validate();
  }

  Future<void> _validate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Masukkan kode pesanan terlebih dahulu.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await context.read<ShopProvider>().validateOrder(code);
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.textGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 8),
          Text(
            'Validasi Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan kode nota konsumen atau pindai QR code pada nota digital.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _validate(),
              decoration: InputDecoration(
                hintText: 'Contoh: LB-8829-JKT',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                errorText: _error,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loading ? null : _scan,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan QR Code'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _validate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Validasi'),
        ),
      ],
    );
  }
}

Future<bool> confirmCompleteOrder(BuildContext context, ShopOrder order) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Selesaikan Pesanan?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesanan ${order.displayCode} akan ditandai selesai.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pastikan konsumen sudah menerima makanan dan menunjukkan nota '
              'digital sebelum kamu menekan tombol selesai.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Ya, Selesaikan'),
        ),
      ],
    ),
  );

  return result ?? false;
}

Future<void> completeOrderWithFeedback(
  BuildContext context,
  ShopOrder order,
) async {
  final confirmed = await confirmCompleteOrder(context, order);
  if (!confirmed || !context.mounted) return;

  final provider = context.read<ShopProvider>();
  try {
    await provider.completeOrder(order);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pesanan ${order.displayCode} selesai. '
          '${Formats.number(order.totalPorsi)} porsi telah diselamatkan.',
        ),
        backgroundColor: AppColors.textGreen,
        behavior: SnackBarBehavior.floating,
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
}

Future<void> showStoreLocationDialog(BuildContext context, ShopStore store) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        store.namaToko,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  store.alamat,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(store.jamOperasional, style: const TextStyle(fontSize: 12)),
            ],
          ),
          if (store.noWhatsapp != null && store.noWhatsapp!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(store.noWhatsapp!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
