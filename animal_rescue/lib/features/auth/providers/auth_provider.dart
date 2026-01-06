import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';
import 'package:animal_rescue_app/core/utils/jwt_utils.dart';
import 'package:animal_rescue_app/features/services/api_service.dart';

const _unset = Object();

class UserStats {
  final int reportedCases;
  final int adoptionListings;
  final int assignedCases;

  const UserStats({
    required this.reportedCases,
    required this.adoptionListings,
    required this.assignedCases,
  });

  factory UserStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const UserStats(
        reportedCases: 0,
        adoptionListings: 0,
        assignedCases: 0,
      );
    }

    return UserStats(
      reportedCases: (json['reportedCases'] as num?)?.toInt() ?? 0,
      adoptionListings: (json['adoptionListings'] as num?)?.toInt() ?? 0,
      assignedCases: (json['assignedCases'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final Map<String, dynamic>? ngo;
  final UserStats stats;
  final String? localImageAsset;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.ngo,
    this.stats = const UserStats(
      reportedCases: 0,
      adoptionListings: 0,
      assignedCases: 0,
    ),
    this.localImageAsset,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      ngo: json['ngo'] as Map<String, dynamic>?,
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>?),
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    Map<String, dynamic>? ngo,
    UserStats? stats,
    String? localImageAsset,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      ngo: ngo ?? this.ngo,
      stats: stats ?? this.stats,
      localImageAsset: localImageAsset ?? this.localImageAsset,
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final String? userRole;
  final String? userId;
  final bool isLoading;
  final bool isProfileLoading;
  final UserProfile? profile;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    this.userRole,
    this.userId,
    required this.isLoading,
    required this.isProfileLoading,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userRole,
    String? userId,
    bool? isLoading,
    bool? isProfileLoading,
    Object? profile = _unset,
    Object? error = _unset,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      isProfileLoading: isProfileLoading ?? this.isProfileLoading,
      profile:
          identical(profile, _unset) ? this.profile : profile as UserProfile?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(const AuthState(
          isAuthenticated: false,
          isLoading: false,
          isProfileLoading: false,
        ));

  final ApiService _apiService = ApiService();

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.authTokenKey);
      final role = prefs.getString(AppConstants.userRoleKey);
      final userId = prefs.getString(AppConstants.userProfileKey);

      if (token != null && token.isNotEmpty) {
        _apiService.setAuthToken(token);

        final effectiveRole = role ?? JwtUtils.tryGetRole(token);
        final effectiveUserId = userId ?? JwtUtils.tryGetUserId(token);

        if (effectiveRole != null) {
          await prefs.setString(AppConstants.userRoleKey, effectiveRole);
        }
        if (effectiveUserId != null) {
          await prefs.setString(AppConstants.userProfileKey, effectiveUserId);
        }

        if (effectiveRole == null) {
          await logout();
          return;
        }

        state = state.copyWith(
          isAuthenticated: true,
          userRole: effectiveRole,
          userId: effectiveUserId,
          isLoading: false,
        );

        await loadProfile(silent: true);
      } else {
        _apiService.clearAuthToken();
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          profile: null,
          isProfileLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isProfileLoading: false,
        profile: null,
        error: 'Failed to check auth status',
      );
    }
  }

  Future<void> login(String email, String password) async {
    if (state.isLoading) return; // Prevent multiple concurrent logins

    state = state.copyWith(
      isLoading: true,
      error: null,
      profile: null,
      isProfileLoading: false,
    );
    try {
      final response = await _apiService.login(email, password);
      final token = (response['access_token'] ?? response['token']) as String?;
      if (token == null || token.isEmpty) {
        throw 'Missing token';
      }

      final role = JwtUtils.tryGetRole(token);
      final userId = JwtUtils.tryGetUserId(token);
      if (role == null || role.isEmpty) {
        throw 'Missing role in token';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, token);
      await prefs.setString(AppConstants.userRoleKey, role);
      if (userId != null) {
        await prefs.setString(AppConstants.userProfileKey, userId);
      }

      _apiService.setAuthToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        userRole: role,
        userId: userId,
        isLoading: false,
      );

      await loadProfile(silent: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> signup(
    String name,
    String email,
    String password,
    String role,
    String? phone,
  ) async {
    if (state.isLoading) return; // Prevent multiple concurrent signups

    state = state.copyWith(
      isLoading: true,
      error: null,
      profile: null,
      isProfileLoading: false,
    );
    try {
      final response =
          await _apiService.signup(name, email, password, role, phone);
      final token = (response['access_token'] ?? response['token']) as String?;
      if (token == null || token.isEmpty) {
        throw 'Missing token';
      }

      final decodedRole = JwtUtils.tryGetRole(token) ?? role;
      final userId = JwtUtils.tryGetUserId(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, token);
      await prefs.setString(AppConstants.userRoleKey, decodedRole);
      if (userId != null) {
        await prefs.setString(AppConstants.userProfileKey, userId);
      }

      _apiService.setAuthToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        userRole: decodedRole,
        userId: userId,
        isLoading: false,
      );

      await loadProfile(silent: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Signup failed: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.authTokenKey);
      await prefs.remove(AppConstants.userRoleKey);
      await prefs.remove(AppConstants.userProfileKey);

      _apiService.clearAuthToken();

      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        isProfileLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isProfileLoading: false,
        error: 'Logout failed: ${e.toString()}',
      );
    }
  }

  Future<void> loadProfile({bool silent = false}) async {
    if (!state.isAuthenticated) return;

    state = state.copyWith(
      isProfileLoading: true,
      error: silent ? state.error : null,
    );

    try {
      final profileData = await _apiService.getProfile();
      var profile = UserProfile.fromJson(profileData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userRoleKey, profile.role);
      await prefs.setString(AppConstants.userProfileKey, profile.id);

      // Load local image asset if exists
      final localImage = prefs.getString('profile_image_${profile.id}');
      if (localImage != null) {
        profile = profile.copyWith(localImageAsset: localImage);
      }

      state = state.copyWith(
        profile: profile,
        userRole: profile.role.isNotEmpty ? profile.role : state.userRole,
        userId: profile.id.isNotEmpty ? profile.id : state.userId,
        isAuthenticated: true,
        isProfileLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProfileLoading: false,
        error: silent ? state.error : 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfileImage(String assetPath) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_${currentProfile.id}', assetPath);

    state = state.copyWith(
      profile: currentProfile.copyWith(localImageAsset: assetPath),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
