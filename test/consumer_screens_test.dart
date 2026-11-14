import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kenyangin/models/app_user.dart';
import 'package:kenyangin/models/shop_models.dart';
import 'package:kenyangin/providers/auth_provider.dart';
import 'package:kenyangin/providers/consumer_provider.dart';
import 'package:kenyangin/repositories/consumer_repository.dart';
import 'package:kenyangin/screens/consumer/checkout/checkout_screen.dart';
import 'package:kenyangin/screens/consumer/favorites/consumer_favorites_screen.dart';
import 'package:kenyangin/screens/consumer/home/beranda_tab.dart';
import 'package:kenyangin/screens/consumer/orders/consumer_orders_screen.dart';
import 'package:kenyangin/screens/consumer/payment/qris_payment_screen.dart';
import 'package:kenyangin/screens/consumer/profile/consumer_profile_screen.dart';
import 'package:kenyangin/screens/consumer/product_detail/product_detail_screen.dart';
import 'package:kenyangin/screens/consumer/receipt/order_receipt_screen.dart';
import 'package:kenyangin/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Test provider yang tidak memanggil Supabase saat load.
class TestConsumerProvider extends ConsumerProvider {
  TestConsumerProvider({required super.user}) : super(repository: _FakeRepo());

  void setStateFromTest({
    List<SurplusProduct> products = const [],
    List<ShopCategory> categories = const [],
    Set<String> favoriteIds = const {},
    List<ShopOrder> orders = const [],
    bool isLoading = false,
    String? errorMessage,
  }) {
    this.products = products;
    this.categories = categories;
    this.favoriteIds = favoriteIds;
    this.orders = orders;
    this.isLoading = isLoading;
    this.errorMessage = errorMessage;
    notifyListeners();
  }

  @override
  Future<void> load({bool silent = false}) async {
    // Tidak memanggil Supabase di test.
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}

class _FakeRepo extends ConsumerRepository {}

void main() {
  final user = AppUser(
    userId: 'user-kon1',
    nama: 'Sarah',
    email: 'sarah@test.com',
    noHp: '081234567890',
    role: 'konsumen',
  );

  final product = SurplusProduct(
    productId: 'prod-1',
    storeId: 'store-1',
    categoryId: 'cat-1',
    namaProduk: 'Paket 3 Rasa Artisan Croissant',
    deskripsi: 'Croissant lezat berkualitas.',
    hargaAsli: 42000,
    hargaSurplus: 21000,
    stok: 3,
    fotoUrl: 'https://example.com/croissant.jpg',
    batasKonsumsi: DateTime.now().add(const Duration(hours: 24)),
    batasPengambilan: DateTime.now().add(const Duration(hours: 4)),
    status: 'tersedia',
    namaKategori: 'Roti & Pastry',
    storeNama: 'Mom Bakery',
    storeAlamat: 'Jl. Tebet Barat No. 14, Jakarta Selatan',
    storeNoWhatsapp: '08123456789',
  );

  final order = ShopOrder(
    orderId: 'order-1',
    userId: 'user-kon1',
    storeId: 'store-1',
    tanggalPesan: DateTime.now(),
    totalHarga: 21000,
    statusPesanan: 'pending',
    batasPengambilan: DateTime.now().add(const Duration(hours: 4)),
    qrToken: 'LB-8829-JKT',
    items: [
      OrderDetailItem(
        productId: 'prod-1',
        namaProduk: 'Paket 3 Rasa Artisan Croissant',
        jumlah: 1,
        hargaSatuan: 21000,
        subtotal: 21000,
        fotoUrl: product.fotoUrl,
      ),
    ],
    customerName: 'Sarah',
    customerPhone: '081234567890',
    storeNama: 'Mom Bakery',
    storeAlamat: product.storeAlamat,
    storePhone: product.storeNoWhatsapp,
    metodePembayaran: 'qris',
    statusPembayaran: 'lunas',
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    Size physicalSize = const Size(1170, 2532),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConsumerProvider>(
            create: (_) {
              final p = TestConsumerProvider(user: user)
                ..setStateFromTest(
                  products: [product],
                  orders: [order],
                );
              return p;
            },
          ),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.shopBackground,
          ),
          home: Scaffold(
            body: SizedBox(
              width: physicalSize.width / tester.view.devicePixelRatio,
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Beranda tab dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      BerandaTab(
        onOpenProduct: (_) {},
        onOpenOrders: () {},
      ),
    );
    expect(find.textContaining('Halo, Sarah!'), findsOneWidget);
    expect(find.text('Bungkus Sebelum Habis'), findsOneWidget);
    expect(find.text('Paket 3 Rasa Artisan Croissant'), findsOneWidget);
  });

  testWidgets('Product detail dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      ProductDetailScreen(product: product),
    );
    expect(find.text('Paket 3 Rasa Artisan Croissant'), findsOneWidget);
    expect(find.text('Rp 21.000'), findsAtLeastNWidgets(1));
    expect(find.text('Klaim Pesanan Sekarang'), findsOneWidget);
  });

  testWidgets('Checkout dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      CheckoutScreen(product: product, jumlah: 1),
    );
    expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Tunai di Kasir'), findsOneWidget);
    expect(find.text('Rp 21.000'), findsAtLeastNWidgets(1));
  });

  testWidgets('QRIS payment dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      QrisPaymentScreen(order: order),
    );
    expect(find.text('Pembayaran QRIS'), findsOneWidget);
    expect(find.text('Rp 21.000'), findsAtLeastNWidgets(1));
  });

  testWidgets('Digital receipt dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      OrderReceiptScreen(order: order),
    );
    expect(find.text('Pesanan Berhasil Dibuat!'), findsOneWidget);
    expect(find.textContaining('LB-8829'), findsOneWidget);
    expect(find.text('Mom Bakery'), findsOneWidget);
    expect(find.text('Rp 21.000'), findsAtLeastNWidgets(1));
  });

  testWidgets('Orders tab dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      ConsumerOrdersScreen(
        onOpenProduct: (_) {},
        onOpenReceipt: (_) {},
      ),
    );
    expect(find.text('Pesanan Saya'), findsOneWidget);
    expect(find.text('Mom Bakery'), findsOneWidget);
    expect(find.text('Lihat Nota Digital'), findsOneWidget);
  });

  testWidgets('Favorites tab dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      ConsumerFavoritesScreen(onOpenProduct: (_) {}),
    );
    expect(find.text('Favorit'), findsOneWidget);
  });

  testWidgets('Profile tab dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      ConsumerProfileScreen(),
    );
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Sarah'), findsAtLeastNWidgets(1));
  });

  test('Jarak real-time mengurutkan toko terdekat tanpa data palsu', () {
    SurplusProduct withStore({
      required String id,
      required DateTime pickup,
      double? lat,
      double? lng,
    }) {
      return SurplusProduct(
        productId: id,
        storeId: 'store-$id',
        namaProduk: 'Produk $id',
        hargaAsli: 20000,
        hargaSurplus: 10000,
        stok: 1,
        batasPengambilan: pickup,
        status: 'tersedia',
        storeNama: 'Toko $id',
        storeLatitude: lat,
        storeLongitude: lng,
      );
    }

    final near = withStore(
      id: 'near',
      pickup: DateTime.now().add(const Duration(hours: 3)),
      lat: -6.2382,
      lng: 106.8567,
    );
    final far = withStore(
      id: 'far',
      pickup: DateTime.now().add(const Duration(hours: 1)),
      lat: -6.3000,
      lng: 106.9500,
    );
    final noCoordinate = withStore(
      id: 'no-coordinate',
      pickup: DateTime.now().add(const Duration(hours: 2)),
    );

    final provider = TestConsumerProvider(user: user)
      ..setStateFromTest(products: [far, noCoordinate, near])
      ..userPosition = Position(
        latitude: -6.2382,
        longitude: 106.8567,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      )
      ..setSortMode('terdekat');

    expect(provider.filteredProducts.first.productId, 'near');
    expect(provider.filteredProducts.last.productId, 'no-coordinate');
    expect(provider.distanceLabelTo(near), startsWith('±'));
    expect(provider.distanceLabelTo(far), isNotNull);
    expect(provider.distanceLabelTo(noCoordinate), isNull);
  });
}

