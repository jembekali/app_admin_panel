import 'package:app_admin_panel/stat_card.dart';
import 'package:app_admin_panel/user_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allUsers = [];
  
  // AKA NI AKANTU GASHASHA KO KUBIKA NIMBA TUREKANA GUSA ABARI KU MURONGO
  bool _showOnlyOnline = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isDisabled': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _allUsers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Habaye ikibazo mu gukurura amakuru'));
        }
        
        if (snapshot.hasData) {
          _allUsers = snapshot.data!.docs;
        }
        
        // UBU BWENGE BWO KURONDERERA NO GUFILTURA BURI HANO
        final lowerCaseQuery = _searchQuery.toLowerCase();
        List<DocumentSnapshot> filteredUsers = _allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = (data['email'] as String? ?? '').toLowerCase();
          return email.contains(lowerCaseQuery);
        }).toList();

        // IKI NI IGICE GISHASHA CO GUFILTURA ABARI KU MURONGO
        final List<DocumentSnapshot> displayUsers;
        if (_showOnlyOnline) {
          displayUsers = filteredUsers.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['isOnline'] == true; // Turaraba namba handitse 'isOnline: true'
          }).toList();
        } else {
          displayUsers = filteredUsers;
        }

        if (_allUsers.isEmpty) {
            return const Center(child: Text('Nta mukoresha n\'umwe araboneka'));
        }

        final totalUsers = _allUsers.length;
        final disabledUsers = _allUsers.where((doc) => (doc.data() as Map<String, dynamic>?)?['isDisabled'] == true).length;
        // UBU DUHARURA ABARI KU MURONGO TUKAVANA MURI DATABASE
        final onlineUsers = _allUsers.where((doc) => (doc.data() as Map<String, dynamic>?)?['isOnline'] == true).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                alignment: WrapAlignment.center,
                children: [
                  StatCard(title: 'Abakoresha Bose', value: totalUsers.toString(), icon: Icons.people, color: Colors.blue),
                  StatCard(title: 'Abahagaritswe', value: disabledUsers.toString(), icon: Icons.block, color: Colors.red),
                  StatCard(title: 'Abari ku Murongo', value: onlineUsers.toString(), icon: Icons.wifi, color: Colors.green),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                // ... (igice co kurondera kiguma uko cari)
              ),
            ),
            // IKI NI IGICE GISHASHA CO GUHINDURA URUTONDE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            Expanded(
              child: displayUsers.isEmpty
                  ? Center(child: Text(_showOnlyOnline ? 'Nta muntu ari ku murongo' : 'Nta mukoresha abonetse'))
                  : ListView.builder(
                      itemCount: displayUsers.length,
                      itemBuilder: (context, index) {
                        final user = displayUsers[index];
                        final data = user.data() as Map<String, dynamic>;
                        final String userEmail = data['email'] ?? 'Email ntiboneka';
                        final bool isDisabled = data['isDisabled'] ?? false;
                        final bool isOnline = data['isOnline'] ?? false;

                        return ListTile(
                          // AKA KADOMAGU K'ICYATSI KEREKANA KO ARI KU MURONGO
                          leading: CircleAvatar(
                            backgroundColor: isDisabled ? Colors.red.shade700 : Colors.indigo,
                            child: Stack(
                              children: [
                                Center(child: Text(userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?')),
                                if (isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          title: Text(userEmail),
                          subtitle: Text("UID: ${user.id}"),
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
      },
    );
  }
}