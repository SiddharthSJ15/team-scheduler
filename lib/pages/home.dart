import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler/cubits/availability_cubit.dart';
import 'package:scheduler/cubits/user_cubit.dart';
import 'package:scheduler/pages/availability_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, dynamic>(
      builder: (context, state) {
        final isAuth = state is UserAuthenticated;
        final name = isAuth ? (state).user.name : null;
        final photo = isAuth ? (state).user.photoUrl : null;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
              if (isAuth)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<UserCubit>().logout(),
                ),
            ],
          ),
          body: Center(
            child: isAuth
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photo != null)
                        Image.network(photo, width: 120, height: 120),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, $name',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This is a minimal home screen for your test.',
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => AvailabilityCubit(),
                                child: const AvailabilityScreen(),
                              ),
                            ),
                          );
                        },
                        child: const Text('Manage Availability'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SizedBox()),
                    ),
                    child: const Text('Not signed in'),
                  ),
          ),
        );
      },
    );
  }
}
