// Code ya: ADMIN PANEL
// Dosiye: lib/main_screen.dart (YAHINDURIWEHO)

// 1. TWONGEREYEMO IYI 'IMPORT' NSHYA
import 'package:app_admin_panel/manage_tv_screen.dart'; 

import 'package:app_admin_panel/analytics_screen.dart';
import 'package:app_admin_panel/announcements_screen.dart';
import 'package:app_admin_panel/chats_screen.dart';
import 'package:app_admin_panel/dashboard_screen.dart';
import 'package:app_admin_panel/feedback_screen.dart';
import 'package:app_admin_panel/users_screen.dart';
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
      
      // 2. TWONGEREYEMO URUPAPURO RWA TV HANO
      const ManageTvScreen(),                       // Index 4
      
      const AnnouncementsScreen(),                  // Index 5 (yahoze ari 4)
      const FeedbackScreen(),                       // Index 6 (yahoze ari 5)
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
      'Urwego Rw\'isonga',
      'Gucunga Abakoresha',
      'Gucunga Ibiganiro',
      'Igenzura Rusangi',

      // 3. TWONGEREYEMO IZINA RY'URUPAPURO RWA TV
      'Gucunga za Television',

      'Kurungika Amatangazo',
      'Imfashanyo n\'Ivyiyumviro'
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
                label: Text('Isonga'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Abakoresha'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Ibiganiro'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Igenzura'),
              ),

              // 4. TWONGEREYEMO BUTO YA TV HANO
              NavigationRailDestination(
                icon: Icon(Icons.tv_outlined),
                selectedIcon: Icon(Icons.tv),
                label: Text('Television'),
              ),

              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Amatangazo'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.feedback_outlined),
                selectedIcon: Icon(Icons.feedback),
                label: Text('Imfashanyo'),
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