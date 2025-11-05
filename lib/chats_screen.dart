import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tugiye gukoresha StreamBuilder nk'uko twabigize ku bakoresha
    return StreamBuilder<QuerySnapshot>(
      // Turaja muri collection yitwa 'chat_rooms'
      stream: FirebaseFirestore.instance.collection('chat_rooms').snapshots(),
      builder: (context, snapshot) {
        // Igihe iriko irarindira amakuru
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Niba habaye ikibazo
        if (snapshot.hasError) {
          return const Center(child: Text('Habaye ikibazo mu gukurura ibiganiro'));
        }

        // Niba ata kiganiro na kimwe kiri muri database
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nta kiganiro na kimwe kiraboneka'));
        }

        // Niba vyose vyagenze neza, yerekane urutonde
        final chatRooms = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            
            // ID y'ikiganiro ni yo irimwo za UID z'abantu barimwo
            // Akenshi iba imeze nka: UID_umuntu_wa_1_UID_umuntu_wa_2
            final String chatRoomId = chatRoom.id;

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.chat)),
              title: const Text('Ikiganiro Hagati ya:'),
              subtitle: Text(chatRoomId.replaceAll('_', '\nna\n')), // Tuvuga ngo 'umuntu na umuntu'
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Turaza gukora igikorwa co kwinjira mu kiganiro niwakanda hano
                print('Ukanze ku kiganiro gifise ID: $chatRoomId');
              },
            );
          },
        );
      },
    );
  }
}