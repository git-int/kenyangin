import 'dart:typed_data';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

class ShopStore {
  final String storeId;
  final String userId;
  final String namaToko;
  final String alamat;
  final String? noWhatsapp;
  final String? jamBuka;
  final String? jamTutup;
  final double? latitude;
  final double? longitude;
  final bool isOpen;

  const ShopStore({
    required this.storeId,
    required this.userId,
    required this.namaToko,
    required this.alamat,
    this.noWhatsapp,
    this.jamBuka,
    this.jamTutup,
    this.latitude,
    this.longitude,
    this.isOpen = true,
  });

  factory ShopStore.fromMap(Map<String, dynamic> map) {
    return ShopStore(
      storeId: map['store_id'].toString(),
      userId: map['user_id'].toString(),
      namaToko: map['nama_toko']?.toString() ?? 'Toko Saya',
      alamat: map['alamat']?.toString() ?? '-',
      noWhatsapp: map['no_whatsapp']?.toString(),
      jamBuka: map['jam_buka']?.toString(),
      jamTutup: map['jam_tutup']?.toString(),
      latitude: map['latitude'] == null ? null : _toDouble(map['latitude']),
      longitude: map['longitude'] == null ? null : _toDouble(map['longitude']),
      isOpen: map['is_open'] is bool ? map['is_open'] as bool : true,
    );
  }

  ShopStore copyWith({bool? isOpen}) {
    return ShopStore(
      storeId: storeId,
      userId: userId,
      namaToko: namaToko,
      alamat: alamat,
      noWhatsapp: noWhatsapp,
      jamBuka: jamBuka,
      jamTutup: jamTutup,
      latitude: latitude,
      longitude: longitude,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  String get initial {
    final trimmed = namaToko.trim();
    return trimmed.isEmpty ? 'L' : trimmed.substring(0, 1).toUpperCase();
  }

  String get alamatSingkat {
    final parts = alamat.split(',');
    return parts.first.trim().isEmpty ? alamat : parts.first.trim();
  }

  String get jamOperasional {
    if (jamBuka == null || jamTutup == null) {
      return 'Jam operasional belum diatur';
    }
    return '${_shortTime(jamBuka!)} - ${_shortTime(jamTutup!)} WIB';
  }

  bool get sedangBuka {
    final buka = _minutes(jamBuka);
    final tutup = _minutes(jamTutup);
    if (buka == null || tutup == null) return true;
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    if (tutup >= buka) return current >= buka && current <= tutup;
    return current >= buka || current <= tutup;
  }

  static int? _minutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  static String _shortTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class ShopCategory {
  final String? categoryId;
  final String namaKategori;
  final String? deskripsi;

  const ShopCategory({
    this.categoryId,
    required this.namaKategori,
    this.deskripsi,
  });

  factory ShopCategory.fromMap(Map<String, dynamic> map) {
    return ShopCategory(
      categoryId: map['category_id']?.toString(),
      namaKategori: map['nama_kategori']?.toString() ?? 'Lainnya',
      deskripsi: map['deskripsi']?.toString(),
    );
  }
}

class SurplusProduct {
  final String productId;
  final String storeId;
  final String? categoryId;
  final String namaProduk;
  final String? deskripsi;
  final double hargaAsli;
  final double hargaSurplus;
  final int stok;
  final String? fotoUrl;
  final DateTime? batasKonsumsi;
  final DateTime batasPengambilan;
  final String status;
  final DateTime? createdAt;
  final String? namaKategori;

  // Informasi toko (dipakai katalog konsumen saat query join ke tabel stores).
  final String? storeNama;
  final String? storeAlamat;
  final String? storeNoWhatsapp;
  final String? storeJamBuka;
  final String? storeJamTutup;
  final double? storeLatitude;
  final double? storeLongitude;

  const SurplusProduct({
    required this.productId,
    required this.storeId,
    this.categoryId,
    required this.namaProduk,
    this.deskripsi,
    required this.hargaAsli,
    required this.hargaSurplus,
    required this.stok,
    this.fotoUrl,
    this.batasKonsumsi,
    required this.batasPengambilan,
    required this.status,
    this.createdAt,
    this.namaKategori,
    this.storeNama,
    this.storeAlamat,
    this.storeNoWhatsapp,
    this.storeJamBuka,
    this.storeJamTutup,
    this.storeLatitude,
    this.storeLongitude,
  });

  factory SurplusProduct.fromMap(Map<String, dynamic> map) {
    final kategori = map['categories'];
    final toko = map['stores'];
    return SurplusProduct(
      productId: map['product_id'].toString(),
      storeId: map['store_id'].toString(),
      categoryId: map['category_id']?.toString(),
      namaProduk: map['nama_produk']?.toString() ?? 'Produk',
      deskripsi: map['deskripsi']?.toString(),
      hargaAsli: _toDouble(map['harga_asli']),
      hargaSurplus: _toDouble(map['harga_surplus']),
      stok: _toInt(map['stok']),
      fotoUrl: map['foto_url']?.toString(),
      batasKonsumsi: _toDate(map['batas_konsumsi']),
      batasPengambilan:
          _toDate(map['batas_pengambilan']) ??
          DateTime.now().add(const Duration(hours: 2)),
      status: map['status']?.toString() ?? 'tersedia',
      createdAt: _toDate(map['created_at']),
      namaKategori: kategori is Map
          ? kategori['nama_kategori']?.toString()
          : null,
      storeNama: toko is Map ? toko['nama_toko']?.toString() : null,
      storeAlamat: toko is Map ? toko['alamat']?.toString() : null,
      storeNoWhatsapp: toko is Map ? toko['no_whatsapp']?.toString() : null,
      storeJamBuka: toko is Map ? toko['jam_buka']?.toString() : null,
      storeJamTutup: toko is Map ? toko['jam_tutup']?.toString() : null,
      storeLatitude: toko is Map ? _toDoubleOrNull(toko['latitude']) : null,
      storeLongitude: toko is Map ? _toDoubleOrNull(toko['longitude']) : null,
    );
  }

  bool get isTersedia => status == 'tersedia' && stok > 0;
  bool get isHabis => status == 'habis' || stok <= 0;

  int get diskonPersen {
    if (hargaAsli <= 0) return 0;
    final diskon = ((hargaAsli - hargaSurplus) / hargaAsli * 100).round();
    return diskon.clamp(0, 100);
  }

  double get hemat => (hargaAsli - hargaSurplus).clamp(0, double.infinity);

  String get statusLabel {
    if (stok <= 0) return 'Habis Terjual';
    if (status == 'nonaktif') return 'Nonaktif';
    if (status == 'habis') return 'Habis Terjual';
    return 'Tersedia';
  }

  SurplusProduct copyWith({int? stok, String? status}) {
    return SurplusProduct(
      productId: productId,
      storeId: storeId,
      categoryId: categoryId,
      namaProduk: namaProduk,
      deskripsi: deskripsi,
      hargaAsli: hargaAsli,
      hargaSurplus: hargaSurplus,
      stok: stok ?? this.stok,
      fotoUrl: fotoUrl,
      batasKonsumsi: batasKonsumsi,
      batasPengambilan: batasPengambilan,
      status: status ?? this.status,
      createdAt: createdAt,
      namaKategori: namaKategori,
      storeNama: storeNama,
      storeAlamat: storeAlamat,
      storeNoWhatsapp: storeNoWhatsapp,
      storeJamBuka: storeJamBuka,
      storeJamTutup: storeJamTutup,
      storeLatitude: storeLatitude,
      storeLongitude: storeLongitude,
    );
  }

  String get storeDisplayName {
    final nama = storeNama?.trim();
    return (nama == null || nama.isEmpty) ? 'Toko Kenyangin' : nama;
  }

  DateTime get mulaiPengambilan =>
      batasPengambilan.subtract(const Duration(minutes: 90));
}

class ProductDraft {
  final String namaProduk;
  final String? categoryId;
  final String? namaKategori;
  final String deskripsi;
  final double hargaAsli;
  final double hargaSurplus;
  final int stok;
  final DateTime batasKonsumsi;
  final DateTime batasPengambilan;
  final Uint8List? imageBytes;
  final String? imageExtension;

  const ProductDraft({
    required this.namaProduk,
    this.categoryId,
    this.namaKategori,
    required this.deskripsi,
    required this.hargaAsli,
    required this.hargaSurplus,
    required this.stok,
    required this.batasKonsumsi,
    required this.batasPengambilan,
    this.imageBytes,
    this.imageExtension,
  });
}

class OrderDetailItem {
  final String productId;
  final String namaProduk;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final String? fotoUrl;

  const OrderDetailItem({
    required this.productId,
    required this.namaProduk,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.fotoUrl,
  });

  factory OrderDetailItem.fromMap(Map<String, dynamic> map) {
    final produk = map['products'];
    return OrderDetailItem(
      productId: map['product_id']?.toString() ?? '',
      namaProduk: produk is Map
          ? produk['nama_produk']?.toString() ?? 'Produk'
          : 'Produk',
      jumlah: _toInt(map['jumlah']),
      hargaSatuan: _toDouble(map['harga_satuan']),
      subtotal: _toDouble(map['subtotal']),
      fotoUrl: produk is Map ? produk['foto_url']?.toString() : null,
    );
  }
}

class ShopOrder {
  final String orderId;
  final String userId;
  final String storeId;
  final DateTime tanggalPesan;
  final double totalHarga;
  final String statusPesanan;
  final DateTime batasPengambilan;
  final DateTime? waktuPengambilan;
  final String qrToken;
  final List<OrderDetailItem> items;
  final String customerName;
  final String? customerPhone;
  final String? storeNama;
  final String? storeAlamat;
  final String? storePhone;
  final String? metodePembayaran;
  final String? statusPembayaran;

  const ShopOrder({
    required this.orderId,
    required this.userId,
    required this.storeId,
    required this.tanggalPesan,
    required this.totalHarga,
    required this.statusPesanan,
    required this.batasPengambilan,
    this.waktuPengambilan,
    required this.qrToken,
    required this.items,
    required this.customerName,
    this.customerPhone,
    this.storeNama,
    this.storeAlamat,
    this.storePhone,
    this.metodePembayaran,
    this.statusPembayaran,
  });

  factory ShopOrder.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? customer,
  }) {
    final detailRows = map['order_details'];
    final items = <OrderDetailItem>[];
    if (detailRows is List) {
      for (final row in detailRows) {
        if (row is Map<String, dynamic>) {
          items.add(OrderDetailItem.fromMap(row));
        } else if (row is Map) {
          items.add(OrderDetailItem.fromMap(Map<String, dynamic>.from(row)));
        }
      }
    }

    final toko = map['stores'];

    return ShopOrder(
      orderId: map['order_id'].toString(),
      userId: map['user_id'].toString(),
      storeId: map['store_id'].toString(),
      tanggalPesan: _toDate(map['tanggal_pesan']) ?? DateTime.now(),
      totalHarga: _toDouble(map['total_harga']),
      statusPesanan: map['status_pesanan']?.toString() ?? 'pending',
      batasPengambilan:
          _toDate(map['batas_pengambilan']) ??
          DateTime.now().add(const Duration(hours: 2)),
      waktuPengambilan: _toDate(map['waktu_pengambilan']),
      qrToken: map['qr_token']?.toString() ?? '-',
      items: items,
      customerName: customer?['nama']?.toString() ?? 'Konsumen',
      customerPhone: customer?['no_hp']?.toString(),
      storeNama: toko is Map ? toko['nama_toko']?.toString() : null,
      storeAlamat: toko is Map ? toko['alamat']?.toString() : null,
      storePhone: toko is Map ? toko['no_whatsapp']?.toString() : null,
      metodePembayaran: map['metode_pembayaran']?.toString(),
      statusPembayaran: map['status_pembayaran']?.toString(),
    );
  }

  bool get isPending => statusPesanan == 'pending';
  bool get isDiproses => statusPesanan == 'diproses';
  bool get isSelesai => statusPesanan == 'selesai';
  bool get isDibatalkan => statusPesanan == 'dibatalkan';
  bool get isAktif => isPending || isDiproses;

  String get displayCode {
    final token = qrToken.trim();
    if (token.isEmpty || token == '-') return '#-';
    if (token.startsWith('#')) return token.toUpperCase();
    return '#${token.toUpperCase()}';
  }

  String get statusLabel {
    switch (statusPesanan) {
      case 'pending':
        return 'Perlu Validasi';
      case 'diproses':
        return 'Menunggu Pengambilan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return statusPesanan;
    }
  }

  int get totalPorsi => items.fold(0, (total, item) => total + item.jumlah);

  String get storeDisplayName {
    final nama = storeNama?.trim();
    return (nama == null || nama.isEmpty) ? 'Toko Kenyangin' : nama;
  }

  String get customerStatusLabel {
    switch (statusPesanan) {
      case 'pending':
      case 'diproses':
        return 'Menunggu Diambil';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return statusPesanan;
    }
  }

  String get metodeLabel {
    switch (metodePembayaran) {
      case 'qris':
        return 'QRIS';
      case 'tunai':
        return 'Tunai di Kasir';
      default:
        return '-';
    }
  }

  bool get isPaid => statusPembayaran == 'lunas';

  String get ringkasanProduk {
    if (items.isEmpty) return 'Detail produk tidak tersedia';
    if (items.length == 1) {
      final item = items.first;
      return '${item.jumlah}x ${item.namaProduk}';
    }
    return '${items.first.jumlah}x ${items.first.namaProduk} +${items.length - 1} lainnya';
  }

  Duration get sisaWaktu {
    final sisa = batasPengambilan.difference(DateTime.now());
    return sisa.isNegative ? Duration.zero : sisa;
  }

  /// Jendela pengambilan ditampilkan 90 menit sebelum batas pengambilan.
  DateTime get mulaiPengambilan =>
      batasPengambilan.subtract(const Duration(minutes: 90));
}

class OrderValidationResult {
  final bool success;
  final String message;
  final ShopOrder? order;

  const OrderValidationResult({
    required this.success,
    required this.message,
    this.order,
  });
}

