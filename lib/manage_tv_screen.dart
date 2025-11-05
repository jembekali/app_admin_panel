// In lib/manage_tv_screen.dart
// IYI NI CODE YUZUYE NEZA 100% YONGEYEMO BUTO YO KUGENZURA VIDEO

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // IMPORT NSHYA

class ManageTvScreen extends StatefulWidget {
  const ManageTvScreen({super.key});

  @override
  State<ManageTvScreen> createState() => _ManageTvScreenState();
}

class _ManageTvScreenState extends State<ManageTvScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showChannelDialog({DocumentSnapshot? channel}) {
    final nameController = TextEditingController(text: channel?['name'] ?? '');
    final urlController = TextEditingController(text: channel?['streamUrl'] ?? '');
    final videoIdController = TextEditingController(text: channel?['videoId'] ?? '');
    final orderController = TextEditingController(text: channel?['order']?.toString() ?? '');
    
    String selectedType = channel?['type'] ?? 'tv';
    final formKey = GlobalKey<FormState>();

    void _handleYoutubeLink(String link, Function(VoidCallback) setState) {
      final videoId = YoutubePlayer.convertUrlToId(link, trimWhitespaces: true);
      setState(() {
        if (videoId != null && videoId.isNotEmpty) {
          videoIdController.text = videoId;
        } else {
          // Niba umuntu asibye byose, videoId igomba kuba ubusa
          videoIdController.text = '';
        }
      });
    }

    Future<void> _launchURL(String videoId) async {
      final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ntibishoboye gufungura link: $url')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(channel == null ? 'Ongeramo Ikintu Gishya' : 'Hindura Amakuru'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Izina (nka RTNB, Indirimbo ya Meddy)'),
                        validator: (value) => value!.isEmpty ? 'Andika izina' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Ubwoko bw\'igikoresho'),
                        items: const [
                          DropdownMenuItem(value: 'tv', child: Text('Televiziyo Isanzwe')),
                          DropdownMenuItem(value: 'youtube', child: Text('Video ya YouTube')),
                        ],
                        onChanged: (value) {
                          if (value != null) { setDialogState(() { selectedType = value; }); }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedType == 'tv')
                        TextFormField(
                          controller: urlController,
                          decoration: const InputDecoration(labelText: 'Link yuzuye ya TV (Stream URL)'),
                          validator: (value) => value!.isEmpty ? 'Shyiramo link ya TV' : null,
                        )
                      else
                        TextFormField(
                          controller: videoIdController,
                          onChanged: (value) => _handleYoutubeLink(value, setDialogState),
                          decoration: const InputDecoration(labelText: 'Paste Link ya YouTube hano cyangwa ID'),
                          validator: (value) => value!.isEmpty ? 'Shyiramo Video ID cyangwa Link' : null,
                        ),
                      
                      if (selectedType == 'youtube' && videoIdController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text("Genzura iyi Video"),
                              onPressed: () => _launchURL(videoIdController.text),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade300,
                                side: BorderSide(color: Colors.blue.shade300.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                      
                      TextFormField(
                        controller: orderController,
                        decoration: const InputDecoration(labelText: 'Inomero ku rutonde'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => value!.isEmpty ? 'Andika inomero' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Reka'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'name': nameController.text,
                        'order': int.tryParse(orderController.text) ?? 0,
                        'type': selectedType,
                        'streamUrl': selectedType == 'tv' ? urlController.text : '',
                        'videoId': selectedType == 'youtube' ? (YoutubePlayer.convertUrlToId(videoIdController.text, trimWhitespaces: true) ?? videoIdController.text) : '',
                      };
                      final String actionName = nameController.text;
                      final bool isCreating = channel == null;
                      Navigator.pop(context);
                      try {
                        if (isCreating) {
                          await _firestore.collection('tv_channels').add(data);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$actionName' vyongejwemwo neza!"), backgroundColor: Colors.green.shade700));
                        } else {
                          await channel.reference.update(data);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$actionName' vyahinduwe neza!"), backgroundColor: Colors.blue.shade700));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Habaye ikibazo mu kubika amakuru: $e"), backgroundColor: Colors.red.shade900));
                      }
                    }
                  },
                  child: const Text('Bika'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteChannel(DocumentSnapshot channel) {
    final String deletedName = channel['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urifuza gusiba?'),
        content: Text("Ugiye gusiba '$deletedName' burundu."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Oya')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await channel.reference.delete();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$deletedName' vyasibwe neza."), backgroundColor: Colors.red.shade700));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Habaye ikibazo mu gusiba: $e"), backgroundColor: Colors.red.shade900));
              }
            },
            child: const Text('Yego, Siba', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrder(List<DocumentSnapshot> channels) async {
    final WriteBatch batch = _firestore.batch();
    for (int i = 0; i < channels.length; i++) {
      final doc = channels[i];
      batch.update(doc.reference, {'order': i + 1});
    }
    await batch.commit();
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Urutonde rwahinduwe neza!"),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gucunga Televiziyo na Video'),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tv_channels').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Habaye ikibazo mu gukurura amakuru."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nta TV cyangwa Video birongerwamo.\nKanda kuri + hepfo ngo utangire.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          List<DocumentSnapshot> channels = snapshot.data!.docs;

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final data = channel.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'tv';
              final isTv = type == 'tv';

              return Card(
                key: ValueKey(channel.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  title: Text(data['name'] ?? 'Izina ntiriboneka', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isTv ? (data['streamUrl'] ?? '') : 'YouTube ID: ${data['videoId'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("No: ${data['order']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showChannelDialog(channel: channel),
                        tooltip: 'Hindura',
                      ),
                       IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteChannel(channel),
                        tooltip: 'Siba',
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final DocumentSnapshot item = channels.removeAt(oldIndex);
                channels.insert(newIndex, item);
              });
              _updateOrder(channels);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChannelDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ongeramo'),
        tooltip: 'Ongeramo TV cyangwa Video nshya',
      ),
    );
  }
}