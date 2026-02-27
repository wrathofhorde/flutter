import 'dart:io'; // Platform 사용을 위해 필수!
import 'package:block_balance/screens/inquiry_screen.dart';
import 'package:block_balance/screens/wallet_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // windowManager 사용을 위해 필요

// pol HOT: 0xc8f7787d062a91a5367dde72b35eeb5da807102d
// eth hot : 0x545b7b7e9372ea6ddc805c0cdee3025eee1880b1

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 윈도우 크기 조정 (Desktop 전용)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 1000), // 폭을 900으로 줄이고 높이를 1000으로 확대
      center: true,
      title: "Block Balance Manager",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
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
