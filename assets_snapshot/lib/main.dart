// lib/main.dart

import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/account_list_screen.dart'; // AccountListScreen 임포트

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // DB 상태는 AccountListScreen에서 관리되므로 여기서는 간단화
  // String _dbStatus = 'Initializing Database...'; // 이제 필요 없음

  @override
  void initState() {
    super.initState();
    _initializeDatabase(); // DB 초기화는 여전히 여기서 수행
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.database; // DB 인스턴스 가져오기 (테이블 생성 포함)
      debugPrint("DB 초기화 성공: Database Initialized Successfully!");
    } catch (e) {
      debugPrint("DB 초기화 실패: $e");
    }
  }

  // main.dart에서는 DB 삭제 버튼을 제거하거나, AccountListScreen으로 옮길 수 있습니다.
  // 여기서는 편의상 main.dart에서 제거합니다.
  /*
  Future<void> _deleteDatabase() async {
    try {
      await DatabaseHelper().deleteDb();
      // 삭제 후 다시 초기화 등의 로직 필요시 추가
      debugPrint('Database Deleted!');
    } catch (e) {
      debugPrint('Database Deletion Failed: $e');
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Snapshot', // 앱 타이틀 설정
      theme: ThemeData(
        primarySwatch: Colors.blue, // 앱 기본 테마 색상 설정
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AccountListScreen(), // 앱 시작 시 AccountListScreen 표시
    );
  }
}
