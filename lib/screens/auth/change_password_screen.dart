import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

const Color _brandRed = Color(0xFFC83E27);
const Color _cream = Color(0xFFFFF9F2);
const Color _border = Color(0xFFE0E0E0);

/// Layar untuk mengatur kata sandi baru.
///
/// Dipakai setelah pengguna membuka tautan reset dari email
/// ([recovery] bernilai true), dan bisa juga dipakai untuk mengganti
/// kata sandi saat sudah login.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.recovery = false});

  final bool recovery;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await auth.updatePassword(_passwordController.text);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      if (widget.recovery) {
        auth.finishPasswordRecovery();
      } else {
        navigator.pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = text.toLowerCase();

    if (lower.contains('session') || lower.contains('jwt')) {
      return 'Sesi pemulihan sudah berakhir. Minta tautan reset baru dari '
          'halaman lupa password.';
    }
    if (lower.contains('password')) {
      return 'Kata sandi tidak memenuhi syarat. Gunakan minimal 6 karakter.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Tidak ada koneksi internet. Periksa jaringan kamu.';
    }

    return text.isEmpty ? 'Gagal memperbarui kata sandi. Coba lagi.' : text;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.recovery,
      child: Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (!widget.recovery)
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.black87,
                          tooltip: 'Kembali',
                        ),
                      if (!widget.recovery) const SizedBox(width: 4),
                      Text(
                        widget.recovery
                            ? 'Kata Sandi Baru'
                            : 'Ubah Kata Sandi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: widget.recovery
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.recovery
                            ? Icons.verified_user_rounded
                            : Icons.password_rounded,
                        size: 38,
                        color: widget.recovery
                            ? const Color(0xFF2E7D32)
                            : _brandRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.recovery
                        ? 'Buat kata sandi baru'
                        : 'Perbarui kata sandi',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recovery
                        ? 'Tautan reset berhasil dibuka. Buat kata sandi baru '
                            'untuk akun kamu.'
                        : 'Masukkan kata sandi baru untuk akun kamu.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Kata Sandi Baru',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _inputDecoration(
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Kata sandi minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ulangi Kata Sandi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _hideConfirm,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saving ? null : _save(),
                    decoration: _inputDecoration(
                      hintText: 'Ulangi kata sandi baru',
                      prefixIcon: Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _hideConfirm = !_hideConfirm);
                        },
                        icon: Icon(
                          _hideConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi kata sandi wajib diisi';
                      }
                      if (value != _passwordController.text) {
                        return 'Kata sandi tidak sama';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.recovery
                                ? 'Simpan Kata Sandi'
                                : 'Perbarui Kata Sandi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandRed, width: 1.5),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3C5BB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _brandRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: _brandRed),
            ),
          ),
        ],
      ),
    );
  }
}
