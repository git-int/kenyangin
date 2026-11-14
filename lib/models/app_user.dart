class AppUser {
  final String userId;
  final String nama;
  final String email;
  final String? noHp;
  final String role;

  AppUser({
    required this.userId,
    required this.nama,
    required this.email,
    this.noHp,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'].toString(),
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      noHp: map['no_hp'],
      role: map['role'] ?? 'konsumen',
    );
  }

  bool get isKonsumen => role == 'konsumen';

  bool get isToko => role == 'toko';
}
