import 'package:flutter_test/flutter_test.dart';
import 'package:kenyangin/core/utils/formats.dart';
import 'package:kenyangin/models/shop_models.dart';

void main() {
  group('SurplusProduct', () {
    test('menghitung diskon, hemat, dan status ketersediaan', () {
      final product = SurplusProduct.fromMap({
        'product_id': 'p-1',
        'store_id': 's-1',
        'nama_produk': 'Paket Croissant',
        'harga_asli': 42000,
        'harga_surplus': 21000,
        'stok': 3,
        'status': 'tersedia',
        'batas_pengambilan': '2026-11-06T14:00:00Z',
        'categories': {'nama_kategori': 'Roti & Pastry'},
      });

      expect(product.diskonPersen, 50);
      expect(product.hemat, 21000);
      expect(product.isTersedia, isTrue);
      expect(product.namaKategori, 'Roti & Pastry');
      expect(product.statusLabel, 'Tersedia');
    });

    test('stok kosong dianggap habis walau status tersedia', () {
      final product = SurplusProduct.fromMap({
        'product_id': 'p-2',
        'store_id': 's-1',
        'nama_produk': 'Cinnamon Roll',
        'harga_asli': 30000,
        'harga_surplus': 15000,
        'stok': 0,
        'status': 'tersedia',
        'batas_pengambilan': '2026-11-06T14:00:00Z',
      });

      expect(product.isTersedia, isFalse);
      expect(product.isHabis, isTrue);
      expect(product.statusLabel, 'Habis Terjual');
    });
  });

  group('ShopOrder', () {
    test('membaca detail pesanan dan total porsi', () {
      final order = ShopOrder.fromMap(
        {
          'order_id': 'o-1',
          'user_id': 'u-1',
          'store_id': 's-1',
          'tanggal_pesan': '2026-11-06T10:00:00Z',
          'total_harga': 42000,
          'status_pesanan': 'diproses',
          'batas_pengambilan': '2026-11-06T14:00:00Z',
          'qr_token': 'LB-8829-JKT',
          'order_details': [
            {
              'product_id': 'p-1',
              'jumlah': 2,
              'harga_satuan': 21000,
              'subtotal': 42000,
              'products': {'nama_produk': 'Paket Croissant'},
            },
          ],
        },
        customer: {'nama': 'Sarah Nuur'},
      );

      expect(order.displayCode, '#LB-8829-JKT');
      expect(order.customerName, 'Sarah Nuur');
      expect(order.totalPorsi, 2);
      expect(order.isDiproses, isTrue);
      expect(order.ringkasanProduk, '2x Paket Croissant');
      expect(order.statusLabel, 'Menunggu Pengambilan');
    });
  });

  group('Formats', () {
    test('memformat rupiah dan durasi', () {
      expect(Formats.rupiah(21000), contains('21'));
      expect(Formats.countdown(const Duration(minutes: 45)), '45 mnt');
      expect(
        Formats.countdown(const Duration(hours: 2, minutes: 5)),
        '2 jam 5 mnt',
      );
    });
  });
}

