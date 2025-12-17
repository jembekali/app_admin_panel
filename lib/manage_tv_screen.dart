// lib/manage_tv_screen.dart (VERSION YUZUYE: ORDER NUMBER VISIBLE)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Class ifasha gucunga urutonde rwa YouTube
class PlaylistItem {
  TextEditingController linkController;
  TextEditingController hoursController;
  TextEditingController minutesController;
  TextEditingController secondsController;

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

  List<PlaylistItem> _playlistItems = [];

  @override
  void initState() {
    super.initState();
    _initializeRealtimeDb();
  }

  // Method yo gutegura Realtime Database
  Future<void> _initializeRealtimeDb() async {
    try {
      _realtimeDb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        // ⚠️⚠️⚠️ HINDURA HANO: Shyira Link yawe nyayo ya Realtime Database ⚠️⚠️⚠️
        databaseURL: 'https://jembe-talk-default-rtdb.firebaseio.com/', 
      );
      setState(() => _dbReady = true);
    } catch (e) {
      debugPrint("Ikosa rya Database Init: $e");
      // Fallback
      _realtimeDb = FirebaseDatabase.instance;
      setState(() => _dbReady = true);
    }
  }

  @override
  void dispose() {
    for (var item in _playlistItems) {
      item.dispose();
    }
    super.dispose();
  }

  // ===========================================================================
  // 1. TICKER MANAGER (DIALOG YO GUHINDURA ITANGAZO)
  // ===========================================================================
  Future<void> _showTickerDialog() async {
    if (!_dbReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Database nturaboneka, rindiraho gato...")),
      );
      _initializeRealtimeDb();
      return;
    }

    final TextEditingController msgController = TextEditingController();
    bool isActive = true;
    bool isLoadingData = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            if (isLoadingData) {
              _realtimeDb.ref('tv_ticker').get().then((snapshot) {
                if (snapshot.exists) {
                  final data = snapshot.value as Map;
                  msgController.text = data['message'] ?? '';
                  setDialogState(() {
                    isActive = data['isActive'] ?? true;
                    isLoadingData = false;
                  });
                } else {
                  setDialogState(() => isLoadingData = false);
                }
              }).catchError((e) {
                debugPrint("Ikosa ryo gusoma: $e");
                setDialogState(() => isLoadingData = false);
              });
              isLoadingData = false; 
            }

            return AlertDialog(
              title: const Text("Hindura Itangazo (Ticker)"),
              content: isLoadingData 
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Iri tangazo rica riboneka ku ma TV yose ubwo nyene.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: msgController,
                          decoration: const InputDecoration(
                            labelText: "Ubutumwa",
                            hintText: "Akarorero: Ikaze kuri Jembe TV...",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text("Erekana iri tangazo?"),
                          subtitle: Text(isActive ? "Ego (Riboneke)" : "Oya (Ntiriboneke)"),
                          value: isActive,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            setDialogState(() {
                              isActive = val;
                            });
                          },
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Reka"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: isSaving ? null : () async {
                    setDialogState(() => isSaving = true);

                    try {
                      await _realtimeDb.ref('tv_ticker').set({
                        'message': msgController.text,
                        'isActive': isActive,
                      });
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Itangazo ryahindutse neza!"), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      debugPrint("Ikosa ryo kubika: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Vyanse kubika: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Bika & Tangaza", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 2. CHANNEL MANAGER (DIALOG YO KONGERA/GUHINDURA TV)
  // ===========================================================================
  void _showChannelDialog({DocumentSnapshot? channel}) {
    for (var item in _playlistItems) {
      item.dispose();
    }
    _playlistItems.clear();

    final nameController = TextEditingController(text: channel?['name'] ?? '');
    final urlController = TextEditingController(text: channel?['streamUrl'] ?? '');
    // Hano orderController izajya yerekana order isanzwe, cyangwa ubusa
    final orderController = TextEditingController(text: channel?['order']?.toString() ?? '');
    String selectedType = channel?['type'] ?? 'tv';
    final formKey = GlobalKey<FormState>();

    if (channel != null && channel['type'] == 'youtube_playlist') {
      final playlistData = List<Map<String, dynamic>>.from(channel['playlist'] ?? []);
      for (var itemData in playlistData) {
        final playlistItem = PlaylistItem();
        playlistItem.linkController.text = itemData['videoId'] ?? '';

        final totalSeconds = itemData['duration'] ?? 0;
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;

        playlistItem.hoursController.text = hours.toString().padLeft(2, '0');
        playlistItem.minutesController.text = minutes.toString().padLeft(2, '0');
        playlistItem.secondsController.text = seconds.toString().padLeft(2, '0');

        _playlistItems.add(playlistItem);
      }
    } else if (channel != null && channel['type'] == 'youtube') {
      final playlistItem = PlaylistItem();
      playlistItem.linkController.text = channel['videoId'] ?? '';
      _playlistItems.add(playlistItem);
    }

    if (_playlistItems.isEmpty) {
      _playlistItems.add(PlaylistItem());
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(channel == null ? 'Ongeramwo Ikintu Gishasha' : 'Hindura Amakuru'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Izina (nka RTNB, Indirimbo za Jembe Kali)'),
                          validator: (value) => value!.isEmpty ? 'Andika izina' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Ubwoko bw\'igikoresho'),
                          items: const [
                            DropdownMenuItem(value: 'tv', child: Text('Television Isanzwe')),
                            DropdownMenuItem(value: 'youtube', child: Text('Video IMWE ya YouTube')),
                            DropdownMenuItem(value: 'youtube_playlist', child: Text('Urutonde gwa YouTube (TV)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (selectedType == 'youtube_playlist')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Urutonde gw'amasanamu:", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _playlistItems.length,
                                itemBuilder: (context, index) {
                                  final item = _playlistItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: item.linkController,
                                                decoration: const InputDecoration(labelText: 'Link canke ID ya YouTube', border: OutlineInputBorder()),
                                                validator: (v) => v!.isEmpty ? 'Vuzura' : null,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                              onPressed: () {
                                                setDialogState(() {
                                                  if (_playlistItems.length > 1) {
                                                    _playlistItems[index].dispose();
                                                    _playlistItems.removeAt(index);
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text("Umwanya: "),
                                            Expanded(child: _buildTimeInput(item.hoursController, "HH")),
                                            const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text(":")),
                                            Expanded(child: _buildTimeInput(item.minutesController, "MM")),
                                            const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text(":")),
                                            Expanded(child: _buildTimeInput(item.secondsController, "SS")),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("Ongeramwo iyindi video"),
                                onPressed: () {
                                  setDialogState(() {
                                    _playlistItems.add(PlaylistItem());
                                  });
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                              ),
                            ],
                          ),
                        if (selectedType == 'tv')
                          TextFormField(
                            controller: urlController,
                            decoration: const InputDecoration(labelText: 'Link yuzuye ya TV (Stream URL)'),
                            validator: (value) => value!.isEmpty ? 'Shiramwo link ya TV' : null,
                          ),
                        if (selectedType == 'youtube')
                          TextFormField(
                            controller: _playlistItems.first.linkController,
                            decoration: const InputDecoration(labelText: 'Paste Link ya YouTube hano canke ID'),
                            validator: (value) => value!.isEmpty ? 'Shiramwo Video ID canke Link' : null,
                          ),
                        
                        // Hano Umuyobozi ashyiramo nimero niba abishaka
                        TextFormField(
                          controller: orderController,
                          decoration: const InputDecoration(labelText: 'Inomero ku rutonde (Order)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) => value!.isEmpty ? 'Andika inomero' : null,
                        ),
                      ],
                    ),
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
                        'streamUrl': '',
                        'videoId': '',
                        'playlist': [],
                      };

                      if (selectedType == 'tv') {
                        data['streamUrl'] = urlController.text;
                      } else if (selectedType == 'youtube') {
                        data['videoId'] = YoutubePlayer.convertUrlToId(_playlistItems.first.linkController.text, trimWhitespaces: true) ?? _playlistItems.first.linkController.text;
                      } else if (selectedType == 'youtube_playlist') {
                        List<Map<String, dynamic>> playlistToSave = [];
                        for (var item in _playlistItems) {
                          final videoId = YoutubePlayer.convertUrlToId(item.linkController.text, trimWhitespaces: true) ?? item.linkController.text;
                          final hours = int.tryParse(item.hoursController.text) ?? 0;
                          final minutes = int.tryParse(item.minutesController.text) ?? 0;
                          final seconds = int.tryParse(item.secondsController.text) ?? 0;
                          final durationInSeconds = (hours * 3600) + (minutes * 60) + seconds;

                          if (videoId.isNotEmpty && durationInSeconds > 0) {
                            playlistToSave.add({
                              'videoId': videoId,
                              'duration': durationInSeconds,
                            });
                          }
                        }
                        data['playlist'] = playlistToSave;
                      }

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

  Widget _buildTimeInput(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(8),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Eka!';
        }
        if (hint == 'MM' || hint == 'SS') {
          final number = int.tryParse(value);
          if (number == null || number > 59) {
            return '>59?';
          }
        }
        return null;
      },
    );
  }

  void _deleteChannel(DocumentSnapshot channel) {
    final String deletedName = channel['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urifuza gufuta?'),
        content: Text("Ugiye gufuta '$deletedName' burundu."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Oya')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await channel.reference.delete();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$deletedName' vyafuswe neza."), backgroundColor: Colors.red.shade700));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Habaye ikibazo mu gufuta: $e"), backgroundColor: Colors.red.shade900));
              }
            },
            child: const Text('Ego, Futa', style: TextStyle(color: Colors.red)),
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
        title: const Text('Kugenzura Television na Video'),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tv_channels').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Habaye ikibazo mu kubona amakuru."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nta TV canke Video birongegwamwo.\nfyonda kuri + hepfo ngo utangure.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          List<DocumentSnapshot> channels = snapshot.data!.docs;

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final data = channel.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'tv';
              final docId = channel.id;

              String subtitle = '';
              if (type == 'tv') {
                subtitle = data['streamUrl'] ?? '';
              } else if (type == 'youtube') {
                subtitle = 'YouTube ID: ${data['videoId'] ?? ''}';
              } else if (type == 'youtube_playlist') {
                final count = (data['playlist'] as List?)?.length ?? 0;
                subtitle = "Urutonde rw'amasanamu $count";
              }

              return Card(
                key: ValueKey(channel.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, color: Colors.white70),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Izina ntiriboneka',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        
                        if (_dbReady)
                          StreamBuilder<DatabaseEvent>(
                            stream: _realtimeDb.ref('tv_viewers/$docId').onValue,
                            builder: (context, viewerSnapshot) {
                              int viewerCount = 0;
                              if (viewerSnapshot.hasData && viewerSnapshot.data!.snapshot.value != null) {
                                final viewerData = viewerSnapshot.data!.snapshot.value;
                                if (viewerData is Map) {
                                  viewerCount = viewerData.length;
                                }
                              }
                              
                              final bool isLive = viewerCount > 0;
                              
                              return Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isLive ? Colors.red.shade700 : Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isLive 
                                    ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)] 
                                    : [],
                                  border: Border.all(
                                    color: isLive ? Colors.redAccent : Colors.grey.shade700,
                                    width: 1.5
                                  )
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.visibility, 
                                      size: 18, 
                                      color: Colors.white
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$viewerCount", 
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 15
                                      )
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    
                    // =========================================================
                    // 3. ORDER NUMBER (YONGEWEMO HANO: Visible Number)
                    // =========================================================
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Aho inomero yanditse neza
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(right: 12), // Umwanya mbere y'ama buto
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5))
                          ),
                          child: Text(
                            "#${data['order'] ?? 0}", // Yerekana #1, #2, etc.
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Colors.blueAccent,
                              fontSize: 14
                            ),
                          ),
                        ),
                        
                        // Ama buto asanzwe
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 24, color: Colors.blueAccent),
                          onPressed: () => _showChannelDialog(channel: channel),
                          tooltip: 'Hindura',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                          onPressed: () => _deleteChannel(channel),
                          tooltip: 'Futa',
                        ),
                      ],
                    ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ticker_btn',
            onPressed: _showTickerDialog,
            icon: const Icon(Icons.campaign),
            label: const Text('Itangazo (Ticker)'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_tv_btn',
            onPressed: () => _showChannelDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ongeramwo'),
            backgroundColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}