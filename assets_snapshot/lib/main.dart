// lib/main.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // defaultTargetPlatform 사용
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:responsive_framework/responsive_framework.dart'; // ResponsiveFramework 임포트

import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/account_list_screen.dart';
import 'package:window_manager/window_manager.dart'; // window_manager 임포트

// MyApp 클래스 정의 시작 (StatefulWidget)
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // GlobalKey<NavigatorState>를 MyApp 클래스의 static 필드로 선언
  // 이렇게 해야 MyApp.navigatorKey로 어디서든 접근할 수 있습니다.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // initState에서 중복되는 데이터베이스 초기화 로직은 제거합니다.
  // main 함수에서 이미 데이터베이스 초기화를 시도하고 있습니다.
  @override
  void initState() {
    super.initState();
    // _initializeDatabase(); // 이 줄은 제거합니다.
  }

  // 이 _initializeDatabase 메서드는 더 이상 사용되지 않으므로 제거하거나,
  // MyApp 위젯 내부에서 필요한 다른 초기화 로직이 있다면 사용하세요.
  // 현재는 main 함수에서 데이터베이스 초기화를 담당하고 있습니다.
  // Future<void> _initializeDatabase() async {
  //   try {
  //     final dbHelper = DatabaseHelper();
  //     await dbHelper.database;
  //     debugPrint("DB 초기화 성공: Database Initialized Successfully!");
  //   } catch (e) {
  //     debugPrint("DB 초기화 실패: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return _materialTheme;
  }

  MaterialApp get _materialTheme {
    return MaterialApp(
      // title: '자산 관리',
      debugShowCheckedModeBanner: false, // 디버그 배너 제거 (선택 사항)
      // MaterialApp의 navigatorKey 속성에 MyApp.navigatorKey를 연결합니다.
      navigatorKey: MyApp.navigatorKey, // static 필드 접근
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

// main 함수
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데스크톱 환경에서 sqflite_common_ffi 초기화 로직은 유지
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    debugPrint('sqfliteFfiInit()');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // WindowManager 초기화 및 창 제목 설정
    await windowManager.ensureInitialized();
    debugPrint('windowManager.ensureInitialized()');
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768), // 초기 창 크기 설정 (선택 사항)
      center: true, // 창을 화면 중앙에 위치 (선택 사항)
      titleBarStyle: TitleBarStyle.normal, // 타이틀 바 스타일
    );

    debugPrint('Database initializing...');
    // 순서 변경하지 말것.
    // 앱이 실행되기 이전에 데이타베이스가 초기화 되어야 함
    try {
      await DatabaseHelper().database; // 데이터베이스 인스턴스를 얻으려고 시도 -> 없으면 생성
      debugPrint('Database initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize database: $e');

      // 데이터베이스 초기화 실패 시 다이얼로그 표시 및 앱 종료 로직
      // runApp을 먼저 호출하여 앱의 기본 위젯 트리를 구성합니다.
      // 그래야 BuildContext를 사용할 수 있습니다.
      runApp(const MyApp()); // 앱을 먼저 실행하여 BuildContext를 사용할 수 있도록 합니다.

      // 데이터베이스 초기화 실패 다이얼로그는 다음 프레임이 빌드된 후 실행되도록 예약
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: MyApp
              .navigatorKey
              .currentState!
              .overlay!
              .context, // GlobalKey를 통해 context 접근
          barrierDismissible: false, // 사용자가 다이얼로그 밖을 탭하여 닫을 수 없도록 설정
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('오류 발생'),
              content: Text('데이터베이스 초기화에 실패했습니다: $e\n앱을 종료합니다.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                    exit(0); // 앱 종료
                  },
                ),
              ],
            );
          },
        );
      });
      return; // 데이터베이스 초기화 실패 시 runApp 이후 로직 실행 방지
    }

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setTitle('자산 관리'); // 한글 제목 설정
    });
    debugPrint('windowManager.waitUntilReadyToShow');
  }

  runApp(const MyApp());
}
