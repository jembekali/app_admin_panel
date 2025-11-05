// Code ya: ADMIN PANEL
// Dosiye: lib/dashboard_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  // TWONGEYEMWO IYI VARIABULU KUGIRA TWAKIRE YA FUNCTION
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
                    onTap: () => onNavigate(1), // Iyo bakanze hano, tuja ku rupapuro rw'abakoresha (index 1)
                  );
                },
              ),
              // Abari ku Murongo
              StatCard(
                icon: Icons.wifi,
                color: Colors.green,
                count: '0',
                title: 'Abari ku Murongo',
                onTap: () {}, // Nta c'irahakora ubu
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
                    // HANO NI HO HAHINDUTSE CYANE
                    onTap: () {
                      // Turabwira MainScreen ngo idushire ku rupapuro rw'imfashanyo (index 5)
                      onNavigate(5);
                    },
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
            child: Text('Ahazaza hano ibikorwa vya vuba...'),
          ),
        ],
      ),
    );
  }
}

// Widget yo kwubaka za karata
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String count;
  final String title;
  final VoidCallback onTap; // Twongeyemwo iyi function

  const StatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
    required this.title,
    required this.onTap, // Na hano nyene
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Turakoresha iyo function hano
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