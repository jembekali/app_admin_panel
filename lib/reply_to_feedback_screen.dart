// lib/reply_to_feedback_screen.dart (VERSION 36.0 - LARGE PROFILE & EMAIL COPY)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; // <--- INGENZI KURI COPY TO CLIPBOARD
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// PROJECT IMPORTS
import 'app_config.dart';
import 'user_details_screen.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class ReplyToFeedbackScreen extends StatefulWidget {
  final DocumentSnapshot? feedbackDoc; 
  final String? targetUserId;         

  const ReplyToFeedbackScreen({super.key, this.feedbackDoc, this.targetUserId});

  @override
  State<ReplyToFeedbackScreen> createState() => _ReplyToFeedbackScreenState();
}

class _ReplyToFeedbackScreenState extends State<ReplyToFeedbackScreen> {
  final _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); 
  bool _isSending = false;
  final String _adminSystemId = 'jembe_talk_official_admin';
  
  DocumentSnapshot? _userFullDoc; 
  bool _isLoadingUserData = true;
  String? _finalUserId;
  String? _chatRoomId;

  String _currentName = "...";
  String _currentEmail = ""; 
  String? _currentPhoto;

  @override
  void initState() {
    super.initState();
    _resolveTargetUser();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 1. COPY EMAIL TO CLIPBOARD
  void _copyEmail() {
    if (_currentEmail.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _currentEmail));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email yakopishijwe neza!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // 2. OPEN EMAIL APP (GMAIL)
  Future<void> _launchEmail() async {
    if (_currentEmail.isEmpty) return;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _currentEmail,
      query: 'subject=Support: Jembe Talk Feedback&body=Muraho ${_currentName},', 
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }
  }

  Future<void> _resolveTargetUser() async {
    try {
      if (widget.feedbackDoc != null) {
        final data = widget.feedbackDoc!.data() as Map<String, dynamic>;
        _finalUserId = data['uid'] ?? data['userId'] ?? data['senderId'];
        _currentName = data['senderName'] ?? data['name'] ?? "...";
      } else {
        _finalUserId = widget.targetUserId;
      }

      if (_finalUserId != null) {
        List<String> ids = [_adminSystemId, _finalUserId!];
        ids.sort();
        _chatRoomId = ids.join("_");

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_finalUserId!).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() { 
              _userFullDoc = userDoc; 
              _currentName = userData['displayName'] ?? "Umukoresha";
              _currentEmail = userData['email'] ?? ""; 
              _currentPhoto = userData['photoUrl'];
              _isLoadingUserData = false; 
            });
          }
          return;
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
    if (mounted) setState(() => _isLoadingUserData = false);
  }

  Future<void> _deleteAllMessages() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text("Futa vyose?", style: TextStyle(color: Colors.redAccent)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hagarika", style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Futa", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
    if (confirm == true && _chatRoomId != null) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final messagesSnap = await firestore.collection('chat_rooms').doc(_chatRoomId).collection('messages').get();
      for (var doc in messagesSnap.docs) { batch.delete(doc.reference); }
      batch.delete(firestore.collection('chat_rooms').doc(_chatRoomId!));
      if (widget.feedbackDoc != null) batch.delete(widget.feedbackDoc!.reference);
      await batch.commit();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _sendReply() async {
    final String replyText = _replyController.text.trim();
    if (replyText.isEmpty || _finalUserId == null || _chatRoomId == null) return;
    setState(() => _isSending = true);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final messageId = const Uuid().v4();
      batch.set(firestore.collection('chat_rooms').doc(_chatRoomId!).collection('messages').doc(messageId), {
        'id': messageId,
        'chatRoomID': _chatRoomId,
        'senderID': _adminSystemId,
        'receiverID': _finalUserId,
        'message': replyText,
        'timestamp': timestamp,
      });
      batch.set(firestore.collection('chat_rooms').doc(_chatRoomId!), {
        'lastMessage': replyText,
        'lastMessageTs': timestamp,
        'lastMessageSenderId': _adminSystemId,
        'users': [_adminSystemId, _finalUserId!],
      }, SetOptions(merge: true));
      if (widget.feedbackDoc != null) {
        batch.update(widget.feedbackDoc!.reference, {'hasAdminReply': true, 'isResolved': true});
      }
      await batch.commit();
      _replyController.clear();
      _scrollToBottom();
    } catch (e) { debugPrint("Error: $e"); }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E26),
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: _deleteAllMessages),
        ],
      ),
      body: Column(
        children: [
          // 1. NEW LARGE PROFILE HEADER
          _buildLargeProfileHeader(),
          
          // 2. LARGE FEEDBACK CARD
          if (widget.feedbackDoc != null && widget.feedbackDoc!.exists) _buildFeedbackHeader(),
          
          // 3. MESSAGES AREA
          Expanded(
            child: ScrollConfiguration(
              behavior: MyCustomScrollBehavior(),
              child: RepaintBoundary(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(_chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final messages = snapshot.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final msg = doc.data() as Map<String, dynamic>;
                        bool isMe = msg['senderID'] == _adminSystemId;
                        return _buildModernMessage(msg['message'] ?? "", isMe, msg['timestamp']);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          _buildModernInput(),
        ],
      ),
    );
  }

  // WIDGET Y'IFOTO NINI NA EMAIL NINI
  Widget _buildLargeProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      color: const Color(0xFF1E1E26),
      child: Row(
        children: [
          // Ifoto Nini (Clickable to User Details)
          GestureDetector(
            onTap: () {
              if (_userFullDoc != null) {
                Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailsScreen(userDocument: _userFullDoc!)));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2)),
              child: CircleAvatar(
                radius: 35, // Ingana nini
                backgroundColor: Colors.white10,
                backgroundImage: (_currentPhoto != null && _currentPhoto!.isNotEmpty) ? CachedNetworkImageProvider(_currentPhoto!) : null,
                child: (_currentPhoto == null || _currentPhoto!.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 35) : null,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Izina na Email (Large)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // Email Clickable
                    GestureDetector(
                      onTap: _launchEmail,
                      child: Text(
                        _currentEmail.isEmpty ? "No Email Provided" : _currentEmail,
                        style: TextStyle(fontSize: 14, color: Colors.amber.shade200, decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Copy Icon Button
                    if (_currentEmail.isNotEmpty)
                      GestureDetector(
                        onTap: _copyEmail,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                          child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackHeader() {
    final fData = widget.feedbackDoc!.data() as Map<String, dynamic>;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C38),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("IKIBAZO C'UMU CLIENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(fData['message'] ?? fData['feedback'] ?? '...', style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildModernMessage(String message, bool isMe, dynamic ts) {
    DateTime dt = ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : (ts is Timestamp ? ts.toDate() : DateTime.now());
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? Colors.amber : const Color(0xFF2C2C38),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Text(message, style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 15)),
            ),
            const SizedBox(height: 4),
            Text(DateFormat('HH:mm').format(dt), style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 25),
      decoration: const BoxDecoration(color: Color(0xFF1E1E26)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: const Color(0xFF0F0F13), borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _replyController,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _sendReply(),
                decoration: const InputDecoration(hintText: "Andika hano...", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _sendReply,
            icon: _isSending 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
              : const Icon(Icons.send_rounded, color: Colors.amber, size: 28),
          ),
        ],
      ),
    );
  }
}


