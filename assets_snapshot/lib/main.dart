// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/account_list_screen.dart';
import 'package:assets_snapshot/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(), // ThemeProvider 인스턴스 생성
      child: const MyApp(), // MyApp 위젯을 ThemeProvider의 자식으로 둠
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.database;
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
    // ThemeProvider의 상태 변화를 감지하여 앱의 테마를 변경
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Asset Snapshot',
      themeMode: themeProvider.themeMode, // ThemeProvider의 themeMode에 따라 테마 변경
      theme: ThemeData.light().copyWith(
        // 라이트 모드 테마 정의
        primaryColor: Colors.blue, // AppBar의 배경색 등을 설정하는 데 사용될 수 있는 기본 색상
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // 라이트 모드 AppBar 배경
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, // 라이트 모드 카드 배경색
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.black87, // 라이트 모드 ListTile 텍스트 색상
          iconColor: Colors.black54, // 라이트 모드 ListTile 아이콘 색상
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // 라이트 모드 버튼 배경색
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87), // 라이트 모드 기본 본문 텍스트 색상
        ),
        // 다른 테마 속성들을 여기에 추가
      ),
      darkTheme: ThemeData.dark().copyWith(
        // 다크 모드 테마 정의 (이전의 크롬 스타일 테마)
        primaryColor: Colors.black, // 다크 모드 기본 색상 (AppBar의 배경색 등에 영향을 줄 수 있음)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black12, // 다크 모드 AppBar 배경
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.grey.shade900, // 다크 모드 카드 배경색
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white, // 다크 모드 ListTile 텍스트 색상
          iconColor: Colors.white70, // 다크 모드 ListTile 아이콘 색상
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade800, // 다크 모드 버튼 배경색
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // 다크 모드 기본 본문 텍스트 색상
        ),
        // 다른 테마 속성들을 여기에 추가
      ),
      home: const AccountListScreen(),
    );
  }
}
