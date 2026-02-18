import 'package:flutter/material.dart';
import 'pages/mainscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
      'Firebase initialized for platform: ${DefaultFirebaseOptions.currentPlatform.appId}',
    );
    debugPrint(
      'Available Firebase apps: ${Firebase.apps.map((a) => a.name).toList()}',
    );
  } catch (e, st) {
    // Log error so we can see why Firebase failed to initialize (use browser console on web)
    debugPrint('Firebase initialization error: $e');
    debugPrint('$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const Mainscreen(),
    );
  }
}
