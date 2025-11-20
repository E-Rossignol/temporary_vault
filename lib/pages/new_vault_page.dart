import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:temporary_vault/models/data.dart';
import '../constants/database_helper.dart';
import '../constants/theme.dart';

class NewVaultPage extends StatefulWidget {
  const NewVaultPage({super.key});

  @override
  State<NewVaultPage> createState() => _NewVaultPageState();
}

class _NewVaultPageState extends State<NewVaultPage> {
  int _step = 0;

  // Step 1: message
  final TextEditingController _messageController = TextEditingController();

  // Step 2: deadline
  bool _usePreciseDate = true;
  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  final TextEditingController _relativeValueController = TextEditingController(text: '1');
  String _relativeUnit = 'Heures';
  final List<String> _units = ['Heures', 'Jours', 'Mois', 'Années'];

  // Step 3: password
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordNoted = false;
  bool _obscure = true;

  // State
  bool _isLoading = false;
  bool _created = false;
  String? _createdId;

  @override
  void dispose() {
    _messageController.dispose();
    _relativeValueController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _step = (_step + 1).clamp(0, 4));
  }

  void _prevStep() {
    setState(() => _step = (_step - 1).clamp(0, 4));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 50),
      builder: (ctx, child) => child ?? const SizedBox.shrink(),
    );
    if (d != null) setState(() => _pickedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay(hour: 12, minute: 0),
      builder: (ctx, child) => child ?? const SizedBox.shrink(),
    );
    if (t != null) setState(() => _pickedTime = t);
  }

  DateTime? _computeDeadline() {
    if (_usePreciseDate) {
      if (_pickedDate == null || _pickedTime == null) return null;
      return DateTime(
        _pickedDate!.year,
        _pickedDate!.month,
        _pickedDate!.day,
        _pickedTime!.hour,
        _pickedTime!.minute,
      );
    } else {
      final val = int.tryParse(_relativeValueController.text);
      if (val == null || val <= 0) return null;
      final now = DateTime.now();
      switch (_relativeUnit) {
        case 'Heures':
          return now.add(Duration(hours: val));
        case 'Jours':
          return now.add(Duration(days: val));
        case 'Mois':
          return now.add(Duration(days: val * 30)); // approximation
        case 'Années':
          return now.add(Duration(days: val * 365)); // approximation
        default:
          return now.add(Duration(hours: val));
      }
    }
  }

  Future<void> _createVault() async {
    final message = _messageController.text.trim();
    final password = _passwordController.text;
    final deadline = _computeDeadline();
    if (message.isEmpty || password.isEmpty || deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir toutes les informations requises'), backgroundColor: Color(0xFFB8860B),
          duration: Duration(seconds: 1),),
      );
      return;
    }
    setState(() => _isLoading = true);
    final email = FirebaseAuth.instance.currentUser?.email;
    Data dt = Data(mail: email ?? '', message: message, deadline: deadline, locked: true);
    final id = await DatabaseHelper.instance.createVault(dt, _passwordController.text);
    setState(() {
      _isLoading = false;
      _created = id != null;
      _createdId = id;
    });
    Navigator.pushReplacementNamed(context, '/home');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Center(
        child: Text('Coffre fort créé'),
      ), backgroundColor: Color(0xFFB8860B),
        duration: Duration(seconds: 1),),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0: // message
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1 • Message à cacher', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Votre message secret...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_messageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Le message ne peut pas être vide'), backgroundColor: Color(0xFFB8860B),
                                duration: Duration(seconds: 1),),
                            );
                            return;
                      }
                            FocusScope.of(context).unfocus();
                            _nextStep();
                          },
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ],
        );
      case 1: // deadline
        final dateStr = _pickedDate == null ? 'Aucune date choisie' : DateFormat.yMMMd().format(_pickedDate!);
        final timeStr = _pickedTime == null ? '—:—' : _pickedTime!.format(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('2 • Deadline', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Date & heure précise'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _usePreciseDate,
                      onChanged: (v) => setState(() => _usePreciseDate = true),
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Délai relatif'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _usePreciseDate,
                      onChanged: (v) => setState(() => _usePreciseDate = false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_usePreciseDate) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dateStr),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(timeStr),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _relativeValueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Nombre'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _relativeUnit,
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _relativeUnit = v ?? _relativeUnit),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_usePreciseDate && (_pickedDate == null || _pickedTime == null)) ||
                            (!_usePreciseDate && (int.tryParse(_relativeValueController.text) == null))
                        ? null
                        : _nextStep,
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        );
      case 2: // password
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('3 • Mot de passe de déverrouillage', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Mot de passe (gardez-le précieusement)',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(value: _passwordNoted, onChanged: (v) => setState(() => _passwordNoted = v ?? false)),
                const Expanded(
                  child: Text(
                    'J’ai noté le mot de passe. Il ne sera plus accessible après validation.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_passwordController.text.isEmpty || !_passwordNoted) ? null : _nextStep,
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        );
      case 3: // confirmation & create
        final computed = _computeDeadline();
        final dlStr = computed == null ? '—' : DateFormat.yMd().add_jm().format(computed);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('4 • Résumé', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Message'),
              subtitle: Text(_messageController.text),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Deadline'),
              subtitle: Text(dlStr),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Mot de passe (masqué)'),
              subtitle: Text('*' * _passwordController.text.length),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      showDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        builder: (ctx) => AlertDialog(
                          title: Text("Confirmation"),
                          content: Text("Si vous oubliez votre mot de passe et tentez de déverrouiller le coffre, le message affiché sera erroné et le message originel définitevement perdu. Êtes-vous sûr de vouloir continuer ?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text("Retour")),
                            ElevatedButton(onPressed: (){
                              Navigator.of(ctx).pop(true);
                              _createVault();
                      }, child: Text("Confirmer")),
                          ],
                        ),
                      );
                    },
    child: const Text('Créer le coffre'),
                  ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau coffre-fort'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              color: const Color(0xFF0F0F12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _stepContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
