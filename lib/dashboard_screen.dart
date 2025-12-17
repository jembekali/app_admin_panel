// lib/dashboard_screen.dart (VERSION YAKIRIYE IBIREGO)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Mwaramutse, Muyobozi!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              // Abakoresha Bose
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return StatCard(
                    icon: Icons.people,
                    color: Colors.blue,
                    count: count.toString(),
                    title: 'Abakoresha Bose',
                    onTap: () => onNavigate(1), // Ija ku bakoresha (index 1)
                  );
                },
              ),
              // Abari ku Murongo
              StatCard(
                icon: Icons.wifi,
                color: Colors.green,
                count: '0',
                title: 'Abari ku Murongo',
                onTap: () {},
              ),
              // Ubutumwa Butarakemuka
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feedback')
                    .where('isResolved', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return StatCard(
                    icon: Icons.question_mark_rounded,
                    color: Colors.orange,
                    count: count.toString(),
                    title: 'Ubutumwa Butarakemuka',
                    onTap: () => onNavigate(6), // Ija ku mfashanyo (index 6, ntiyari 5)
                  );
                },
              ),

              // =========================================================
              // =====> IYI NI YO KARATA NSHASHA Y'IBIREGO <=====
              // =========================================================
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('post_reports').where('status', isEqualTo: 'pending').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return StatCard(
                    icon: Icons.report_problem,
                    // Ibara rirahinduka iyo hari ikirego gishasha
                    color: count > 0 ? Colors.redAccent : Colors.teal,
                    count: count.toString(),
                    title: 'Ibirego Bishasha',
                    // Iyo bayikanze, ija ku rupapuro rw'ibirego (index 7)
                    onTap: () => onNavigate(7),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(),
          Text(
            'Ibikorwa vya Vuba',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Aha hazoza ibikorwa vya vuba...'),
          ),
        ],
      ),
    );
  }
}

// Widget yo kwubaka za karata (Iyi ntihinduka)
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String count;
  final String title;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}