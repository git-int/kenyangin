import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenyangin/providers/auth_provider.dart';
import 'package:kenyangin/screens/auth/change_password_screen.dart';
import 'package:kenyangin/screens/auth/forgot_password_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('halaman lupa password tampil dan memvalidasi email',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ForgotPasswordScreen()));

    expect(find.text('Lupa kata sandi?'), findsOneWidget);
    expect(find.text('Kirim Tautan Reset'), findsOneWidget);

    await tester.tap(find.text('Kirim Tautan Reset'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('halaman kata sandi baru memvalidasi konfirmasi',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ChangePasswordScreen(recovery: true)));

    expect(find.text('Buat kata sandi baru'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(1), 'beda123');
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pump();

    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
