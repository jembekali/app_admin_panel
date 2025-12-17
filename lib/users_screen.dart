// lib/users_screen.dart (VERSION FINAL & COMPLETE)

import 'package:app_admin_panel/stat_card.dart';
import 'package:app_admin_panel/user_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// =============================================================================
// CLASS 1: PARENT WIDGET (Iyi itwara Search Bar na Switch gusa)
// Iyi niyo ituma keyboard itagenda yifunga igihe wandika.
// =============================================================================
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyOnline = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. SEARCH BAR (IGUMA IHAMYE)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            // Hano dukoresha onChanged kugira ngo tudakora rebuild ya TextField
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: "Rondera (Email, Izina, Telefone)",
              hintText: "Andika hano...",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            ),
          ),
        ),

        // 2. SWITCH (FILTER)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Erekana gusa abari ku murongo'),
              Switch(
                value: _showOnlyOnline,
                onChanged: (value) {
                  setState(() {
                    _showOnlyOnline = value;
                  });
                },
              ),
            ],
          ),
        ),

        // 3. IGICE CY'AMAKURU (LIST) - Iki nicyo gihinduka gusa
        Expanded(
          child: _UsersDataList(
            searchQuery: _searchQuery,
            showOnlyOnline: _showOnlyOnline,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CLASS 2: DATA WIDGET (Iyi niyoivugana na Firebase)
// =============================================================================
class _UsersDataList extends StatefulWidget {
  final String searchQuery;
  final bool showOnlyOnline;

  const _UsersDataList({
    required this.searchQuery,
    required this.showOnlyOnline,
  });

  @override
  State<_UsersDataList> createState() => _UsersDataListState();
}

class _UsersDataListState extends State<_UsersDataList> {
  late final FirebaseDatabase _realtimeDb;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initializeRealtimeDb();
  }

  // Method yo gutegura Realtime Database na Link yawe
  Future<void> _initializeRealtimeDb() async {
    try {
      _realtimeDb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        // ⚠️ IYI NIYO LINK YAWE - NTUYIKUREHO ⚠️
        databaseURL: 'https://jembe-talk-default-rtdb.firebaseio.com/', 
      );
      if (mounted) setState(() => _dbReady = true);
    } catch (e) {
      debugPrint("Ikosa rya Database Init: $e");
      // Fallback
      _realtimeDb = FirebaseDatabase.instance;
      if (mounted) setState(() => _dbReady = true);
    }
  }

  // Method yo guhagarika cyangwa gukomoreza umukoresha
  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isDisabled': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Niba Database ititeguye, turindira
    if (!_dbReady) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. STREAM YA MBERE: FIRESTORE (Urutonde rw'abantu bose)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, firestoreSnapshot) {
        
        // 2. STREAM YA KABIRI: REALTIME DB (Kumenya abari Online)
        return StreamBuilder<DatabaseEvent>(
          stream: _realtimeDb.ref('status').onValue,
          builder: (context, statusSnapshot) {
            
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- A. LOGIC YO GUKUSANYA ABARI ONLINE ---
            Set<String> onlineUserIds = {};
            
            if (statusSnapshot.hasData && statusSnapshot.data!.snapshot.value != null) {
              try {
                final rawData = statusSnapshot.data!.snapshot.value;
                
                if (rawData is Map) {
                  final statusMap = Map<dynamic, dynamic>.from(rawData);
                  statusMap.forEach((key, value) {
                    bool isUserOnline = false;

                    // Turagenzura uburyo bwose bushoboka bwo kubika status
                    if (value is Map && value['state'] == 'online') {
                      isUserOnline = true;
                    } else if (value is String && value == 'online') {
                      isUserOnline = true;
                    }

                    if (isUserOnline) {
                      onlineUserIds.add(key.toString());
                    }
                  });
                }
              } catch (e) {
                debugPrint("Ikosa ryo gusoma status: $e");
              }
            }

            // --- B. GUKUSANYA NO GUFILTURA URUTONDE ---
            final allUserDocs = firestoreSnapshot.data?.docs ?? [];
            final lowerCaseQuery = widget.searchQuery.toLowerCase();
            
            List<DocumentSnapshot> filteredUsers = allUserDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              
              // Gukurura amakuru yose ashoboka
              final email = (data['email'] as String? ?? '').toLowerCase();
              final name = (data['displayName'] as String? ?? '').toLowerCase();
              final phone = (data['phoneNumber'] as String? ?? '');
              
              // Logic yo gushakisha
              final matchesSearch = email.contains(lowerCaseQuery) || 
                                    name.contains(lowerCaseQuery) ||
                                    phone.contains(lowerCaseQuery);
                                    
              // Niba switch ifunguye, tureba niba ari no muri onlineUserIds
              if (widget.showOnlyOnline) {
                return matchesSearch && onlineUserIds.contains(doc.id);
              }
              return matchesSearch;
            }).toList();

            // --- C. IMIBARE (STATS) ---
            final totalUsers = allUserDocs.length;
            final disabledUsers = allUserDocs.where((doc) => (doc.data() as Map<String, dynamic>?)?['isDisabled'] == true).length;
            final onlineUsersCount = onlineUserIds.length; 

            return Column(
              children: [
                // Cards zerekana imibare
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    alignment: WrapAlignment.center,
                    children: [
                      StatCard(title: 'Abakoresha', value: totalUsers.toString(), icon: Icons.people, color: Colors.blue),
                      StatCard(title: 'Abahagaritswe', value: disabledUsers.toString(), icon: Icons.block, color: Colors.red),
                      StatCard(title: 'Online', value: onlineUsersCount.toString(), icon: Icons.wifi, color: Colors.green),
                    ],
                  ),
                ),

                const Divider(),

                // Urutonde nyirizina (List View)
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(child: Text(widget.showOnlyOnline ? 'Nta muntu ari ku murongo.' : 'Nta mukoresha abonetse.'))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final data = user.data() as Map<String, dynamic>;
                            
                            final String userEmail = data['email'] ?? 'Email ntiboneka';
                            final String userName = data['displayName'] ?? 'Izina ntiriboneka';
                            final bool isDisabled = data['isDisabled'] ?? false;
                            
                            // Kureba niba uyu muntu ari online
                            final bool isOnline = onlineUserIds.contains(user.id);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDisabled ? Colors.red.shade700 : Colors.indigo,
                                child: Stack(
                                  children: [
                                    Center(child: Text(userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?')),
                                    
                                    // Akadomo k'icyatsi (Kagaragara gusa niba ari Online)
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14, 
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              title: Text(userEmail),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text("UID: ${user.id}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              trailing: Switch(
                                value: isDisabled,
                                onChanged: (newValue) => _toggleUserStatus(user.id, isDisabled),
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserDetailsScreen(userDocument: user))),
                            );
                          },
                        ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}