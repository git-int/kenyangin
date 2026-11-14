import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenyangin/screens/splash/splash_screen.dart';

void main() {
  testWidgets('splash menampilkan logo, wordmark, dan indikator loading',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.text('Kenyangin', findRichText: true), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
