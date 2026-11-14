import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';
import '../models/app_user.dart';
import '../models/shop_models.dart';

class ShopRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  static const String _imageBucket = 'product-images';

  Future<ShopStore> ensureStore(AppUser user) async {
    final existing = await _client
        .from('stores')
        .select()
        .eq('user_id', user.userId)
        .maybeSingle();

    if (existing != null) return ShopStore.fromMap(existing);

    final metadata = _client.auth.currentUser?.userMetadata ?? const {};
    final namaToko = (metadata['nama_toko'] as String?)?.trim();
    final alamat = (metadata['alamat_toko'] as String?)?.trim();

    final inserted = await _client
        .from('stores')
        .insert({
          'user_id': user.userId,
          'nama_toko': (namaToko == null || namaToko.isEmpty)
              ? 'Toko ${user.nama}'
              : namaToko,
          'alamat': (alamat == null || alamat.isEmpty)
              ? 'Alamat belum diisi'
              : alamat,
          if (user.noHp != null && user.noHp!.trim().isNotEmpty)
            'no_whatsapp': user.noHp!.trim(),
        })
        .select()
        .single();

    return ShopStore.fromMap(inserted);
  }

  Future<ShopStore> updateStore({
    required String storeId,
    required String namaToko,
    required String alamat,
    String? noWhatsapp,
    String? jamBuka,
    String? jamTutup,
    double? latitude,
    double? longitude,
  }) async {
    final updated = await _client
        .from('stores')
        .update({
          'nama_toko': namaToko.trim(),
          'alamat': alamat.trim(),
          'no_whatsapp': noWhatsapp?.trim(),
          'jam_buka': jamBuka,
          'jam_tutup': jamTutup,
          'latitude': latitude,
          'longitude': longitude,
        })
        .eq('store_id', storeId)
        .select()
        .single();

    return ShopStore.fromMap(updated);
  }

  Future<AppUser> updateAccountProfile({
    required String userId,
    required String nama,
    String? noHp,
  }) async {
    final updated = await _client
        .from('users')
        .update({
          'nama': nama.trim(),
          'no_hp': noHp == null || noHp.trim().isEmpty ? null : noHp.trim(),
        })
        .eq('user_id', userId)
        .select()
        .single();

    return AppUser.fromMap(Map<String, dynamic>.from(updated));
  }

  Future<void> updateStoreOpenStatus({
    required String storeId,
    required bool isOpen,
  }) async {
    await _client
        .from('stores')
        .update({'is_open': isOpen})
        .eq('store_id', storeId);
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

  Future<List<SurplusProduct>> getProducts(String storeId) async {
    final rows = await _client
        .from('products')
        .select('*, categories(nama_kategori)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => SurplusProduct.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<SurplusProduct> createProduct({
    required String storeId,
    required ProductDraft draft,
  }) async {
    final productId = const Uuid().v4();
    String? fotoUrl;

    if (draft.imageBytes != null) {
      fotoUrl = await _uploadImage(
        storeId: storeId,
        productId: productId,
        bytes: draft.imageBytes!,
        extension: draft.imageExtension ?? 'jpg',
      );
    }

    final inserted = await _client
        .from('products')
        .insert({
          'product_id': productId,
          'store_id': storeId,
          'category_id': draft.categoryId,
          'nama_produk': draft.namaProduk.trim(),
          'deskripsi': draft.deskripsi.trim(),
          'harga_asli': draft.hargaAsli,
          'harga_surplus': draft.hargaSurplus,
          'stok': draft.stok,
          'foto_url': fotoUrl,
          'batas_konsumsi': draft.batasKonsumsi.toUtc().toIso8601String(),
          'batas_pengambilan': draft.batasPengambilan.toUtc().toIso8601String(),
          'status': 'tersedia',
        })
        .select('*, categories(nama_kategori)')
        .single();

    return SurplusProduct.fromMap(inserted);
  }

  Future<SurplusProduct> updateProduct({
    required String storeId,
    required String productId,
    required ProductDraft draft,
  }) async {
    String? fotoUrl;

    if (draft.imageBytes != null) {
      fotoUrl = await _uploadImage(
        storeId: storeId,
        productId: productId,
        bytes: draft.imageBytes!,
        extension: draft.imageExtension ?? 'jpg',
      );
    }

    final updated = await _client
        .from('products')
        .update({
          'category_id': draft.categoryId,
          'nama_produk': draft.namaProduk.trim(),
          'deskripsi': draft.deskripsi.trim(),
          'harga_asli': draft.hargaAsli,
          'harga_surplus': draft.hargaSurplus,
          'stok': draft.stok,
          'batas_konsumsi': draft.batasKonsumsi.toUtc().toIso8601String(),
          'batas_pengambilan': draft.batasPengambilan.toUtc().toIso8601String(),
          'foto_url': ?fotoUrl,
        })
        .eq('product_id', productId)
        .select('*, categories(nama_kategori)')
        .single();

    return SurplusProduct.fromMap(updated);
  }

  Future<void> updateProductStatus({
    required String productId,
    required String status,
  }) async {
    await _client
        .from('products')
        .update({'status': status})
        .eq('product_id', productId);
  }

  Future<void> updateProductStock({
    required String productId,
    required int stok,
    String? status,
  }) async {
    final Map<String, dynamic> data = {'stok': stok};
    if (status != null) {
      data['status'] = status;
    } else if (stok <= 0) {
      data['status'] = 'habis';
    } else {
      data['status'] = 'tersedia';
    }
    await _client
        .from('products')
        .update(data)
        .eq('product_id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('product_id', productId);
  }

  Future<String> _uploadImage({
    required String storeId,
    required String productId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final safeExtension = extension.toLowerCase().replaceAll('.', '');
    final path =
        '$storeId/$productId/menu_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await _client.storage
        .from(_imageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(safeExtension),
            upsert: true,
          ),
        );

    return _client.storage.from(_imageBucket).getPublicUrl(path);
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<List<ShopOrder>> getOrders(String storeId) async {
    final orderRows = await _client
        .from('orders')
        .select('''
          order_id,
          user_id,
          store_id,
          tanggal_pesan,
          total_harga,
          status_pesanan,
          batas_pengambilan,
          waktu_pengambilan,
          qr_token,
          created_at,
          order_details (
            product_id,
            jumlah,
            harga_satuan,
            subtotal,
            products (nama_produk, foto_url)
          )
        ''')
        .eq('store_id', storeId)
        .order('tanggal_pesan', ascending: false)
        .limit(200);

    final rows = (orderRows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    final userIds = rows
        .map((row) => row['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final customers = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      try {
        final userRows = await _client
            .from('users')
            .select('user_id, nama, no_hp')
            .inFilter('user_id', userIds);
        for (final row in userRows as List) {
          final map = Map<String, dynamic>.from(row);
          customers[map['user_id'].toString()] = map;
        }
      } on PostgrestException {
        // RLS dapat membatasi data profil konsumen. Nama akan memakai fallback.
      }
    }

    return rows
        .map(
          (row) => ShopOrder.fromMap(
            row,
            customer: customers[row['user_id']?.toString()],
          ),
        )
        .toList();
  }

  Future<ShopOrder?> findOrderByCode({
    required String storeId,
    required String code,
  }) async {
    final normalized = code.trim().replaceAll('#', '').trim();
    if (normalized.isEmpty) return null;

    final row = await _client
        .from('orders')
        .select('''
          order_id,
          user_id,
          store_id,
          tanggal_pesan,
          total_harga,
          status_pesanan,
          batas_pengambilan,
          waktu_pengambilan,
          qr_token,
          created_at,
          order_details (
            product_id,
            jumlah,
            harga_satuan,
            subtotal,
            products (nama_produk, foto_url)
          )
        ''')
        .eq('store_id', storeId)
        .ilike('qr_token', normalized)
        .maybeSingle();

    if (row == null) return null;

    Map<String, dynamic>? customer;
    try {
      customer = await _client
          .from('users')
          .select('user_id, nama, no_hp')
          .eq('user_id', row['user_id'])
          .maybeSingle();
    } on PostgrestException {
      customer = null;
    }

    return ShopOrder.fromMap(row, customer: customer);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _client
        .from('orders')
        .update({'status_pesanan': status})
        .eq('order_id', orderId);
  }

  Future<void> completeOrder(String orderId) async {
    await _client
        .from('orders')
        .update({
          'status_pesanan': 'selesai',
          'waktu_pengambilan': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('order_id', orderId);
  }
}
