// lib/user_posts_screen.dart (STABLE - THUMBNAIL FIRST + TEXT TRUNCATION)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'app_config.dart';

class UserPostsScreen extends StatefulWidget {
  final String userId; final String userName; final String? userPhoto;
  const UserPostsScreen({super.key, required this.userId, required this.userName, this.userPhoto});
  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _cachedPosts = [];
  bool _isLoading = false;

  @override
  void initState() { super.initState(); _fetchPosts(); }

  Future<void> _fetchPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final snap = await _firestore.collection('posts').where('userId', isEqualTo: widget.userId).orderBy('timestamp', descending: true).get();
    setState(() { _cachedPosts = snap.docs; _isLoading = false; });
  }

  void _showFullText(String fullText) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1E1E26), title: const Text("Inyandiko yose", style: TextStyle(color: Colors.white)), content: SingleChildScrollView(child: Text(fullText, style: const TextStyle(color: Colors.white70))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("FUNGA"))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(backgroundColor: const Color(0xFF1E1E26), title: Text("Posts za ${widget.userName}")),
      body: _isLoading && _cachedPosts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : ListView.builder(
              itemCount: _cachedPosts.length,
              padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 20),
              itemBuilder: (context, index) {
                final data = _cachedPosts[index].data() as Map<String, dynamic>;
                final String text = data['content'] ?? data['text'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text.length > 30 ? "${text.substring(0, 30)}..." : text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            if (text.length > 30)
                              GestureDetector(onTap: () => _showFullText(text), child: const Text("Soma vyose", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      _SmartMediaItem(postId: _cachedPosts[index].id, data: data),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// --- WIDGET YA MEDIA (THUMBNAIL FIRST) ---
class _SmartMediaItem extends StatefulWidget {
  final String postId; final Map<String, dynamic> data;
  const _SmartMediaItem({required this.postId, required this.data});
  @override
  State<_SmartMediaItem> createState() => _SmartMediaItemState();
}

class _SmartMediaItemState extends State<_SmartMediaItem> {
  bool _play = false;
  String _getStreamUrl(String? r) => (r == null || r.isEmpty) ? "" : (r.contains('cloudflarestorage.com') ? "${AppConfig.workerUrl}${Uri.parse(r).path}?auth=${AppConfig.secretKey}" : r);

  @override
  void initState() {
    super.initState();
    ui.platformViewRegistry.registerViewFactory('thumb-${widget.postId}', (id) => html.ImageElement()..src = _getStreamUrl(widget.data['imageUrl'])..style.objectFit = 'contain');
    if (widget.data['videoUrl'] != null) ui.platformViewRegistry.registerViewFactory('vid-${widget.postId}', (id) => html.VideoElement()..src = _getStreamUrl(widget.data['videoUrl'])..controls = true..autoplay = true);
  }

  @override
  Widget build(BuildContext context) {
    bool hasVid = widget.data['videoUrl'] != null && widget.data['videoUrl'] != "";
    return Container(
      height: 450, width: double.infinity, color: Colors.black,
      child: Stack(alignment: Alignment.center, children: [
        _play ? HtmlElementView(viewType: 'vid-${widget.postId}') : HtmlElementView(viewType: 'thumb-${widget.postId}'),
        if (!_play && hasVid) GestureDetector(onTap: () => setState(() => _play = true), child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 50))),
      ]),
    );
  }
}