// lib/manage_tv_screen.dart (VERSION YUZUYE + REALTIME VIEWERS + CORRECT HINT)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Class ifasha gucunga urutonde rwa YouTube (Playlist Mode)
class PlaylistItem {
  final TextEditingController linkController;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController secondsController;

  PlaylistItem()
      : linkController = TextEditingController(),
        hoursController = TextEditingController(text: '00'),
        minutesController = TextEditingController(text: '00'),
        secondsController = TextEditingController(text: '00');

  void dispose() {
    linkController.dispose();
    hoursController.dispose();
    minutesController.dispose();
    secondsController.dispose();
  }
}

class ManageTvScreen extends StatefulWidget {
  const ManageTvScreen({super.key});
  @override
  State<ManageTvScreen> createState() => _ManageTvScreenState();
}

class _ManageTvScreenState extends State<ManageTvScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseDatabase _realtimeDb;
  bool _dbReady = false; 
  final List<PlaylistItem> _playlistItems = [];

  @override
  void initState() {
    super.initState();
    _initializeRealtimeDb();
  }

  Future<void> _initializeRealtimeDb() async {
    try {
      _realtimeDb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://jembe-talk-1-default-rtdb.firebaseio.com/', 
      );
      if (mounted) setState(() => _dbReady = true);
    } catch (e) {
      _realtimeDb = FirebaseDatabase.instance;
      if (mounted) setState(() => _dbReady = true);
    }
  }

  @override
  void dispose() {
    for (var item in _playlistItems) { item.dispose(); }
    super.dispose();
  }

  // ===========================================================================
  // 1. HELPERS: LOGIC YO GUFATA VIDEO ID
  // ===========================================================================
  String _extractVideoId(String url) {
    url = url.trim();
    if (url.isEmpty) return "";
    String? id = YoutubePlayer.convertUrlToId(url);
    if (id != null && id.length == 11) return id;

    if (url.contains('/live/')) {
      final parts = url.split('/live/');
      if (parts.length > 1) return parts[1].split('?').first.split('&').first;
    }
    if (url.contains('/shorts/')) {
      final parts = url.split('/shorts/');
      if (parts.length > 1) return parts[1].split('?').first.split('&').first;
    }
    return url; 
  }

  // ===========================================================================
  // 2. TICKER MANAGER (DIALOG YO GUHINDURA ITANGAZO)
  // ===========================================================================
  Future<void> _showTickerDialog() async {
    if (!_dbReady) return;
    final msgController = TextEditingController();
    bool isActive = true;
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoading) {
            _realtimeDb.ref('tv_ticker').get().then((snap) {
              if (snap.exists) {
                final data = snap.value as Map;
                msgController.text = data['message'] ?? '';
                if (mounted) setDialogState(() { isActive = data['isActive'] ?? true; isLoading = false; });
              } else {
                if (mounted) setDialogState(() => isLoading = false);
              }
            });
            isLoading = false;
          }
          return AlertDialog(
            title: const Text("Itangazo rya Ticker"),
            content: isLoading ? const Center(child: CircularProgressIndicator()) : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: msgController, decoration: const InputDecoration(labelText: "Ubutumwa", border: OutlineInputBorder())),
                SwitchListTile(title: const Text("Erekana"), value: isActive, onChanged: (v) => setDialogState(() => isActive = v)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("REKA")),
              ElevatedButton(onPressed: () async {
                await _realtimeDb.ref('tv_ticker').set({'message': msgController.text, 'isActive': isActive});
                if (context.mounted) Navigator.pop(context);
              }, child: const Text("BIKA")),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. CHANNEL MANAGER (DIALOG YO KONGERA/GUHINDURA TV)
  // ===========================================================================
  void _showChannelDialog({DocumentSnapshot? channel}) {
    for (var item in _playlistItems) { item.dispose(); }
    _playlistItems.clear();

    final nameController = TextEditingController(text: channel?['name'] ?? '');
    final urlController = TextEditingController(text: channel?['streamUrl'] ?? '');
    final orderController = TextEditingController(text: channel?['order']?.toString() ?? '0');
    String selectedType = channel?['type'] ?? 'tv';
    final formKey = GlobalKey<FormState>();

    if (channel != null) {
      if (channel['type'] == 'youtube_playlist') {
        final playlistData = List<Map<String, dynamic>>.from(channel['playlist'] ?? []);
        for (var itemData in playlistData) {
          final item = PlaylistItem();
          item.linkController.text = itemData['videoId'] ?? '';
          final dur = itemData['duration'] ?? 0;
          item.hoursController.text = (dur ~/ 3600).toString().padLeft(2, '0');
          item.minutesController.text = ((dur % 3600) ~/ 60).toString().padLeft(2, '0');
          item.secondsController.text = (dur % 60).toString().padLeft(2, '0');
          _playlistItems.add(item);
        }
      } else if (channel['type'] == 'youtube') {
        final item = PlaylistItem();
        item.linkController.text = channel['videoId'] ?? '';
        _playlistItems.add(item);
      }
    }
    if (_playlistItems.isEmpty) _playlistItems.add(PlaylistItem());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(channel == null ? 'Ongeramwo Ibishasha' : 'Hindura Amakuru'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Izina rya TV')),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: const [
                        DropdownMenuItem(value: 'tv', child: Text('Television Isanzwe (m3u8)')),
                        DropdownMenuItem(value: 'youtube', child: Text('YouTube (Live/Video IMWE)')),
                        DropdownMenuItem(value: 'youtube_playlist', child: Text('Playlist Mode (TV)')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 10),
                    if (selectedType == 'tv')
                      TextFormField(controller: urlController, decoration: const InputDecoration(labelText: 'Stream URL (m3u8)')),
                    
                    // --- AGACE KABIZOBA MO HINT TEXT NK'UKO IRI KURI PHOTO ---
                    if (selectedType == 'youtube')
                      TextFormField(
                        controller: _playlistItems.first.linkController,
                        decoration: const InputDecoration(
                          labelText: 'YouTube Link (Standard/Live)',
                          hintText: 'https://www.youtube.com/live/...', // IYI NIYO HINT TEXT
                        ),
                      ),
                    
                    if (selectedType == 'youtube_playlist')
                      Column(children: [
                        const Text("Urutonde rw'amavideo:", style: TextStyle(fontWeight: FontWeight.bold)),
                        for (int i = 0; i < _playlistItems.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(children: [
                              Row(children: [
                                Expanded(child: TextFormField(controller: _playlistItems[i].linkController, decoration: const InputDecoration(labelText: 'Video Link/ID', border: OutlineInputBorder(), hintText: 'https://www.youtube.com/watch?v=...'))),
                                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setDialogState(() => _playlistItems.removeAt(i))),
                              ]),
                              const SizedBox(height: 5),
                              Row(children: [
                                const Text("Umwanya: "),
                                Expanded(child: _buildTimeInput(_playlistItems[i].hoursController, "HH")),
                                const Text(":"),
                                Expanded(child: _buildTimeInput(_playlistItems[i].minutesController, "MM")),
                                const Text(":"),
                                Expanded(child: _buildTimeInput(_playlistItems[i].secondsController, "SS")),
                              ])
                            ]),
                          ),
                        TextButton.icon(onPressed: () => setDialogState(() => _playlistItems.add(PlaylistItem())), icon: const Icon(Icons.add), label: const Text("Ongeramwo iyindi video"))
                      ]),
                    const SizedBox(height: 10),
                    TextFormField(controller: orderController, decoration: const InputDecoration(labelText: 'Inomero (Order)'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('REKA')),
            ElevatedButton(onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = {
                  'name': nameController.text,
                  'order': int.tryParse(orderController.text) ?? 0,
                  'type': selectedType,
                  'streamUrl': urlController.text,
                  'videoId': '',
                  'playlist': [],
                };
                if (selectedType == 'youtube') {
                  data['videoId'] = _extractVideoId(_playlistItems.first.linkController.text);
                } else if (selectedType == 'youtube_playlist') {
                  List<Map<String, dynamic>> playlistToSave = [];
                  for (var item in _playlistItems) {
                    final vId = _extractVideoId(item.linkController.text);
                    final dur = (int.parse(item.hoursController.text) * 3600) + (int.parse(item.minutesController.text) * 60) + int.parse(item.secondsController.text);
                    if (vId.isNotEmpty && dur > 0) playlistToSave.add({'videoId': vId, 'duration': dur});
                  }
                  data['playlist'] = playlistToSave;
                }
                if (channel == null) {
                  await _firestore.collection('tv_channels').add(data);
                } else {
                  await channel.reference.update(data);
                }
                if (context.mounted) Navigator.pop(context);
              }
            }, child: const Text('BIKA')),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInput(TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
      decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder(), contentPadding: EdgeInsets.zero),
    );
  }

  // ===========================================================================
  // 4. MAIN BUILD (REALTIME ITEM LIST WITH VIEWERS)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin TV Panel')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tv_channels').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final channels = snapshot.data!.docs;
          return ReorderableListView.builder(
            itemCount: channels.length,
            onReorder: (oldIdx, newIdx) {
              if (oldIdx < newIdx) newIdx -= 1;
              final item = channels.removeAt(oldIdx);
              channels.insert(newIdx, item);
              final batch = _firestore.batch();
              for (int i = 0; i < channels.length; i++) { batch.update(channels[i].reference, {'order': i + 1}); }
              batch.commit();
            },
            itemBuilder: (context, index) {
              final doc = channels[index];
              final data = doc.data() as Map<String, dynamic>;
              final channelId = doc.id;

              return Card(
                key: ValueKey(doc.id),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${data['type']} | Order: ${data['order']}"),
                      
                      // --- KUBARA ABANTU (REALTIME) ---
                      if (_dbReady)
                        StreamBuilder(
                          stream: _realtimeDb.ref('tv_viewers/$channelId').onValue,
                          builder: (context, AsyncSnapshot<DatabaseEvent> viewerSnapshot) {
                            int count = 0;
                            if (viewerSnapshot.hasData && viewerSnapshot.data!.snapshot.value != null) {
                              final viewersMap = viewerSnapshot.data!.snapshot.value as Map;
                              count = viewersMap.length;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.remove_red_eye, size: 14, color: count > 0 ? Colors.green : Colors.grey),
                                  const SizedBox(width: 5),
                                  Text(
                                    "$count Bariko barayiraba",
                                    style: TextStyle(
                                      color: count > 0 ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showChannelDialog(channel: doc)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(heroTag: 'ticker', onPressed: _showTickerDialog, label: const Text("Ticker"), icon: const Icon(Icons.campaign), backgroundColor: Colors.orange),
          const SizedBox(height: 10),
          FloatingActionButton.extended(heroTag: 'add', onPressed: () => _showChannelDialog(), label: const Text("Ongeramwo"), icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}