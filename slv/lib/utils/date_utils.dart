import 'package:intl/intl.dart'; // pubspec.yaml에 intl 패키지 추가 필요

class DateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // String을 DateTime으로 파싱
  static DateTime parseDate(String dateString) {
    return _dateFormat.parse(dateString);
  }

  // DateTime을 String으로 포매팅
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  // 두 날짜 문자열을 비교하여 date1이 date2보다 이후인지 확인 (동일하면 false)
  static bool isAfter(String date1, String date2) {
    return parseDate(date1).isAfter(parseDate(date2));
  }

  // 두 날짜 문자열을 비교하여 date1이 date2와 같거나 이후인지 확인
  static bool isAtOrAfter(String date1, String date2) {
    final dt1 = parseDate(date1);
    final dt2 = parseDate(date2);
    return dt1.isAfter(dt2) || dt1.isAtSameMomentAs(dt2);
  }

  // 주어진 시작일로부터 오늘까지의 날짜 목록 생성 (API 필터링용은 아님)
  static List<String> getDateRange(
    String startDateString,
    String endDateString,
  ) {
    List<String> dates = [];
    DateTime startDate = parseDate(startDateString);
    DateTime endDate = parseDate(endDateString);

    for (
      DateTime d = startDate;
      d.isBefore(endDate) || d.isAtSameMomentAs(endDate);
      d = d.add(const Duration(days: 1))
    ) {
      dates.add(formatDate(d));
    }
    return dates;
  }
}
