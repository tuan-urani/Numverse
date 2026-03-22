import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _appFlavor = String.fromEnvironment(
  'APP_FLAVOR',
  defaultValue: 'prod',
);

String _resolveEnvFileName() {
  switch (_appFlavor.trim().toLowerCase()) {
    case 'staging':
      return '.env.staging';
    case 'prod':
      return '.env.prod';
    default:
      return '.env';
  }
}

Future<void> registerEnvironmentModule() async {
  if (dotenv.isInitialized) return;

  final String preferredFileName = _resolveEnvFileName();
  try {
    await dotenv.load(fileName: preferredFileName);
  } catch (_) {
    if (preferredFileName == '.env') {
      rethrow;
    }
    await dotenv.load(fileName: '.env');
  }
}
