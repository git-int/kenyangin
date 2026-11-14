import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../checkout/checkout_screen.dart';
import '../shared/consumer_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final SurplusProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _jumlah = 1;

  int get _maxJumlah => widget.product.stok <= 0 ? 1 : widget.product.stok;

  void _openCheckout() {
    final provider = context.read<ConsumerProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: CheckoutScreen(product: widget.product, jumlah: _jumlah),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();
    final product = widget.product;
    final total = product.hargaSurplus * _jumlah;
    final favorite = provider.isFavorite(product.productId);

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _HeroSection(
                    product: product,
                    favorite: favorite,
                    onFavorite: () => _toggleFavorite(context, provider),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StoreLine(product: product),
                            const SizedBox(height: 10),
                            Text(
                              product.namaProduk,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if ((product.deskripsi ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                product.deskripsi!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _PriceCard(product: product),
                            const SizedBox(height: 16),
                            _PickupCard(product: product),
                            const SizedBox(height: 14),
                            _InfoLine(
                              icon: Icons.eco_outlined,
                              label: 'Makanan Surplus Segar',
                              value:
                                  'Dipanggang/disiapkan hari ini dan tetap '
                                  'layak konsumsi. Membantu menyelamatkan '
                                  '${(0.32 * _jumlah).toStringAsFixed(1)} kg '
                                  'jejak karbon.',
                            ),
                            const SizedBox(height: 10),
                            const _InfoLine(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Catatan Pengambilan',
                              value:
                                  'Harap bawa kantong belanja sendiri dan '
                                  'tunjukkan nota digital saat tiba di toko.',
                            ),
                            if (product.batasKonsumsi != null) ...[
                              const SizedBox(height: 10),
                              _InfoLine(
                                icon: Icons.schedule_outlined,
                                label: 'Batas Konsumsi',
                                value: _consumptionLabel(product.batasKonsumsi!),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _LocationSection(product: product),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jumlah Porsi',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Maksimal ${product.stok} porsi per '
                                        'pesanan',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                QuantityStepper(
                                  value: _jumlah,
                                  min: 1,
                                  max: _maxJumlah,
                                  onChanged: (value) =>
                                      setState(() => _jumlah = value),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ImpactCard(
                              message:
                                  'Dengan mengklaim ini, kamu menyelamatkan '
                                  '$_jumlah porsi makanan dari potensi food '
                                  'waste hari ini!',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            total: total,
            onClaim: product.stok <= 0 ? null : _openCheckout,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    ConsumerProvider provider,
  ) async {
    try {
      await provider.toggleFavorite(widget.product.productId);
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

  static String _consumptionLabel(DateTime batas) {
    final jam = batas.difference(DateTime.now()).inHours;
    if (jam <= 0) return 'Segera dikonsumsi setelah diambil.';
    if (jam < 24) {
      return 'Sebaiknya dikonsumsi dalam $jam jam untuk kesegaran optimal.';
    }
    return 'Sebaiknya dikonsumsi dalam ${(jam / 24).round()} hari untuk '
        'kesegaran optimal.';
  }
}

class _HeroSection extends StatelessWidget {
  final SurplusProduct product;
  final bool favorite;
  final VoidCallback onFavorite;

  const _HeroSection({
    required this.product,
    required this.favorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FoodPhoto(
            url: product.fotoUrl,
            width: double.infinity,
            height: 290,
            radius: 0,
            category: product.namaKategori,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: MediaQuery.of(context).padding.top + 4,
            child: Row(
              children: [
                const ConsumerBackButton(),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 14,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            product.storeDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CircleAction(
                  icon: Icons.ios_share_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bagikan menu surplus ini ke temanmu.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _CircleAction(
                  icon: favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: favorite ? AppColors.primary : AppColors.textSecondary,
                  onTap: onFavorite,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: MediaQuery.of(context).padding.top + 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8C3B16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 12, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    'Diskon ${product.diskonPersen}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Sisa ${product.stok} Porsi',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _StoreLine extends StatelessWidget {
  final SurplusProduct product;

  const _StoreLine({required this.product});

  @override
  Widget build(BuildContext context) {
    final alamat = (product.storeAlamat ?? '').trim();
    final lokasi = alamat.isEmpty
        ? null
        : alamat.split(',').first.trim();

    return Row(
      children: [
        Flexible(
          child: Text(
            product.storeDisplayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (lokasi != null) ...[
          const Text(
            ' • ',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          Flexible(
            child: Text(
              lokasi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final SurplusProduct product;

  const _PriceCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        Formats.rupiah(product.hargaSurplus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          Formats.rupiah(product.hargaAsli),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Harga surplus per paket',
                  style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 13,
                  color: Color(0xFFB85C2E),
                ),
                const SizedBox(width: 4),
                Text(
                  'Hemat ${Formats.rupiah(product.hemat)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB85C2E),
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

class _PickupCard extends StatelessWidget {
  final SurplusProduct product;

  const _PickupCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF1EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3C5BB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE1D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waktu Pengambilan Hari Ini',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pickupWindowLabel(product),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Harap tiba sebelum toko tutup pukul '
                  '${Formats.time(product.batasPengambilan)} WIB.',
                  style: const TextStyle(
                    fontSize: 9.5,
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppColors.textGreen),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  final SurplusProduct product;

  const _LocationSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final alamat = (product.storeAlamat ?? '').trim();
    final lat = product.storeLatitude;
    final lng = product.storeLongitude;
    final hasCoordinate = lat != null && lng != null;
    final consumer = context.watch<ConsumerProvider>();
    final distance = consumer.distanceLabelTo(product);
    final locationNote = consumer.locationMessage;

    final coordinateRow = hasCoordinate
        ? Row(
            children: [
              const Icon(
                Icons.gps_fixed_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Koordinat: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DottedDivider(),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi Penjemputan',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alamat.isEmpty ? 'Alamat toko belum diisi mitra.' : alamat,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (coordinateRow != null) ...[
                    const SizedBox(height: 6),
                    coordinateRow,
                  ],
                  const SizedBox(height: 6),
                  if (distance != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Jarak dari lokasi kamu: $distance',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      hasCoordinate
                          ? (locationNote ??
                                'Aktifkan lokasi untuk melihat jarak toko '
                                    'secara real-time.')
                          : 'Koordinat toko belum diisi mitra, jarak belum '
                                'bisa dihitung.',
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasCoordinate)
              _MapButton(
                // ignore: unnecessary_non_null_assertion
                lat: lat!,
                // ignore: unnecessary_non_null_assertion
                lng: lng!,
                storeName: product.storeDisplayName,
              )
            else
              OutlinedButton(
                onPressed: () => _showMapInfo(context, product),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.borderCard),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Peta',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showMapInfo(BuildContext context, SurplusProduct product) {
    final lat = product.storeLatitude;
    final lng = product.storeLongitude;
    final coordinate = (lat != null && lng != null)
        ? 'Koordinat: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
        : 'Koordinat toko belum diisi mitra.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Lokasi Penjemputan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.storeDisplayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.storeAlamat ?? '-',
              style: const TextStyle(fontSize: 11.5, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              coordinate,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
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
}

/// Tombol membuka lokasi toko di Google Maps (web/app).
class _MapButton extends StatelessWidget {
  final double lat;
  final double lng;
  final String storeName;

  const _MapButton({
    required this.lat,
    required this.lng,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openMap(context),
      icon: const Icon(Icons.open_in_new, size: 14),
      label: const Text(
        'Buka Peta',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.borderCard),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context) async {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    try {
      final launched = await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka peta.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka peta.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _BottomBar extends StatelessWidget {
  final double total;
  final VoidCallback? onClaim;

  const _BottomBar({required this.total, this.onClaim});

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
                  'Total Pembayaran',
                  style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  Formats.rupiah(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Klaim Pesanan Sekarang',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
