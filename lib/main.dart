import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyage_app/core/theme/app_theme.dart';
import 'package:voyage_app/features/auth/screens/auth_screen.dart';
import 'package:voyage_app/features/home/screens/home_screen.dart';
import 'package:voyage_app/features/onboarding/screens/onboarding_screen.dart';

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
            return FutureBuilder(
              future: Supabase.instance.client
                  .from('preferences')
                  .select()
                  .eq('id_user', session.user.id)
                  .maybeSingle(),
              builder: (context, prefSnapshot) {
                if (prefSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }
                // Pas de préférences → Onboarding
                if (prefSnapshot.data == null) {
                  return const OnboardingScreen();
                }
                // Préférences existantes → Accueil
                return const HomeScreen();
              },
            );
          }
        }
        return const AuthScreen();
      },
    );
  }
}
