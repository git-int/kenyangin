import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../models/shop_models.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';

class CatalogTab extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onAddProduct;
  final ValueChanged<SurplusProduct> onEditProduct;

  const CatalogTab({
    super.key,
    required this.onBack,
    required this.onAddProduct,
    required this.onEditProduct,
  });

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final products = provider.filteredProducts;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // A. Header
          _CatalogTopBar(
            storeName: provider.storeName,
            isOpen: provider.isStoreOpen,
            onBack: widget.onBack,
            onFilterSettings: () => _openFilterSheet(context, provider),
            onHelp: () => _showHelpDialog(context),
          ),
          const SizedBox(height: 14),

          // B. Tab Filter Produk (Semua, Tersedia, Habis)
          _FilterTabs(provider: provider),
          const SizedBox(height: 12),

          // C. Search Bar
          _SearchBar(
            controller: _searchController,
            onChanged: provider.setSearchQuery,
            onClear: () {
              _searchController.clear();
              provider.setSearchQuery('');
              setState(() {});
            },
          ),
          const SizedBox(height: 12),

          // D. Informasi Produk Hari Ini (Summary Card)
          _SurplusSummaryCard(
            totalActiveProducts: provider.availableProducts.length,
            totalStockPortions: provider.stockPortions,
            totalCatalogProducts: provider.products.length,
          ),
          const SizedBox(height: 12),

          // E. Tombol Tambah Produk
          _AddProductButton(onTap: widget.onAddProduct),
          const SizedBox(height: 18),

          // F. Product List Header
          Row(
            children: [
              Expanded(
                child: Text(
                  '${products.length} menu ditampilkan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (provider.productSort != 'terbaru')
                GestureDetector(
                  onTap: () => provider.setProductSort('terbaru'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sortLabel(provider.productSort),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.close,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // F. Product List Content
          if (products.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Menu Tidak Ditemukan',
              message: provider.products.isEmpty
                  ? 'Belum ada menu surplus yang didaftarkan. Mulai tambahkan menu surplus pertamamu.'
                  : 'Tidak ada produk yang cocok dengan kata kunci atau filter yang dipilih.',
              actionLabel: provider.products.isEmpty
                  ? 'Tambah Menu Surplus'
                  : 'Reset Filter & Cari',
              onAction: provider.products.isEmpty
                  ? widget.onAddProduct
                  : () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                      provider.setProductFilter('semua');
                      provider.setProductSort('terbaru');
                      setState(() {});
                    },
            )
          else
            ...products.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CatalogProductCard(
                  product: product,
                  onEdit: () => widget.onEditProduct(product),
                  onDelete: () => _confirmDelete(context, product),
                  onRestock: () => _showRestockDialog(context, product),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // G. Tips Mitra Kenyangin Card
          const _TipsMitraCard(),
        ],
      ),
    );
  }

  static String _sortLabel(String sort) {
    switch (sort) {
      case 'stok_terendah':
        return 'Stok Terendah';
      case 'diskon_tertinggi':
        return 'Diskon Tertinggi';
      case 'harga_terendah':
        return 'Harga Termurah';
      default:
        return 'Terbaru';
    }
  }

  // ------------------------------------------------------------- Dialog Restock
  Future<void> _showRestockDialog(
    BuildContext context,
    SurplusProduct product,
  ) async {
    final provider = context.read<ShopProvider>();
    int added = 2;
    final controller = TextEditingController(text: '2');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalAfter = (product.stok < 0 ? 0 : product.stok) + added;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Restock Menu Surplus',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.namaProduk,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stok saat ini: ${product.stok} porsi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tambah jumlah porsi:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: added > 1
                          ? () {
                              setDialogState(() {
                                added--;
                                controller.text = added.toString();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppColors.primary,
                      iconSize: 28,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderCard,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            setDialogState(() => added = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setDialogState(() {
                          added++;
                          controller.text = added.toString();
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.primary,
                      iconSize: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 8,
                    children: [1, 2, 5, 10].map((count) {
                      final isSelected = added == count;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setDialogState(() {
                            added = count;
                            controller.text = added.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.softGrey,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '+$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.badgeGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.textGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Total stok akan menjadi $totalAfter porsi dan otomatis berstatus "Tersedia".',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGreen,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: added <= 0
                    ? null
                    : () async {
                        Navigator.of(dialogCtx).pop();
                        try {
                          await provider.restockProduct(product, added);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Stok "${product.namaProduk}" berhasil ditambah $added porsi.',
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
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan Stok'),
              ),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------- Hapus Produk Dialog
  Future<void> _confirmDelete(
    BuildContext context,
    SurplusProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Menu Surplus?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${product.namaProduk}" dari katalog toko?\n\n'
          'Riwayat pesanan yang sudah berjalan tetap tersimpan aman.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ShopProvider>().deleteProduct(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.namaProduk} berhasil dihapus dari katalog.'),
          backgroundColor: AppColors.textPrimary,
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

  // ---------------------------------------------------- Filter & Sort BottomSheet
  void _openFilterSheet(BuildContext context, ShopProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Urutkan & Pengaturan Katalog',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Urutkan Berdasarkan:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _sortListTile(
                  sheetContext,
                  provider,
                  title: 'Terbaru Ditambahkan',
                  value: 'terbaru',
                  icon: Icons.access_time_rounded,
                ),
                _sortListTile(
                  sheetContext,
                  provider,
                  title: 'Stok Terendah (Prioritas Habis)',
                  value: 'stok_terendah',
                  icon: Icons.inventory_2_outlined,
                ),
                _sortListTile(
                  sheetContext,
                  provider,
                  title: 'Diskon Paling Besar (% OFF)',
                  value: 'diskon_tertinggi',
                  icon: Icons.percent_rounded,
                ),
                _sortListTile(
                  sheetContext,
                  provider,
                  title: 'Harga Surplus Paling Terjangkau',
                  value: 'harga_terendah',
                  icon: Icons.price_check_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortListTile(
    BuildContext sheetContext,
    ShopProvider provider, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = provider.productSort == value;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        provider.setProductSort(value);
        Navigator.of(sheetContext).pop();
      },
    );
  }

  // ---------------------------------------------------- Bantuan Katalog Dialog
  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Panduan Katalog Toko',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HelpBullet(
                title: 'Status Tersedia & Habis',
                body:
                    'Menu dengan stok > 0 otomatis berstatus "Tersedia" dan tayang di konsumen. Jika stok habis (0 porsi), status berganti menjadi "Habis Terjual".',
              ),
              SizedBox(height: 10),
              _HelpBullet(
                title: 'Waktu Surplus Terbaik',
                body:
                    'Daftarkan menu surplus 2 jam sebelum operasional toko berakhir agar pelanggan sempat memesan dan mengambil pesanan.',
              ),
              SizedBox(height: 10),
              _HelpBullet(
                title: 'Fitur Restock',
                body:
                    'Gunakan tombol "Restock" pada menu habis untuk menambahkan porsi baru dengan cepat tanpa perlu mengisi ulang data menu.',
              ),
              SizedBox(height: 10),
              _HelpBullet(
                title: 'Harga Diskon Surplus',
                body:
                    'Tetapkan diskon minimal 50% dari harga asli agar surplus cepat terjual dan meminimalisir sisa makanan terbuang.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// A. HEADER COMPONENT
// ============================================================================

class _CatalogTopBar extends StatelessWidget {
  final String storeName;
  final bool isOpen;
  final VoidCallback onBack;
  final VoidCallback onFilterSettings;
  final VoidCallback onHelp;

  const _CatalogTopBar({
    required this.storeName,
    required this.isOpen,
    required this.onBack,
    required this.onFilterSettings,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tombol Kembali
        CircleIconButton(
          icon: Icons.arrow_back_rounded,
          background: Colors.white,
          foreground: AppColors.textPrimary,
          size: 38,
          onTap: onBack,
        ),
        const SizedBox(width: 12),

        // Judul & Status Toko
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Katalog Produk Toko',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.badgeGreenBg
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOpen
                                ? AppColors.textGreen
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOpen ? 'Buka' : 'Tutup',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isOpen
                                ? AppColors.textGreen
                                : const Color(0xFF757575),
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

        // Tombol Pengaturan / Filter
        CircleIconButton(
          icon: Icons.tune_rounded,
          background: Colors.white,
          foreground: AppColors.textPrimary,
          size: 36,
          tooltip: 'Pengaturan & Urutkan',
          onTap: onFilterSettings,
        ),
        const SizedBox(width: 6),

        // Tombol Bantuan
        CircleIconButton(
          icon: Icons.help_outline_rounded,
          background: Colors.white,
          foreground: AppColors.textPrimary,
          size: 36,
          tooltip: 'Bantuan Katalog',
          onTap: onHelp,
        ),
      ],
    );
  }
}

// ============================================================================
// B. TAB FILTER PRODUK (Semua, Tersedia, Habis)
// ============================================================================

class _FilterTabs extends StatelessWidget {
  final ShopProvider provider;

  const _FilterTabs({required this.provider});

  @override
  Widget build(BuildContext context) {
    final current = provider.productFilter;

    return Row(
      children: [
        Expanded(
          child: _FilterTabItem(
            label: 'Semua',
            count: provider.products.length,
            selected: current == 'semua',
            activeColor: AppColors.primary,
            onTap: () => provider.setProductFilter('semua'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterTabItem(
            label: 'Tersedia',
            count: provider.availableProducts.length,
            selected: current == 'tersedia',
            activeColor: AppColors.primary,
            onTap: () => provider.setProductFilter('tersedia'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterTabItem(
            label: 'Habis',
            count: provider.soldOutProducts.length,
            selected: current == 'habis',
            activeColor: AppColors.primary,
            onTap: () => provider.setProductFilter('habis'),
          ),
        ),
      ],
    );
  }
}

class _FilterTabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterTabItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? activeColor : AppColors.borderCard,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.softGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// C. SEARCH BAR
// ============================================================================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Cari produk surplus toko...',
        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderCard),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

// ============================================================================
// D. INFORMASI PRODUK HARI INI (Summary Card)
// ============================================================================

class _SurplusSummaryCard extends StatelessWidget {
  final int totalActiveProducts;
  final int totalStockPortions;
  final int totalCatalogProducts;

  const _SurplusSummaryCard({
    required this.totalActiveProducts,
    required this.totalStockPortions,
    required this.totalCatalogProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E6), // Soft orange
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD9BF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0CC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFFE8722A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Produk Hari Ini',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$totalActiveProducts menu ditawarkan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE8722A),
                        ),
                      ),
                    ),
                    const Text(
                      '  â€¢  ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '$totalStockPortions porsi tersedia',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ],
        ),
      )
    ;
  }
}

// ============================================================================
// E. TOMBOL TAMBAH PRODUK
// ============================================================================

class _AddProductButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_rounded, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Tambah Menu Surplus Baru',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// F. PRODUCT CARD ITEM
// ============================================================================

class _CatalogProductCard extends StatelessWidget {
  final SurplusProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestock;

  const _CatalogProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShopProvider>();
    final isSoldOut = product.isHabis;

    return Opacity(
      opacity: isSoldOut ? 0.78 : 1.0,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        radius: 18,
        borderColor: isSoldOut ? const Color(0xFFE8E8E8) : AppColors.borderCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Konten Card Utama
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto Produk & Diskon Badge
                  Stack(
                    children: [
                      ProductThumb(
                        fotoUrl: product.fotoUrl,
                        size: 94,
                        radius: 14,
                        category: product.namaKategori,
                      ),
                      if (product.diskonPersen > 0)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '${product.diskonPersen}% OFF',
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Detail Produk
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori & Status Badge
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softGrey,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer_outlined,
                                      size: 10,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        product.namaKategori ?? 'Surplus',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (product.isTersedia)
                              StatusBadge.green('Tersedia')
                            else
                              StatusBadge.grey('Habis'),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Nama Produk
                        Text(
                          product.namaProduk,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Harga Surplus & Harga Asli
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Formats.rupiah(product.hargaSurplus),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                Formats.rupiah(product.hargaAsli),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Stok
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 12,
                              color: isSoldOut
                                  ? AppColors.textMuted
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSoldOut
                                  ? 'Stok: 0 porsi'
                                  : 'Stok: ${product.stok} porsi',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isSoldOut
                                    ? const Color(0xFFC83E27)
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.borderCard),

            // Batas Waktu Pengambilan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Batas pengambilan: ${Formats.pickupWindow(product.batasPengambilan.subtract(const Duration(minutes: 90)), product.batasPengambilan)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Bar (Restock, Toggle, Edit, Hapus)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF8F5),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  if (isSoldOut) ...[
                    // Tombol Restock Cepat
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onRestock,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.badgeGreenBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.replay_rounded,
                              size: 13,
                              color: AppColors.textGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Restock Menu',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Toggle Status Aktif
                    Row(
                      children: [
                        AppToggle(
                          value: product.isTersedia,
                          activeColor: AppColors.textGreen,
                          onChanged: (value) async {
                            try {
                              await provider.setProductActive(product, value);
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ShopProvider.friendlyError(error),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 7),
                        GestureDetector(
                          onTap: onRestock,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.add,
                                  size: 11,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Restock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Tombol Edit
                  CircleIconButton(
                    icon: Icons.edit_outlined,
                    size: 30,
                    background: Colors.white,
                    foreground: AppColors.textSecondary,
                    tooltip: 'Edit Menu',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),

                  // Tombol Hapus
                  CircleIconButton(
                    icon: Icons.delete_outline_rounded,
                    size: 30,
                    background: AppColors.dangerSoft,
                    foreground: AppColors.primary,
                    tooltip: 'Hapus Menu',
                    onTap: onDelete,
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

// ============================================================================
// G. TIPS MITRA Kenyangin CARD
// ============================================================================

class _TipsMitraCard extends StatelessWidget {
  const _TipsMitraCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBE4BD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFE8722A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Mitra Kenyangin',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Update sisa makanan surplus 2 jam sebelum operasional tutup agar pelanggan dapat menemukan pilihan makanan yang masih tersedia.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
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

// ============================================================================
// HELPER: DIALOG BULLET
// ============================================================================

class _HelpBullet extends StatelessWidget {
  final String title;
  final String body;

  const _HelpBullet({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

