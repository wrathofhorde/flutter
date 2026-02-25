import 'package:flutter/material.dart';
import 'screens/wallet_management_screen.dart';
import 'screens/inquiry_screen.dart';

// pol HOT: 0xc8f7787d062a91a5367dde72b35eeb5da807102d
// eth hot : 0x545b7b7e9372ea6ddc805c0cdee3025eee1880b1

void main() {
  // 위젯 바인딩 초기화 (윈도우 앱 안정성)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlockBalanceApp());
}

class BlockBalanceApp extends StatelessWidget {
  const BlockBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Balance Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true, // 최신 UI 스타일 적용
      ),
      home: const HomeScreen(), // 실제 메인 탭 화면 호출
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Block Balance Manager'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_balance_wallet), text: '지갑 관리'),
              Tab(icon: Icon(Icons.list_alt), text: '내역 조회'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [WalletManagementScreen(), InquiryScreen()],
        ),
      ),
    );
  }
}
