// lib/reply_to_feedback_screen.dart (VERSION IKOSOYE - UI NZIZA)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ReplyToFeedbackScreen extends StatefulWidget {
  final DocumentSnapshot feedbackDoc;
  const ReplyToFeedbackScreen({super.key, required this.feedbackDoc});

  @override
  State<ReplyToFeedbackScreen> createState() => _ReplyToFeedbackScreenState();
}

class _ReplyToFeedbackScreenState extends State<ReplyToFeedbackScreen> {
  final _replyController = TextEditingController();
  bool _isLoading = false;

  final String _adminSystemId = 'jembe_talk_official_admin';

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banza wandike inyishu.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final feedbackData = widget.feedbackDoc.data() as Map<String, dynamic>;
    
    // Gushaka ID y'umukoresha
    final String? targetUserId = feedbackData['uid'] ?? feedbackData['userId'] ?? feedbackData['senderId'];

    if (targetUserId == null) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nta ID y\'umukoresha ibonetse. Ntitwoshobora kumwandikira.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 1. GUHINDURA FEEDBACK (Mark as resolved)
      batch.update(widget.feedbackDoc.reference, {
        'hasAdminReply': true,
        'hasUnreadReply': true,
        'adminReply': _replyController.text,
        'replyTimestamp': FieldValue.serverTimestamp(),
        'isResolved': true,
      });

      // 2. KUREMA MESSAGE
      List<String> ids = [_adminSystemId, targetUserId];
      ids.sort(); 
      String chatRoomId = ids.join("_");

      final messageId = const Uuid().v4();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final messageRef = firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      final messageData = {
        'id': messageId,
        'chatRoomID': chatRoomId,
        'senderID': _adminSystemId,
        'receiverID': targetUserId,
        'message': _replyController.text,
        'messageType': 'text',
        'timestamp': timestamp,
        'status': 'sent',
      };

      batch.set(messageRef, messageData);

      final chatRoomRef = firestore.collection('chat_rooms').doc(chatRoomId);
      final chatRoomData = {
        'lastMessage': _replyController.text,
        'lastMessageTs': timestamp,
        'lastSenderID': _adminSystemId,
        'users': ids,
      };

      batch.set(chatRoomRef, chatRoomData, SetOptions(merge: true));

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inyishu yarungitswe nka Message!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ikosa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = widget.feedbackDoc.data() as Map<String, dynamic>;
    final originalMessage = feedbackData['message'] ?? 'Ikibazo ntikiboneka';
    final userEmail = feedbackData['userEmail'] ?? feedbackData['email'] ?? 'Nta Email';

    // UI YASUKUWE: Umweru n'Umukara
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kwishuza & Chat'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikarita y'Ikibazo
            Card(
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueGrey[100],
                          child: Icon(Icons.person, color: Colors.blueGrey[800]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ubutumwa bwa:", 
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])
                              ),
                              Text(
                                userEmail, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      "Ikibazo:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      originalMessage, 
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4)
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Andika inyishu:', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _replyController,
              maxLines: 6,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
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
                hintText: 'Andika hano...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: const Text('Rungika Inyishu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: _isLoading ? null : _sendReply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[800]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Iyi nyishu izoca ija muri Chat y\'umukoresha nk\'aho ari Jembe Talk imwandikiye.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
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