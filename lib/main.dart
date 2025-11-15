import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/database_helper.dart';

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
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _userData = [];

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('uid');
      await prefs.remove('email');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(child: Text('Déconnecté')),
          duration: Duration(seconds: 1),
          backgroundColor: MyApp.darkGold,
        ),
      );
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion : $e'), backgroundColor: MyApp.darkGold),
      );
    }
  }

  void _getUserData() async {
    final db = DatabaseHelper.instance;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    _userData = await db.getCurrentUserData(email);
    if (_userData.isEmpty){
      print("Oups");
    }
    if (mounted) setState(() {}); // rafraîchir l'UI après chargement
  }

  @override
  void dispose() {
    super.dispose();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Bienvenue dans la Temporary Vault !', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Charger données'),
                    onPressed: _getUserData,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _userData.isEmpty
                  ? Center(child: Text('Aucune donnée chargée', style: TextStyle(color: Colors.white.withOpacity(0.7))))
                  : ListView.separated(
                      itemCount: _userData.length,
                      separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final item = _userData[index];
                        // format attendu : "docId • key1: value1 • key2: value2"
                        final parts = item.split(' • ');
                        final id = parts.isNotEmpty ? parts[0] : 'sans id';
                        final values = parts.length > 1 ? parts.sublist(1).join(' • ') : '';
                        return ListTile(
                          title: Text(id, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            values,
                            style: TextStyle(color: Colors.white.withOpacity(0.75)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          dense: true,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Text('Total documents: ${_userData.length}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
