import 'package:asset_tracker/ui/screens/asset_list_screen.dart';
import 'package:asset_tracker/ui/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // 나중에 각각 별도 파일로 분리된 Screen 위젯으로 교체하세요.
  final List<Widget> _pages = [
    const DashboardScreen(),
    const AssetListScreen(),
    const Center(child: Text('월별기록 화면')),
    const Center(child: Text('설정 화면')),
  ];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool showSidebar = width > 700;

    return Scaffold(
      body: Row(
        children: [
          if (showSidebar)
            NavigationRail(
              extended: width > 1000,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) =>
                  setState(() => _selectedIndex = index),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Icon(
                  Icons.account_balance,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('대시보드'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text('자산관리'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit_calendar),
                  label: Text('월별기록'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('설정'),
                ),
              ],
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Asset Tracker'),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              body: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: showSidebar
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) =>
                  setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: '홈'),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet),
                  label: '자산',
                ),
                NavigationDestination(
                  icon: Icon(Icons.edit_calendar),
                  label: '기록',
                ),
                NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
              ],
            ),
    );
  }
}
