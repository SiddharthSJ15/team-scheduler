import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler/pages/splash_screen.dart';
import 'package:scheduler/cubits/user_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read environment variables using compile-time constants
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final res = await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  print(res.isInitialized);
  runApp(const MyApp());
}

// Get a reference to your Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserCubit()..loadSavedUser(),
      child: MaterialApp(
        title: 'Team Scheduler',
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
