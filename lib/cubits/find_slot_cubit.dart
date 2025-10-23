import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../services/service.dart';

class FindSlotState {
  final bool loading;
  final List<Map<String, dynamic>> users;
  final Set<String> selectedIds;
  final int durationMinutes;
  final List<List<DateTime>> slots; // UTC timestamps
  final String? error;

  FindSlotState({
    this.loading = false,
    this.users = const [],
    Set<String>? selectedIds,
    this.durationMinutes = 30,
    this.slots = const [],
    this.error,
  }) : selectedIds = selectedIds ?? <String>{};

  FindSlotState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? users,
    Set<String>? selectedIds,
    int? durationMinutes,
    List<List<DateTime>>? slots,
    String? error,
  }) => FindSlotState(
    loading: loading ?? this.loading,
    users: users ?? this.users,
    selectedIds: selectedIds ?? this.selectedIds,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    slots: slots ?? this.slots,
    error: error,
  );
}

class FindSlotCubit extends Cubit<FindSlotState> {
  FindSlotCubit() : super(FindSlotState());

  Future<void> loadUsers() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final users = await SupabaseService.getAllUsers();
      emit(state.copyWith(loading: false, users: users));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load users'));
    }
  }

  void toggleSelect(String userId) {
    final copy = Set<String>.from(state.selectedIds);
    if (copy.contains(userId))
      copy.remove(userId);
    else
      copy.add(userId);
    emit(state.copyWith(selectedIds: copy));
  }

  void setDuration(int minutes) {
    emit(state.copyWith(durationMinutes: minutes));
  }

  Future<void> findSlots({required String includeCreatorId}) async {
    if (state.selectedIds.isEmpty) {
      emit(state.copyWith(error: 'Select at least one collaborator'));
      return;
    }
    emit(state.copyWith(loading: true, error: null, slots: []));
    try {
      final ids = List<String>.from(state.selectedIds);
      if (!ids.contains(includeCreatorId)) ids.add(includeCreatorId);

      final map = await SupabaseService.getAvailabilitiesForUsers(ids);

      final perUserIntervals = <List<List<DateTime>>>[];
      for (final id in ids) {
        final rows = map[id] ?? [];
        final intervals = rows.map((r) {
          // Keep everything in UTC - don't convert to local
          final start = DateTime.parse(r['start_time']).toUtc();
          final end = DateTime.parse(r['end_time']).toUtc();
          return [start, end];
        }).toList();
        perUserIntervals.add(intervals);
      }

      final duration = Duration(minutes: state.durationMinutes);
      final slots = SupabaseService.findCommonSlots(
        perUserIntervals,
        duration,
        stepDuration: const Duration(minutes: 15),
      );
      emit(state.copyWith(loading: false, slots: slots));
    } catch (e, st) {
      debugPrint('findSlots error: $e\n$st');
      emit(state.copyWith(loading: false, error: 'Failed to compute slots'));
    }
  }

  void setSelected(Set<String> newSelected) {
    emit(state.copyWith(selectedIds: newSelected));
  }

  void clearSlots() => emit(state.copyWith(slots: []));
}
