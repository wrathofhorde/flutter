import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';

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
  String _dbStatus = 'Initializing Database...';

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.database;
      setState(() {
        _dbStatus = 'Database Initialized Successfully!';
      });
      debugPrint("DB 초기화 성공: $_dbStatus");
    } catch (e) {
      setState(() {
        _dbStatus = 'Database Initialization Failed: $e';
      });
      debugPrint("DB 초기화 실패: $_dbStatus");
    }
  }

  Future<void> _deleteDatabase() async {
    try {
      await DatabaseHelper().deleteDb();
      setState(() {
        _dbStatus = 'Database Deleted! Re-initializing...';
      });
      await _initializeDatabase();
    } catch (e) {
      setState(() {
        _dbStatus = 'Database Deletion Failed: $e';
      });
      debugPrint("DB 삭제 실패: $e"); // 오류 메시지 추가 (선택 사항)
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Asset Snapshot App')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_dbStatus),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteDatabase,
                child: const Text('Delete and Recreate Database (for testing)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
