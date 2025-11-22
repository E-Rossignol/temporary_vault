import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/database_helper.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  void _autoLogin() {
    _emailCtrl.text = 'admiiiin@admin.ch';
    _passCtrl.text = 'mypassword123';
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // sauvegarder dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final uid = cred.user?.uid ?? '';
      final email = cred.user?.email ?? _emailCtrl.text.trim();
      await prefs.setString('uid', uid);
      await prefs.setString('email', email);
      if (!mounted) return;
      DatabaseHelper db = DatabaseHelper.instance;
      bool hasVault = await db.hasVault(email);
      if (!hasVault) {
        Navigator.pushReplacementNamed(context, '/new_vault');
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(
          child: Text('Connecté'),
        ),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFFB8860B)),
      );
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Erreur lors de la connexion';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Color(0xFFB8860B),
        duration: Duration(seconds: 1),));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGold = Color(0xFFB8860B);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.shield, color: darkGold, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Security',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: darkGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E10),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 18, offset: const Offset(0, 8)),
                      BoxShadow(color: darkGold.withOpacity(0.06), blurRadius: 0, spreadRadius: 1),
                    ],
                    border: Border.all(color: darkGold.withOpacity(0.08)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Icon(Icons.lock_outline, size: 56, color: darkGold),
                        const SizedBox(height: 12),
                        Text('Connexion', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 caractères' : null,
                        ),
                        const SizedBox(height: 20),
                        _loading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _signIn,
                                  child: const Text('Se connecter'),
                                ),
                              ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _autoLogin,
                            child: const Text('Auto Login'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: Text("Pas de compte ? S'inscrire", style: TextStyle(color: Colors.white.withOpacity(0.72))),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Security-first • Tous les accès sont chiffrés',
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
