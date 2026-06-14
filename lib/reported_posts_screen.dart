// lib/reported_posts_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; // Iyi ni ingenzi cyane

import 'reply_to_feedback_screen.dart';
import 'user_posts_screen.dart';

class ReportedPostsScreen extends StatefulWidget {
  const ReportedPostsScreen({super.key});

  @override
  State<ReportedPostsScreen> createState() => _ReportedPostsScreenState();
}

class _ReportedPostsScreenState extends State<ReportedPostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logic yo kureba niba URL ari Video (ireba extension)
  bool _isVideo(String url) {
    final String lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.mp4') ||
        lowerUrl.contains('.mov') ||
        lowerUrl.contains('.avi') ||
        lowerUrl.contains('.m4v') ||
        lowerUrl.contains('video') ||
        lowerUrl.contains('.webm');
  }

  // Logic yo gukeka Optimized Image URL
  String _guessOptimizedUrl(String originalUrl) {
    if (_isVideo(originalUrl)) return originalUrl;
    try {
      final String decoded = Uri.decodeFull(originalUrl);
      if (decoded.contains('optimized_')) return originalUrl;
      final Uri uri = Uri.parse(originalUrl);
      final String path = uri.path;
      final List<String> parts = path.split('/');
      final String filename = parts.last;
      final String nameWithoutExt = filename.split('.').first;
      final String optimizedName = 'optimized_$nameWithoutExt.webp';
      final String encodedFilename = Uri.encodeComponent(filename);
      final String encodedOptimized = Uri.encodeComponent(optimizedName);
      return originalUrl.replaceAll(encodedFilename, encodedOptimized);
    } catch (e) {
      return originalUrl;
    }
  }

  // Firebase Functions
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getPostAndAuthorData(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return null;
      final postData = postDoc.data()!;
      final authorId = postData['userId'] as String?;
      Map<String, dynamic>? authorData;
      if (authorId != null) {
        authorData = await _getUserData(authorId);
      }
      return {'post': postData, 'author': authorData};
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getReporters(String postId) async {
    try {
      final reportsSnapshot = await _firestore
          .collection('post_reports')
          .where('postId', isEqualTo: postId)
          .get();
      List<Future<Map<String, dynamic>>> reporterFutures = [];
      for (var doc in reportsSnapshot.docs) {
        final reporterId = doc.data()['reporterId'];
        if (reporterId != null && reporterId is String) {
          reporterFutures.add(_getUserData(reporterId).then((userData) => {
                'name': userData?['displayName'] ?? 'Izina ritaboneka',
                'photoUrl': userData?['photoUrl'] ?? '',
              }));
        }
      }
      return await Future.wait(reporterFutures);
    } catch (e) {
      return [];
    }
  }

  Future<void> _resolveReportsForPost(String postId) async {
    final batch = _firestore.batch();
    final reportsQuery = await _firestore
        .collection('post_reports')
        .where('postId', isEqualTo: postId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (var doc in reportsQuery.docs) {
      batch.update(doc.reference, {'status': 'resolved'});
    }
    await batch.commit();
  }

  Future<void> _deletePostAndNotify(BuildContext context, String postId,
      Map<String, dynamic>? authorData) async {
    Navigator.of(context).pop();
    try {
      await _firestore.collection('posts').doc(postId).delete();
      await _resolveReportsForPost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Post yafuswe burundu.'),
            backgroundColor: Colors.green));
        if (authorData != null && authorData['uid'] != null) {
          _showNotifyDialog(context, authorData['uid']);
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gufuta vyanse: $e'), backgroundColor: Colors.red));
    }
  }

  void _showNotifyDialog(BuildContext context, String authorId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Menyesha Umukoresha"),
        content: const Text(
            "Post irafuswe. Urashobora kumwandikira umumenyeshe igituma post yiwe yakuweho?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Oya, Bihorere")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              try {
                DocumentSnapshot userDoc =
                    await _firestore.collection('users').doc(authorId).get();
                if (mounted && userDoc.exists) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ReplyToFeedbackScreen(feedbackDoc: userDoc)));
                }
              } catch (e) {
                print("Error getting user doc: $e");
              }
            },
            child: const Text("Ego, Mwandikire"),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(
      BuildContext context, Map<String, dynamic> groupedReport) {
    final String postId = groupedReport['postId'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Amakuru y'Ikirego"),
          content: SizedBox(
            width: 500,
            child: FutureBuilder(
              future: Future.wait(
                  [_getPostAndAuthorData(postId), _getReporters(postId)]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Haje ikosa: ${snapshot.error}"));
                }

                final postAndAuthorData =
                    snapshot.data?[0] as Map<String, dynamic>?;
                final reporters =
                    snapshot.data?[1] as List<Map<String, dynamic>>;

                if (postAndAuthorData == null) {
                  return const Center(
                      child: Text('Iyi post ishobora kuba yarafuswe.'));
                }

                final postData =
                    postAndAuthorData['post'] as Map<String, dynamic>;
                final authorData =
                    postAndAuthorData['author'] as Map<String, dynamic>?;
                final String? authorId = postData['userId'];

                // Fata URL (aba ari imageUrl cyangwa videoUrl)
                final String originalUrl =
                    postData['imageUrl'] ?? postData['videoUrl'] ?? '';
                final bool isVideo = _isVideo(originalUrl);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Umwanditsi:",
                          style: Theme.of(context).textTheme.titleSmall),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: (authorData?['photoUrl'] != null &&
                                  authorData!['photoUrl'] != '')
                              ? CachedNetworkImageProvider(
                                  authorData['photoUrl'])
                              : null,
                          child: (authorData?['photoUrl'] == null ||
                                  authorData!['photoUrl'] == '')
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                            authorData?['displayName'] ?? 'Izina ritaboneka'),
                        subtitle: Text(authorData?['email'] ?? ''),
                      ),
                      const Divider(),

                      const Text("Ibirimwo (Media):",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // HANO NIHO HAHINDUTSE:
                      if (originalUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: isVideo
                              ? AdminInternalVideoPlayer(
                                  videoUrl:
                                      originalUrl) // Kina video hano imbere
                              : CachedNetworkImage(
                                  imageUrl: originalUrl,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      CachedNetworkImage(
                                    imageUrl: _guessOptimizedUrl(originalUrl),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.broken_image,
                                            size: 50),
                                  ),
                                ),
                        ),

                      const SizedBox(height: 10),
                      SelectableText(postData['content'] ??
                          'Nta majambo ari muri iyi post.'),
                      const Divider(),

                      Text("Abayireze (${reporters.length}):",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...reporters
                          .map((r) => ListTile(
                                dense: true,
                                leading:
                                    const Icon(Icons.person_outline, size: 18),
                                title: Text(r['name']),
                              ))
                          .toList(),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final postAndAuthor = await _getPostAndAuthorData(postId);
                if (context.mounted)
                  _deletePostAndNotify(
                      context, postId, postAndAuthor?['author']);
              },
              child: const Text("Futa Post",
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resolveReportsForPost(postId);
              },
              child: const Text("Futa Ibirego"),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Funga")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ivyarezwe (Reports)")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('post_reports')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("Nta kirego gihari."));

          final Map<String, Map<String, dynamic>> grouped = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String? pid = data['postId'];
            if (pid != null) {
              if (!grouped.containsKey(pid)) {
                grouped[pid] = {
                  'postId': pid,
                  'count': 0,
                  'time': data['timestamp']
                };
              }
              grouped[pid]!['count']++;
            }
          }

          final list = grouped.values.toList();
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final item = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading:
                      const Icon(Icons.report_problem, color: Colors.orange),
                  title: Text(
                      "Post ID: ...${item['postId'].toString().substring(item['postId'].toString().length - 6)}"),
                  subtitle: Text("Incuro yarezwe: ${item['count']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReportDetails(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET YO GUKINA VIDEO IMBERE MURI ADMIN PANEL (WEB/MOBILE)
// -----------------------------------------------------------------------------
class AdminInternalVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const AdminInternalVideoPlayer({super.key, required this.videoUrl});

  @override
  State<AdminInternalVideoPlayer> createState() =>
      _AdminInternalVideoPlayerState();
}

class _AdminInternalVideoPlayerState extends State<AdminInternalVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
      }).catchError((e) {
        setState(() {
          _error = "Video ntishoboye gufunguka: $e";
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Container(
        height: 200,
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(_error,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center),
      );
    }

    if (!_initialized) {
      return Container(
          height: 200,
          color: Colors.black12,
          child: const Center(child: CircularProgressIndicator()));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              _ControlsOverlay(
                  controller: _controller, refresh: () => setState(() {})),
              VideoProgressIndicator(_controller, allowScrubbing: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback refresh;
  const _ControlsOverlay({required this.controller, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
        refresh();
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
