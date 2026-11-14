import 'package:flutter_test/flutter_test.dart';
import 'package:kenyangin/models/app_user.dart';

void main() {
  group('AppUser Model & Role Test', () {
    test('Membuat AppUser konsumen dari Map dengan benar', () {
      final map = {
        'user_id': 'usr-123',
        'nama': 'Budi Santoso',
        'email': 'budi@test.com',
        'no_hp': '08123456789',
        'role': 'konsumen',
      };

      final user = AppUser.fromMap(map);

      expect(user.userId, 'usr-123');
      expect(user.nama, 'Budi Santoso');
      expect(user.email, 'budi@test.com');
      expect(user.noHp, '08123456789');
      expect(user.role, 'konsumen');
      expect(user.isKonsumen, isTrue);
      expect(user.isToko, isFalse);
    });

    test('Membuat AppUser toko dari Map dengan benar', () {
      final map = {
        'user_id': 'usr-456',
        'nama': 'Siti Rahmawati',
        'email': 'siti@test.com',
        'no_hp': '08567890123',
        'role': 'toko',
      };

      final user = AppUser.fromMap(map);

      expect(user.userId, 'usr-456');
      expect(user.nama, 'Siti Rahmawati');
      expect(user.role, 'toko');
      expect(user.isToko, isTrue);
      expect(user.isKonsumen, isFalse);
    });

    test('Default role adalah konsumen jika role bernilai null', () {
      final map = {
        'user_id': 'usr-789',
        'nama': 'Anonim',
        'email': 'anonim@test.com',
      };

      final user = AppUser.fromMap(map);

      expect(user.role, 'konsumen');
      expect(user.isKonsumen, isTrue);
    });
  });
}

