import 'dart:developer'; // log 함수를 위해 추가
import 'package:intl/intl.dart';

class Days {
  static const String _dateFormat = 'yyyy-MM-dd';

  late DateTime _today;
  late DateTime _yesterday;
  late DateTime _firstDayOfMonth; // 이달의 1일
  late DateTime _lastDayOfPreviousMonth; // 직전달 마지막 날
  late DateTime _firstDayOfLastYear; // 1년 전 이달의 1일
  late DateTime _lastUpdateDay; // 마지막 종가 업데이트 날

  Days(String? lastUpdate) {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _yesterday = _today.subtract(const Duration(days: 1));
    _firstDayOfMonth = DateTime(_today.year, _today.month, 1);
    _lastDayOfPreviousMonth = _firstDayOfMonth.subtract(
      const Duration(days: 1),
    );
    _firstDayOfLastYear = DateTime(
      _firstDayOfMonth.year - 1,
      _firstDayOfMonth.month,
      _firstDayOfMonth.day,
    );
    try {
      _lastUpdateDay = DateTime.parse(lastUpdate ?? "2021-01-01");
    } catch (e) {
      // 파싱 오류 발생 시 기본값으로 설정하고 로그 출력
      log('Days 생성자: lastUpdate 날짜 파싱 오류: $lastUpdate - $e', name: 'DaysClass');
      _lastUpdateDay = DateTime.parse("2021-01-01"); // 오류 발생 시 안전한 기본값
    }
  }

  // 이 getter는 여전히 외부에서 '오늘의 자정'을 가져오는 데 유용할 수 있습니다.
  DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateFormat get dateFormatter => DateFormat(_dateFormat);

  String get today => dateFormatter.format(_today);
  String get yesterday => dateFormatter.format(_yesterday);
  String get startDay => dateFormatter.format(_firstDayOfLastYear);
  String get endDay => dateFormatter.format(_lastDayOfPreviousMonth);
  String get lastUpdateDay => dateFormatter.format(_lastUpdateDay);

  DateTime get updateStartDay => _lastUpdateDay.add(const Duration(days: 1));
  DateTime get updateEndDay => _yesterday;

  // PricePage 등에서 DateTime 타입의 시작/종료 날짜가 필요할 경우 사용
  DateTime get startDateTime => _firstDayOfLastYear;
  DateTime get endDateTime =>
      _lastDayOfPreviousMonth; // 또는 _yesterday, PricePage의 로직에 맞춰 선택

  set updateLastUpdateDay(String newDateString) {
    try {
      _lastUpdateDay = DateTime.parse(newDateString);
    } catch (e) {
      log(
        'Days: updateLastUpdateDay 날짜 파싱 오류: $newDateString - $e',
        name: 'DaysClass',
      );
      // 오류 처리 로직 추가 (예: 예외를 다시 던지거나 기본값 설정)
    }
  }

  set updateLastUpdateDayAsDateTime(DateTime newDateTime) {
    _lastUpdateDay = newDateTime;
  }

  @override
  String toString() {
    final formatter = dateFormatter;
    String str = "";
    str += '오늘 (자정): ${formatter.format(_today)}\n';
    str += '어제: ${formatter.format(_yesterday)}\n';
    str += '이달의 1일: ${formatter.format(_firstDayOfMonth)}\n';
    str += '직전달 마지막 날: ${formatter.format(_lastDayOfPreviousMonth)}\n';
    str += '1년 전 이달의 1일: ${formatter.format(_firstDayOfLastYear)}\n';
    str += '최종 업데이트 날짜: ${formatter.format(_lastUpdateDay)}';
    return str;
  }
}
