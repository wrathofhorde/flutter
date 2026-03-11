import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/asset_model.dart';

// 월별 총자산 합계 데이터 모델 (차트용)
class MonthlyTotal {
  final DateTime date;
  final double totalAmount;
  MonthlyTotal(this.date, this.totalAmount);
}

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
      AccountSchema,
      AssetItemSchema,
      AssetRecordSchema,
    ], directory: dir.path);
  }

  // 특정 금융사에 계좌 추가 로직
  static Future<void> addAccount(int institutionId, String accountName) async {
    final institution = await isar.institutions.get(institutionId);
    if (institution != null) {
      final newAccount = Account()..name = accountName;
      newAccount.institution.value = institution; // 관계 설정

      await isar.writeTxn(() async {
        await isar.accounts.put(newAccount);
        await newAccount.institution.save(); // Link 저장 필수
      });
    }
  }

  // 모든 금융기관 가져오기
  static Future<List<Institution>> getAllInstitutions() async {
    return await isar.institutions.where().findAll();
  }

  // 새로운 금융기관 추가
  static Future<void> addInstitution(String name) async {
    final newInstitution = Institution()..name = name;
    await isar.writeTxn(() async {
      await isar.institutions.put(newInstitution);
    });
  }

  static Future<List<Account>> getAccountsByInstitution(
    int institutionId,
  ) async {
    final institution = await isar.institutions.get(institutionId);
    if (institution != null) {
      // IsarLinks를 로드하여 리스트로 반환
      await institution.accounts.load();
      return institution.accounts.toList();
    }
    return [];
  }

  // 특정 계좌에 속한 모든 종목 가져오기
  static Future<List<AssetItem>> getAssetsByAccount(int accountId) async {
    final account = await isar.accounts.get(accountId);
    if (account != null) {
      await account.assets.load();
      return account.assets.toList();
    }
    return [];
  }

  // 특정 계좌에 종목 추가
  static Future<void> addAssetItem(
    int accountId,
    String name,
    String type,
  ) async {
    final account = await isar.accounts.get(accountId);
    if (account != null) {
      final newItem = AssetItem()
        ..name = name
        ..type = type;
      newItem.account.value = account;

      await isar.writeTxn(() async {
        await isar.assetItems.put(newItem);
        await newItem.account.save();
      });
    }
  }

  // 특정 종목의 모든 월별 기록 가져오기 (날짜 역순)
  static Future<List<AssetRecord>> getRecordsByAsset(int assetItemId) async {
    final assetItem = await isar.assetItems.get(assetItemId);
    if (assetItem != null) {
      await assetItem.records.load();
      final list = assetItem.records.toList();
      // 최신 날짜가 위로 오도록 정렬
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    return [];
  }

  // 월별 기록 추가/수정
  static Future<void> addAssetRecord(
    int assetItemId,
    DateTime date,
    double purchase,
    double evaluation,
  ) async {
    final assetItem = await isar.assetItems.get(assetItemId);
    if (assetItem != null) {
      // 같은 날짜의 기록이 있는지 확인 (있으면 업데이트, 없으면 신규)
      final existingRecord = await isar.assetRecords
          .filter()
          .item((q) => q.idEqualTo(assetItemId))
          .dateEqualTo(date)
          .findFirst();

      final record = existingRecord ?? AssetRecord();
      record.date = date;
      record.purchaseAmount = purchase;
      record.evaluationAmount = evaluation;
      record.item.value = assetItem;

      await isar.writeTxn(() async {
        await isar.assetRecords.put(record);
        await record.item.save();
      });
    }
  }

  // ... DatabaseService 클래스 내부
  static Future<List<MonthlyTotal>> getMonthlyTotalHistory() async {
    // 모든 기록 가져오기
    final allRecords = await isar.assetRecords.where().sortByDate().findAll();

    // 월별로 그룹화하여 합계 계산
    Map<DateTime, double> monthlyMap = {};

    for (var record in allRecords) {
      // 날짜를 해당 월의 1일로 정규화
      DateTime month = DateTime(record.date.year, record.date.month);
      monthlyMap[month] = (monthlyMap[month] ?? 0) + record.evaluationAmount;
    }

    // 맵을 리스트로 변환하고 날짜순 정렬
    List<MonthlyTotal> result = monthlyMap.entries
        .map((e) => MonthlyTotal(e.key, e.value))
        .toList();
    result.sort((a, b) => a.date.compareTo(b.date));

    return result;
  }
}
