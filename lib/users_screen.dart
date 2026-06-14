import 'package:app_admin_panel/stat_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// 🔥 KOSORA HANO: Import yanditse neza ubu
import 'package:firebase_database/firebase_database.dart' as rtdb; 
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'user_details_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final rtdb.FirebaseDatabase _realtimeDb;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _onlineUsersDocs = [];
  
  bool _isLoading = false;
  bool _isOnlineLoading = false;
  bool _hasMore = true;
  bool _showOnlyOnline = false; 
  
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  int _totalUsersCount = 0;
  List<String> _currentOnlineIds = [];

  @override
  void initState() {
    super.initState();
    _initializeDb();
    _fetchUsers();
    _fetchTotalCount();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_showOnlyOnline && _searchQuery.isEmpty) _fetchUsers();
      }
    });
  }

  void _initializeDb() {
    _realtimeDb = rtdb.FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.rtdbUrl,
    );
  }

  Future<void> _fetchTotalCount() async {
    try {
      final aggregateQuery = await _firestore.collection('users').count().get();
      if (mounted) setState(() => _totalUsersCount = aggregateQuery.count ?? 0);
    } catch (e) {
      debugPrint("Error counting: $e");
    }
  }

  Future<void> _fetchUsers({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;
    setState(() => _isLoading = true);
    Query query = _firestore.collection('users').orderBy('displayName').limit(30);
    if (_lastDocument != null && !isRefresh) query = query.startAfterDocument(_lastDocument!);
    if (_searchQuery.isNotEmpty) {
      query = _firestore.collection('users')
          .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
          .where('displayName', isLessThanOrEqualTo: '$_searchQuery\uf8ff').limit(30);
    }
    final snapshot = await query.get();
    if (snapshot.docs.length < 30) _hasMore = false;
    setState(() {
      if (isRefresh) { _users = snapshot.docs; } else { _users.addAll(snapshot.docs); }
      if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      _isLoading = false;
    });
  }

  Future<void> _fetchOnlineUsersFirestore() async {
    if (_currentOnlineIds.isEmpty) return;
    setState(() => _isOnlineLoading = true);
    try {
      List<String> limitedIds = _currentOnlineIds.take(30).toList();
      final snapshot = await _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: limitedIds).get();
      setState(() {
        _onlineUsersDocs = snapshot.docs;
        _isOnlineLoading = false;
      });
    } catch (e) {
      setState(() => _isOnlineLoading = false);
    }
  }

  void _onSearch(String value) {
    setState(() {
      _searchQuery = value; _users.clear(); _lastDocument = null; _hasMore = true;
    });
    _fetchUsers(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 1. STATS SECTION ---
        StreamBuilder<rtdb.DatabaseEvent>(
          stream: _realtimeDb.ref('status').onValue,
          builder: (context, snapshot) {
            int onlineCount = 0;
            List<String> onlineIds = [];
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final rawData = snapshot.data!.snapshot.value as Map;
              rawData.forEach((key, value) {
                if (value is Map && value['state'] == 'online') {
                  onlineCount++; onlineIds.add(key.toString());
                }
              });
            }
            _currentOnlineIds = onlineIds;

            return Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatCard(title: 'Abantu Bose', value: _totalUsersCount.toString(), icon: Icons.people, color: Colors.blue),
                      StatCard(title: 'Online Ubu', value: onlineCount.toString(), icon: Icons.wifi, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),

                  // --- 2. SEARCH & SWITCH SECTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Rondera izina, Numero, canke Gmail...",
                              hintStyle: const TextStyle(color: Colors.white24),
                              prefixIcon: const Icon(Icons.search, color: Colors.amber, size: 24),
                              filled: true,
                              fillColor: const Color(0xFF1E1E26),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            const Text('ONLINE', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            Transform.scale(
                              scale: 1.1,
                              child: Switch(
                                value: _showOnlyOnline,
                                activeColor: Colors.greenAccent,
                                onChanged: (value) {
                                  setState(() => _showOnlyOnline = value);
                                  if (value) _fetchOnlineUsersFirestore();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- 3. LIST AREA ---
                  Expanded(
                    child: _showOnlyOnline 
                        ? _buildOnlineStaticList(onlineIds) 
                        : _buildNormalPaginatedList(onlineIds),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOnlineStaticList(List<String> liveOnlineIds) {
    if (_isOnlineLoading) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    if (_onlineUsersDocs.isEmpty) return const Center(child: Text("Nta muntu uri ku murongo ubu.", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _onlineUsersDocs.length,
      itemBuilder: (context, index) {
        final doc = _onlineUsersDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildUserTile(doc, data, liveOnlineIds.contains(doc.id));
      },
    );
  }

  Widget _buildNormalPaginatedList(List<String> onlineIds) {
    if (_users.isEmpty && _isLoading) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _users.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _users.length) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.amber)));
        final doc = _users[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildUserTile(doc, data, onlineIds.contains(doc.id));
      },
    );
  }

  Widget _buildUserTile(DocumentSnapshot doc, Map<String, dynamic> data, bool isOnline) {
    final String userName = data['displayName'] ?? 'No Name';
    final String? photoUrl = data['photoUrl'];

    return Card(
      color: const Color(0xFF1E1E26).withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 35, 
              backgroundColor: Colors.indigo,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? CachedNetworkImageProvider(photoUrl) : null,
              child: (photoUrl == null || photoUrl.isEmpty) 
                ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : "?", style: const TextStyle(fontSize: 24, color: Colors.white)) 
                : null,
            ),
            if (isOnline)
              Positioned(
                right: 2, bottom: 2, 
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 3)),
                ),
              ),
          ],
        ),
        title: Text(
          userName, 
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white10),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserDetailsScreen(userDocument: doc))),
      ),
    );
  }
}