import 'package:isar/isar.dart';

part 'asset_model.g.dart';

@collection
class Institution {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name; // 예: 신한은행, 삼성증권, 미래에셋

  // 이 기관에 속한 자산들 (1:N)
  final assets = IsarLinks<AssetItem>();
}

@collection
class AssetItem {
  Id id = Isar.autoIncrement;

  late String name; // 상품명 (예: 삼성전자, 미국달러, 아파트)

  @Index()
  late String type; // 종류 (CASH, STOCK, REAL_ESTATE, LOAN 등)

  // 이 자산의 월별 히스토리
  @Backlink(to: 'item')
  final records = IsarLinks<AssetRecord>();
}

@collection
class AssetRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // 기록 날짜 (매월 말일)

  late double purchaseAmount; // **추가: 매수 금액 (원가)**
  late double evaluationAmount; // 평가 금액 (현재 가치)

  // 수익률 계산 (Getter)
  double get profitRate => purchaseAmount > 0
      ? ((evaluationAmount - purchaseAmount) / purchaseAmount) * 100
      : 0;

  final item = IsarLink<AssetItem>();
}
