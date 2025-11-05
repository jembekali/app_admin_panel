import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDetailsScreen extends StatelessWidget {
  final DocumentSnapshot userDocument;

  const UserDetailsScreen({super.key, required this.userDocument});

  Future<void> _deleteUser(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      Navigator.pop(context); 
    } catch (e) {
      print("Gufuta umukoresha vyanse: $e");
    }
  }
  
  void _showDeleteConfirmationDialog(BuildContext context, String uid, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // TWAHINDURIYE HANO
          title: const Text('Kwemeza Gufuta'),
          content: Text('Uzi neza ko ushaka gufuta umukoresha $email burundu?\n\nIki gikorwa ntigisubirwako.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OYA, SUBIZA INYUMA'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              // NA HANO
              child: const Text('EGO, FUTA BURUNDU'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(context, uid);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = userDocument.data() as Map<String, dynamic>;
    final String userEmail = data['email'] ?? 'Email ntiboneka';
    final String userUID = data['uid'] ?? 'UID ntiboneka';
    final bool isDisabled = data['isDisabled'] ?? false;
    
    final Timestamp createdAtTimestamp = data['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('d MMMM y, HH:mm').format(createdAtTimestamp.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(userEmail),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: <Widget>[
                  // ... (ibindi bice biguma uko vyari biri)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(userEmail),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('User ID (UID)'),
                    subtitle: Text(userUID),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text('Yiyandikishije ku wa'),
                    subtitle: Text(formattedDate),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      isDisabled ? Icons.block : Icons.check_circle,
                      color: isDisabled ? Colors.red : Colors.green,
                    ),
                    title: const Text('Status'),
                    subtitle: Text(isDisabled ? 'YAHAGARITSWE' : 'ARAKORA NEZA'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                // NA HANO
                label: const Text('Futa Uyu Mukoresha Burundu'),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, userDocument.id, userEmail);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}