import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temporary_vault/models/data.dart';

class UnlockedVaultPage extends StatefulWidget {
  UnlockedVaultPage({super.key, this.data, this.message});
  Data? data;
  String? message;
  @override
  State<UnlockedVaultPage> createState() => _UnlockedVaultPageState();
}

class _UnlockedVaultPageState extends State<UnlockedVaultPage> {

  String message = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initMessage();
  }

  Future<void> initMessage() async {
    if (widget.message != null && widget.message!.isNotEmpty) {
      setState(() {
        message = widget.message!;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        message = prefs.getString('clear_message') ?? '';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            SizedBox(height: 100),
            Icon(Icons.lock_open, size: 80, color: Colors.greenAccent,),
            Text("Unlocked Vault Page", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            Text("Clear message: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
            Text(message, style: TextStyle(fontSize: 16),),
          ],
        ),
      ),
    );
  }
}
