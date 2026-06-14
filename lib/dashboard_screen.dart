import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb; 
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'system_control_screen.dart'; 
import 'utils/admin_utils.dart'; 

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final rtdb.FirebaseDatabase _realtimeDb;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initializeDb();
  }

  void _initializeDb() {
    try {
      _realtimeDb = rtdb.FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.rtdbUrl,
      );
      setState(() => _dbReady = true);
    } catch (e) {
      _realtimeDb = rtdb.FirebaseDatabase.instance;
      setState(() => _dbReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) return const Center(child: CircularProgressIndicator(color: Colors.amber));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: ListView(
        padding: const EdgeInsets.all(30.0),
        children: [
          const Center(
            child: Column(
              children: [
                Text('Jembe Talk, Admin!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Raba incamake y'uko App ya Jembe Talk imeze uyu munsi.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Wrap(
            spacing: 20.0, runSpacing: 20.0,
            alignment: WrapAlignment.center,
            children: [
              
              // 1. ABAKORESHA BOSE (Aggregated count)
              _buildOptimizedCount(
                collection: 'users',
                icon: Icons.group,
                color: Colors.blueAccent,
                title: 'Abakoresha Bose Jembe Talk',
                index: 2,
              ),

              // 2. ABARI KU MURONGO (RTDB - Ubuntu)
              StreamBuilder<rtdb.DatabaseEvent>(
                stream: _realtimeDb.ref('status').onValue,
                builder: (context, snapshot) {
                  int onlineCount = 0;
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final rawData = snapshot.data!.snapshot.value as Map;
                    rawData.forEach((key, value) {
                      if (value is Map && value['state'] == 'online') onlineCount++;
                    });
                  }
                  return _buildCustomStatCard(icon: Icons.wifi, color: Colors.green, count: onlineCount.toString(), title: 'Abari ku Murongo', onTap: () => widget.onNavigate(2));
                },
              ),

              // 🔥 3. APP MASTER CONTROL (KOSORA HANO IZINA RIGARAGARE RYOSE)
              StreamBuilder<rtdb.DatabaseEvent>(
                stream: _realtimeDb.ref('app_settings/maintenance_mode').onValue,
                builder: (context, snapshot) {
                  bool isOn = false;
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    isOn = snapshot.data!.snapshot.value as bool;
                  }
                  return _buildCustomStatCard(
                    icon: Icons.settings_suggest_rounded, 
                    color: isOn ? Colors.redAccent : Colors.amber, 
                    count: isOn ? "ON" : "OFF", 
                    title: 'App Version, Force Update, Lock App', // 👈 IZINA RIGARAGARA RYOSE UBU
                    onTap: () async {
                      bool isAuthorized = await AdminUtils.checkMasterPassword(context);
                      if (isAuthorized && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const SystemControlScreen()));
                      }
                    }
                  );
                },
              ),

              // 4. IBIBAZO BISHASHA
              _buildOptimizedCount(
                collection: 'feedback',
                filterField: 'isResolved',
                filterValue: false,
                icon: Icons.question_answer,
                color: Colors.orange,
                title: 'Ibibazo Bishasha',
                index: 7,
              ),

              // 5. IBIREGO BISHASHA
              _buildOptimizedCount(
                collection: 'post_reports',
                filterField: 'status',
                filterValue: 'pending',
                icon: Icons.error_outline,
                color: Colors.redAccent,
                title: 'Ibirego Bishasha',
                index: 8,
              ),

              // 6. KUGARUZA KONTE
              _buildOptimizedCount(
                collection: 'recovery_requests',
                icon: Icons.sync,
                color: Colors.cyan,
                title: 'Kugaruza Konte',
                index: 1,
              ),
            ],
          ),

          const SizedBox(height: 50),
          const Text('Ibikorwa vya Vuba', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildActivityPlaceholder(),
        ],
      ),
    );
  }

  // --- HELPER: OPTIMIZED COUNT (.count()) ---
  Widget _buildOptimizedCount({
    required String collection, 
    String? filterField, 
    dynamic filterValue, 
    required IconData icon, 
    required Color color, 
    required String title, 
    required int index
  }) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (filterField != null) {
      query = query.where(filterField, isEqualTo: filterValue);
    }

    return FutureBuilder<AggregateQuerySnapshot>(
      future: query.count().get(),
      builder: (context, snapshot) {
        final count = snapshot.data?.count ?? 0;
        return _buildCustomStatCard(
          icon: icon, 
          color: color, 
          count: count.toString(), 
          title: title, 
          onTap: () => widget.onNavigate(index)
        );
      },
    );
  }

  // --- UI HELPER: STAT CARD (RE-SIZED FOR LONG TITLES) ---
  Widget _buildCustomStatCard({required IconData icon, required Color color, required String count, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 300, // 🔥 ONGERA UBUGARI (Kuva 240 tujya 300)
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: Colors.white.withOpacity(0.05))
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Uburinganire
          children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
              child: Icon(icon, color: color, size: 28)
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(
                    title, 
                    style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5), 
                    maxLines: 2, // 🔥 BITUMA IMIRONGO IBA 2 NIBA ARI MUREMURE
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ]
              )
            )
          ]
        ),
      ),
    );
  }

  Widget _buildActivityPlaceholder() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(40), 
      decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(15)), 
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.white10, size: 50),
          SizedBox(height: 10),
          Text('Nta gikogwa gisha sha kiragaragara uyu munsi.', style: TextStyle(color: Colors.grey)),
        ],
      )
    );
  }
}