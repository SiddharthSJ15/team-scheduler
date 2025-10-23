import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../services/service.dart';

enum TaskFilter { all, created, mine }

class TaskState {
  final bool loading;
  final List<Map<String, dynamic>> tasks;
  final TaskFilter filter;
  final String? error;
  final String? userId; // current user id for filtering

  TaskState({
    this.loading = false,
    this.tasks = const [],
    this.filter = TaskFilter.all,
    this.error,
    this.userId,
  });

  TaskState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? tasks,
    TaskFilter? filter,
    String? error,
    String? userId,
  }) => TaskState(
    loading: loading ?? this.loading,
    tasks: tasks ?? this.tasks,
    filter: filter ?? this.filter,
    error: error,
    userId: userId ?? this.userId,
  );
}

class TaskCubit extends Cubit<TaskState> {
  TaskCubit({String? userId}) : super(TaskState(userId: userId));

  Future<void> loadTasks({String? userId}) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final tasks = await SupabaseService.getAllTasksWithCollaborators();
      emit(
        state.copyWith(
          loading: false,
          tasks: tasks,
          userId: userId ?? state.userId,
        ),
      );
    } catch (e) {
      debugPrint('loadTasks error: $e');
      emit(state.copyWith(loading: false, error: 'Failed to load tasks'));
    }
  }

  void setFilter(TaskFilter f) => emit(state.copyWith(filter: f));

  List<Map<String, dynamic>> get filteredTasks {
    if (state.filter == TaskFilter.all) return state.tasks;
    final uid = state.userId;
    if (uid == null) return [];
    if (state.filter == TaskFilter.created) {
      return state.tasks
          .where((t) => t['created_by']?.toString() == uid)
          .toList();
    } else {
      // mine -> creator OR collaborator
      return state.tasks.where((t) {
        final created = t['created_by']?.toString();
        if (created == uid) return true;
        final coll = (t['collaborators'] as List<dynamic>?) ?? [];
        return coll.any((u) => u['id']?.toString() == uid);
      }).toList();
    }
  }
}
