import 'package:flutter/material.dart';

class LogService extends ChangeNotifier {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<String> _logs = [];
  List<String> get logs => _logs;

  void addLog(String message) {
    _logs.insert(0, message); // 최신 로그가 위로
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
