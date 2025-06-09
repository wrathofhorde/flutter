import 'dart:convert'; // JSON 파싱을 위해
import 'package:http/http.dart' as http; // http 패키지 임포트
import 'package:flutter/foundation.dart'; // debugPrint를 위해

class ClosePrice {
  final String _baseUrl = "https://api.upbit.com/v1";
  final Map<String, String> _headers = {"accept": "application/json"};
  final List<String> _markets = ["KRW-BTC", "KRW-ETH", "KRW-XRP"];

  Future<List<int>> getTradePricesForDay(String day) async {
    final String dateTimeParam = "${day}T15:00:00Z"; // Z는 UTC를 나타냄

    List<int> tradePrices = [];

    for (String market in _markets) {
      await Future.delayed(const Duration(milliseconds: 500));

      final url = Uri.parse(
        '$_baseUrl/candles/minutes/1?market=$market&to=$dateTimeParam',
      );
      debugPrint('Upbit API URL: $url');

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        if (responseData.isNotEmpty) {
          final Map<String, dynamic> data = responseData[0];
          debugPrint('$day data for $market: $data');
          tradePrices.add((data['trade_price'] as num).toInt());
        } else {
          debugPrint('No data found for $market at $dateTimeParam');
          tradePrices.add(0);
        }
      } else {
        debugPrint(
          'Upbit API Request failed for $market. Status Code: ${response.statusCode}',
        );
        debugPrint('Response Body: ${response.body}');
        tradePrices.add(0);
      }
    }

    return tradePrices;
  }
}
