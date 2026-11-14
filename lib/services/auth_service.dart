import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String role,
    String? namaToko,
    String? alamatToko,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nama': nama.trim(),
        'no_hp': noHp.trim(),
        'role': role,
        if (role == 'toko') ...{
          'nama_toko': namaToko?.trim(),
          'alamat_toko': alamatToko?.trim(),
        },
      },
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _client
        .from('users')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> ensureStoreProfile() async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    final role = user.userMetadata?['role'];

    if (role != 'toko') return;

    final existingStore = await _client
        .from('stores')
        .select('store_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingStore != null) return;

    final namaToko = user.userMetadata?['nama_toko'];
    final alamatToko = user.userMetadata?['alamat_toko'];

    if (namaToko == null ||
        namaToko.toString().trim().isEmpty ||
        alamatToko == null ||
        alamatToko.toString().trim().isEmpty) {
      throw Exception(
        'Informasi toko belum lengkap. Silakan lengkapi profil toko.',
      );
    }

    await _client.from('stores').insert({
      'user_id': user.id,
      'nama_toko': namaToko,
      'alamat': alamatToko,
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
