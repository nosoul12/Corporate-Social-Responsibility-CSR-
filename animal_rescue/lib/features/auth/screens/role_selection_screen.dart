import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/core/theme/primary_gradient_button.dart';
import 'package:animal_rescue_app/features/auth/providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Header
              Icon(
                Icons.person_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Role Selection',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your role is selected during signup and is included in your login token.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryGradientButton(
                onPressed: authState.isLoading
                    ? null
                    : () => context.go(AppConstants.loginRoute),
                child: const Text('Go to Login'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: authState.isLoading
                    ? null
                    : () => context.go(AppConstants.signupRoute),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
