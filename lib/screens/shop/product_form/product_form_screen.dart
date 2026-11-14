import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../models/shop_models.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';

class ProductFormScreen extends StatefulWidget {
  final SurplusProduct? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaAsliController = TextEditingController();
  final _hargaSurplusController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  late DateTime _pickupStart;
  late DateTime _pickupEnd;
  int _consumptionHours = 24;
  int _stock = 3;
  String? _categoryKey;
  String? _existingPhotoUrl;
  Uint8List? _pickedBytes;
  String? _pickedExtension;
  bool _initializedCategory = false;

  bool get _isEditing => widget.product != null;

  int get _descriptionLength => _deskripsiController.text.characters.length;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _pickupStart = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(hours: 1));
    _pickupEnd = _pickupStart.add(const Duration(minutes: 90));

    final product = widget.product;
    if (product != null) {
      _namaController.text = product.namaProduk;
      _deskripsiController.text = product.deskripsi ?? '';
      _hargaAsliController.text = Formats.number(product.hargaAsli);
      _hargaSurplusController.text = Formats.number(product.hargaSurplus);
      _stock = product.stok <= 0 ? 1 : product.stok;
      _existingPhotoUrl = product.fotoUrl;
      _pickupEnd = product.batasPengambilan;
      _pickupStart = product.batasPengambilan.subtract(
        const Duration(minutes: 90),
      );
      if (product.batasKonsumsi != null) {
        final hours = product.batasKonsumsi!
            .difference(product.batasPengambilan)
            .inHours
            .abs();
        _consumptionHours = [
          12,
          24,
          48,
        ].reduce((a, b) => (a - hours).abs() <= (b - hours).abs() ? a : b);
      }
    }

    _hargaAsliController.addListener(_refreshPriceState);
    _hargaSurplusController.addListener(_refreshPriceState);
    _deskripsiController.addListener(_refreshDescriptionState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedCategory) return;

    final provider = context.read<ShopProvider>();
    final categories = _categoriesOf(provider);
    if (categories.isEmpty) return;

    final product = widget.product;
    if (product != null) {
      ShopCategory? selected;
      if (product.categoryId != null) {
        for (final category in categories) {
          if (category.categoryId == product.categoryId) {
            selected = category;
            break;
          }
        }
      }
      selected ??= _findByName(categories, product.namaKategori);
      if (selected != null) {
        _categoryKey = _keyOf(selected);
        _initializedCategory = true;
      }
    } else {
      _categoryKey = _keyOf(categories.first);
      _initializedCategory = true;
    }
  }

  @override
  void dispose() {
    _hargaAsliController.removeListener(_refreshPriceState);
    _hargaSurplusController.removeListener(_refreshPriceState);
    _deskripsiController.removeListener(_refreshDescriptionState);
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaAsliController.dispose();
    _hargaSurplusController.dispose();
    super.dispose();
  }

  void _refreshPriceState() {
    if (mounted) setState(() {});
  }

  void _refreshDescriptionState() {
    if (mounted) setState(() {});
  }

  List<ShopCategory> _categoriesOf(ShopProvider provider) =>
      provider.categories;

  String _keyOf(ShopCategory category) =>
      category.categoryId ?? 'name:${category.namaKategori}';

  ShopCategory? _findByName(List<ShopCategory> categories, String? name) {
    if (name == null) return null;
    for (final category in categories) {
      if (category.namaKategori.toLowerCase() == name.toLowerCase()) {
        return category;
      }
    }
    return null;
  }

  double get _hargaAsli => _parsePrice(_hargaAsliController.text);

  double get _hargaSurplus => _parsePrice(_hargaSurplusController.text);

  int get _discountPercent {
    if (_hargaAsli <= 0 || _hargaSurplus <= 0) return 0;
    final percent = ((_hargaAsli - _hargaSurplus) / _hargaAsli * 100).round();
    return percent.clamp(0, 100);
  }

  double _parsePrice(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final store = provider.store;
    final categories = _categoriesOf(provider);

    ShopCategory? selectedCategory;
    for (final category in categories) {
      if (_keyOf(category) == _categoryKey) {
        selectedCategory = category;
        break;
      }
    }
    if (_categoryKey == null && categories.isNotEmpty) {
      _categoryKey = _keyOf(categories.first);
      selectedCategory = categories.first;
    }

    return Scaffold(
      backgroundColor: AppColors.shopBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              title: _isEditing ? 'Edit Menu Surplus' : 'Tambah Menu Surplus',
              onClose: () => Navigator.of(context).pop(),
              onReset: _resetForm,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _ModeCard(storeName: store?.namaToko ?? 'Mitra Kenyangin'),
                    const SizedBox(height: 14),
                    _PhotoSection(
                      bytes: _pickedBytes,
                      existingUrl: _existingPhotoUrl,
                      onPick: _showPhotoSource,
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(text: 'Nama Produk', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        hint: 'cth. Paket 3 Rasa Artisan Croissant',
                        suffixIcon: Icons.sell_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama produk wajib diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Nama produk minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(text: 'Kategori Menu', required: true),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryKey,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        hint: categories.isEmpty
                            ? 'Kategori belum tersedia di database'
                            : 'Pilih kategori',
                        suffixIcon: Icons.keyboard_arrow_down_rounded,
                        showSuffixIcon: false,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: _keyOf(category),
                              child: Text(category.namaKategori),
                            ),
                          )
                          .toList(),
                      onChanged: categories.isEmpty
                          ? null
                          : (value) => setState(() => _categoryKey = value),
                      validator: (value) {
                        if (categories.isEmpty) {
                          return 'Belum ada kategori di Supabase. '
                              'Jalankan migrasi schema_shop_features.sql.';
                        }
                        return value == null ? 'Kategori wajib dipilih' : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(
                      text: 'Deskripsi Singkat',
                      trailing: Text(
                        '${_descriptionLength.clamp(0, 150)}/150',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      maxLength: 150,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        hint: 'Jelaskan isi paket, bahan, dan porsi makananmu.',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value != null && value.characters.length > 150) {
                          return 'Deskripsi maksimal 150 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PricingSection(
                      hargaAsliController: _hargaAsliController,
                      hargaSurplusController: _hargaSurplusController,
                      discountPercent: _discountPercent,
                      savings: (_hargaAsli - _hargaSurplus).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StockSection(
                      stock: _stock,
                      onDecrease: () {
                        if (_stock > 1) setState(() => _stock--);
                      },
                      onIncrease: () {
                        if (_stock < 999) setState(() => _stock++);
                      },
                    ),
                    const SizedBox(height: 16),
                    _PickupSection(
                      start: _pickupStart,
                      end: _pickupEnd,
                      onPickStart: () => _pickTime(true),
                      onPickEnd: () => _pickTime(false),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(text: 'Batas Waktu Konsumsi Direkomendasikan'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _consumptionHours,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 12,
                          child: Text('12 jam setelah pengambilan'),
                        ),
                        DropdownMenuItem(
                          value: 24,
                          child: Text('24 jam setelah pengambilan'),
                        ),
                        DropdownMenuItem(
                          value: 48,
                          child: Text('48 jam setelah pengambilan'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _consumptionHours = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const _QualityNote(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.borderCard)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SectionConstrained(
            child: GradientButton(
              label: _isEditing
                  ? 'Simpan Perubahan Menu'
                  : 'Simpan & Terbitkan Menu',
              icon: Icons.restaurant_menu_rounded,
              loading: provider.isSaving,
              onTap: () => _save(provider, selectedCategory),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? suffixIcon,
    bool showSuffixIcon = true,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      suffixIcon: showSuffixIcon && suffixIcon != null
          ? Icon(suffixIcon, size: 19, color: AppColors.textMuted)
          : null,
      counterText: counterText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 10, color: AppColors.primary),
    );
  }

  Future<void> _showPhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tambahkan Foto Produk',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Foto nyata membantu konsumen memilih makanan surplus.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Pilih dari Galeri',
                subtitle: 'JPG, PNG, atau WEBP',
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              _PhotoSourceTile(
                icon: Icons.photo_camera_outlined,
                title: 'Ambil dari Kamera',
                subtitle: 'Pastikan foto terang dan jelas',
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final extension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';

      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedExtension = extension;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $error'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _pickupStart : _pickupEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (pickerContext, child) {
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    final now = DateTime.now();
    final value = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    setState(() {
      if (isStart) {
        _pickupStart = value;
        if (_pickupEnd.isBefore(_pickupStart)) {
          _pickupEnd = _pickupStart.add(const Duration(minutes: 90));
        }
      } else {
        _pickupEnd = value;
      }
    });
  }

  void _resetForm() {
    final product = widget.product;
    setState(() {
      _namaController.text = product?.namaProduk ?? '';
      _deskripsiController.text = product?.deskripsi ?? '';
      _hargaAsliController.text = product == null
          ? ''
          : Formats.number(product.hargaAsli);
      _hargaSurplusController.text = product == null
          ? ''
          : Formats.number(product.hargaSurplus);
      _stock = product == null ? 3 : (product.stok <= 0 ? 1 : product.stok);
      _existingPhotoUrl = product?.fotoUrl;
      _pickedBytes = null;
      _pickedExtension = null;

      final now = DateTime.now();
      if (product == null) {
        _pickupStart = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(const Duration(hours: 1));
        _pickupEnd = _pickupStart.add(const Duration(minutes: 90));
        _consumptionHours = 24;
      } else {
        _pickupEnd = product.batasPengambilan;
        _pickupStart = product.batasPengambilan.subtract(
          const Duration(minutes: 90),
        );
      }
    });
  }

  Future<void> _save(
    ShopProvider provider,
    ShopCategory? selectedCategory,
  ) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_hargaAsli <= 0) {
      _showError('Harga normal harus lebih dari 0.');
      return;
    }
    if (_hargaSurplus <= 0) {
      _showError('Harga surplus harus lebih dari 0.');
      return;
    }
    if (_hargaSurplus > _hargaAsli) {
      _showError('Harga surplus tidak boleh melebihi harga normal.');
      return;
    }
    if (!_pickupEnd.isAfter(DateTime.now())) {
      _showError('Batas waktu pengambilan harus setelah waktu sekarang.');
      return;
    }
    if (!_pickupEnd.isAfter(_pickupStart)) {
      _showError('Waktu selesai pengambilan harus setelah waktu mulai.');
      return;
    }
    if (_pickedBytes == null &&
        (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)) {
      _showError('Tambahkan foto produk surplus terlebih dahulu.');
      return;
    }

    final draft = ProductDraft(
      namaProduk: _namaController.text.trim(),
      categoryId: selectedCategory?.categoryId,
      namaKategori: selectedCategory?.namaKategori,
      deskripsi: _deskripsiController.text.trim(),
      hargaAsli: _hargaAsli,
      hargaSurplus: _hargaSurplus,
      stok: _stock,
      batasKonsumsi: _pickupEnd.add(Duration(hours: _consumptionHours)),
      batasPengambilan: _pickupEnd,
      imageBytes: _pickedBytes,
      imageExtension: _pickedExtension,
    );

    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.saveProduct(existing: widget.product, draft: draft);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Menu ${draft.namaProduk} berhasil diperbarui.'
                : 'Menu ${draft.namaProduk} berhasil diterbitkan.',
          ),
          backgroundColor: AppColors.textGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(ShopProvider.friendlyError(error));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback onReset;

  const _TopBar({
    required this.title,
    required this.onClose,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.close,
            size: 32,
            background: Colors.white,
            foreground: AppColors.textPrimary,
            onTap: onClose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String storeName;

  const _ModeCard({required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Mode Mitra:',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          StatusBadge.green('Aktif'),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onPick;

  const _PhotoSection({
    required this.bytes,
    required this.existingUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(text: 'Foto Produk Surplus', required: true),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Maks 5MB',
            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 158,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  Image.memory(bytes!, fit: BoxFit.cover)
                else if (existingUrl != null && existingUrl!.isNotEmpty)
                  Image.network(
                    existingUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                  )
                else
                  const _PhotoPlaceholder(),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 11,
                          color: AppColors.textGreen,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Foto Utama Terpasang',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onPick,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 12,
                              color: AppColors.textPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ganti Foto',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        DashedBorder(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.all(Radius.circular(9)),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Foto dari Galeri atau Kamera',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Format: PNG/JPG, rasio 16:9 disarankan',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBE3CF), Color(0xFFF0C3A0)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bakery_dining_outlined,
            size: 38,
            color: const Color(0xFFB85C2E).withOpacity(0.7),
          ),
          const SizedBox(height: 4),
          const Text(
            'Belum ada foto produk',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C4A22),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  final TextEditingController hargaAsliController;
  final TextEditingController hargaSurplusController;
  final int discountPercent;
  final double savings;

  const _PricingSection({
    required this.hargaAsliController,
    required this.hargaSurplusController,
    required this.discountPercent,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Skema Penyelamatan Pangan',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.orangeGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hemat $discountPercent%!',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga Normal',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: hargaAsliController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsInputFormatter(),
                      ],
                      decoration: _priceDecoration(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga Surplus',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: hargaSurplusController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsInputFormatter(),
                      ],
                      decoration: _priceDecoration(focused: true),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 12,
                color: AppColors.textGreen,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  savings > 0
                      ? 'Konsumen menghemat ${Formats.rupiah(savings)} dari harga normal.'
                      : 'Penyelamatan harga minimal 3x lebih cepat untuk habis terjual.',
                  style: const TextStyle(
                    fontSize: 8.8,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _priceDecoration({bool focused = false}) {
    return InputDecoration(
      prefixText: 'Rp ',
      prefixStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: focused ? AppColors.primary : AppColors.textMuted,
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 1.3 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorStyle: const TextStyle(fontSize: 9, color: AppColors.primary),
    );
  }
}

class _StockSection extends StatelessWidget {
  final int stock;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _StockSection({
    required this.stock,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(text: 'Jumlah Porsi Tersedia', required: true),
              SizedBox(height: 3),
              Text(
                'Stok kantong siap bungkus',
                style: TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: stock > 1 ? onDecrease : null,
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '$stock',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onTap: stock < 999 ? onIncrease : null,
                filled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _StepButton({required this.icon, this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : AppColors.softGrey,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            size: 15,
            color: filled ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PickupSection extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _PickupSection({
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(text: 'Jendela Waktu Pengambilan', required: true),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _TimeBox(
                icon: Icons.schedule,
                value: Formats.timeWib(start),
                onTap: onPickStart,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TimeBox(
                icon: Icons.schedule,
                value: Formats.timeWib(end),
                onTap: onPickEnd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Pastikan staf toko siap melayani konsumen pada rentang jam ini.',
          style: TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _TimeBox({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityNote extends StatelessWidget {
  const _QualityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBE0C9)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 15,
            color: AppColors.primary,
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Standar Kualitas: Hanya tampilkan surplus dalam kondisi higienis '
              'dan layak konsumsi sesuai standar keamanan pangan Kenyangin.',
              style: TextStyle(
                fontSize: 9,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionConstrained extends StatelessWidget {
  final Widget child;

  const SectionConstrained({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: child,
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDFAF7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

