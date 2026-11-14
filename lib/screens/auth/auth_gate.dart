import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/consumer_provider.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import '../consumer/home/consumer_home_screen.dart';
import '../shop/home/shop_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.hasLoaded) auth.loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isPasswordRecovery) {
          return const ChangePasswordScreen(recovery: true);
        }

        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => auth.loadUser(),
                      child: const Text('Coba Lagi'),
                    ),
                    TextButton(
                      onPressed: () => auth.logout(),
                      child: const Text('Kembali ke Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (auth.user == null) {
          return const LoginScreen();
        }

        if (auth.user!.role == 'konsumen') {
          return ConsumerHomeScreen(
            provider: ConsumerProvider(user: auth.user!),
          );
        }

        if (auth.user!.role == 'toko') {
          return const ShopHomeScreen();
        }

        return const Scaffold(
          body: Center(
            child: Text('Role pengguna tidak dikenali.'),
          ),
        );
      },
    );
  }
}