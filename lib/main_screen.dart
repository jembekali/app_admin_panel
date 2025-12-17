// lib/main_screen.dart (VERSION YUZUYE - NA BROADCAST)

import 'package:app_admin_panel/manage_tv_screen.dart';
import 'package:app_admin_panel/analytics_screen.dart';
import 'package:app_admin_panel/announcements_screen.dart';
import 'package:app_admin_panel/chats_screen.dart';
import 'package:app_admin_panel/dashboard_screen.dart';
import 'package:app_admin_panel/feedback_screen.dart';
import 'package:app_admin_panel/reported_posts_screen.dart';
import 'package:app_admin_panel/users_screen.dart';
// ===> IMPORT NSHYA <===
import 'package:app_admin_panel/send_broadcast_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      DashboardScreen(onNavigate: _navigateToPage), // Index 0
      const UsersScreen(),                          // Index 1
      const ChatsScreen(),                          // Index 2
      const AnalyticsScreen(),                      // Index 3
      const ManageTvScreen(),                       // Index 4
      const AnnouncementsScreen(),                  // Index 5
      const FeedbackScreen(),                       // Index 6
      const ReportedPostsScreen(),                  // Index 7
      // ===> URUPAPURO RWA BROADCAST <===
      const SendBroadcastScreen(),                  // Index 8
    ];
  }

  void _navigateToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pageTitles = [
      'Urwego Gw\'intango',
      'Kugenzura Abakoresha',
      'Kugenzura Ibiganiro',
      'Igenzura Rusangi',
      'Kugenzura Television',
      'Kurungika Amatangazo',
      'Imfashanyo n\'Ivyiyumviro',
      'Kugenzura Ibirego',
      // ===> TITRE NSHASHA <===
      'Kwandikira Bose'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            tooltip: 'Sohoka',
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              _navigateToPage(index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('ITANGURIRO'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('ABAKORESHA'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('IBIGANIRO'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('IGENZURA'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tv_outlined),
                selectedIcon: Icon(Icons.tv),
                label: Text('TELEVISION'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('AMATANGAZO'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.feedback_outlined),
                selectedIcon: Icon(Icons.feedback),
                label: Text('IMFASHANYO'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report_problem_outlined),
                selectedIcon: Icon(Icons.report_problem),
                label: Text('IBIREGO'),
              ),
              // ===> BUTO NSHYA YO KWANDIKIRA BOSE <===
              NavigationRailDestination(
                icon: Icon(Icons.mark_chat_unread_outlined),
                selectedIcon: Icon(Icons.mark_chat_unread),
                label: Text('BROADCAST'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}