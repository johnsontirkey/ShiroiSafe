import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wsa4/screens/auth/signupscreens/signup_screen.dart';
import 'package:wsa4/screens/homescreens/admins/admin_home_screen.dart';
import 'package:wsa4/screens/homescreens/admins/manage_settings_screen.dart';
import 'package:wsa4/screens/homescreens/admins/screens/add_edit_service_screen.dart';
import 'package:wsa4/screens/homescreens/admins/screens/emergency_services_screen.dart';
import 'package:wsa4/screens/homescreens/admins/screens/notification_settings_screen.dart';
import 'package:wsa4/screens/homescreens/admins/screens/sos_settings_screen.dart';
import 'package:wsa4/screens/homescreens/admins/screens/trusted_contacts_rules_screen.dart';
import 'package:wsa4/screens/homescreens/admins/view_complaints_screen.dart';
import 'package:wsa4/screens/homescreens/admins/view_reports_screen.dart';
import 'package:wsa4/screens/homescreens/admins/view_users_screen.dart';
import 'package:wsa4/screens/homescreens/users/user_home_screen.dart';
import 'package:wsa4/screens/login_screen.dart';
import 'package:wsa4/screens/splashscreen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Women Safety App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Baumans',
                colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: Colors.pink,
          secondary: Colors.redAccent.shade200, // Use a crimson variant
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E63), // Pink
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.pink,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF1F3), // Very light pink
      ),
      initialRoute: '/splash', // Start with SplashScreen
      routes: {
        
        '/splash': (context) => const SplashScreen(), // SplashScreen route
        '/signup': (context) => const SignupScreen(), // SignupScreen route
        '/login': (context) => const LoginScreen(),   // LoginScreen route
        '/home' : (context) => const UserHomeScreen(), // UserHomeScreen route
        '/adminhome':(context) => const AdminHomeScreen(),
        '/admin/view_users': (context) => const ViewUsersScreen(),
        '/admin/view_reports': (context) => const ViewReportsScreen(),
        '/admin/view_complaints': (context) => const ViewComplaintsScreen(),
        '/admin/manage_settings': (context) => const ManageSettingsScreen(),
        '/admin/emergency_services': (context) => const EmergencyServicesScreen(),
        '/admin/add_edit_service': (context) => const AddEditServiceScreen(),
        '/admin/notification_settings': (context) => const NotificationSettingsScreen(),
        '/admin/sos_settings': (context) => const SOSSettingsScreen(),
        '/admin/trusted_contacts_rules': (context) => const TrustedContactsRulesScreen(),
      },
    );
  }
}
