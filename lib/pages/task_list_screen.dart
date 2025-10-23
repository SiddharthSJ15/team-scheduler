import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler/cubits/find_slot_cubit.dart';
import 'package:scheduler/cubits/tast_cubit.dart';
import '../cubits/user_cubit.dart';
import 'create_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final s = context.read<UserCubit>().state;
    if (s is UserAuthenticated) _userId = s.user.id;
    // Create TaskCubit at runtime and load tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tc = context.read<TaskCubit>();
      tc.loadTasks(userId: _userId);
    });
  }

  String _fmtSlot(Map<String, dynamic> t) {
    if (t['start_time'] == null) return 'No slot assigned';
    final start = DateTime.parse(t['start_time']).toUtc().toLocal();
    final end = DateTime.parse(t['end_time']).toUtc().toLocal();
    final df = DateFormat('MMM d, yyyy');
    final tf = DateFormat('h:mm a');
    if (df.format(start) == df.format(end)) {
      return '${df.format(start)} • ${tf.format(start)} - ${tf.format(end)}';
    }
    return '${df.format(start)} ${tf.format(start)} - ${df.format(end)} ${tf.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Tasks',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            onPressed: () =>
                context.read<TaskCubit>().loadTasks(userId: _userId),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Tasks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All Tasks'),
                          selected: state.filter == TaskFilter.all,
                          onSelected: (_) => context
                              .read<TaskCubit>()
                              .setFilter(TaskFilter.all),
                          selectedColor: Colors.blue[600],
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: state.filter == TaskFilter.all
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Created by Me'),
                          selected: state.filter == TaskFilter.created,
                          onSelected: (_) => context
                              .read<TaskCubit>()
                              .setFilter(TaskFilter.created),
                          selectedColor: Colors.blue[600],
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: state.filter == TaskFilter.created
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Assigned to Me'),
                          selected: state.filter == TaskFilter.mine,
                          onSelected: (_) => context
                              .read<TaskCubit>()
                              .setFilter(TaskFilter.mine),
                          selectedColor: Colors.blue[600],
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: state.filter == TaskFilter.mine
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Tasks list
          Expanded(
            child: BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () {
                            context.read<TaskCubit>().loadTasks(
                              userId: _userId,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                final tasks = context.read<TaskCubit>().filteredTasks;

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new task to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) {
                    final t = tasks[i];
                    final coll = (t['collaborators'] as List<dynamic>?) ?? [];
                    final createdBy =
                        (t['created_by_user'] as Map<String, dynamic>?);
                    final durationMins =
                        (t['start_time'] != null && t['end_time'] != null)
                        ? DateTime.parse(t['end_time'])
                              .toUtc()
                              .difference(
                                DateTime.parse(t['start_time']).toUtc(),
                              )
                              .inMinutes
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.assignment,
                              color: Colors.blue[600],
                            ),
                          ),
                        ),
                        title: Text(
                          t['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _fmtSlot(t),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (durationMins != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$durationMins min',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (coll.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      coll.map((c) => c['name']).join(', '),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (createdBy != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'by ${createdBy['name']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => FindSlotCubit()..loadUsers(),
                    child: CreateTaskScreen(),
                  ),
                ),
              )
              .then((_) {
                context.read<TaskCubit>().loadTasks(userId: _userId);
              });
        },
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        elevation: 2,
      ),
    );
  }
}
