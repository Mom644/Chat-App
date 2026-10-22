import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// =========================
// Main App
// =========================
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkLoginStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mini Chat App',

            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),

            // =========================
            // Routes
            // =========================
            routes: {
              "/login": (_) => const LoginScreen(),
              "/register": (_) => const RegisterScreen(),
              "/home": (_) => HomeScreen(),
            },

            // =========================
            // Start Screen
            // =========================
            home: auth.isLoggedIn
                ? HomeScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}