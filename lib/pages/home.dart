import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scheduler/cubits/availability_cubit.dart';
import 'package:scheduler/cubits/find_slot_cubit.dart';
import 'package:scheduler/cubits/tast_cubit.dart';
import 'package:scheduler/cubits/user_cubit.dart';
import 'package:scheduler/pages/availability_screen.dart';
import 'package:scheduler/pages/create_task_screen.dart';
import 'package:scheduler/pages/onboarding_screen.dart';
import 'package:scheduler/pages/task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userId;
  TaskCubit? _taskCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<UserCubit>().state;
      if (s is UserAuthenticated) {
        setState(() {
          _userId = s.user.id;
          _taskCubit = TaskCubit(userId: s.user.id);
          _taskCubit!.setFilter(TaskFilter.mine);
          _taskCubit!.loadTasks(userId: s.user.id);
        });
      }
    });
  }

  @override
  void dispose() {
    _taskCubit?.close();
    super.dispose();
  }

  String _formatSlot(Map<String, dynamic> t) {
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
    return BlocBuilder<UserCubit, dynamic>(
      builder: (context, state) {
        final isAuth = state is UserAuthenticated;
        final name = isAuth ? (state).user.name : null;
        final photo = isAuth ? (state).user.photoUrl : null;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(
              'Scheduler',
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (isAuth) ...[
                IconButton(
                  icon: Icon(Icons.event_available, color: Colors.grey[700]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => AvailabilityCubit(),
                          child: AvailabilityScreen(),
                        ),
                      ),
                    );
                  },
                  tooltip: 'Manage Availability',
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.grey[700]),
                  onPressed: () => context.read<UserCubit>().logout(),
                  tooltip: 'Logout',
                ),
              ],
            ],
          ),
          body: isAuth
              ? Column(
                  children: [
                    // User profile header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Row(
                        children: [
                          if (photo != null)
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(photo),
                            )
                          else
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                name?.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  name ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick actions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('New Task'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider(
                                          create: (_) =>
                                              FindSlotCubit()..loadUsers(),
                                          child: CreateTaskScreen(),
                                        ),
                                      ),
                                    )
                                    .then((_) {
                                      _taskCubit?.loadTasks(userId: _userId);
                                    });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.list_alt),
                              label: const Text('All Tasks'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[600]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider(
                                          create: (_) =>
                                              TaskCubit(userId: _userId!)
                                                ..loadTasks(userId: _userId),
                                          child: const TaskListScreen(),
                                        ),
                                      ),
                                    )
                                    .then((_) {
                                      _taskCubit?.loadTasks(userId: _userId);
                                    });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tasks section
                    Expanded(
                      child: _taskCubit == null
                          ? const Center(child: CircularProgressIndicator())
                          : BlocBuilder<TaskCubit, TaskState>(
                              bloc: _taskCubit,
                              builder: (context, taskState) {
                                if (taskState.loading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (taskState.error != null) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          taskState.error!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextButton.icon(
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry'),
                                          onPressed: () {
                                            _taskCubit?.loadTasks(
                                              userId: _userId,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final tasks = _taskCubit!.filteredTasks;

                                if (tasks.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.task_alt,
                                          size: 80,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No tasks yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Create your first task to get started',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Recent Tasks',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.refresh,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _taskCubit?.loadTasks(
                                                userId: _userId,
                                              );
                                            },
                                            tooltip: 'Refresh',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: tasks.length > 10
                                            ? 10
                                            : tasks.length,
                                        itemBuilder: (ctx, i) {
                                          final t = tasks[i];
                                          final coll =
                                              (t['collaborators']
                                                  as List<dynamic>?) ??
                                              [];
                                          final createdBy =
                                              (t['created_by_user']
                                                  as Map<String, dynamic>?);
                                          final durationMins =
                                              (t['start_time'] != null &&
                                                  t['end_time'] != null)
                                              ? DateTime.parse(t['end_time'])
                                                    .toUtc()
                                                    .difference(
                                                      DateTime.parse(
                                                        t['start_time'],
                                                      ).toUtc(),
                                                    )
                                                    .inMinutes
                                              : null;

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              leading: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                          _formatSlot(t),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[700],
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
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '$durationMins min',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[700],
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
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            coll
                                                                .map(
                                                                  (c) =>
                                                                      c['name'],
                                                                )
                                                                .join(', '),
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: Colors
                                                                  .grey[700],
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
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
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'by ${createdBy['name']}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600],
                                                            fontStyle: FontStyle
                                                                .italic,
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
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Scheduler',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to manage your tasks',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => OnboardingScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
