import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException, AuthState;

import '../core/config/supabase_config.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({bool initialPasswordRecovery = false})
      : isPasswordRecovery = initialPasswordRecovery;

  final AuthRepository _repository = AuthRepository();

  AppUser? user;
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;

  /// True saat pengguna membuka tautan pemulihan kata sandi dari email
  /// (mode "atur kata sandi baru").
  bool isPasswordRecovery;

  StreamSubscription<AuthState>? _authStateSubscription;

  Future<void> loadUser() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      user = await _repository.getCurrentProfile();

      if (user?.isToko == true) {
        await _repository.ensureStoreProfile();
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    hasLoaded = true;
    notifyListeners();
  }

  /// Dengarkan event pemulihan kata sandi dari Supabase.
  void startRecoveryListener() {
    if (_authStateSubscription != null || !SupabaseConfig.isInitialized) return;

    _authStateSubscription = _repository.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        isPasswordRecovery = true;
        notifyListeners();
      }
    });
  }

  void finishPasswordRecovery() {
    if (!isPasswordRecovery) return;
    isPasswordRecovery = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);

      await loadUser();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String role,
    String? namaToko,
    String? alamatToko,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.signUp(
        nama: nama,
        email: email,
        noHp: noHp,
        password: password,
        role: role,
        namaToko: namaToko,
        alamatToko: alamatToko,
      );
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    final redirect = _passwordResetRedirect;

    try {
      await _repository.sendPasswordReset(email, redirectTo: redirect);
    } on AuthException catch (error) {
      // Sebagian project Supabase belum mengizinkan URL redirect aplikasi.
      // Kirim ulang tanpa redirect agar email reset tetap terkirim.
      final needsFallback =
          redirect != null && error.message.toLowerCase().contains('redirect');

      if (!needsFallback) rethrow;

      await _repository.sendPasswordReset(email);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _repository.updatePassword(newPassword);
  }

  String? get _passwordResetRedirect {
    if (!kIsWeb) return null;
    final origin = Uri.base.origin;
    if (origin.isEmpty || origin == 'null') return null;
    return origin;
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
