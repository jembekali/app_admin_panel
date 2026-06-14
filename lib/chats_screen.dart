// lib/chats_screen.dart (VERSION 19.1 - REDIRECTED TO HYBRID MESSENGER)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// IMPORTS
import 'reply_to_feedback_screen.dart'; // 🔥 KOSORA HANO
import 'user_details_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  Future<DocumentSnapshot?> _getUserDoc(String uid) async {
    if (uid == 'jembe_talk_official_admin' || uid.isEmpty) return null;
    try {
      return await FirebaseFirestore.instance.collection('users').doc(uid).get();
    } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    const String adminId = 'jembe_talk_official_admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Monitor Conversations", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .orderBy('lastMessageTs', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nta kiganiro gihari."));

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatDoc = chatRooms[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final List<dynamic> users = chatData['users'] ?? [];
              final String clientUid = users.firstWhere((id) => id != adminId, orElse: () => "");

              return FutureBuilder<DocumentSnapshot?>(
                future: _getUserDoc(clientUid),
                builder: (context, userSnapshot) {
                  final Map<String, dynamic>? userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final String title = userData?['displayName'] ?? "Umukoresha ($clientUid)";
                  final String? photoUrl = userData?['photoUrl'];

                  return ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailsScreen(userDocument: userSnapshot.data!)));
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                        child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person) : null,
                      ),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(chatData['lastMessage'] ?? "...", maxLines: 1),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      // 🔥 KOSORA HANO: Koresha Messenger nshya
                      Navigator.push(context, MaterialPageRoute(builder: (c) => ReplyToFeedbackScreen(targetUserId: clientUid)));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}