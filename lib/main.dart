import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:temporary_vault/pages/locked_vault_page.dart';
import 'package:temporary_vault/pages/password_missing_vault_page.dart';
import 'package:temporary_vault/pages/unlocked_vault_page.dart';
import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/theme.dart';
import 'pages/new_vault_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // lire SharedPreferences pour savoir si l'utilisateur est déjà identifié
  final prefs = await SharedPreferences.getInstance();
  final storedUid = prefs.getString('uid');
  final bool isLogged = storedUid != null && storedUid.isNotEmpty;
  runApp(MyApp(isLogged: isLogged));
}

class MyApp extends StatelessWidget {
  final bool isLogged;
  const MyApp({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security — Temporary Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(), // thème centralisé
      // builder global : on place l'image d'arrière-plan derrière le "child" de l'app
      builder: (context, child) {
        return Stack(
          children: [
            // image de fond couvrant tout l'écran
            Positioned.fill(
              child: Image.asset(
                // --> utiliser le chemin tel que déclaré dans pubspec.yaml (ex: images/background.jpg)
                'lib/constants/images/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // contenu de l'application : s'assurer que le child n'ajoute pas une couleur de fond opaque
            if (child != null)
              Positioned.fill(
                child: Container(color: Colors.transparent, child: child),
              ),
          ],
        );
      },
      initialRoute: isLogged ? '/home' : '/signin',
      routes: {
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/new_vault': (context) => const NewVaultPage(),
        '/locked_vault': (context) => const LockedVaultPage(),
        '/unlocked_vault': (context) => UnlockedVaultPage(),
        '/password_missing': (context) => const PasswordMissingVaultPage(),
      },
    );
  }
}
