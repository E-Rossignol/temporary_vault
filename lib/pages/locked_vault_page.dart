import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temporary_vault/pages/password_missing_vault_page.dart';
import '../models/data.dart';
import '../constants/database_helper.dart';
import '../constants/theme.dart';

class LockedVaultPage extends StatefulWidget {
  final Data? data; // facultatif : si null, la page chargera les données courantes
  const LockedVaultPage({super.key, this.data});

  @override
  State<LockedVaultPage> createState() => _LockedVaultPageState();
}

class _LockedVaultPageState extends State<LockedVaultPage> with SingleTickerProviderStateMixin {
  Data? _data;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  // animation de "shake" pour l'icône
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    // initialisation de l'animation
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 4),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.08), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 4),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    // timer périodique qui déclenche l'animation toutes les 10 secondes
    _shakeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _shakeController.forward(from: 0);
    });

    if (_data == null) {
      _loadCurrentUserData();
    } else {
      _startTimer();
    }
  }

  Future<void> _loadCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('clear_message'); // nettoyer le message en clair stocké
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final d = await DatabaseHelper.instance.getCurrentUserData(email);
    if (!mounted) return;
    setState(() {
      _data = d;
    });
    _startTimer();
  }

  void _startTimer() {
    _updateRemaining();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final deadline = _data?.deadline ?? DateTime.now();
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff <= Duration.zero) {
      // échéance atteinte
      _timer?.cancel();
      if (mounted) setState(() => _remaining = Duration.zero);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PasswordMissingVaultPage(data: _data),
        ),
      );
    } else {
      if (mounted) setState(() => _remaining = diff);
    }
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (days > 0) {
      return '${days}j ${_two(hours)}h ${_two(minutes)}m ${_two(seconds)}s';
    } else if (hours > 0) {
      return '${hours}h ${_two(minutes)}m ${_two(seconds)}s';
    } else if (minutes > 0) {
      return '${minutes}m ${_two(seconds)}s';
    } else {
      return '${seconds}s';
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _timer?.cancel();
    _shakeTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // si pas encore de données, afficher chargement
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final remainingStr = _remaining == Duration.zero ? 'Échéance atteinte' : _formatDuration(_remaining);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          color: const Color(0xFF0F0F12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // icône animée : rotation "shake" déclenchée toutes les 10s
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _shakeAnim.value,
                      child: child,
                    );
                  },
                  child: Icon(Icons.lock, size: 100, color: AppTheme.darkGold),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    remainingStr,
                    key: ValueKey(remainingStr),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.darkGold,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                if (_remaining == Duration.zero)
                  ElevatedButton.icon(
                    onPressed: () {
                      // action possible : rafraîchir / vérifier état
                      _startTimer();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rafraîchir'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
