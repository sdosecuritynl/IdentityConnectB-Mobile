import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IdentityConnect',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.primaryBlue),
        ),
        colorScheme: ColorScheme.light(
          background: Colors.white,
          primary: AppTheme.primaryBlue,
          secondary: AppTheme.accentBlue,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppTheme.primaryBlue,
          selectionColor: AppTheme.primaryBlue.withOpacity(0.2),
          selectionHandleColor: AppTheme.primaryBlue,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
}
