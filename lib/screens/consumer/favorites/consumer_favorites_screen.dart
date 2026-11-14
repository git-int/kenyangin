import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/shop_models.dart';
import '../../../providers/consumer_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';
import '../shared/consumer_widgets.dart';

class ConsumerFavoritesScreen extends StatelessWidget {
  final ValueChanged<SurplusProduct> onOpenProduct;

  const ConsumerFavoritesScreen({super.key, required this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsumerProvider>();
    final favorites = provider.favoriteProducts;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            'Favorit',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            favorites.isEmpty
                ? 'Simpan menu surplus favoritmu di sini.'
                : '${favorites.length} menu surplus tersimpan.',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'Belum ada menu favorit',
                message:
                    'Tekan ikon hati pada menu surplus untuk menyimpannya. '
                    'Menu favorit memudahkanmu memantau stok dan diskon.',
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 262,
              ),
              itemBuilder: (context, index) {
                final product = favorites[index];
                return ProductGridCard(
                  product: product,
                  isFavorite: true,
                  distanceLabel: provider.distanceLabelTo(product),
                  onTap: () => onOpenProduct(product),
                  onOrder: () => onOpenProduct(product),
                  onFavorite: () => _removeFavorite(context, provider, product),
                );
              },
            ),
          const SizedBox(height: 16),
          const ImpactCard(
            title: 'Tips hemat',
            message:
                'Aktifkan favorit agar kamu lebih cepat tahu saat menu '
                'langgananmu kembali tersedia dengan harga surplus.',
            icon: Icons.lightbulb_outline_rounded,
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(
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
}
