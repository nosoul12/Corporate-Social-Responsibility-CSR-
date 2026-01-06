import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animal_rescue_app/features/cases/models/case_model.dart';
import 'package:animal_rescue_app/features/services/api_service.dart';

class AdoptionState {
  final List<AnimalCase> adoptions;
  final bool isLoading;
  final String? error;

  const AdoptionState({
    this.adoptions = const [],
    this.isLoading = false,
    this.error,
  });

  AdoptionState copyWith({
    List<AnimalCase>? adoptions,
    bool? isLoading,
    String? error,
  }) {
    return AdoptionState(
      adoptions: adoptions ?? this.adoptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdoptionNotifier extends StateNotifier<AdoptionState> {
  AdoptionNotifier() : super(const AdoptionState());

  final ApiService _apiService = ApiService();

  Future<void> loadAdoptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.getAdoptions();
      final adoptions =
          response.map((json) => AnimalCase.fromJson(json)).toList();
      state = state.copyWith(adoptions: adoptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load adoptions: ${e.toString()}',
      );
    }
  }

  Future<void> createAdoption({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.createAdoptionMultipart(
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );

      final newAdoption = AnimalCase.fromJson(response);
      state = state.copyWith(
        adoptions: [newAdoption, ...state.adoptions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create adoption: ${e.toString()}',
      );
    }
  }

  Future<void> deleteAdoption(String adoptionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteAdoption(adoptionId);
      state = state.copyWith(
        adoptions: state.adoptions
            .where((adoption) => adoption.id != adoptionId)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete adoption: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adoptionProvider =
    StateNotifierProvider<AdoptionNotifier, AdoptionState>((ref) {
  return AdoptionNotifier();
});
