import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animal_rescue_app/core/router/app_router.dart';
import 'package:animal_rescue_app/core/theme/app_theme.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';
import 'package:animal_rescue_app/features/services/api_service.dart';
import 'package:animal_rescue_app/core/config/backend_config.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppInitializer(
        child: RescueLinkApp(),
      ),
    ),
  );
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Perform initialization after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    print('[App Startup] API Base URL: ${BackendConfig.baseUrl}');

    // Initialize API service
    final apiService = ApiService();
    apiService.initialize();

    // Set up unauthorized handler
    apiService.setUnauthorizedHandler(() async {
      print('[App Startup] Unauthorized detected - logging out');
      await ref.read(authProvider.notifier).logout();
    });

    // Check authentication status
    print('[App Startup] Checking authentication status...');
    await ref.read(authProvider.notifier).checkAuthStatus();

    print('[App Startup] App initialization complete');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class RescueLinkApp extends ConsumerWidget {
  const RescueLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pet Buddy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
