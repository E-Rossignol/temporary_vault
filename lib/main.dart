import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'pages/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/database_helper.dart';
import 'constants/theme.dart';

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
      initialRoute: isLogged ? '/home' : '/signin',
      routes: {
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

