import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:temporary_vault/constants/database_helper.dart';
import 'package:temporary_vault/pages/locked_vault_page.dart';
import 'package:temporary_vault/pages/new_vault_page.dart';
import 'package:temporary_vault/pages/password_missing_vault_page.dart';
import 'package:temporary_vault/pages/unlocked_vault_page.dart';
import '../constants/theme.dart';
import '../models/data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int userState = 0; // STATES: 0 = locked, 1 = ready to be unlocked, 2 = unlocked
  Data dt = Data(mail: "", deadline: DateTime.now(), message: '', locked: false);

  // stocker le Future d'initialisation pour éviter de le recréer à chaque build
  late Future<void> _initFuture;

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
          backgroundColor: AppTheme.darkGold,
        ),
      );
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion : $e'), backgroundColor: AppTheme.darkGold),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // initialiser une seule fois et réutiliser ce Future dans le FutureBuilder
    _initFuture = initUserState();
  }

  Future<void> initUserState() async {
    dt = await DatabaseHelper.instance.getCurrentUserData(FirebaseAuth.instance.currentUser?.email ?? '');
    bool hasVault = await DatabaseHelper.instance.hasVault(FirebaseAuth.instance.currentUser?.email ?? '');
    setState(() {
      if (!hasVault) {
        userState = -1; // pas de vault, considéré comme déverrouillé
        return;
      }
      if (dt.deadline.isAfter(DateTime.now()) && dt.locked) {
        userState = 0; // locked
      } else if (dt.deadline.isBefore(DateTime.now()) && dt.locked) {
        userState = 1; // ready to unlock
      } else if (dt.deadline.isBefore(DateTime.now()) && !dt.locked) {
        userState = 2; // unlocked
      }
    });
  }

  Widget screen() {
    switch (userState){
      case -1: return NewVaultPage();
      case 0: return LockedVaultPage(data: dt);
      case 1: return PasswordMissingVaultPage(data: dt);
      case 2: return UnlockedVaultPage(data: dt);
      default: return const Center(child: Text('Unknown state'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporary Vault'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      // utiliser le Future stocké pour éviter la recréation à chaque build
      body: FutureBuilder<void>(future: _initFuture, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return screen();
        }
      }),
    );
  }
}