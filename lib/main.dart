import 'package:flutter/material.dart';
import 'package:scheduler/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  final res = await Supabase.initialize(
    url: 'https://wjcdutzlamxihrgkxkad.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqY2R1dHpsYW14aWhyZ2t4a2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MjM2MzUsImV4cCI6MjA3MzQ5OTYzNX0.GRj0ikI2hnF_ISO1af_q8GTGaG4DgWCvB7_JiHErZ3Y',
  );
  print(res.isInitialized);
  runApp(MyApp());
}

// Get a reference your Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Team Scheduler', home: SplashScreen());
  }
}
