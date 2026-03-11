import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/database_service.dart';
import 'ui/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Isar DB 초기화
  await DatabaseService.initialize();

  // 2. 윈도우 매니저 초기화
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    minimumSize: Size(800, 600),
    center: true,
    title: "Asset Tracker",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const AssetTrackerApp());
}

class AssetTrackerApp extends StatelessWidget {
  const AssetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const MainLayout(),
    );
  }
}
