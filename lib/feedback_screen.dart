// Code ya: ADMIN PANEL
// Dosiye: lib/feedback_screen.dart

import 'package:app_admin_panel/reply_to_feedback_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ubutumwa bw'Imfashanyo n'Ivyiyumviro"),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "BITARAKEMUKA"),
            Tab(text: "VYAKEMUWE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FeedbackList(isResolved: false),
          FeedbackList(isResolved: true),
        ],
      ),
    );
  }
}

class FeedbackList extends StatefulWidget {
  final bool isResolved;
  const FeedbackList({super.key, required this.isResolved});

  @override
  State<FeedbackList> createState() => _FeedbackListState();
}

class _FeedbackListState extends State<FeedbackList> with AutomaticKeepAliveClientMixin<FeedbackList> {
  
  @override
  bool get wantKeepAlive => true; 

  Future<void> _toggleResolvedStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('feedback').doc(docId).update({
      'isResolved': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('feedback').where('isResolved', isEqualTo: widget.isResolved).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('IKOSA RYABAYE: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('Nta butumwa buhari muri iki gice.'));

        return ListView.builder(
          padding: const EdgeInsets.all(8.0), // Twagabanyije padding kugira amakarita yegere urubibe
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final userEmail = data['userEmail'] ?? 'Umukoresha ntazwi';
            final message = data['message'] ?? 'Ubutumwa ntibuboneka';
            final category = data['category'] ?? 'Category ntizwi';
            final timestamp = data['createdAt'] as Timestamp?;
            final date = timestamp != null ? DateFormat('d MMM y, HH:mm').format(timestamp.toDate()) : 'Isaha ntiboneka';

            // =================================================================
            // >>>>>>>> HANO NI HO TWONGEYE GUKOSORA UBURYO BIGARAGARA <<<<<<<<
            // =================================================================
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Umurongo wa mbere: Category, Izina, n'Isaha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        Text(date, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Ubutumwa bwa: $userEmail', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Divider(height: 20),
                    
                    // Umurongo wa kabiri: Akadirisha k'ubutumwa n'utubuto
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // >>> AKADIRISHA GASHASHA K'UBUTUMWA <<<
                        Expanded(
                          child: ConstrainedBox(
                            // Tuvuga ko akadirisha katarenga uburebure bwa 200
                            constraints: const BoxConstraints(maxHeight: 200),
                            // Iyo ubutumwa ari burebure, turashobora kugenda hasi no hejuru
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(message),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // >>> UTUBUTO TWARASUBIJWEHO UTUMENYETSO <<<
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.reply, size: 18),
                              label: const Text('Ishura'),
                              style: TextButton.styleFrom(foregroundColor: Colors.blue),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReplyToFeedbackScreen(feedbackDoc: doc))),
                            ),
                            const SizedBox(height: 8),
                             TextButton.icon(
                              icon: Icon(
                                widget.isResolved ? Icons.undo : Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(widget.isResolved ? 'Subiza' : 'Cakemuwe'),
                              style: TextButton.styleFrom(
                                foregroundColor: widget.isResolved ? Colors.orange : Colors.green,
                              ),
                              onPressed: () => _toggleResolvedStatus(doc.id, widget.isResolved),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}