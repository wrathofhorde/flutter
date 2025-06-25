// lib/services/alpha_vantage_service.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AlphaVantageService {
  final String _apiKey = dotenv.env['ALPHA_VANTAGE_API_KEY']!;

  // 외환 데이터 가져오기 (USD/KRW)
  Future<Map<String, dynamic>> fetchForexDailyData(
    String fromSymbol,
    String toSymbol,
  ) async {
    final String url =
        'https://www.alphavantage.co/query?function=FX_DAILY&from_symbol=$fromSymbol&to_symbol=$toSymbol&outputsize=full&apikey=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      debugPrint(
        'API response for $fromSymbol/$toSymbol (FX): ${json.encode(data)}',
      );
      return data;
    } else {
      debugPrint(
        'Failed to load forex data for $fromSymbol/$toSymbol: ${response.statusCode}, Body: ${response.body}',
      );
      throw Exception('Failed to load forex data for $fromSymbol/$toSymbol');
    }
  }

  // 이제 USD_KRW만 가져옵니다.
  Future<Map<String, Map<String, dynamic>>> fetchOnlyUsdKrwData() async {
    final Map<String, Map<String, dynamic>> allData = {};

    await _fetchAndAssignData(
      'USD_KRW',
      () => fetchForexDailyData('USD', 'KRW'),
      allData,
    );

    return allData;
  }

  Future<void> _fetchAndAssignData(
    String key,
    Future<Map<String, dynamic>> Function() fetchFunction,
    Map<String, Map<String, dynamic>> targetMap,
  ) async {
    try {
      targetMap[key] = await fetchFunction();
    } catch (e) {
      debugPrint('Error fetching $key data: $e');
      targetMap[key] = {}; // 오류 발생 시 빈 맵으로 처리
    }
  }
}
