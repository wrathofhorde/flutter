import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/asset_model.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    // 디버그 콘솔에 경로 출력
    debugPrint('================================================');
    debugPrint('Isar DB 저장 경로: ${dir.path}');
    debugPrint('확인할 파일명: default.isar (또는 설정한 이름.isar)');
    debugPrint('================================================');

    isar = await Isar.open([
      InstitutionSchema,
      AssetItemSchema,
      AssetRecordSchema,
    ], directory: dir.path);
  }
}
