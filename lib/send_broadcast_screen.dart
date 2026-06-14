// lib/send_broadcast_screen.dart (VERSION YUZUYE - WITH OFFICIAL IDENTITY)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// PROJECT IMPORTS
import 'app_config.dart';

class SendBroadcastScreen extends StatefulWidget {
  const SendBroadcastScreen({super.key});

  @override
  State<SendBroadcastScreen> createState() => _SendBroadcastScreenState();
}

class _SendBroadcastScreenState extends State<SendBroadcastScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  
  // ID ya System Admin nk'uko Mobile App yawe iyitegereje
  final String _adminSystemId = 'jembe_talk_official_admin';

  // 1. FUNCTION YO KOHEREZA UBUTUMWA KURI BOSE
  Future<void> _sendBroadcastToAll() async {
    final String msgText = _messageController.text.trim();
    if (msgText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banza wandike ubutumwa.')));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text('Uremeza neza?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Ubu butumwa bugiye kuboneka muri Chats z\'abakoresha BOSE ba Jembe Talk.\n\nNtushobora kubufuta bumaze kugenda.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hagarika', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rungika', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final String broadcastId = const Uuid().v4();
      final timestamp = FieldValue.serverTimestamp();

      // A. VUGURURA IDENTITY YA JEMBE TALK (Kugira ngo ubutumwa buze buriho Logo)
      batch.set(firestore.collection('users').doc(_adminSystemId), {
        'uid': _adminSystemId,
        'displayName': 'Jembe Talk',
        'photoUrl': AppConfig.adminLogoUrl, // Iva muri AppConfig (R2 Logo)
        'email': 'support@jembetalk.com',
        'isVerified': true,
        'isAdmin': true,
        'lastUpdated': timestamp,
      }, SetOptions(merge: true));

      // B. TWANDIKA MURI 'LATEST' (Kugira ngo Mobile App ihite iyibona)
      batch.set(firestore.collection('global_broadcasts').doc('latest'), {
        'id': broadcastId, 
        'message': msgText,
        'timestamp': timestamp,
        'adminId': _adminSystemId,
        'type': 'text',
      });

      // C. ARCHIVE (Kubika muri History)
      final historyRef = firestore.collection('broadcast_history').doc(broadcastId);
      batch.set(historyRef, {
        'broadcastId': broadcastId,
        'message': msgText,
        'sentAt': timestamp,
      });

      await batch.commit();

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubutumwa bwarungitswe kuri bose!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. FUNCTION YO GUSIBA UBUTUMWA BURIHO (EXPIRE/DELETE)
  Future<void> _deleteActiveBroadcast() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text("Futa ubu butumwa?", style: TextStyle(color: Colors.white)),
        content: const Text("Niwabufuta hano, ntibuzosubira kuboneka kubantu.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Oya")),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("Ego, Futa")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('global_broadcasts').doc('latest').delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ubutumwa bwafuswe burundu.")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ikosa: $e"), backgroundColor: Colors.red));
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), 
      appBar: AppBar(
        title: const Text("UBUTUMWA KUBANTU BOSE"),
        backgroundColor: const Color(0xFF1E1E26),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: ACTIVE BROADCAST ---
            const Text("Ubutumwa buriho kuri bose ubu:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('global_broadcasts').doc('latest').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                    child: const Text("Nta butumwa buriho kuri bose ubu.", style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final String msg = data['message'] ?? "";
                final Timestamp? ts = data['timestamp'] as Timestamp?;

                return Card(
                  color: const Color(0xFF1E1E26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(ts), style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 22), onPressed: _deleteActiveBroadcast)
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(msg, style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 50),

            // --- SECTION 2: SEND NEW BROADCAST ---
            const Text("Kurungika ubutumwa bushasha:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 15),
            TextField(
              controller: _messageController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Andikira buri muntu wese koresha Jembe Talk...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1E1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendBroadcastToAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                icon: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.campaign_rounded, color: Colors.white),
                label: const Text("RUNGIKA KURI BOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            const Center(child: Text("Ubu butumwa bugaragara muri Chats z'abantu bose.", style: TextStyle(color: Colors.white24, fontSize: 11))),
          ],
        ),
      ),
    );
  }
}