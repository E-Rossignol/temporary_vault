import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temporary_vault/constants/database_helper.dart';
import 'package:temporary_vault/constants/helper.dart';
import 'package:temporary_vault/pages/home_page.dart';
import 'package:temporary_vault/pages/unlocked_vault_page.dart';
import '../models/data.dart';
import '../constants/theme.dart';

class PasswordMissingVaultPage extends StatefulWidget {
  final Data? data;
  const PasswordMissingVaultPage({super.key, this.data});

  @override
  State<PasswordMissingVaultPage> createState() => _PasswordMissingVaultPageState();
}

class _PasswordMissingVaultPageState extends State<PasswordMissingVaultPage> {
  final TextEditingController _pwdController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _pwdController.dispose();
    super.dispose();
  }

  // méthode decrypt demandée (pour l'instant ne fait rien)
  Future<void> decrypt(String password) async {
    final dt = await DatabaseHelper.instance.getCurrentUserData(FirebaseAuth.instance.currentUser?.email ?? '');
    // no-op : implémentation de décryptage à venir
    final clearMessage = Helper.decryptMessage(dt.message, password);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('clear_message', clearMessage);
  }

  Future<void> _validatePassword() async {
    final pwd = _pwdController.text;
    if (pwd.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      decrypt(pwd); // actuellement ne fait rien
      if (!mounted) return;
      await DatabaseHelper.instance.unlockUser(FirebaseAuth.instance.currentUser?.email ?? '');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          color: const Color(0xFF0F0F12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_open, size: 48, color: AppTheme.darkGold),
                const SizedBox(height: 12),
                Text('Entrez le mot de passe', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Saisissez le mot de passe pour déverrouiller ce coffre‑fort.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pwdController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _pwdController.text.isEmpty ? null : _validatePassword,
                              child: const Text('Valider'),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}