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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _supabase = Supabase.instance.client;
  Future<Map<String, dynamic>?>? _prefFuture;
  String? _userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            // Ne recrée la future que si l'utilisateur change
            if (_userId != session.user.id) {
              _userId = session.user.id;
              _prefFuture = _supabase
                  .from('preferences')
                  .select()
                  .eq('id_user', session.user.id)
                  .maybeSingle();
            }
            return FutureBuilder(
              future: _prefFuture,
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
