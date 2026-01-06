import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animal_rescue_app/features/cases/models/case_model.dart';
import 'package:animal_rescue_app/features/services/api_service.dart';

class CaseState {
  final List<AnimalCase> cases;
  final AnimalCase? selectedCase;
  final bool isLoading;
  final String? error;

  const CaseState({
    this.cases = const [],
    this.selectedCase,
    this.isLoading = false,
    this.error,
  });

  CaseState copyWith({
    List<AnimalCase>? cases,
    AnimalCase? selectedCase,
    bool? isLoading,
    String? error,
  }) {
    return CaseState(
      cases: cases ?? this.cases,
      selectedCase: selectedCase ?? this.selectedCase,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CaseNotifier extends StateNotifier<CaseState> {
  CaseNotifier() : super(const CaseState());

  final ApiService _apiService = ApiService();

  Future<void> loadCases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.getCases();
      final cases = response
          .map((json) => AnimalCase.fromJson(json))
          .where((c) => c.type != 'ADOPTION')
          .toList();
      state = state.copyWith(cases: cases, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load cases: ${e.toString()}',
      );
    }
  }

  Future<void> loadCase(String caseId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.getCase(caseId);
      final animalCase = AnimalCase.fromJson(response);
      state = state.copyWith(selectedCase: animalCase, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load case: ${e.toString()}',
      );
    }
  }

  Future<void> createCase({
    required String title,
    required String description,
    required String type,
    required String severity,
    required double latitude,
    required double longitude,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.createCase(
        title: title,
        description: description,
        type: type,
        severity: severity,
        latitude: latitude,
        longitude: longitude,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
      final newCase = AnimalCase.fromJson(response);

      final updatedCases = [newCase, ...state.cases];
      state = state.copyWith(cases: updatedCases, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create case: ${e.toString()}',
      );
    }
  }

  Future<void> updateCaseStatus(String caseId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Backend expects "InProgress" (no space)
      final normalizedStatus = status == 'In Progress' ? 'InProgress' : status;

      final response =
          await _apiService.updateCaseStatus(caseId, normalizedStatus);
      final updatedCase = AnimalCase.fromJson(response);

      final updatedCases = state.cases.map((case_) {
        if (case_.id == caseId) {
          return updatedCase;
        }
        return case_;
      }).toList();

      state = state.copyWith(
        cases: updatedCases,
        selectedCase:
            state.selectedCase?.id == caseId ? updatedCase : state.selectedCase,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update case status: ${e.toString()}',
      );
    }
  }

  Future<void> deleteCase(String caseId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteCase(caseId);

      state = state.copyWith(
        cases: state.cases.where((case_) => case_.id != caseId).toList(),
        selectedCase:
            state.selectedCase?.id == caseId ? null : state.selectedCase,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete case: ${e.toString()}',
      );
    }
  }

  List<AnimalCase> getCasesByStatus(String status) {
    return state.cases.where((case_) => case_.status == status).toList();
  }

  List<AnimalCase> getCasesBySeverity(String severity) {
    return state.cases
        .where((case_) => (case_.severity ?? '') == severity)
        .toList();
  }

  List<AnimalCase> getMyCases(String userId) {
    return state.cases.where((case_) => case_.reportedBy.id == userId).toList();
  }

  List<AnimalCase> getAssignedCases(String ngoId) {
    return state.cases
        .where((case_) => case_.assignedNgo?.id == ngoId)
        .toList();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedCase() {
    state = state.copyWith(selectedCase: null);
  }
}

final caseProvider = StateNotifierProvider<CaseNotifier, CaseState>((ref) {
  return CaseNotifier();
});

final casesByStatusProvider = Provider.family<List<AnimalCase>, String>((
  ref,
  status,
) {
  return ref
      .watch(caseProvider)
      .cases
      .where((case_) => case_.status == status)
      .toList();
});

final casesBySeverityProvider = Provider.family<List<AnimalCase>, String>((
  ref,
  severity,
) {
  return ref
      .watch(caseProvider)
      .cases
      .where((case_) => case_.severity == severity)
      .toList();
});
