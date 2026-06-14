import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. IMPORT UTILS KUGIRA NGO TUbone PASSWORD CHECK
import 'utils/admin_utils.dart';

// 2. IMPORT SCREENS ZOSE
import 'dashboard_screen.dart';       
import 'recovery_requests_screen.dart'; 
import 'users_screen.dart';           
import 'chats_screen.dart';           
import 'analytics_screen.dart';       
import 'manage_tv_screen.dart';        
import 'announcements_screen.dart';   
import 'feedback_screen.dart';        
import 'reported_posts_screen.dart';   
import 'send_broadcast_screen.dart';   
import 'manage_dame_screen.dart';      
import 'manage_star_ads_screen.dart';   
import 'system_control_screen.dart';    

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
    _pages = [
      DashboardScreen(onNavigate: _navigateToPage), // 0
      const RecoveryRequestsScreen(),               // 1
      const UsersScreen(),                          // 2
      const ChatsScreen(),                          // 3
      const AnalyticsScreen(),                      // 4
      const ManageTvScreen(),                       // 5
      const AnnouncementsScreen(),                  // 6
      const FeedbackScreen(),                       // 7
      const ReportedPostsScreen(),                  // 8
      const SendBroadcastScreen(),                  // 9
      const ManageDameScreen(),                     // 10
      const ManageStarAdsScreen(),                  // 11
      const SystemControlScreen(),                  // 12 (Master Control)
    ];
  }

  // Iyi function ifasha Dashboard guhindura paje
  void _navigateToPage(int index) async {
    // Niba paje agiyeho ari Master Control (12), nabwo tubaze Password
    if (index == 12) {
      bool isAuthorized = await AdminUtils.checkMasterPassword(context);
      if (isAuthorized) {
        setState(() => _selectedIndex = index);
      }
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E26), 
        elevation: 4,
        title: const Text(
          "Jembe Talk Admin", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Row(
        children: [
          // SIDEBAR (NAVIGATION RAIL)
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E26),
              border: Border(right: BorderSide(color: Colors.black, width: 0.5))
            ),
            child: LayoutBuilder(
              builder: (context, constraint) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraint.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        backgroundColor: const Color(0xFF1E1E26),
                        selectedIndex: _selectedIndex,
                        // --- HANO NIHO TWASHYIZE LOGIC YA PASSWORD ---
                        onDestinationSelected: (index) async {
                          if (index == 12) {
                            // Baza password mbere yo kwinjira kuri CONTROL
                            bool isAuthorized = await AdminUtils.checkMasterPassword(context);
                            if (isAuthorized) {
                              setState(() => _selectedIndex = index);
                            }
                          } else {
                            setState(() => _selectedIndex = index);
                          }
                        },
                        labelType: NavigationRailLabelType.all,
                        groupAlignment: -1.0, 
                        selectedLabelTextStyle: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        unselectedLabelTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                        selectedIconTheme: const IconThemeData(color: Colors.amber, size: 26),
                        unselectedIconTheme: const IconThemeData(color: Colors.grey, size: 22),
                        indicatorColor: Colors.amber.withOpacity(0.1),
                        destinations: const [
                          NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('DASHBOARD')), // 0
                          NavigationRailDestination(icon: Icon(Icons.published_with_changes), label: Text('KUGARUZA')), // 1
                          NavigationRailDestination(icon: Icon(Icons.group_outlined), label: Text('USERS')), // 2
                          NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('IBIGANIRO')), // 3
                          NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), label: Text('MUMISI 7')), // 4
                          NavigationRailDestination(icon: Icon(Icons.tv_outlined), label: Text('TV')), // 5
                          NavigationRailDestination(icon: Icon(Icons.ads_click), label: Text('ITANGAZO')), // 6
                          NavigationRailDestination(icon: Icon(Icons.feedback_outlined), label: Text('FEEDBACK')), // 7
                          NavigationRailDestination(icon: Icon(Icons.report_gmailerrorred), label: Text('REPORTS')), // 8
                          NavigationRailDestination(icon: Icon(Icons.send_outlined), label: Text('KURI BOSE')), // 9
                          NavigationRailDestination(icon: Icon(Icons.sports_esports_outlined), label: Text('DAME')), // 10
                          NavigationRailDestination(icon: Icon(Icons.star_rounded), label: Text('STARS')), // 11
                          // BUTO YA MASTER CONTROL
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_suggest_rounded, color: Colors.cyanAccent), 
                            label: Text('CONTROL', style: TextStyle(color: Colors.cyanAccent))
                          ), // 12
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // MAIN CONTENT AREA
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