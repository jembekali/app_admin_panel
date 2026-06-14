// lib/manage_dame_screen.dart (STABLE PRODUCTION VERSION)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// IMPORT CONFIG
import 'app_config.dart';

class ManageDameScreen extends StatefulWidget {
  const ManageDameScreen({super.key});

  @override
  State<ManageDameScreen> createState() => _ManageDameScreenState();
}

class _ManageDameScreenState extends State<ManageDameScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseDatabase _realtimeDb;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initializeDb();
  }

  void _initializeDb() {
    try {
      _realtimeDb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.rtdbUrl, // Isoma muri config
      );
      setState(() => _dbReady = true);
    } catch (e) {
      _realtimeDb = FirebaseDatabase.instance;
      setState(() => _dbReady = true);
    }
  }

  // ===========================================================================
  // DIALOG YO GUHINDURA ITANGAZO RYA DAME
  // ===========================================================================
  void _showTickerDialog() async {
    if (!_dbReady) return;

    final TextEditingController msgController = TextEditingController();
    bool isActive = true;
    bool isFetching = true;
    bool isSaving = false;

    // 1. Fata amakuru ahari ubu
    try {
      final snapshot = await _realtimeDb.ref('dame_ticker').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        msgController.text = data['message'] ?? '';
        isActive = data['isActive'] ?? true;
      }
      isFetching = false;
    } catch (e) {
      isFetching = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Itangazo rya Dame", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: isFetching 
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: msgController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Ubutumwa buca hejuru muri Dame",
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text("Erekana itangazo?", style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: isActive,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("REKA", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  await _realtimeDb.ref('dame_ticker').set({
                    'message': msgController.text.trim(),
                    'isActive': isActive,
                    'updatedAt': ServerValue.timestamp,
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("BIKA & TANGAZA"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Igenzura rya Dame Game", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
            const Text("Hano ucunga amatangazo n'abakinnyi mu buryo bwa Real-time.", style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 40),

            // 1. LIVE PLAYERS CARD (Firestore Stream)
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('games').where('status', isEqualTo: 'active').snapshots(),
              builder: (context, snapshot) {
                int activeGames = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.purple.shade900, Colors.purple.shade600]),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.sports_esports, color: Colors.white, size: 70),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("ABAKINNYI BARIKO BARAKINA", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text("${activeGames * 2}", style: const TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.bold)),
                          Text("$activeGames imikino iriko iraba ubu", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // 2. TICKER CONTROL CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: Color(0xFF2A2A35), child: Icon(Icons.campaign, color: Colors.purpleAccent)),
                    title: const Text("Itangazo rya Dame (Ticker)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Ubutumwa wandika hano buca hejuru y'ikibuga c'abakinnyi bose.", style: TextStyle(color: Colors.white24, fontSize: 11)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _showTickerDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("HINDURA ITANGAZO UBU", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}