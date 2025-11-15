import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  MyApp({super.key, required this.isLogged});

  static const Color darkBackground = Color(0xFF0C0C0F);
  static const Color darkGold = Color(0xFFB8860B); // dark gold accent

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'Security — Temporary Vault',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: darkBackground,
        textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.dark(
          primary: darkGold,
          secondary: darkGold.withOpacity(0.9),
          background: darkBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0B0D),
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF131316),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
      ),
      initialRoute: isLogged ? '/home' : '/signin',
      routes: {
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// Remplacer la HomePage existante par cette version qui inclut un bouton de déconnexion
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('uid');
      await prefs.remove('email');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(
          child: Text('Déconnecté'),
        ),
            duration: Duration(seconds: 1),
            backgroundColor: MyApp.darkGold),
      );
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion : $e'), backgroundColor: MyApp.darkGold),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil — Security'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenue dans la Temporary Vault !', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
