import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/security/security_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'models/user_model.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize push notifications
  await NotificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Emergency Alert System',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<UserModel?>(
            future: _authService.getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData) {
                String role = userSnapshot.data!.role;
                String email = userSnapshot.data!.email;

                // debugPrint('DEBUG START');
                // debugPrint('Email: $email');
                // debugPrint('Role: $role');
                // debugPrint('Role length: ${role.length}');
                // debugPrint('Role == admin: ${role == "admin"}');
                // debugPrint('Role == security: ${role == "security"}');
                // debugPrint('Role == student: ${role == "student"}');
                // debugPrint('DEBUG END');

                if (role == 'student') {
                  // debugPrint('ROUTING TO: Student');
                  return StudentHomeScreen();
                } else if (role == 'security') {
                  // debugPrint('ROUTING TO: Security');
                  return SecurityHomeScreen();
                } else if (role == 'admin') {
                  // debugPrint('ROUTING TO: Admin');
                  return AdminHomeScreen();
                }

                // debugPrint('NO MATCH FOR ROLE: $role');
              }

              _authService.logout();
              return LoginScreen();
            },
          );
        }

        return LoginScreen();
      },
    );
  }
}