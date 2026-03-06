import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 윈도우 매니저 초기화
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800), // 초기 가로, 세로
    center: true,
    title: "Asset Tracker",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const AssetTrackerApp());
  runApp(const AssetTrackerApp());
}

class AssetTrackerApp extends StatelessWidget {
  const AssetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // 표시할 페이지들
  final List<Widget> _pages = [
    const Center(child: Text('대시보드 (차트 및 요약)')),
    const Center(child: Text('자산 목록 (금융사/종목 관리)')),
    const Center(child: Text('월별 기록 (데이터 입력)')),
    const Center(child: Text('설정')),
  ];

  @override
  Widget build(BuildContext context) {
    // 화면 너비 확인
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 900; // 태블릿/데스크톱 기준

    return Scaffold(
      appBar: AppBar(title: const Text('Asset Tracker'), elevation: 1),
      body: Row(
        children: [
          // 1. 데스크톱용 사이드바 (NavigationRail)
          if (isDesktop)
            NavigationRail(
              extended: width > 1200, // 화면이 아주 넓으면 글자도 표시
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
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
          // 2. 메인 컨텐츠 영역
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      // 3. 모바일/작은 태블릿용 하단 탭바
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
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
