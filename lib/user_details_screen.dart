// lib/user_details_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// MENYA: Hindura iri zina rya file niba ryitwa ukundi iwawe
import 'reply_to_feedback_screen.dart'; 

class UserDetailsScreen extends StatelessWidget {
  final DocumentSnapshot userDocument;

  const UserDetailsScreen({super.key, required this.userDocument});

  // Function yo gufuta umukoresha burundu
  Future<void> _deleteUser(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Umukoresha yafuswe burundu."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gufuta vyanse: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Function yo kwerekana ifoto nini
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true, 
                minScale: 0.5,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 25),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String uid, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kwemeza Gufuta', style: TextStyle(color: Colors.red)),
          content: Text(
            'Uzi neza ko ushaka gufuta umukoresha "$email" burundu?\n\n'
            'Iki gikorwa ntigisubirwako, kandi amakuru yiwe yose arazimira.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OYA, SUBIRA INYUMA'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('EGO, FUTA BURUNDU', style: TextStyle(color: Colors.white)),
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
    
    // Gukusanya amakuru yose
    final String userEmail = data['email'] ?? 'Email ntiboneka';
    final String userName = data['displayName'] ?? 'Izina ntiriraboneka';
    final String userPhone = data['phoneNumber'] ?? 'Nta numero';
    final String userUID = data['uid'] ?? userDocument.id;
    final bool isDisabled = data['isDisabled'] ?? false;
    final String? photoUrl = data['photoUrl'];
    
    // Itariki
    final Timestamp? createdAtTimestamp = data['createdAt'];
    String formattedDate = "Itariki ntizwi";
    if (createdAtTimestamp != null) {
      formattedDate = DateFormat('d MMMM y, HH:mm').format(createdAtTimestamp.toDate());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Imyirondoro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // IGICE CYO HEJURU: Ifoto n'Izina
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (photoUrl != null && photoUrl.isNotEmpty) {
                        _showFullImage(context, photoUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Nta foto uyu mukoresha afise.")),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null 
                          ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : "?", style: const TextStyle(fontSize: 30)) 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(userEmail, style: TextStyle(color: Colors.grey.shade600)),
                  if (photoUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        "(Fyonda kwifoto uyirabe neza)",
                        style: TextStyle(color: Colors.blue.shade300, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            
            // IGICE CY'AMAKURU RAMBURAMBU
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Numero ya Telefone'),
                    subtitle: Text(userPhone),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('User ID (UID)'),
                    subtitle: Text(userUID, style: const TextStyle(fontSize: 12)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Yiyandikishije ku wa'),
                    subtitle: Text(formattedDate),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      isDisabled ? Icons.block : Icons.check_circle,
                      color: isDisabled ? Colors.red : Colors.green,
                    ),
                    title: const Text('Status (Imikorere)'),
                    subtitle: Text(
                      isDisabled ? 'YAHAGARITSWE (Blocked)' : 'ARAKORA NEZA (Active)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // IBIKORWA (ACTIONS)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  // BUTO YO KWANDIKIRA (CHAT) - YONGEWE
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text(
                        'Mwandikire (Start Chat)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        // Twifashishije ReplyToFeedbackScreen kugira ngo tumwandikire.
                        // Turamuhereza userDocument nkaho ari feedbackDoc kugira abone UID.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReplyToFeedbackScreen(
                              feedbackDoc: userDocument,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700, // Ibara ry'ubururu
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 15), // Umwanya hagati ya buto
                  
                  // BUTO YO GUFUTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text(
                        'Futa Uyu Mukoresha Burundu',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        _showDeleteConfirmationDialog(context, userUID, userEmail);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}