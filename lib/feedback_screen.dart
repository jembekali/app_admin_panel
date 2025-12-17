// lib/feedback_screen.dart (VERSION IKOSOYE - TABS & DELETE)

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
  
  // Function yo gusiba ikintu kimwe
  Future<void> _deleteFeedback(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gufuta?'),
        content: const Text('Vyukuri urashaka gufuta iki kibazo burundu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ego Futa')
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vyafuswe.')));
      }
    }
  }

  // Function yo gufuta VYOSE ivyakemuwe
  Future<void> _deleteAllResolved() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gufuta Vyose?'),
        content: const Text(
          'Ugiye gufuta ibibazo VYOSE byakemuwe.\n\nNtushobora kubigarura. Uremeza?',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Oya')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Futa Vyose')
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Shaka ibyakemuwe byose
      final snapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .where('isResolved', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nta kintu cogufuta gihari.')));
        return;
      }

      // 2. Siba kimwe kimwe muri Batch (Firestore yemera 500 icyarimwe)
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${snapshot.docs.length} Vyafuswe burundu.'), backgroundColor: Colors.green),
        );
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Imfashanyo & Ibibazo"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Ibitarakemuka (Pending)", icon: Icon(Icons.pending_actions)),
              Tab(text: "Ivyakemuwe (Resolved)", icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: IBITARAKEMUKA
            _buildFeedbackList(isResolved: false),
            
            // TAB 2: IVYAKEMUWE (Irimo Delete All)
            _buildResolvedList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList({required bool isResolved}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .where('isResolved', isEqualTo: isResolved)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Ikosa: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isResolved ? Icons.check_circle : Icons.inbox, size: 60, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  isResolved ? "Nta bibazo vyakemuwe bihari." : "Nta bibazo bishasha bihari.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final message = data['message'] ?? '';
            final email = data['userEmail'] ?? data['email'] ?? 'Nta Email';
            final timestamp = data['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isResolved ? Colors.green[100] : Colors.orange[100],
                  child: Icon(
                    isResolved ? Icons.check : Icons.priority_high, 
                    color: isResolved ? Colors.green : Colors.orange
                  ),
                ),
                title: Text(
                  email, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_formatDate(timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReplyToFeedbackScreen(feedbackDoc: doc),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // LIST YIHARIYE KURI RESOLVED (Kugira ngo dushyiremo Delete buttons)
  Widget _buildResolvedList() {
    return Column(
      children: [
        // Header ifite Delete All Button
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Urutonde gw'ivyakemuwe", style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _deleteAllResolved,
                icon: const Icon(Icons.delete_sweep),
                label: const Text("Futa Vyose"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
        
        // List nyirizina
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .where('isResolved', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Ikosa: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("Nta kintu gihari."));
              }

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final message = data['message'] ?? '';
                  final email = data['userEmail'] ?? 'Nta Email';

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(email, maxLines: 1),
                      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Buto yo gufuta umwe umwe
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Futa iki gusa',
                            onPressed: () => _deleteFeedback(doc.id),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color.fromARGB(255, 141, 88, 88)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReplyToFeedbackScreen(feedbackDoc: doc),
                          ),
                        );
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
}