import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubits/availability_cubit.dart';
import '../services/service.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late String userId;
  final df = DateFormat('hh:mm a, MMM d');

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final id = await SupabaseService.getSavedUserId();
    if (id != null) {
      setState(() => userId = id);
      context.read<AvailabilityCubit>().loadSlots(id);
    }
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    final start = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (start == null) return;
    final end = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (end == null) return;

    final startDate = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final endDate = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    await context.read<AvailabilityCubit>().addSlot(userId, startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Availability')),
      body: BlocBuilder<AvailabilityCubit, AvailabilityState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.slots.isEmpty) {
            return const Center(child: Text('No availability added yet.'));
          }

          return ListView.builder(
            itemCount: state.slots.length,
            itemBuilder: (context, index) {
              final slot = state.slots[index];
              final start = DateTime.parse(slot['start_time']);
              final end = DateTime.parse(slot['end_time']);
              return ListTile(
                title: Text('${df.format(start)} → ${df.format(end)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => context.read<AvailabilityCubit>().deleteSlot(userId, slot['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSlot,
        child: const Icon(Icons.add),
      ),
    );
  }
}
