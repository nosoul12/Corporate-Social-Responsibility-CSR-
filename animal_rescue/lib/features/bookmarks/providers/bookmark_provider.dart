import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkState {
  final Set<String> caseIds;
  final bool isLoading;

  const BookmarkState({
    this.caseIds = const <String>{},
    this.isLoading = false,
  });

  BookmarkState copyWith({
    Set<String>? caseIds,
    bool? isLoading,
  }) {
    return BookmarkState(
      caseIds: caseIds ?? this.caseIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BookmarkNotifier extends StateNotifier<BookmarkState> {
  BookmarkNotifier() : super(const BookmarkState()) {
    _load();
  }

  static const _key = 'bookmarked_case_ids';

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key) ?? <String>[];
      state = state.copyWith(caseIds: ids.toSet(), isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> toggle(String caseId) async {
    final next = {...state.caseIds};
    final isNowSaved = !next.contains(caseId);
    if (isNowSaved) {
      next.add(caseId);
    } else {
      next.remove(caseId);
    }

    state = state.copyWith(caseIds: next);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, next.toList());
    } catch (_) {
      // ignore
    }

    return isNowSaved;
  }

  bool isSaved(String caseId) => state.caseIds.contains(caseId);
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  return BookmarkNotifier();
});
