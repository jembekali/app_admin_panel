// lib/reply_to_feedback_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReplyToFeedbackScreen extends StatefulWidget {
  final DocumentSnapshot feedbackDoc;

  const ReplyToFeedbackScreen({super.key, required this.feedbackDoc});

  @override
  State<ReplyToFeedbackScreen> createState() => _ReplyToFeedbackScreenState();
}

class _ReplyToFeedbackScreenState extends State<ReplyToFeedbackScreen> {
  final _replyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final replyMessage = _replyController.text.trim();
    if (replyMessage.isEmpty) {
      return; // Nta c'urandika
    }

    setState(() { _isLoading = true; });

    try {
      // Dushira inyishu mu gace gashasha (subcollection) k'ubutumwa bw'imfashanyo
      await widget.feedbackDoc.reference.collection('admin_replies').add({
        'message': replyMessage,
        'repliedAt': FieldValue.serverTimestamp(),
        'repliedBy': 'Admin', // Ushobora no gushiramwo email y'umuyobozi
      });

      // Tuvuga ko ubutumwa bwakiriwe inyishu
      await widget.feedbackDoc.reference.update({'hasAdminReply': true});
      
      if(mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inyishu yarungitswe neza!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kwirungika inyishu vyanse: $e')),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.feedbackDoc.data() as Map<String, dynamic>;
    final userEmail = data['userEmail'] ?? 'Ntazwi';
    final originalMessage = data['message'] ?? 'Nta butumwa';
    final timestamp = data['createdAt'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('d MMMM y, HH:mm').format(timestamp.toDate())
        : 'Isaha ntiboneka';

    return Scaffold(
      appBar: AppBar(
        title: Text('Kwishura $userEmail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ubutumwa Bw'umukoresha:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(originalMessage),
                  const SizedBox(height: 8),
                  Text(
                    'Yarungitswe ku wa: $date',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Andika Inyishu Yawe Hano:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Inyishu yawe...',
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('RUNGIKA INYISHU'),
                onPressed: _isLoading ? null : _sendReply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}