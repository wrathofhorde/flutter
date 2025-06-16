// lib/main.dart

import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/account_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:assets_snapshot/providers/theme_provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Asset Snapshot',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.black87,
          iconColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        // === 수정된 부분: 라이트 모드 InputDecorationTheme 설정 ===
        inputDecorationTheme: InputDecorationTheme(
          // 입력된 텍스트의 기본 색상
          // 이 부분이 TextField에 입력되는 글자의 색상을 직접 제어합니다.
          // TextField/TextFormField의 style 속성이 우선하지만, 테마 기본값으로 좋습니다.
          // 여기서 입력 텍스트의 기본 색상을 검정색으로 설정합니다.
          // TextField 위젯 자체의 style 속성을 명시적으로 'style: TextStyle(color: Colors.black)'으로 설정하는 것도 좋습니다.
          labelStyle: TextStyle(color: Colors.grey[700]), // 라벨 텍스트 색상
          hintStyle: TextStyle(color: Colors.grey[400]), // 힌트 텍스트 색상
          // 필드의 배경색을 아주 미묘하게 다르게 설정하여 구분감을 줍니다.
          // 너무 흰색이면 배경과 구분이 안 되므로, 살짝 회색을 줍니다.
          filled: true, // 배경색 채움 활성화
          fillColor: Colors.white, // 변경: 아주 연한 회색으로 배경색 설정 (Colors.white 대신)

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
            borderSide: BorderSide(
              color: Colors.blue,
              width: 2.0,
            ), // 포커스 시 파란색 강조
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
        // ========================================================
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black12,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white70,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade800,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        // === 다크 모드 InputDecorationTheme도 필요하다면 여기에 설정 가능 ===
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade800, // 다크 모드 필드 배경색
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade700, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade700, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
          ),
        ),
        // =============================================================
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
