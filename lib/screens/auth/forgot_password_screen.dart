import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

const Color _brandRed = Color(0xFFC83E27);
const Color _cream = Color(0xFFFFF9F2);
const Color _border = Color(0xFFE0E0E0);

/// Layar untuk meminta tautan reset kata sandi lewat email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send({bool resend = false}) async {
    FocusScope.of(context).unfocus();

    if (!resend && !_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await context
          .read<AuthProvider>()
          .sendPasswordReset(_emailController.text.trim());

      if (!mounted) return;

      setState(() => _sent = true);

      if (resend) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tautan reset sudah dikirim ulang.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = text.toLowerCase();

    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('failed host lookup')) {
      return 'Tidak ada koneksi internet. Periksa jaringan kamu.';
    }
    if (lower.contains('redirect')) {
      return 'Tautan reset belum bisa dikirim. Hubungi admin untuk pengaturan URL aplikasi.';
    }

    return text.isEmpty ? 'Gagal mengirim tautan reset. Coba lagi.' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.black87,
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Lupa Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_sent) _buildSuccess(context) else _buildForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 38,
                color: _brandRed,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lupa kata sandi?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan email akun Kenyangin kamu. Kami akan mengirim tautan '
            'untuk membuat kata sandi baru.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          const Text(
            'Alamat Email',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _sending ? null : _send(),
            decoration: _inputDecoration(
              hintText: 'budi.santoso@email.com',
              prefixIcon: Icons.alternate_email,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              final email = value.trim();
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Format email tidak valid';
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
            onPressed: _sending ? null : () => _send(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Tautan Reset',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(foregroundColor: Colors.black54),
            child: const Text('Kembali ke halaman masuk'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 38,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tautan Terkirim',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jika $email terdaftar, kami sudah mengirim tautan untuk mengatur '
          'ulang kata sandi. Cek kotak masuk atau folder spam kamu.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: _brandRed),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tautan berlaku terbatas. Jika sudah kedaluwarsa, kirim ulang '
                  'tautan dari halaman ini.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _error!),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _sending ? null : () => _send(resend: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Kirim Ulang Tautan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(foregroundColor: Colors.black54),
          child: const Text('Kembali ke halaman masuk'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey),
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
