// lib/manage_star_ads_screen.dart (STABLE VERSION - NO ERRORS)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

// IMPORTS
import 'app_config.dart';
import 'user_details_screen.dart';

class ManageStarAdsScreen extends StatefulWidget {
  const ManageStarAdsScreen({super.key});

  @override
  State<ManageStarAdsScreen> createState() => _ManageStarAdsScreenState();
}

class _ManageStarAdsScreenState extends State<ManageStarAdsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _cachedPosts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStarPosts();
  }

  Future<void> _loadStarPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('posts').where('isStar', isEqualTo: true).get();
      List<Map<String, dynamic>> tempPosts = [];
      for (var doc in snapshot.docs) {
        final postData = doc.data();
        final userDoc = await _firestore.collection('users').doc(postData['userId']).get();
        final userData = userDoc.data();
        tempPosts.add({
          'id': doc.id,
          ...postData,
          'userDoc': userDoc,
          'userName': userData?['displayName'] ?? "Jembe User",
          'userPhoto': userData?['photoUrl'],
        });
      }
      setState(() { _cachedPosts = tempPosts; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getStreamUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty || rawUrl == "null") return "";
    try {
      Uri uri = Uri.parse(rawUrl);
      if (rawUrl.contains('cloudflarestorage.com')) {
        return "${AppConfig.workerUrl}${uri.path}?auth=${AppConfig.secretKey}";
      }
      return rawUrl;
    } catch (e) { return rawUrl; }
  }

  void _showFullText(String title, String fullText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(child: Text(fullText, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("FUNGA"))],
      ),
    );
  }

  // --- DIALOG YO KWAMAMAZA ---
  void _showAdDialog(String postId, String displayName) async {
    final TextEditingController msgController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    final TextEditingController labelController = TextEditingController(text: 'RABA');
    bool isActive = true;

    final adDoc = await _firestore.collection('star_ads').doc(postId).get();
    if (adDoc.exists) {
      final data = adDoc.data()!;
      msgController.text = data['message'] ?? '';
      linkController.text = data['link_url'] ?? '';
      labelController.text = data['button_label'] ?? 'RABA';
      isActive = data['is_active'] ?? true;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E26),
          title: Text("Amamaza: $displayName", style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: msgController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Ticker")),
              TextField(controller: linkController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Link")),
              TextField(controller: labelController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Button")),
              SwitchListTile(title: const Text("Active?", style: TextStyle(color: Colors.white)), value: isActive, onChanged: (v) => setDialogState(() => isActive = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("REKA")),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('star_ads').doc(postId).set({
                  'post_id': postId, 'message': msgController.text.trim(), 'link_url': linkController.text.trim(),
                  'button_label': labelController.text.trim(), 'is_active': isActive, 'updated_at': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                if (mounted) Navigator.pop(context);
              },
              child: const Text("BIKA"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text("Amatangazo y'aba Stars"),
        backgroundColor: const Color(0xFF1E1E26),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStarPosts)],
      ),
      body: _isLoading && _cachedPosts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : ListView.builder(
              itemCount: _cachedPosts.length,
              padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 20),
              itemBuilder: (context, index) {
                final post = _cachedPosts[index];
                final String text = post['text'] ?? post['content'] ?? "No text.";
                final String streamUrl = _getStreamUrl(post['videoUrl'] ?? post['imageUrl']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailsScreen(userDocument: post['userDoc']))),
                        leading: SizedBox(width: 40, height: 40, child: _AuthorizedFastMedia(url: _getStreamUrl(post['userPhoto']), isVideo: false, isAvatar: true, uniqueId: 'star-av-${post['id']}')),
                        title: Text(post['userName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Container(height: 450, width: double.infinity, color: Colors.black, child: _AuthorizedFastMedia(url: streamUrl, isVideo: post['videoUrl'] != null && post['videoUrl'] != "", uniqueId: 'star-med-${post['id']}')),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(text.length > 30 ? "${text.substring(0, 30)}..." : text, style: const TextStyle(color: Colors.white70)),
                                  if (text.length > 30)
                                    GestureDetector(onTap: () => _showFullText(post['userName'], text), child: const Text("Soma vyose", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            ElevatedButton(onPressed: () => _showAdDialog(post['id'], post['userName']), child: const Text("AMAMAZA")),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// =============================================================================
// IYI NIYO CLASS YABURAGA (FIXED)
// =============================================================================
class _AuthorizedFastMedia extends StatefulWidget {
  final String url;
  final bool isVideo;
  final bool isAvatar;
  final String uniqueId;

  const _AuthorizedFastMedia({required this.url, required this.isVideo, this.isAvatar = false, required this.uniqueId});

  @override
  State<_AuthorizedFastMedia> createState() => _AuthorizedFastMediaState();
}

class _AuthorizedFastMediaState extends State<_AuthorizedFastMedia> {
  @override
  void initState() {
    super.initState();
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(widget.uniqueId, (int viewId) {
      if (widget.isVideo) {
        return html.VideoElement()
          ..src = widget.url
          ..style.border = 'none'
          ..controls = true
          ..autoplay = false;
      } else {
        return html.ImageElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.objectFit = widget.isAvatar ? 'cover' : 'contain'
          ..style.borderRadius = widget.isAvatar ? '50%' : '0px';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.isAvatar 
      ? ClipOval(child: HtmlElementView(key: ValueKey(widget.uniqueId), viewType: widget.uniqueId))
      : HtmlElementView(key: ValueKey(widget.uniqueId), viewType: widget.uniqueId);
  }
}