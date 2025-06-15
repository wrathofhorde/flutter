// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // 기본값은 시스템 테마 따르기

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode(); // 생성 시 저장된 테마 모드를 불러옴
  }

  // 저장된 테마 모드를 불러오는 비동기 함수
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString =
        prefs.getString('themeMode') ??
        ThemeMode.system.toString(); // 저장된 값 없으면 system
    _themeMode = _getThemeModeFromString(themeString);
    notifyListeners(); // 변경 사항을 리스너들에게 알림
  }

  // 테마 모드를 설정하고 저장하는 함수
  void setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return; // 동일한 모드면 변경하지 않음

    _themeMode = mode;
    notifyListeners(); // UI 갱신을 위해 리스너들에게 알림

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString()); // 변경된 테마 모드를 저장
  }

  // String을 ThemeMode로 변환
  ThemeMode _getThemeModeFromString(String themeString) {
    if (themeString == ThemeMode.light.toString()) {
      return ThemeMode.light;
    } else if (themeString == ThemeMode.dark.toString()) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system;
    }
  }
}
