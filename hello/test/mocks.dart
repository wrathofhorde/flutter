import 'package:hello/utils/database_helper.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart'; // 실제 sqflite DB 타입을 모의하기 위해

// MockDatabaseHelper는 실제 DatabaseHelper를 모의하기 위해 Mockito의 Mock 클래스를 상속하고,
// DatabaseHelper를 implements 하여 타입 일치를 강제합니다.
class MockDatabaseHelper extends Mock implements DatabaseHelper {
  // Database 인스턴스를 모의할 수 있도록 추가
  @override
  Database? get database => throwIf(true); // 실제 DB 접근을 막기 위함
}

// Database 객체 자체를 모의해야 할 경우
class MockDatabase extends Mock implements Database {}

class MockHttpClient extends Mock implements http.Client {}
