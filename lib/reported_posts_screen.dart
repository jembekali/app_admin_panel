// lib/reported_posts_screen.dart (VERSION YA NYUMA KANDI YUZUYE NEZA)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportedPostsScreen extends StatefulWidget {
  const ReportedPostsScreen({super.key});

  @override
  State<ReportedPostsScreen> createState() => _ReportedPostsScreenState();
}

class _ReportedPostsScreenState extends State<ReportedPostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _getUserData(String userId) async { try { final userDoc = await _firestore.collection('users').doc(userId).get(); return userDoc.data(); } catch (e) { print("Ikosa ryo kurondera umukoresha: $e"); return null; } }
  Future<Map<String, dynamic>?> _getPostAndAuthorData(String postId) async { try { final postDoc = await _firestore.collection('posts').doc(postId).get(); if (!postDoc.exists) return null; final postData = postDoc.data()!; final authorId = postData['userId'] as String?; Map<String, dynamic>? authorData; if (authorId != null) { authorData = await _getUserData(authorId); } return {'post': postData, 'author': authorData}; } catch (e) { print("Ikosa ryo kurondera post n'uwayikoze: $e"); return null; } }
  Future<List<Map<String, dynamic>>> _getReporters(String postId) async { try { final reportsSnapshot = await _firestore.collection('post_reports').where('postId', isEqualTo: postId).get(); List<Future<Map<String, dynamic>>> reporterFutures = []; for (var doc in reportsSnapshot.docs) { final reporterId = doc.data()['reporterId']; if (reporterId != null && reporterId is String) { reporterFutures.add(_getUserData(reporterId).then((userData) => { 'name': userData?['displayName'] ?? 'Izina ritaboneka', 'photoUrl': userData?['photoUrl'] ?? '', })); } } return await Future.wait(reporterFutures); } catch (e) { return []; } }
  Future<void> _resolveReportsForPost(String postId) async { final batch = _firestore.batch(); final reportsQuery = await _firestore.collection('post_reports').where('postId', isEqualTo: postId).where('status', isEqualTo: 'pending').get(); for (var doc in reportsQuery.docs) { batch.update(doc.reference, {'status': 'resolved'}); } await batch.commit(); }
  Future<void> _deletePost(String postId) async { await _firestore.collection('posts').doc(postId).delete(); await _resolveReportsForPost(postId); }
  
  void _showReportDetails(BuildContext context, Map<String, dynamic> groupedReport) {
    final String postId = groupedReport['postId'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Amakuru y'Ikirego"),
          content: SizedBox(
            width: 500,
            child: FutureBuilder(
              future: Future.wait([_getPostAndAuthorData(postId), _getReporters(postId)]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
                if (snapshot.hasError) { return Center(child: Text("Haje ikosa: ${snapshot.error}")); }

                final postAndAuthorData = snapshot.data?[0] as Map<String, dynamic>?;
                final reporters = snapshot.data?[1] as List<Map<String, dynamic>>;

                if (postAndAuthorData == null) { return const Center(child: Text('Iyi post ishobora kuba yarafuswe.')); }
                
                final postData = postAndAuthorData['post'] as Map<String, dynamic>;
                final authorData = postAndAuthorData['author'] as Map<String, dynamic>?;
                
                final String authorPhotoUrl = authorData?['photoUrl'] ?? '';
                
                String postImageUrl = postData['imageUrl'] ?? '';
                if (postImageUrl.isNotEmpty && !postImageUrl.contains('optimized_')) {
                  final uri = Uri.parse(postImageUrl);
                  final pathSegments = uri.pathSegments;
                  final fileName = Uri.decodeComponent(pathSegments.last);
                  final baseName = fileName.split('.').first;
                  final newFileName = 'optimized_$baseName.webp';
                  postImageUrl = postImageUrl.replaceAll(Uri.encodeComponent(fileName), Uri.encodeComponent(newFileName));
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Yashizweho na:", style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: authorPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(authorPhotoUrl) : null,
                          child: authorPhotoUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(authorData?['displayName'] ?? 'Umukoresha Atakiboneka'),
                      ),
                      const SizedBox(height: 20),

                      Text("Post Yarezwe:", style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      if (postImageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: postImageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(height: 200, alignment: Alignment.center, child: const CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Container(height: 200, alignment: Alignment.center, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.broken_image, size: 40), Text("Ifoto ntiyabonetse", style: TextStyle(fontSize: 12))]))
                            ),
                          ),
                        ),
                      
                      SelectableText(postData['content'] ?? 'Nta majambo ari muri iyi post.'),
                      const SizedBox(height: 20),

                      Text("Yarezwe n'aba (${reporters.length}):", style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      if (reporters.isEmpty) const Text('Amakuru y\'abayireze ntabonetse.'),
                      ...reporters.map((reporter) {
                        final String reporterPhotoUrl = reporter['photoUrl'] ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: reporterPhotoUrl.isNotEmpty ? CachedNetworkImageProvider(reporterPhotoUrl) : null,
                            child: reporterPhotoUrl.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(reporter['name']),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Futa Iyi Post', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(context).pop(); _deletePost(postId); }),
            TextButton(child: const Text('Reka Ntaco (Futa Ibirego)'), onPressed: () { Navigator.of(context).pop(); _resolveReportsForPost(postId); }),
            TextButton(child: const Text('Subira Inyuma'), onPressed: () { Navigator.of(context).pop(); }),
          ],
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('post_reports').where('status', isEqualTo: 'pending').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
          if (snapshot.hasError) { return Center(child: Text("Haje ikosa: ${snapshot.error}")); }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return const Center(child: Text('Nta kirego gishasha kiraboneka.')); }

          final Map<String, Map<String, dynamic>> groupedReports = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dynamic postIdValue = data['postId'];
            if (postIdValue != null && postIdValue is String && postIdValue.isNotEmpty) {
              final String postId = postIdValue;
              if (!groupedReports.containsKey(postId)) { groupedReports[postId] = { 'postId': postId, 'reportCount': 0, 'latestTimestamp': data['timestamp'] as Timestamp?, }; }
              groupedReports[postId]!['reportCount']++;
              final currentTimestamp = groupedReports[postId]!['latestTimestamp'] as Timestamp?;
              final newTimestamp = data['timestamp'] as Timestamp?;
              if (newTimestamp != null && (currentTimestamp == null || newTimestamp.compareTo(currentTimestamp) > 0)) { groupedReports[postId]!['latestTimestamp'] = newTimestamp; }
            }
          }
          
          if (groupedReports.isEmpty) { return const Center(child: Text('Nta kirego na kimwe gifise amakuru yuzuye cabonetse.')); }

          final sortedReports = groupedReports.values.toList()
            ..sort((a, b) { final tsA = a['latestTimestamp'] as Timestamp?; final tsB = b['latestTimestamp'] as Timestamp?; if (tsB == null) return -1; if (tsA == null) return 1; return tsB.compareTo(tsA); });

          return ListView.builder(
            itemCount: sortedReports.length,
            itemBuilder: (context, index) {
              final reportGroup = sortedReports[index];
              final postId = reportGroup['postId'] as String;
              final reportCount = reportGroup['reportCount'] as int;
              final timestamp = (reportGroup['latestTimestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.flag_circle, color: Colors.red, size: 36),
                  title: Text('Post (ID: $postId)'),
                  subtitle: Text('Imaze kuregwa incuro $reportCount.\nIkirego giheruka: ${timestamp != null ? DateFormat.yMMMd().add_jm().format(timestamp) : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () { _showReportDetails(context, reportGroup); },
                ),
              );
            },
          );
        },
      ),
    );
  }
}