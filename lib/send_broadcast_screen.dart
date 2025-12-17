// lib/send_broadcast_screen.dart (VERSION IKOSOYE - HIGH CONTRAST)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class SendBroadcastScreen extends StatefulWidget {
  const SendBroadcastScreen({super.key});

  @override
  State<SendBroadcastScreen> createState() => _SendBroadcastScreenState();
}

class _SendBroadcastScreenState extends State<SendBroadcastScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendBroadcastToAll() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banza wandike ubutumwa.')),
      );
      return;
    }

    // Kubaza niba adashaka kwibeshya
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Force white background
        title: const Text('Uremeza neza?', style: TextStyle(color: Colors.black)),
        content: const Text(
          'Ubu butumwa bugiye kuboneka muri Chats z\'abakoresha BOSE ba Jembe Talk.\n\nNtushobora kubufuta bumaze kugenda.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hagarika', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rungika', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String broadcastId = const Uuid().v4();
      
      // Twandika muri document yitwa 'latest' kugira ngo Home Screen ihite iyibona
      await FirebaseFirestore.instance.collection('global_broadcasts').doc('latest').set({
        'id': broadcastId, 
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'adminId': 'jembe_talk_official_admin',
        'type': 'text',
      });

      // Archive
      await FirebaseFirestore.instance.collection('broadcast_history').add({
        'broadcastId': broadcastId,
        'message': _messageController.text.trim(),
        'sentAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubutumwa bwawe bwarungitswe kuri bose!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duhisemo ibara ry'inyuma (Background) ryorohereye ijisho
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: const Text("Kwandikira Bose (Broadcast)"),
        backgroundColor: Colors.blueGrey[900], // Ibara rya Admin
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikarita y'umuburo (Warning Card)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.orange[50], // Ibara ryerurutse
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[900], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Menya neza: Ubu butumwa buca buja muri 'Chats' z'abantu bose nk'aho Jembe Talk ibandikiye.",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[900], // Inyuguti zijimye kugira ngo zisomeke
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Titre y'aho kwandikira
            const Text(
              "Ubutumwa:",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black87 // Umukara wijimye
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Aho kwandikira (TextField)
            // Hano twakoresheje amabara yihariye kugira ngo bitijima
            TextField(
              controller: _messageController,
              maxLines: 6,
              maxLength: 500,
              style: const TextStyle(color: Colors.black, fontSize: 16), // Inyuguti z'umukara
              decoration: InputDecoration(
                hintText: "Andika hano (Akarorero: Twashizeho version nshasha...)",
                hintStyle: TextStyle(color: Colors.grey[500]), // Hint ifite ibara risomeka
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.white, // Inyuma h'aho wandikira ni umweru
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Buto yo kohereza
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendBroadcastToAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800], // Ibara ry'ubururu
                  foregroundColor: Colors.white,     // Inyuguti z'umweru
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: const Text("Rungika Kuri Bose"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}