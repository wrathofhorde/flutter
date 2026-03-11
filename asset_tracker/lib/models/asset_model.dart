import 'package:isar/isar.dart';

part 'asset_model.g.dart';

@collection
class Institution {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name; // 예: 삼성증권, 신한은행

  @Backlink(to: 'institution')
  final accounts = IsarLinks<Account>(); // 금융사 하위의 계좌들 (1:N)
}

@collection
class Account {
  Id id = Isar.autoIncrement;

  late String name; // 예: ISA, IRP, 연금저축, 보통예금

  final institution = IsarLink<Institution>(); // 어느 금융사 소속인지

  @Backlink(to: 'account')
  final assets = IsarLinks<AssetItem>(); // 이 계좌에 담긴 종목들 (1:N)
}

@collection
class AssetItem {
  Id id = Isar.autoIncrement;

  late String name; // 예: 삼성전자, S&P500 ETF, 현금
  late String type; // STOCK, CASH, LOAN 등

  final account = IsarLink<Account>(); // 어느 계좌에 속해있는지

  @Backlink(to: 'item')
  final records = IsarLinks<AssetRecord>(); // 이 종목의 월별 히스토리
}

@collection
class AssetRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late double purchaseAmount; // 매수 원가
  late double evaluationAmount; // 현재 평가 금액

  final item = IsarLink<AssetItem>();

  // ✅ 이 부분이 추가되어야 합니다!
  // 수익률 계산 (매수금액이 0보다 클 때만 계산)
  double get profitRate => purchaseAmount > 0
      ? ((evaluationAmount - purchaseAmount) / purchaseAmount) * 100
      : 0;
}
