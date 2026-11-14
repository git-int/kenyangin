import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';
import '../models/shop_models.dart';

/// Semua data katalog, favorit, dan pesanan konsumen dibaca/ditulis langsung
/// ke Supabase. Tidak ada data contoh lokal.
class ConsumerRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  static const String _productSelect = '''
    *,
    categories (nama_kategori),
    stores (nama_toko, alamat, no_whatsapp, jam_buka, jam_tutup, latitude, longitude)
  ''';

  static const String _orderSelect = '''
    *,
    stores (nama_toko, alamat, no_whatsapp),
    order_details (
      product_id,
      jumlah,
      harga_satuan,
      subtotal,
      products (nama_produk, foto_url)
    )
  ''';

  Future<List<SurplusProduct>> getAvailableProducts() async {
    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('status', 'tersedia')
        .gt('stok', 0)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => SurplusProduct.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<ShopCategory>> getCategories() async {
    final rows = await _client
        .from('categories')
        .select()
        .order('nama_kategori', ascending: true);

    return (rows as List)
        .map((row) => ShopCategory.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Set<String>> getFavoriteIds(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);

    return (rows as List)
        .map((row) => row['product_id'].toString())
        .toSet();
  }

  Future<void> addFavorite({
    required String userId,
    required String productId,
  }) async {
    await _client
        .from('favorites')
        .upsert({
          'user_id': userId,
          'product_id': productId,
        }, onConflict: 'user_id,product_id');
  }

  Future<void> removeFavorite({
    required String userId,
    required String productId,
  }) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<List<ShopOrder>> getOrders(String userId) async {
    final rows = await _client
        .from('orders')
        .select(_orderSelect)
        .eq('user_id', userId)
        .order('tanggal_pesan', ascending: false)
        .limit(200);

    return (rows as List)
        .map((row) => ShopOrder.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ShopOrder> createOrder({
    required String userId,
    required SurplusProduct product,
    required int jumlah,
    required String metodePembayaran,
  }) async {
    final orderId = const Uuid().v4();
    final total = product.hargaSurplus * jumlah;
    final qrToken = _generateQrToken(product.storeDisplayName);

    final paymentStatus = metodePembayaran == 'qris'
        ? 'menunggu'
        : 'belum_lunas';

    await _client.from('orders').insert({
      'order_id': orderId,
      'user_id': userId,
      'store_id': product.storeId,
      'total_harga': total,
      'status_pesanan': 'pending',
      'batas_pengambilan': product.batasPengambilan.toUtc().toIso8601String(),
      'qr_token': qrToken,
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': paymentStatus,
    });

    await _client.from('order_details').insert({
      'order_id': orderId,
      'product_id': product.productId,
      'jumlah': jumlah,
      'harga_satuan': product.hargaSurplus,
      'subtotal': total,
    });

    await _client.rpc(
      'decrement_product_stock',
      params: {'p_product_id': product.productId, 'p_jumlah': jumlah},
    );

    return ShopOrder(
      orderId: orderId,
      userId: userId,
      storeId: product.storeId,
      tanggalPesan: DateTime.now(),
      totalHarga: total,
      statusPesanan: 'pending',
      batasPengambilan: product.batasPengambilan,
      qrToken: qrToken,
      items: [
        OrderDetailItem(
          productId: product.productId,
          namaProduk: product.namaProduk,
          jumlah: jumlah,
          hargaSatuan: product.hargaSurplus,
          subtotal: total,
          fotoUrl: product.fotoUrl,
        ),
      ],
      customerName: 'Konsumen',
      storeNama: product.storeNama,
      storeAlamat: product.storeAlamat,
      storePhone: product.storeNoWhatsapp,
      metodePembayaran: metodePembayaran,
      statusPembayaran: paymentStatus,
    );
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String status,
  }) async {
    await _client
        .from('orders')
        .update({'status_pembayaran': status})
        .eq('order_id', orderId);
  }

  Future<void> updatePaymentMethod({
    required String orderId,
    required String metodePembayaran,
  }) async {
    await _client
        .from('orders')
        .update({
          'metode_pembayaran': metodePembayaran,
          'status_pembayaran': metodePembayaran == 'qris'
              ? 'menunggu'
              : 'belum_lunas',
        })
        .eq('order_id', orderId);
  }

  Future<void> cancelOrder(ShopOrder order) async {
    await _client
        .from('orders')
        .update({'status_pesanan': 'dibatalkan'})
        .eq('order_id', order.orderId);

    for (final item in order.items) {
      await _client.rpc(
        'restore_product_stock',
        params: {'p_product_id': item.productId, 'p_jumlah': item.jumlah},
      );
    }
  }

  String _generateQrToken(String storeName) {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    final letters = storeName
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final suffix = letters.isEmpty
        ? 'LB'
        : letters.substring(0, letters.length >= 3 ? 3 : letters.length);
    return 'LB-$number-$suffix';
  }
}
