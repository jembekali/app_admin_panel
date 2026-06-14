// lib/recovery_requests_screen.dart (ADMIN PANEL - FINAL VERSION)

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:ui_web' as ui;
import 'dart:html' as html;

import 'app_config.dart';
import 'user_details_screen.dart'; 

class RecoveryRequestsScreen extends StatefulWidget {
  const RecoveryRequestsScreen({super.key});
  @override
  State<RecoveryRequestsScreen> createState() => _RecoveryRequestsScreenState();
}

class _RecoveryRequestsScreenState extends State<RecoveryRequestsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _approveRequest(Map<String, dynamic> req, String docId) async {
    final confirmed = await _showConfirmDialog("Kwemeza", "Uremeza ko uhinduye Email ya ${req['phone_number']}?");
    if (confirmed != true) return;
    setState(() => _isActionLoading = true);
    try {
      final q = await _firestore.collection('users').where('phoneNumber', isEqualTo: req['phone_number']).limit(1).get();
      if (q.docs.isEmpty) { _showSnackBar("Numero ntibonetse!", Colors.red); return; }
      final result = await FirebaseFunctions.instance.httpsCallable('approveAccountRecovery').call({'uid': q.docs.first.id, 'newEmail': req['new_email']});
      if (result.data['success'] == true) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: req['new_email']);
        await _firestore.collection('recovery_history').add({...req, 'status': 'Approved', 'processed_at': FieldValue.serverTimestamp(), 'user_confirmed_login': false});
        await _deleteFromCloudflare(req['id_document_url']);
        await _firestore.collection('recovery_requests').doc(docId).delete();
        _showSnackBar("Vyakunze! Link yarungitswe.", Colors.green);
      }
    } catch (e) { _showSnackBar("Error: $e", Colors.red); } finally { if (mounted) setState(() => _isActionLoading = false); }
  }

  Future<void> _rejectRequest(Map<String, dynamic> req, String docId) async {
    final confirmed = await _showConfirmDialog("Kwanka", "Uremeza?");
    if (confirmed != true) return;
    setState(() => _isActionLoading = true);
    try {
      await _firestore.collection('recovery_history').add({...req, 'status': 'Rejected', 'processed_at': FieldValue.serverTimestamp(), 'user_confirmed_login': false});
      await _deleteFromCloudflare(req['id_document_url']);
      await _firestore.collection('recovery_requests').doc(docId).delete();
      _showSnackBar("Ubusabe bwanswe.");
    } catch (e) { _showSnackBar("Error: $e"); } finally { if (mounted) setState(() => _isActionLoading = false); }
  }

  Future<void> _deleteFromCloudflare(String url) async {
    try { await http.post(Uri.parse('${AppConfig.workerUrl}/delete'), body: {'url': url}, headers: {'X-Jembe-Auth': AppConfig.secretKey}); } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text("Recovery Admin Panel"),
        backgroundColor: const Color(0xFF1E1E26),
        bottom: TabBar(controller: _tabController, indicatorColor: Colors.amber, tabs: const [Tab(text: "PENDING"), Tab(text: "HISTORY")]),
      ),
      body: TabBarView(controller: _tabController, children: [_buildList('recovery_requests'), _buildList('recovery_history')]),
    );
  }

  Widget _buildList(String coll) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(coll).orderBy(coll == 'recovery_requests' ? 'created_at' : 'processed_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nta busabe buhari.", style: TextStyle(color: Colors.white24)));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final req = doc.data() as Map<String, dynamic>;
            return _buildRequestCard(req, doc.id, isHistory: coll == 'recovery_history');
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, String docId, {required bool isHistory}) {
    String phoneNumber = req['phone_number'] ?? "";
    return Card(
      color: const Color(0xFF1E1E26),
      margin: const EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        title: Text(req['full_name'] ?? "No Name", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Row(children: [Text("Tel: $phoneNumber", style: const TextStyle(color: Colors.white38, fontSize: 11)), const SizedBox(width: 10), InkWell(onTap: () { Clipboard.setData(ClipboardData(text: phoneNumber)); _showSnackBar("Numero yabaye copy!", Colors.teal); }, child: const Icon(Icons.copy, color: Colors.amber, size: 14))]),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!isHistory) FutureBuilder<QuerySnapshot>(
                future: _firestore.collection('users').where('phoneNumber', isEqualTo: phoneNumber).limit(1).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return ElevatedButton.icon(icon: const Icon(Icons.person_search, size: 16), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailsScreen(userDocument: snapshot.data!.docs.first))), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800), label: const Text("RABA PROFILE Y'UBU MURI APP", style: TextStyle(color: Colors.white, fontSize: 11)));
                  }
                  return const Text("⚠️ Iyi numero ntayiri muri App.", style: TextStyle(color: Colors.redAccent, fontSize: 11));
                },
              ),
              const SizedBox(height: 15),
              
              // --- IYI NI YO NSHASHA: KWEREKANA IKIBAZO YAGIZE ---
              const Text("Ibisobanuro vy'ikibazo yagize:", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Text(req['reason'] ?? "Nta bisobanuro vyatanzwe.", style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
              const SizedBox(height: 15),

              Text("Email Nsha sha: ${req['new_email']}", style: const TextStyle(color: Colors.tealAccent)),
              const SizedBox(height: 15),
              if (!isHistory) _IDPhotoItem(docId: docId, imageUrl: req['id_document_url']),
              const SizedBox(height: 20),
              if (_isActionLoading) const CircularProgressIndicator() 
              else if (!isHistory) 
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => _rejectRequest(req, docId), child: const Text("REJECT", style: TextStyle(color: Colors.redAccent))),
                  const SizedBox(width: 20),
                  ElevatedButton(onPressed: () => _approveRequest(req, docId), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), child: const Text("APPROVE")),
                ]),
            ]),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String m, [Color c = Colors.orange]) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c)); }
  Future<bool?> _showConfirmDialog(String t, String d) { return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E1E26), title: Text(t, style: const TextStyle(color: Colors.white)), content: Text(d, style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("REKA")), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("EGO"))])); }
}

class _IDPhotoItem extends StatefulWidget {
  final String docId; final String? imageUrl;
  const _IDPhotoItem({required this.docId, this.imageUrl});
  @override
  State<_IDPhotoItem> createState() => _IDPhotoItemState();
}

class _IDPhotoItemState extends State<_IDPhotoItem> {
  String _getStreamUrl(String? r) {
    if (r == null || r.isEmpty) return "";
    if (r.contains('cloudflarestorage.com')) return "${AppConfig.workerUrl}${Uri.parse(r).path}?auth=${AppConfig.secretKey}";
    return r.contains('?') ? "$r&auth=${AppConfig.secretKey}" : "$r?auth=${AppConfig.secretKey}";
  }
  @override
  void initState() {
    super.initState();
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('id-img-${widget.docId}', (id) => html.ImageElement()..src = _getStreamUrl(widget.imageUrl)..style.objectFit = 'contain'..style.backgroundColor = 'black');
  }
  @override
  Widget build(BuildContext context) { return Container(height: 450, width: double.infinity, color: Colors.black, child: HtmlElementView(viewType: 'id-img-${widget.docId}')); }
}