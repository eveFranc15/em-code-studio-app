import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración de Supabase.
///
/// Las credenciales NO se guardan en el repositorio. Pásalas al ejecutar:
///
/// flutter run \
///   --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan las credenciales de Supabase. Ejecuta con --dart-define=SUPABASE_URL=... '
        'y --dart-define=SUPABASE_ANON_KEY=... (consulta el README).',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      publishableKey: supabasePublishableKey.isEmpty
          ? null
          : supabasePublishableKey,
    );
  }
}
