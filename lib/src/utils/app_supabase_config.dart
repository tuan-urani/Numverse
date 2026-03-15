import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppSupabaseConfig {
  const AppSupabaseConfig({this.baseUrl, this.anonKey});

  final String? baseUrl;
  final String? anonKey;

  String get resolvedBaseUrl {
    final String value = (baseUrl ?? dotenv.env['SUPABASE_URL'] ?? '').trim();
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  String get resolvedAnonKey {
    return (anonKey ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
  }

  bool get isConfigured {
    return resolvedBaseUrl.isNotEmpty && resolvedAnonKey.isNotEmpty;
  }

  Uri rpcUri(String functionName) {
    return Uri.parse('$resolvedBaseUrl/rest/v1/rpc/$functionName');
  }
}
