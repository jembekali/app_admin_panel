// lib/system_control_screen.dart (VERSION 1.1 - FIXED ICON ERROR)

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SystemControlScreen extends StatefulWidget {
  const SystemControlScreen({super.key});

  @override
  State<SystemControlScreen> createState() => _SystemControlScreenState();
}

class _SystemControlScreenState extends State<SystemControlScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://jembe-talk-1-default-rtdb.firebaseio.com",
  );

  final _messageController = TextEditingController();
  final _versionController = TextEditingController();
  final _dateController = TextEditingController();
  
  bool _isMaintenanceMode = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentSettings();
  }

  Future<void> _fetchCurrentSettings() async {
    try {
      final snapshot = await _database.ref('app_settings').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _isMaintenanceMode = data['maintenance_mode'] ?? false;
          _messageController.text = data['maintenance_message'] ?? "";
          _versionController.text = data['latest_version'] ?? "1.0.0";
          _dateController.text = data['release_date'] ?? "";
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _database.ref('app_settings').update({
        'maintenance_mode': _isMaintenanceMode,
        'maintenance_message': _messageController.text.trim(),
        'latest_version': _versionController.text.trim(),
        'release_date': _dateController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Settings zabitswe neza!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ikosa: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text("App Master Control", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- MAINTENANCE SECTION ---
                _buildSectionHeader("AHA HAKORERWA IBIKOGWA BIKOMEYE", Icons.engineering_rounded), // 🔥 KOSORA HANO: e ntoya
                Card(
                  color: const Color(0xFF1E1E26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Funga App Yose", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: const Text("Ibi bituma App yose ifungwa. ntamuntu numwe asubira gukoresha app.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          value: _isMaintenanceMode,
                          activeColor: Colors.amber,
                          onChanged: (val) => setState(() => _isMaintenanceMode = val),
                        ),
                        const Divider(color: Colors.white10),
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "Ubutumwa abakoresha app babona",
                            labelStyle: TextStyle(color: Colors.amber),
                            hintText: "Andika hano...",
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- VERSION SECTION ---
                _buildSectionHeader("APP VERSION & UPDATES", Icons.system_update_rounded),
                Card(
                  color: const Color(0xFF1E1E26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInputField("Latest Version (e.g 1.0.3)", _versionController),
                        const SizedBox(height: 20),
                        _buildInputField("Release Date (ISO Format)", _dateController, hint: "2026-05-09T10:00:00Z"),
                        const SizedBox(height: 10),
                        const Text(
                          "Icitonderwa: inyuma y'iminsi 5 kuva kuri iyi tariki, App izoca yifunga isabe Update.",
                          style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // --- SAVE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                    label: const Text("BIKA IMPINDUKA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, {String? hint}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10), borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}