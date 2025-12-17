import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utegerezwa kwuzuza umutwe n\'ubutumwa.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _messageController.clear();
      
      // TWAHINDURIYE HANO
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itangazo ryarungitswe neza!')),
        );
      }

    } catch (e) {
      // NA HANO
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habaye ikibazo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Andika Itangazo Rishasha',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Umutwe w\'Itangazo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Ubutumwa',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('RUNGIKA ITANGAZO'),
                    onPressed: _isLoading ? null : _sendAnnouncement,
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
        ),
        
        const Divider(height: 30, thickness: 1),
        const Text(
          'Amatangazo Ya Kera',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Nta tangazo rirarungikwa.'));
              }

              final announcements = snapshot.data!.docs;
              return ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final doc = announcements[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Umutwe ntuboneka';
                  final message = data['message'] ?? 'Ubutumwa ntibuboneka';
                  final timestamp = data['createdAt'] as Timestamp?;
                  final date = timestamp != null
                      ? DateFormat('d MMMM y, HH:mm').format(timestamp.toDate())
                      : 'Isaha ntiboneka';

                  return ListTile(
                    leading: const Icon(Icons.campaign),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$message\n- Yarungitswe ku wa: $date'),
                    isThreeLine: true,
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