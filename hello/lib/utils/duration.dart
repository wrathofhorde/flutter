import 'dart:developer';
import 'package:intl/intl.dart';

class Days {
  static const String _startDate = '2024-06-07';
  static const String _dateFormat = 'yyyy-MM-dd';

  late DateTime _today;
  late DateTime _yesterday;
  late DateTime _firstDayOfMonth; // 이달의 1일
  late DateTime _lastDayOfPreviousMonth; // 직전달 마지막 날
  late DateTime _firstDayOfLastYear; // 1년 전 이달의 1일
  late DateTime _lastUpdateDay; // 마지막 종가 업데이트 날

  // 현재 표시 중인 기간의 시작일과 종료일을 관리할 변수 추가
  late DateTime _currentDisplayStartDate;
  late DateTime _currentDisplayEndDate;

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
      _lastUpdateDay = DateTime.parse(lastUpdate ?? _startDate);
    } catch (e) {
      // 파싱 오류 발생 시 기본값으로 설정하고 로그 출력
      log('Days 생성자: lastUpdate 날짜 파싱 오류: $lastUpdate - $e', name: 'DaysClass');
      _lastUpdateDay = DateTime.parse(_startDate); // 오류 발생 시 안전한 기본값
    }

    _currentDisplayEndDate = _lastDayOfPreviousMonth;
    _currentDisplayStartDate = _firstDayOfLastYear;
  }

  // 이 getter는 여전히 외부에서 '오늘의 자정'을 가져오는 데 유용할 수 있습니다.
  DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateFormat get dateFormatter => DateFormat(_dateFormat);

  String get today => dateFormatter.format(_today);
  String get yesterday => dateFormatter.format(_yesterday);

  // 현재 표시 중인 기간의 시작일과 종료일을 반환하는 getter
  String get startDay => dateFormatter.format(_currentDisplayStartDate);
  String get endDay => dateFormatter.format(_currentDisplayEndDate);

  // 기존 getter들은 유지 (필요에 따라)
  String get lastUpdateDay => dateFormatter.format(_lastUpdateDay);
  String get firstDateOfMonth => dateFormatter.format(_firstDayOfMonth);

  DateTime get updateStartDay => _lastUpdateDay.add(const Duration(days: 1));
  DateTime get updateEndDay => _yesterday;

  // PricePage 등에서 DateTime 타입의 시작/종료 날짜가 필요할 경우 사용
  // 이 부분은 PricePage의 로직에 맞춰서 필요하면 유지하거나 수정
  DateTime get startDateTime => _currentDisplayStartDate;
  DateTime get endDateTime => _currentDisplayEndDate;

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

  // 이전 1달 기간으로 이동하는 메서드
  void goToPreviousMonth() {
    final oneDay = Duration(days: 1);
    final DateTime lastSearchableDate = DateTime(2025, 7, 31);

    if (_currentDisplayEndDate.year == lastSearchableDate.year &&
        _currentDisplayEndDate.month == lastSearchableDate.month) {
      return;
    }
    // 현재 표시된 달의 첫번째 일
    _currentDisplayEndDate = DateTime(
      _currentDisplayEndDate.year,
      _currentDisplayEndDate.month,
      1,
    );
    // 일년 전의 1일
    _currentDisplayStartDate = DateTime(
      _currentDisplayEndDate.year - 1,
      _currentDisplayEndDate.month,
      _currentDisplayEndDate.day,
    );
    // 현재 표시된 달의 직전 달의 마지막 날
    // _currentDisplayEndDate = _currentDisplayEndDate.subtract(oneDay);
    _currentDisplayEndDate = _currentDisplayEndDate.subtract(oneDay);
  }

  // 다음 1달 기간으로 이동하는 메서드
  void goToNextMonth() {
    if (_currentDisplayEndDate.year == _lastDayOfPreviousMonth.year &&
        _currentDisplayEndDate.month == _lastDayOfPreviousMonth.month) {
      return;
    }
    // 다음 달의 1일
    DateTime nextDayOfCurrentEndDate = DateTime(
      _currentDisplayEndDate.year,
      _currentDisplayEndDate.month + 1,
      1,
    );
    // 일년 전 달의 1일, 그리고 다음 달
    _currentDisplayStartDate = DateTime(
      nextDayOfCurrentEndDate.year - 1,
      nextDayOfCurrentEndDate.month + 1,
      nextDayOfCurrentEndDate.day,
    );
    _currentDisplayEndDate = DateTime(
      nextDayOfCurrentEndDate.year,
      nextDayOfCurrentEndDate.month + 1,
      0, // month + 1 이전 달, 즉  month의 마지막 날
    );
  }

  // 기존 1년 단위 이동 메서드는 제거하거나 주석 처리
  /*
  void goToPreviousYear() {
    _currentDisplayStartDate = DateTime(_currentDisplayStartDate.year - 1, _currentDisplayStartDate.month, _currentDisplayStartDate.day);
    _currentDisplayEndDate = DateTime(_currentDisplayEndDate.year - 1, _currentDisplayEndDate.month, _currentDisplayEndDate.day);
  }

  void goToNextYear() {
    _currentDisplayStartDate = DateTime(_currentDisplayStartDate.year + 1, _currentDisplayStartDate.month, _currentDisplayStartDate.day);
    _currentDisplayEndDate = DateTime(_currentDisplayEndDate.year + 1, _currentDisplayEndDate.month, _currentDisplayEndDate.day);
  }
  */

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
    str += '\n현재 표시 시작일: ${formatter.format(_currentDisplayStartDate)}';
    str += '\n현재 표시 종료일: ${formatter.format(_currentDisplayEndDate)}';
    return str;
  }
}
