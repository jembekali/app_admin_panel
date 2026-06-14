// lib/user_details_screen.dart (VERSION 32.0 - ATOMIC DELETE & GHOST FORCE OUT)

import 'dart:async';
import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Izi ni ingenzi kuri Flutter Web
import 'dart:ui_web' as ui;
import 'dart:html' as html;

// PROJECT IMPORTS
import 'app_config.dart'; 
import 'reply_to_feedback_screen.dart'; 
import 'user_posts_screen.dart'; 

class UserDetailsScreen extends StatefulWidget {
  final DocumentSnapshot userDocument;
  const UserDetailsScreen({super.key, required this.userDocument});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final String _adminSystemId = 'jembe_talk_official_admin';
  Uint8List? _imageBytes; 
  bool _isLoadingImage = true;
  bool _isProcessing = false; 

  late bool _isCurrentlyDisabled;
  String _viewId = "";

  @override
  void initState() {
    super.initState();
    final data = widget.userDocument.data() as Map<String, dynamic>;
    _isCurrentlyDisabled = data['isDisabled'] ?? false;
    _viewId = 'avatar-detail-${widget.userDocument.id}';
    _fetchAuthorizedImage();
  }

  // 1. GUFUNGA/GUFUNGURA (BAN SYSTEM)
  Future<void> _toggleBlockUser(String uid) async {
    setState(() => _isProcessing = true);
    final bool newStatus = !_isCurrentlyDisabled;
    try {
      // Vugurura Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isDisabled': newStatus});
      
      // Vugurura Realtime Database kugira ngo presence_service ibimenye
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: "https://jembe-talk-1-default-rtdb.firebaseio.com",
      );
      await rtdb.ref('status/$uid').update({'is_blocked': newStatus});

      if (mounted) {
        setState(() => _isCurrentlyDisabled = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newStatus ? "Uyu muntu yahagaritswe!" : "Uyu muntu yafunguwe!"),
          backgroundColor: newStatus ? Colors.orange.shade900 : Colors.green.shade800,
        ));
      }
    } catch (e) {
      debugPrint("Error blocking user: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 2. 🔥 🔥 🔥 GUFUTA BURUNDU KANDI GUSOHORA UMUKORESHA (ATOMIC DELETE) 🔥 🔥 🔥
  Future<void> _permanentDeleteUser(String uid) async {
    setState(() => _isProcessing = true);
    final firestore = FirebaseFirestore.instance;
    
    try {
      final batch = firestore.batch();
      
      // Ids za chat room hagati ya Admin na User
      List<String> ids = [_adminSystemId, uid];
      ids.sort();
      String chatRoomId = ids.join("_");
      
      // A. Siba messages zose mu kiganiro cyabo
      final messages = await firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').get();
      for (var doc in messages.docs) { 
        batch.delete(doc.reference); 
      }
      
      // B. Siba chat room document ubwayo
      batch.delete(firestore.collection('chat_rooms').doc(chatRoomId));
      
      // C. SIBA USER DOCUMENT (Ibi nibyo bituma AuthGate yo muri main.dart imusohora)
      batch.delete(firestore.collection('users').doc(uid));

      // D. Kuraho status ye muri Realtime Database
      final rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: "https://jembe-talk-1-default-rtdb.firebaseio.com",
      );
      await rtdb.ref('status/$uid').remove();

      // EMEZA IMPINDUKA ZOSE ICYARIMWE
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Garuka kuri list y'abakoresha
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Uyu muntu yafuswe burundu kandi asohogwa muri App!"), 
          backgroundColor: Colors.red
        ));
      }
    } catch (e) { 
      debugPrint("Error deleting user: $e"); 
      _showSnackBar("Habaye ikosa mu gusiba: $e", Colors.red);
    } finally { 
      if (mounted) setState(() => _isProcessing = false); 
    }
  }

  // --- IBINDI BISANZWE (Image loading, UI components) ---

  Future<void> _fetchAuthorizedImage() async {
    final data = widget.userDocument.data() as Map<String, dynamic>;
    final String? photoUrl = data['photoUrl'];
    if (photoUrl == null || photoUrl.isEmpty || photoUrl == "null") { if (mounted) setState(() => _isLoadingImage = false); return; }
    try {
      String finalUrl = photoUrl;
      if (photoUrl.contains('cloudflarestorage.com')) { finalUrl = "${AppConfig.workerUrl}${Uri.parse(photoUrl).path}"; }
      final response = await http.get(Uri.parse(finalUrl), headers: {'X-Jembe-Auth': AppConfig.secretKey});
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (mounted) setState(() => _imageBytes = bytes);
        final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => html.ImageElement()..src = url..style.border = 'none'..style.width = '100%'..style.height = '100%'..style.objectFit = 'cover'..style.borderRadius = '50%');
        if (mounted) setState(() => _isLoadingImage = false);
      } else { if (mounted) setState(() => _isLoadingImage = false); }
    } catch (e) { if (mounted) setState(() => _isLoadingImage = false); }
  }

  void _showFullImage() {
    if (_imageBytes == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))), body: Center(child: InteractiveViewer(child: Image.memory(_imageBytes!, fit: BoxFit.contain))))));
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    final data = widget.userDocument.data() as Map<String, dynamic>;
    final String userEmail = data['email'] ?? 'Nta Email';
    final String userName = data['displayName'] ?? '...';
    final String userPhone = data['phoneNumber'] ?? '...';
    final String userUID = data['uid'] ?? widget.userDocument.id;
    final Timestamp? createdAtTimestamp = data['createdAt'];
    String formattedDate = createdAtTimestamp != null ? DateFormat('d MMMM y, HH:mm').format(createdAtTimestamp.toDate()) : "...";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(backgroundColor: const Color(0xFF1E1E26), elevation: 0, title: const Text("Imyirondoro y'Umukoresha")),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      // PROFILE PHOTO
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle, border: Border.all(color: _isCurrentlyDisabled ? Colors.red : Colors.amber.withOpacity(0.4), width: 3)),
                            child: _isLoadingImage 
                              ? const Padding(padding: EdgeInsets.all(45), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                              : (_imageBytes == null ? Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "?", style: const TextStyle(fontSize: 55, color: Colors.white))) : ClipOval(child: HtmlElementView(viewType: _viewId))),
                          ),
                          Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(65), onTap: _showFullImage))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // NAME & NAVIGATION TO POSTS
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserPostsScreen(userId: userUID, userName: userName, userPhoto: data['photoUrl']))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(userName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.underline)),
                            const SizedBox(width: 8),
                            const Icon(Icons.grid_view_rounded, size: 22, color: Colors.amber),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(onTap: () => _launchEmail(userEmail, userName), child: Text(userEmail, style: TextStyle(color: Colors.amber.shade200, fontSize: 16, decoration: TextDecoration.underline))),
                          IconButton(onPressed: () { Clipboard.setData(ClipboardData(text: userEmail)); _showSnackBar("Email yakopishijwe!", Colors.teal); }, icon: const Icon(Icons.copy_all_rounded, color: Colors.white54, size: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(color: Colors.white10),
                _buildInfoTile(Icons.phone_iphone_rounded, 'Telefone', userPhone),
                _buildInfoTile(Icons.fingerprint_rounded, 'User UID', userUID),
                _buildInfoTile(Icons.calendar_today_rounded, 'Yiyandikishije', formattedDate),
                
                ListTile(
                  leading: Icon(_isCurrentlyDisabled ? Icons.lock_person_rounded : Icons.verified_user_rounded, color: _isCurrentlyDisabled ? Colors.redAccent : Colors.greenAccent, size: 24),
                  title: const Text('Imikorere (Status)', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  subtitle: Text(_isCurrentlyDisabled ? 'YAHAGARITSWE (AFUNZWE)' : 'ARAKORA NEZA', style: TextStyle(color: _isCurrentlyDisabled ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                ),

                const SizedBox(height: 40),

                // ACTION BUTTONS
                _buildActionButton(Icons.chat_bubble_rounded, 'Mwandikire (Reply)', Colors.blue.shade700, () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => ReplyToFeedbackScreen(targetUserId: userUID)));
                }),
                const SizedBox(height: 15),

                _buildActionButton(
                  _isCurrentlyDisabled ? Icons.lock_open_rounded : Icons.block_rounded, 
                  _isCurrentlyDisabled ? 'FUNGURA UYU MUNTU' : 'FUNGA UYU MUNTU', 
                  _isCurrentlyDisabled ? Colors.green.shade800 : Colors.orange.shade900, 
                  () => _toggleBlockUser(userUID)
                ),
                const SizedBox(height: 15),

                _buildActionButton(Icons.delete_forever_rounded, 'FUTA UYU MUNTU BURUNDU', Colors.red.shade900, () {
                  showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E1E26), title: const Text("FUTA BURUNDU?", style: TextStyle(color: Colors.white)), content: const Text("Vyukuri urashaka gufuta uyu muntu? Azahita asohoka muri App burundu.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HAGARIKA")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); _permanentDeleteUser(userUID); }, child: const Text("EGO, FUTA"))]));
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String sub) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber, size: 24),
      title: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white, fontSize: 17)),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(icon: Icon(icon, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
    );
  }

  Future<void> _launchEmail(String email, String name) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email, query: 'subject=Support: Jembe Talk&body=Muraho $name,');
    if (await canLaunchUrl(emailLaunchUri)) { await launchUrl(emailLaunchUri); }
  }
}