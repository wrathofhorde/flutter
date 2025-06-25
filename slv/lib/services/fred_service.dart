// lib/services/fred_service.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FredService {
  final String _apiKey =
      dotenv.env['FRED_API_KEY']!; // .env 파일에 FRED_API_KEY 추가해야 합니다.
  final String _baseUrl = 'https://api.stlouisfed.org/fred/series/observations';

  // 달러 인덱스 (Nominal Broad U.S. Dollar Index) 가져오기
  Future<Map<String, dynamic>> fetchDollarIndex(
    String seriesId,
    String startDate,
  ) async {
    // FRED API는 start_date와 end_date를 사용하여 특정 기간의 데이터를 가져올 수 있습니다.
    // 'DTWEXBGS'는 일별 데이터를 제공하는 시리즈 ID 중 하나입니다.
    final String url =
        '$_baseUrl?series_id=$seriesId&api_key=$_apiKey&file_type=json&observation_start=$startDate';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      // FRED API 응답 구조를 확인하여 'observations' 키 아래에 데이터가 있는지 확인해야 합니다.
      debugPrint('FRED API response for $seriesId: ${json.encode(data)}');
      return data;
    } else {
      debugPrint(
        'Failed to load FRED data for $seriesId: ${response.statusCode}, Body: ${response.body}',
      );
      throw Exception('Failed to load FRED data for $seriesId');
    }
  }
}
