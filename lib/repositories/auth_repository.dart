import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<void> signIn({required String email, required String password}) async {
    await _authService.signIn(email: email, password: password);
  }

  Future<void> signUp({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String role,
    String? namaToko,
    String? alamatToko,
  }) async {
    final response = await _authService.signUp(
      nama: nama,
      email: email,
      noHp: noHp,
      password: password,
      role: role,
      namaToko: namaToko,
      alamatToko: alamatToko,
    );

    if (response.user == null) {
      throw Exception('Registrasi gagal. Silakan coba kembali.');
    }
  }

  Future<AppUser?> getCurrentProfile() async {
    final user = _authService.currentUser;

    if (user == null) return null;

    final data = await _authService.getUserProfile(user.id);

    if (data == null) return null;

    return AppUser.fromMap(data);
  }

  Future<void> ensureStoreProfile() async {
    await _authService.ensureStoreProfile();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> sendPasswordReset(String email, {String? redirectTo}) async {
    await _authService.resetPassword(email, redirectTo: redirectTo);
  }

  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  get authStateChanges => _authService.authStateChanges;
}
