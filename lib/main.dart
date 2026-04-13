import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/auth/screens/auth_screen.dart';
import 'package:voyage_app/features/home/screens/home_screen.dart';
import 'package:voyage_app/features/admin/screens/admin_panel.dart';
import 'package:voyage_app/features/admin/services/admin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyage App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            // User is authenticated, let's load their profile to check role
            return FutureBuilder<Map<String, dynamic>?>(
              future: AdminService.getCurrentAdmin(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  );
                }
                
                final userData = userSnapshot.data;
                final role = userData?['role'] ?? 'voyageur';

                if (role == 'admin') {
                  return AdminPanel(adminData: userData ?? {});
                }
                
                // Normal user goes to the home screen
                return const HomeScreen();
              },
            );
          }
        }
        // Not authenticated
        return const AuthScreen();
      },
    );
  }
}

