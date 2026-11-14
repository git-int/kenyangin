import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/shop_models.dart';
import '../repositories/consumer_repository.dart';
import '../services/location_service.dart';

class ConsumerProvider extends ChangeNotifier {
  ConsumerProvider({
    required this.user,
    ConsumerRepository? repository,
    LocationService? locationService,
  }) : _repository = repository ?? ConsumerRepository(),
       _locationService = locationService ?? LocationService();

  final AppUser user;
  final ConsumerRepository _repository;
  final LocationService _locationService;

  List<SurplusProduct> products = [];
  List<ShopCategory> categories = [];
  List<ShopOrder> orders = [];
  Set<String> favoriteIds = {};

  bool isLoading = true;
  bool isBusy = false;
  String? errorMessage;

  String searchQuery = '';
  String? selectedCategoryId;
  String sortMode = 'terdekat';

  // ------------------------------------------------------------- lokasi
  Position? userPosition;
  bool isLocating = false;
  LocationReadiness? locationReadiness;
  String? locationMessage;
  StreamSubscription<Position>? _positionSubscription;
  bool _disposed = false;

  bool get hasLocation => userPosition != null;

  /// Izin ditolak permanen / GPS mati: pengguna perlu membuka Pengaturan.
  bool get needsLocationSettings =>
      locationReadiness == LocationReadiness.deniedForever ||
      locationReadiness == LocationReadiness.serviceDisabled;

  /// Jarak (km) antara posisi pengguna dan toko pemilik produk, atau null
  /// jika lokasi pengguna / koordinat toko belum tersedia.
  double? distanceKmTo(SurplusProduct product) {
    final position = userPosition;
    final lat = product.storeLatitude;
    final lng = product.storeLongitude;
    if (position == null || lat == null || lng == null) return null;

    return LocationService.distanceInKm(
      fromLatitude: position.latitude,
      fromLongitude: position.longitude,
      toLatitude: lat,
      toLongitude: lng,
    );
  }

  /// Label jarak siap tampil, mis. "± 850 m" atau "± 2,4 km".
  String? distanceLabelTo(SurplusProduct product) {
    final km = distanceKmTo(product);
    if (km == null) return null;
    return LocationService.formatDistance(km);
  }

  Future<void> startLocationUpdates() async {
    if (_disposed || _positionSubscription != null || isLocating) return;

    isLocating = true;
    locationMessage = null;
    locationReadiness = null;
    _notify();

    try {
      final readiness = await _locationService.ensureReady();
      locationReadiness = readiness;
      if (readiness != LocationReadiness.ready) {
        locationMessage = _locationService.errorMessage;
        return;
      }

      final position = await _locationService.currentPosition();
      if (_disposed) return;
      if (position != null) {
        userPosition = position;
        _notify();
      }

      _positionSubscription = _locationService
          .positionStream(distanceFilter: 25)
          .listen(
            (position) {
              userPosition = position;
              locationMessage = null;
              locationReadiness = LocationReadiness.ready;
              _notify();
            },
            onError: (Object error) {
              locationMessage =
                  'Pemantauan lokasi terhenti: ${_cleanLocationError(error)}';
              _notify();
            },
          );
    } catch (error) {
      locationMessage = 'Lokasi tidak tersedia: ${_cleanLocationError(error)}';
    } finally {
      isLocating = false;
      _notify();
    }
  }

  Future<void> retryLocation() async {
    stopLocationUpdates();
    await startLocationUpdates();
  }

  Future<void> openLocationSettings() async {
    try {
      final opened = locationReadiness == LocationReadiness.deniedForever
          ? await _locationService.openAppSettings()
          : await _locationService.openLocationSettings();
      if (!opened) {
        await _locationService.openAppSettings();
      }
    } catch (_) {
      // Perangkat tidak mendukung pembukaan pengaturan; abaikan.
    }
  }

  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    _disposed = true;
    stopLocationUpdates();
    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  static String _cleanLocationError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  String get firstName {
    final nama = user.nama.trim();
    if (nama.isEmpty) return 'Konsumen';
    return nama.split(RegExp(r'\s+')).first;
  }

  // ------------------------------------------------------------- katalog

  List<SurplusProduct> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    final list = products.where((product) {
      if (selectedCategoryId != null &&
          product.categoryId != selectedCategoryId) {
        return false;
      }
      if (query.isEmpty) return true;
      return product.namaProduk.toLowerCase().contains(query) ||
          product.storeDisplayName.toLowerCase().contains(query) ||
          (product.namaKategori ?? '').toLowerCase().contains(query);
    }).toList();

    switch (sortMode) {
      case 'diskon':
        list.sort((a, b) => b.diskonPersen.compareTo(a.diskonPersen));
        break;
      case 'harga':
        list.sort((a, b) => a.hargaSurplus.compareTo(b.hargaSurplus));
        break;
      case 'terdekat':
      default:
        // Urutkan berdasarkan jarak asli (Haversine). Produk dengan toko yang
        // koordinatnya belum diisi mitra diletakkan paling akhir, diurutkan
        // menurut jendela pengambilan tercepat.
        list.sort((a, b) {
          final distanceA = distanceKmTo(a);
          final distanceB = distanceKmTo(b);
          if (distanceA != null && distanceB != null) {
            return distanceA.compareTo(distanceB);
          }
          if (distanceA != null) return -1;
          if (distanceB != null) return 1;
          return a.batasPengambilan.compareTo(b.batasPengambilan);
        });
        break;
    }

    return list;
  }

  List<SurplusProduct> get favoriteProducts =>
      products.where((product) => favoriteIds.contains(product.productId)).toList();

  int get openStoreCount =>
      products.map((product) => product.storeId).toSet().length;

  bool isFavorite(String productId) => favoriteIds.contains(productId);

  // ------------------------------------------------------------- pesanan

  List<ShopOrder> get activeOrders {
    final list = orders.where((order) => order.isAktif).toList();
    list.sort((a, b) => a.batasPengambilan.compareTo(b.batasPengambilan));
    return list;
  }

  List<ShopOrder> get completedOrders =>
      orders.where((order) => order.isSelesai).toList();

  ShopOrder? get nearestActiveOrder =>
      activeOrders.isEmpty ? null : activeOrders.first;

  List<ShopOrder> get _completedThisMonth {
    final now = DateTime.now();
    return completedOrders.where((order) {
      final waktu = order.waktuPengambilan ?? order.tanggalPesan;
      return waktu.year == now.year && waktu.month == now.month;
    }).toList();
  }

  int get savedPortionsThisMonth => _completedThisMonth.fold(
    0,
    (total, order) => total + order.totalPorsi,
  );

  double get savedCo2ThisMonth => savedPortionsThisMonth * 0.32;

  // ------------------------------------------------------------- pemuatan

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait<dynamic>([
        _repository.getAvailableProducts(),
        _repository.getCategories(),
        _repository.getFavoriteIds(user.userId),
        _repository.getOrders(user.userId),
      ]);

      products = results[0] as List<SurplusProduct>;
      categories = results[1] as List<ShopCategory>;
      favoriteIds = results[2] as Set<String>;
      orders = results[3] as List<ShopOrder>;
      errorMessage = null;
    } catch (error) {
      errorMessage = friendlyError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(silent: true);

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSortMode(String mode) {
    sortMode = mode;
    notifyListeners();
  }

  // -------------------------------------------------------------- favorit

  Future<void> toggleFavorite(String productId) async {
    final alreadyFavorite = favoriteIds.contains(productId);
    if (alreadyFavorite) {
      favoriteIds.remove(productId);
    } else {
      favoriteIds.add(productId);
    }
    notifyListeners();

    try {
      if (alreadyFavorite) {
        await _repository.removeFavorite(
          userId: user.userId,
          productId: productId,
        );
      } else {
        await _repository.addFavorite(
          userId: user.userId,
          productId: productId,
        );
      }
    } catch (error) {
      // Kembalikan status jika penulisan ke Supabase gagal.
      if (alreadyFavorite) {
        favoriteIds.add(productId);
      } else {
        favoriteIds.remove(productId);
      }
      notifyListeners();
      rethrow;
    }
  }

  // -------------------------------------------------------------- checkout

  Future<ShopOrder> placeOrder({
    required SurplusProduct product,
    required int jumlah,
    required String metodePembayaran,
  }) async {
    isBusy = true;
    notifyListeners();

    try {
      final order = await _repository.createOrder(
        userId: user.userId,
        product: product,
        jumlah: jumlah,
        metodePembayaran: metodePembayaran,
      );

      products = await _repository.getAvailableProducts();
      orders = await _repository.getOrders(user.userId);
      return order;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> confirmPayment(ShopOrder order) async {
    await _repository.updatePaymentStatus(
      orderId: order.orderId,
      status: 'lunas',
    );
    orders = await _repository.getOrders(user.userId);
    notifyListeners();
  }

  Future<void> changePaymentMethod(ShopOrder order, String metode) async {
    await _repository.updatePaymentMethod(
      orderId: order.orderId,
      metodePembayaran: metode,
    );
    orders = await _repository.getOrders(user.userId);
    notifyListeners();
  }

  Future<void> cancelOrder(ShopOrder order) async {
    isBusy = true;
    notifyListeners();
    try {
      await _repository.cancelOrder(order);
      products = await _repository.getAvailableProducts();
      orders = await _repository.getOrders(user.userId);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  static String friendlyError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501' || error.code == '403') {
        return 'Akses ditolak. Jalankan schema_consumer_features.sql di '
            'Supabase agar RLS pesanan & favorit aktif.';
      }
      return error.message;
    }
    if (error is AuthException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
