import 'package:flutter/foundation.dart';

/// Menghubungkan layar lain (mis. nota digital) dengan tab di shell konsumen
/// tanpa membuat ketergantungan melingkar antar file layar.
abstract class ConsumerTabs {
  static final ValueNotifier<int> index = ValueNotifier<int>(0);

  static void open(int tab) => index.value = tab;
}
