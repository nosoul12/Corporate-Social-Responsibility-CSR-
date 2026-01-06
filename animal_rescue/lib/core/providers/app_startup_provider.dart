import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animal_rescue_app/core/config/backend_config.dart';

final appStartupProvider = Provider<String>((ref) {
  // This provider is now pure - no side effects
  // It just returns the API base URL for logging/debugging
  return BackendConfig.baseUrl;
});
