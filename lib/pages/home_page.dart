import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/database_helper.dart';
import '../constants/theme.dart';

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

  void _getUserData() async {
    final db = DatabaseHelper.instance;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    _userData = await db.getCurrentUserData(email);
    if (mounted) setState(() {}); // rafraîchir l'UI après chargement
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
          ],
        ),
      ),
    );
  }
}