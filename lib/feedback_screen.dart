import 'package:app_admin_panel/reply_to_feedback_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  
  // 1. Widget ifasha gusoma izina rya nyaryo (displayName) muri Users collection
  Widget _buildUserName(String? uid, String fallbackEmail) {
    if (uid == null || uid == 'Anonymous') {
      return Text(fallbackEmail, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String realName = userData['displayName'] ?? fallbackEmail;
          return Text(
            realName, 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          );
        }
        // Igihe rigisoma cyangwa ritanabonetse, erekana Email
        return Text(fallbackEmail, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14));
      },
    );
  }

  String _getFeedbackTypeLabel(String? type) {
    if (type == null) return "IKINDI KIBAZO";
    switch (type) {
      case 'contact_us_banned_user': return "KUGARUZA KONTE (Banned)";
      case 'bug_report': return "IKIBAZO MURI APP (Bug)";
      case 'payment_issue': return "IKIBAZO CO KWISHURA";
      case 'suggestion': return "ICIFUZO/INYONGEZO";
      default: return type.toUpperCase().replaceAll('_', ' ');
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('dd/MM HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F13),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E26),
          title: const Text("Imfashanyo & Ibibazo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "PINDING", icon: Icon(Icons.pending_actions)),
              Tab(text: "RESOLVED", icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeedbackList(isResolved: false),
            _buildFeedbackList(isResolved: true, showDeleteAll: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList({required bool isResolved, bool showDeleteAll = false}) {
    return Column(
      children: [
        if (showDeleteAll)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ivyakemuwe Yose", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                TextButton.icon(
                  onPressed: _deleteAllResolved,
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text("FUTA VYOSE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .where('isResolved', isEqualTo: isResolved)
                .orderBy('createdAt', descending: isResolved) // Pending: Oldest on Top, Resolved: Newest on Top
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Ikosa: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("Nta kintu gihari.", style: TextStyle(color: Colors.grey)));

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  final String uid = data['uid'] ?? 'Anonymous';
                  final String email = data['userEmail'] ?? data['email'] ?? 'No Email';
                  final String feedbackType = _getFeedbackTypeLabel(data['type']);
                  final timestamp = data['createdAt'] as Timestamp?;

                  return Card(
                    color: const Color(0xFF1E1E26),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isResolved ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                        child: Icon(
                          isResolved ? Icons.check : Icons.person_outline, 
                          color: isResolved ? Colors.green : Colors.amber,
                          size: 20,
                        ),
                      ),
                      // =======================================================
                      // HANO NIHO HAHINDUWE: Ryerekana Izina ry'ukuri (DisplayName)
                      // =======================================================
                      title: _buildUserName(uid, email), 
                      
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(feedbackType, style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(_formatDate(timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                      trailing: isResolved 
                        ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white24), onPressed: () => _deleteFeedback(doc.id))
                        : const Icon(Icons.chevron_right, color: Colors.white24),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ReplyToFeedbackScreen(feedbackDoc: doc)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Functions zo gusiba (Delete) zasigaye ari zimwe ---
  Future<void> _deleteFeedback(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text('Gufuta?', style: TextStyle(color: Colors.white)),
        content: const Text('Vyukuri urashaka gufuta iki kibazo burundu?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Ego Futa')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
    }
  }

  Future<void> _deleteAllResolved() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text('Gufuta Vyose?', style: TextStyle(color: Colors.white)),
        content: const Text('Ugiye gufuta ibibazo VYOSE Vyakemuwe. Uremeza?', style: TextStyle(color: Colors.redAccent)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Futa Vyose')),
        ],
      ),
    );
    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance.collection('feedback').where('isResolved', isEqualTo: true).get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();
    }
  }
}