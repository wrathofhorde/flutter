import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

DateTime get startOfToday {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class Days {
  static const String _dateFormat = 'yyyy-MM-dd';

  late DateTime _today;
  late DateTime _yesterday;
  late DateTime _firstDayOfMonth; // 이달의 1일
  late DateTime _lastDayOfPreviousMonth; // 직전달 마지막 날
  late DateTime _firstDayOfLastYear; // 1년 전 이달의 1일
  late DateTime _lastUpdateDay; // 마지막 종가 업데이트 날

  Days(String? lastUpdate) {
    // 오늘 날짜의 시작 (자정)
    _today = startOfToday;
    _yesterday = _today.subtract(const Duration(days: 1));
    // 이달의 1일
    _firstDayOfMonth = DateTime(_today.year, _today.month, 1);
    // 직전달 마지막 날
    _lastDayOfPreviousMonth = _firstDayOfMonth.subtract(
      const Duration(days: 1),
    );
    // 1년 전 이달의 1일
    _firstDayOfLastYear = DateTime(
      _firstDayOfMonth.year - 1,
      _firstDayOfMonth.month,
      _firstDayOfMonth.day,
    );
    final String lastUpdateDay = lastUpdate ?? "2021-01-01";
    _lastUpdateDay = DateTime.parse(lastUpdateDay);
  }

  String get today {
    final formatter = DateFormat(_dateFormat);
    return formatter.format(_today);
  }

  String get yesterday {
    final formatter = DateFormat(_dateFormat);
    return formatter.format(_yesterday);
  }

  String get startDay {
    final formatter = DateFormat(_dateFormat);
    return formatter.format(_firstDayOfLastYear);
  }

  String get endDay {
    final formatter = DateFormat(_dateFormat);
    return formatter.format(_lastDayOfPreviousMonth);
  }

  String get recentUpdateDay {
    final formatter = DateFormat(_dateFormat);
    return formatter.format(_lastUpdateDay);
  }

  void print() {
    final formatter = DateFormat(_dateFormat);

    debugPrint('오늘 (자정): ${formatter.format(_today)}');
    debugPrint('어제: ${formatter.format(_yesterday)}');
    debugPrint('이달의 1일: ${formatter.format(_firstDayOfMonth)}');
    debugPrint('직전달 마지막 날: ${formatter.format(_lastDayOfPreviousMonth)}');
    debugPrint('1년 전 이달의 1일: ${formatter.format(_firstDayOfLastYear)}');
    debugPrint('최종 업데이트 날짜: ${formatter.format(_lastUpdateDay)}');
  }
}
