import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/features/auth/screens/login_screen.dart';
import 'package:animal_rescue_app/features/auth/screens/signup_screen.dart';
import 'package:animal_rescue_app/features/cases/screens/report_case_screen.dart';
import 'package:animal_rescue_app/features/cases/screens/case_list_screen.dart';
import 'package:animal_rescue_app/features/cases/screens/case_detail_screen.dart';
import 'package:animal_rescue_app/features/ngo/screens/ngo_dashboard_screen.dart';
import 'package:animal_rescue_app/features/adoption/screens/adoption_list_screen.dart';
import 'package:animal_rescue_app/features/home/screens/home_screen.dart';
import 'package:animal_rescue_app/features/adoption/screens/create_adoption_screen.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppConstants.loginRoute,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.userRole;

      // If not authenticated, redirect to login
      if (!isAuthenticated &&
          !state.uri.toString().startsWith('/login') &&
          !state.uri.toString().startsWith('/signup')) {
        return AppConstants.loginRoute;
      }

      // If authenticated but no role available, treat as invalid session
      if (isAuthenticated && userRole == null) {
        return AppConstants.loginRoute;
      }

      // If authenticated and role selected, prevent access to auth screens
      if (isAuthenticated &&
          userRole != null &&
          (state.uri.toString().startsWith('/login') ||
              state.uri.toString().startsWith('/signup'))) {
        return AppConstants.dashboardRoute;
      }

      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.signupRoute,
        builder: (context, state) => const SignupScreen(),
      ),

      // Main Dashboard Route (role-based)
      GoRoute(
        path: AppConstants.dashboardRoute,
        builder: (context, state) {
          final userRole = authState.userRole;
          if (userRole == AppConstants.ngoRole) {
            return const NgoDashboardScreen();
          }
          return const HomeScreen(); // Citizen dashboard - new social feed
        },
      ),

      // Cases Routes
      GoRoute(
        path: AppConstants.reportCaseRoute,
        builder: (context, state) => const ReportCaseScreen(),
      ),
      GoRoute(
        path: AppConstants.casesRoute,
        builder: (context, state) => const CaseListScreen(),
      ),
      GoRoute(
        path: AppConstants.caseDetailRoute,
        builder: (context, state) {
          final caseId = state.uri.queryParameters['id'] ?? '';
          return CaseDetailScreen(caseId: caseId);
        },
      ),

      // Adoption Routes
      GoRoute(
        path: AppConstants.adoptionRoute,
        builder: (context, state) => const AdoptionListScreen(),
      ),
      GoRoute(
        path: AppConstants.createAdoptionRoute,
        builder: (context, state) => const CreateAdoptionScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.toString()}')),
    ),
  );
});
