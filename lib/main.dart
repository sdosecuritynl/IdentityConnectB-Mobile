import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/approval_request_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

// Global navigator key for handling navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Custom page transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            var curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(tween);
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  NotificationService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IdentityConnect',
      navigatorKey: navigatorKey, // Add navigator key
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
        // Add page transition theme
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: CupertinoPageTransitionsBuilder(), // Using iOS-style transitions on Android too for consistency
          },
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/approval_request') {
          final args = settings.arguments as Map<String, dynamic>;
          return FadePageRoute(
            page: ApprovalRequestScreen(sessionId: args['sessionId'] as String),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
}
