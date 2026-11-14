import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenyangin/models/app_user.dart';
import 'package:kenyangin/models/shop_models.dart';
import 'package:kenyangin/providers/auth_provider.dart';
import 'package:kenyangin/providers/shop_provider.dart';
import 'package:kenyangin/repositories/shop_repository.dart';
import 'package:kenyangin/screens/shop/catalog/shop_catalog_screen.dart';
import 'package:kenyangin/screens/shop/dashboard/shop_dashboard_screen.dart';
import 'package:kenyangin/screens/shop/home/shop_home_screen.dart';
import 'package:kenyangin/screens/shop/orders/shop_orders_screen.dart';
import 'package:kenyangin/screens/shop/product_form/product_form_screen.dart';
import 'package:kenyangin/screens/shop/profile/shop_profile_screen.dart';
import 'package:kenyangin/screens/shop/reports/shop_reports_screen.dart';
import 'package:kenyangin/theme/app_colors.dart';
import 'package:provider/provider.dart';

void main() {
  final user = AppUser(
    userId: 'user-1',
    nama: 'Siti Rahmawati',
    email: 'siti@test.com',
    noHp: '08567890123',
    role: 'toko',
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    bool withAuth = false,
    Size physicalSize = const Size(1170, 2532),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = ShopProvider(user: user);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          if (withAuth) ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
          ),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Dashboard mitra dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      DashboardTab(
        onAddProduct: () {},
        onOpenCatalog: () {},
        onOpenOrders: () {},
        onEditProduct: (_) {},
      ),
    );

    expect(find.text('Dashboard Mitra Toko'), findsOneWidget);
    expect(find.text('Tambah Produk Surplus'), findsWidgets);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
  });

  testWidgets('Katalog mitra dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      CatalogTab(onBack: () {}, onAddProduct: () {}, onEditProduct: (_) {}),
    );

    expect(find.text('Katalog Produk Toko'), findsOneWidget);
    expect(find.textContaining('Tambah Menu Surplus Baru'), findsOneWidget);
  });

  testWidgets('Halaman pesanan dapat dirender', (tester) async {
    await pumpScreen(tester, const OrdersTab());

    expect(find.textContaining('Perlu Validasi'), findsOneWidget);
    expect(find.textContaining('Scan QR Nota Konsumen'), findsOneWidget);
  });

  testWidgets('Halaman laporan dapat dirender', (tester) async {
    await pumpScreen(tester, const ReportsTab());

    expect(find.text('Laporan Mitra'), findsOneWidget);
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);
  });

  testWidgets('Halaman profil dapat dirender', (tester) async {
    await pumpScreen(tester, const ProfileTab(), withAuth: true);

    expect(find.text('Profil Saya'), findsOneWidget);
  });

  testWidgets('Form tambah menu surplus dapat dirender', (tester) async {
    await pumpScreen(
      tester,
      const ProductFormScreen(),
      physicalSize: const Size(1170, 9000),
    );

    expect(find.text('Tambah Menu Surplus'), findsOneWidget);
    expect(find.text('Foto Produk Surplus'), findsOneWidget);
    expect(find.text('Simpan & Terbitkan Menu'), findsOneWidget);
  });

  testWidgets('Shell toko menampilkan konten, bukan hanya bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthProvider()..user = user;
    final store = ShopStore(
      storeId: 'store-test',
      userId: user.userId,
      namaToko: 'Toko Uji',
      alamat: 'Jl. Uji No. 1',
      jamBuka: '08:00',
      jamTutup: '21:00',
    );
    final repository = _FakeShopRepository(
      store: store,
      categories: const [
        ShopCategory(categoryId: 'cat-1', namaKategori: 'Roti & Pastry'),
      ],
      products: [
        SurplusProduct(
          productId: 'prod-1',
          storeId: store.storeId,
          namaProduk: 'Croissant Uji',
          hargaAsli: 20000,
          hargaSurplus: 10000,
          stok: 3,
          batasPengambilan: DateTime.now().add(const Duration(hours: 1)),
          status: 'tersedia',
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
          ),
          home: ShopHomeScreen(repository: repository),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Konten dashboard harus terlihat, bukan cuma bottom navigation.
    expect(find.text('Dashboard Mitra Toko'), findsOneWidget);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
    expect(find.text('Toko Uji'), findsWidgets);

    // Bottom nav tidak boleh memakan seluruh tinggi layar.
    final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
    final bodyHeight = tester.getSize(find.byType(IndexedStack)).height;
    expect(bodyHeight, greaterThan(scaffoldHeight * 0.8));

    // Pindah tab juga harus menampilkan kontennya.
    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();
    expect(find.text('Katalog Produk Toko'), findsOneWidget);
  });

  test('ShopProvider memakai data Supabase apa adanya, tanpa data demo', () async {
    final store = ShopStore(
      storeId: 'store-test',
      userId: user.userId,
      namaToko: 'Toko Uji',
      alamat: 'Jl. Uji No. 1',
    );
    final provider = ShopProvider(
      user: user,
      repository: _FakeShopRepository(store: store),
    );

    await provider.load();

    expect(provider.store?.namaToko, 'Toko Uji');
    expect(provider.categories, isEmpty);
    expect(provider.products, isEmpty);
    expect(provider.orders, isEmpty);
    expect(provider.errorMessage, isNull);
  });

  test('ShopProvider melaporkan error tanpa mengisi data demo', () async {
    final provider = ShopProvider(
      user: user,
      repository: _FakeShopRepository(),
    );

    await provider.load();

    expect(provider.store, isNull);
    expect(provider.categories, isEmpty);
    expect(provider.products, isEmpty);
    expect(provider.orders, isEmpty);
    expect(provider.errorMessage, isNotNull);
  });
}

class _FakeShopRepository extends ShopRepository {
  _FakeShopRepository({
    this.store,
    this.categories = const [],
    this.products = const [],
  }) : orders = const [];

  final ShopStore? store;
  final List<ShopCategory> categories;
  final List<SurplusProduct> products;
  final List<ShopOrder> orders;

  @override
  Future<ShopStore> ensureStore(AppUser user) async {
    final value = store;
    if (value == null) {
      throw Exception('Supabase tidak tersedia');
    }
    return value;
  }

  @override
  Future<List<ShopCategory>> getCategories() async => categories;

  @override
  Future<List<SurplusProduct>> getProducts(String storeId) async => products;

  @override
  Future<List<ShopOrder>> getOrders(String storeId) async => orders;
}

