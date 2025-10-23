import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler/cubits/user_cubit.dart';
import 'package:scheduler/pages/onboarding_screen.dart';
import 'package:scheduler/pages/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loading();
  }

  Future<void> _loading() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserAuthenticated) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
        } else if (state is UserUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => OnboardingScreen()),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Team Scheduler',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              BlocBuilder<UserCubit, UserState>(
                builder: (context, state) {
                  if (state is UserLoading) {
                    return CircularProgressIndicator();
                  } else if (state is UserError) {
                    return Column(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        Text('Error: ${state.message}'),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            context.read<UserCubit>().loadSavedUser();
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    );
                  }
                  return SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
