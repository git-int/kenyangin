import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _defaultUrl = 'https://yewqrhoycgscshofqprh.supabase.co';
  static const String _defaultAnonKey =
      'sb_publishable_P5xV7Io6knh0vF_07eImpw_L85defFC';

  static SupabaseClient get client => Supabase.instance.client;

  static bool isInitialized = false;

  static Future<void> initialize() async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final supabaseUrl = envUrl.isNotEmpty ? envUrl : _defaultUrl;
    final supabaseAnonKey = envAnonKey.isNotEmpty ? envAnonKey : _defaultAnonKey;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_URL atau SUPABASE_ANON_KEY belum diatur.');
    }

    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
    isInitialized = true;
  }
}
