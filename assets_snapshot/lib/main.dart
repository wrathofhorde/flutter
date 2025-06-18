// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/account_list_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데스크톱 환경에서 sqflite_common_ffi 초기화 로직은 유지
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // WindowManager 초기화 및 창 제목 설정
    await windowManager.ensureInitialized(); // <-- windowManager 초기화

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768), // 초기 창 크기 설정 (선택 사항)
      center: true, // 창을 화면 중앙에 위치 (선택 사항)
      // skipTaskbar: false, // 작업 표시줄에 표시 (기본값)
      titleBarStyle: TitleBarStyle.normal, // 타이틀 바 스타일
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setTitle('자산 관리'); // <-- 여기에 원하는 한글 제목 설정
    });
  }

  runApp(const MyApp());
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

  @override
  Widget build(BuildContext context) {
    return _materialTheme;
  }

  MaterialApp get _materialTheme {
    return MaterialApp(
      // title: '자산 관리',
      debugShowCheckedModeBanner: false, // 디버그 배너 제거 (선택 사항)
      theme: ThemeData.light(useMaterial3: true).copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white), // 앱바 아이콘 색상
        ),

        cardTheme: CardThemeData(
          color: Colors.white, // 카드 배경색을 흰색으로 고정
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        listTileTheme: const ListTileThemeData(
          textColor: Colors.black87, // ListTile 텍스트 색상
          iconColor: Colors.black54, // ListTile 아이콘 색상
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // 버튼 배경색을 라이트 모드 기본색으로
            foregroundColor: Colors.white, // 버튼 텍스트 색상
          ),
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87), // 기본 본문 텍스트 색상
        ),

        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.grey[700]), // 라벨 텍스트 색상
          hintStyle: TextStyle(color: Colors.grey[400]), // 힌트 텍스트 색상
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
      ),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1000, name: TABLET),
          const Breakpoint(start: 1001, end: 1200, name: DESKTOP),
          const Breakpoint(start: 1201, end: double.infinity, name: DESKTOP),
        ],
      ),
      home: const AccountListScreen(),
    );
  }
}
