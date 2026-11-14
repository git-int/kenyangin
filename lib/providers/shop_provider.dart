import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/shop_models.dart';
import '../repositories/shop_repository.dart';

class ShopProvider extends ChangeNotifier {
  ShopProvider({required this.user, ShopRepository? repository})
    : _repository = repository ?? ShopRepository();

  final AppUser user;
  final ShopRepository _repository;

  ShopStore? store;
  List<ShopCategory> categories = [];
  List<SurplusProduct> products = [];
  List<ShopOrder> orders = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isStoreOpen = true;
  String? errorMessage;
  DateTime? lastUpdated;

  String productFilter = 'semua';
  String searchQuery = '';
  String productSort = 'terbaru';

  bool get hasStore => store != null;

  String get storeName => store?.namaToko ?? 'Toko Saya';

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final storeData = await _repository.ensureStore(user);
      final results = await Future.wait<dynamic>([
        _repository.getCategories(),
        _repository.getProducts(storeData.storeId),
        _repository.getOrders(storeData.storeId),
      ]);

      store = storeData;
      categories = results[0] as List<ShopCategory>;
      products = results[1] as List<SurplusProduct>;
      orders = results[2] as List<ShopOrder>;

      isStoreOpen = storeData.isOpen;
      lastUpdated = DateTime.now();
      errorMessage = null;
    } catch (error) {
      // Tidak ada data lokal/demo: tampilkan kegagalan apa adanya agar
      // pengguna tahu Supabase belum siap (migrasi/RLS/koneksi).
      errorMessage = friendlyError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(silent: true);

  void setProductFilter(String filter) {
    productFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setProductSort(String sort) {
    productSort = sort;
    notifyListeners();
  }

  Future<void> setStoreOpen(bool value) async {
    final currentStore = store;
    if (currentStore == null) return;

    final previous = isStoreOpen;
    isStoreOpen = value;
    notifyListeners();

    try {
      await _repository.updateStoreOpenStatus(
        storeId: currentStore.storeId,
        isOpen: value,
      );
      store = currentStore.copyWith(isOpen: value);
      notifyListeners();
    } catch (error) {
      isStoreOpen = previous;
      notifyListeners();
      rethrow;
    }
  }

  // ---------------------------------------------------------------- statistik

  List<SurplusProduct> get availableProducts =>
      products.where((product) => product.isTersedia).toList();

  List<SurplusProduct> get soldOutProducts =>
      products.where((product) => product.isHabis).toList();

  int get stockPortions =>
      availableProducts.fold(0, (total, product) => total + product.stok);

  int get potentialRevenue => availableProducts.fold(
    0,
    (total, product) => total + (product.stok * product.hargaSurplus).round(),
  );

  List<SurplusProduct> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    final list = products.where((product) {
      final matchFilter = switch (productFilter) {
        'tersedia' => product.isTersedia,
        'habis' => product.isHabis,
        _ => true,
      };
      if (!matchFilter) return false;
      if (query.isEmpty) return true;
      return product.namaProduk.toLowerCase().contains(query) ||
          (product.namaKategori ?? '').toLowerCase().contains(query);
    }).toList();

    switch (productSort) {
      case 'stok_terendah':
        list.sort((a, b) => a.stok.compareTo(b.stok));
        break;
      case 'harga_terendah':
        list.sort((a, b) => a.hargaSurplus.compareTo(b.hargaSurplus));
        break;
      case 'diskon_tertinggi':
        list.sort((a, b) => b.diskonPersen.compareTo(a.diskonPersen));
        break;
      case 'terbaru':
      default:
        // urutan default dari repository (created_at descending)
        break;
    }

    return list;
  }

  List<ShopOrder> get pendingOrders =>
      orders.where((order) => order.isPending).toList();

  List<ShopOrder> get waitingOrders =>
      orders.where((order) => order.isDiproses).toList();

  List<ShopOrder> get activeOrders {
    final list = orders.where((order) => order.isAktif).toList();
    list.sort((a, b) => a.batasPengambilan.compareTo(b.batasPengambilan));
    return list;
  }

  int get needActionCount => pendingOrders.length + waitingOrders.length;

  ShopOrder? get nextPickupOrder =>
      activeOrders.isEmpty ? null : activeOrders.first;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ShopOrder> get completedToday {
    final list = orders.where((order) {
      if (!order.isSelesai) return false;
      final waktu = order.waktuPengambilan ?? order.tanggalPesan;
      return _sameDay(waktu, DateTime.now());
    }).toList();
    list.sort((a, b) {
      final aTime = a.waktuPengambilan ?? a.tanggalPesan;
      final bTime = b.waktuPengambilan ?? b.tanggalPesan;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  double get revenueToday =>
      completedToday.fold(0, (total, order) => total + order.totalHarga);

  double get revenueYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return orders
        .where((order) {
          if (!order.isSelesai) return false;
          final waktu = order.waktuPengambilan ?? order.tanggalPesan;
          return _sameDay(waktu, yesterday);
        })
        .fold(0, (total, order) => total + order.totalHarga);
  }

  int? get revenueGrowthPercent {
    if (revenueYesterday <= 0) return null;
    return ((revenueToday - revenueYesterday) / revenueYesterday * 100).round();
  }

  int get savedPortionsToday =>
      completedToday.fold(0, (total, order) => total + order.totalPorsi);

  double get savedCo2Today => savedPortionsToday * 0.32;

  // ------------------------------------------------------------------ aksi

  Future<void> saveProduct({
    SurplusProduct? existing,
    required ProductDraft draft,
  }) async {
    final currentStore = store;
    if (currentStore == null) {
      throw Exception(
        'Profil toko belum siap. Muat ulang halaman terlebih dahulu.',
      );
    }

    isSaving = true;
    notifyListeners();

    try {
      if (existing == null) {
        await _repository.createProduct(
          storeId: currentStore.storeId,
          draft: draft,
        );
      } else {
        await _repository.updateProduct(
          storeId: currentStore.storeId,
          productId: existing.productId,
          draft: draft,
        );
      }

      products = await _repository.getProducts(currentStore.storeId);
      lastUpdated = DateTime.now();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setProductActive(SurplusProduct product, bool active) async {
    if (active && product.stok <= 0) {
      throw Exception(
        'Stok masih 0. Ubah jumlah porsi sebelum mengaktifkan produk.',
      );
    }

    final currentStore = store;
    if (currentStore == null) throw Exception('Profil toko belum siap.');

    await _repository.updateProductStatus(
      productId: product.productId,
      status: active ? 'tersedia' : 'habis',
    );

    products = await _repository.getProducts(currentStore.storeId);
    notifyListeners();
  }

  Future<void> updateProductStock(SurplusProduct product, int newStock) async {
    final currentStore = store;
    if (currentStore == null) throw Exception('Profil toko belum siap.');

    final newStatus = newStock > 0 ? 'tersedia' : 'habis';
    await _repository.updateProductStock(
      productId: product.productId,
      stok: newStock,
      status: newStatus,
    );

    products = await _repository.getProducts(currentStore.storeId);
    notifyListeners();
  }

  Future<void> restockProduct(SurplusProduct product, int addedPortions) async {
    final currentStock = product.stok < 0 ? 0 : product.stok;
    final totalStock = currentStock + addedPortions;
    await updateProductStock(product, totalStock);
  }

  Future<void> deleteProduct(SurplusProduct product) async {
    final currentStore = store;
    if (currentStore == null) throw Exception('Profil toko belum siap.');

    await _repository.deleteProduct(product.productId);
    products = await _repository.getProducts(currentStore.storeId);
    notifyListeners();
  }

  Future<OrderValidationResult> validateOrder(String code) async {
    if (code.trim().isEmpty) {
      return const OrderValidationResult(
        success: false,
        message: 'Masukkan kode pesanan terlebih dahulu.',
      );
    }

    try {
      final order = await _repository.findOrderByCode(
        storeId: store?.storeId ?? '',
        code: code,
      );

      if (order == null) {
        return const OrderValidationResult(
          success: false,
          message: 'Kode pesanan tidak ditemukan untuk toko ini.',
        );
      }

      if (order.isSelesai) {
        return OrderValidationResult(
          success: true,
          message: 'Pesanan ${order.displayCode} sudah selesai sebelumnya.',
          order: order,
        );
      }

      if (order.isDibatalkan) {
        return OrderValidationResult(
          success: false,
          message: 'Pesanan ${order.displayCode} sudah dibatalkan.',
          order: order,
        );
      }

      if (order.isDiproses) {
        return OrderValidationResult(
          success: true,
          message:
              'Pesanan ${order.displayCode} sudah divalidasi. '
              'Silakan selesaikan saat makanan diserahkan.',
          order: order,
        );
      }

      await _repository.updateOrderStatus(
        orderId: order.orderId,
        status: 'diproses',
      );

      await refresh();

      final updated = orders.firstWhere(
        (item) => item.orderId == order.orderId,
        orElse: () => order,
      );

      return OrderValidationResult(
        success: true,
        message: 'Pesanan ${order.displayCode} berhasil divalidasi.',
        order: updated,
      );
    } catch (error) {
      return OrderValidationResult(
        success: false,
        message: friendlyError(error),
      );
    }
  }

  Future<void> completeOrder(ShopOrder order) async {
    await _repository.completeOrder(order.orderId);
    await refresh();
  }

  Future<void> updateAccountProfile({
    required String nama,
    String? noHp,
  }) async {
    isSaving = true;
    notifyListeners();

    try {
      await _repository.updateAccountProfile(
        userId: user.userId,
        nama: nama,
        noHp: noHp,
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateStoreProfile({
    required String namaToko,
    required String alamat,
    String? noWhatsapp,
    String? jamBuka,
    String? jamTutup,
    double? latitude,
    double? longitude,
  }) async {
    final currentStore = store;
    if (currentStore == null) throw Exception('Profil toko belum siap.');

    isSaving = true;
    notifyListeners();

    try {
      store = await _repository.updateStore(
        storeId: currentStore.storeId,
        namaToko: namaToko,
        alamat: alamat,
        noWhatsapp: noWhatsapp,
        jamBuka: jamBuka,
        jamTutup: jamTutup,
        latitude: latitude,
        longitude: longitude,
      );
      isStoreOpen = store!.isOpen;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  static String friendlyError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '23514') {
        return 'Data ditolak oleh aturan database. Pastikan harga surplus '
            'tidak melebihi harga asli dan stok tidak negatif.';
      }
      if (error.code == '42501' || error.code == '403') {
        return 'Akses ditolak. Pastikan kebijakan RLS Supabase sudah dijalankan.';
      }
      return error.message;
    }
    if (error is StorageException) {
      return 'Gagal mengunggah foto: ${error.message}. '
          'Pastikan bucket product-images sudah dibuat.';
    }
    if (error is AuthException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
