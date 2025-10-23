import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/service.dart';

class AvailabilityState {
  final List<Map<String, dynamic>> slots;
  final bool loading;

  AvailabilityState({this.slots = const [], this.loading = false});

  AvailabilityState copyWith({
    List<Map<String, dynamic>>? slots,
    bool? loading,
  }) => AvailabilityState(
    slots: slots ?? this.slots,
    loading: loading ?? this.loading,
  );
}

class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit() : super(AvailabilityState());

  Future<void> loadSlots(String userId) async {
    emit(state.copyWith(loading: true));
    final data = await SupabaseService.getAvailability(userId);
    emit(state.copyWith(slots: data, loading: false));
  }

  Future<void> addSlot(String userId, DateTime start, DateTime end) async {
    await SupabaseService.addAvailability(
      userId: userId,
      start: start,
      end: end,
    );
    await loadSlots(userId);
  }

  Future<void> deleteSlot(String userId, int id) async {
    await SupabaseService.deleteAvailability(id);
    await loadSlots(userId);
  }
}
