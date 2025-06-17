// lib/widgets/asset_card.dart
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/screens/asset_calculator_screen.dart';
import 'package:assets_snapshot/screens/add_asset_screen.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onAssetUpdated;
  final VoidCallback onAssetDeleted;

  const AssetCard({
    super.key,
    required this.asset,
    required this.onAssetUpdated,
    required this.onAssetDeleted,
  });

  // AssetType enum 값을 한글 텍스트로 변환 (AddAssetScreen과 동일)
  String _assetTypeToKorean(AssetType type) {
    switch (type) {
      case AssetType.stock:
        return '주식';
      case AssetType.crypto:
        return '가상화폐';
      case AssetType.deposit:
        return '예금';
      case AssetType.bond:
        return '채권';
      case AssetType.fund:
        return '펀드';
      case AssetType.etf:
        return 'ETF';
      case AssetType.wrap:
        return 'Wrap';
      case AssetType.other:
        return '기타';
    }
  }

  // AssetLocation enum 값을 한글 텍스트로 변환 (AddAssetScreen과 동일)
  String _assetLocationToKorean(AssetLocation location) {
    switch (location) {
      case AssetLocation.domestic:
        return '국내';
      case AssetLocation.overseas:
        return '해외';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // AssetCalculatorScreen으로 이동하여 상세 계산 및 스냅샷 저장
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetCalculatorScreen(
                asset: asset,
                onAssetUpdated: onAssetUpdated,
              ),
            ),
          );
          // 비동기 작업 (Navigator.push) 후 context 사용 전에 mounted 확인
          if (result == true && context.mounted) {
            // !!! mounted 체크 추가 !!!
            // 스냅샷 저장 후 목록 업데이트 (AssetCalculatorScreen에서 pop(true) 시)
            onAssetUpdated();
          }
        },
        onLongPress: () {
          _showAssetOptions(context); // 길게 누르면 옵션 메뉴 표시
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      asset.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 자산 유형과 투자 지역 표시
                  Text(
                    '${_assetTypeToKorean(asset.assetType)} | ${_assetLocationToKorean(asset.assetLocation)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (asset.memo != null && asset.memo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    asset.memo!,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // 매수/평가 금액 및 수익률 표시 (null이 아닐 경우만)
              if (asset.purchasePrice != null && asset.currentValue != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '매수: ${asset.purchasePrice?.toStringAsFixed(0) ?? '-'} 원',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '평가: ${asset.currentValue?.toStringAsFixed(0) ?? '-'} 원',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('수익률: ', style: const TextStyle(fontSize: 16)),
                        Text(
                          '${asset.lastProfitRate?.toStringAsFixed(2) ?? '-'}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (asset.lastProfitRate ?? 0) >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              // 아직 매수/평가 금액이 없는 경우
              if (asset.purchasePrice == null || asset.currentValue == null)
                const Text(
                  '아직 매수/평가 정보가 없습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 길게 눌렀을 때 옵션 표시 메서드
  void _showAssetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('종목 정보 수정'),
                onTap: () async {
                  Navigator.pop(bc); // 바텀 시트 닫기
                  // 비동기 작업 전에 context.mounted를 캡처
                  final bool isMountedBeforePush = context.mounted;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddAssetScreen(
                        accountId: asset.accountId,
                        asset: asset, // 기존 종목 정보를 전달하여 수정 모드 활성화
                      ),
                    ),
                  );
                  // 비동기 작업 후, 초기 context가 여전히 유효한지 확인
                  if (result == true && isMountedBeforePush) {
                    // !!! mounted 체크 추가 !!!
                    onAssetUpdated(); // 수정 후 목록 업데이트
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('종목 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bc); // 바텀 시트 닫기
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('종목 삭제'),
          content: Text(
            '${asset.name} 종목을 삭제하시겠습니까?\n모든 관련 데이터(스냅샷 등)가 삭제됩니다.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // 다이얼로그 컨텍스트 닫기 (즉시)
                Navigator.of(dialogContext).pop();

                // 비동기 작업 전에 위젯의 context가 mounted인지 확인
                // 이 `mounted`는 `AssetCard`의 `build` 메서드의 `context`를 참조합니다.
                // Stateless Widget이므로 `context.mounted`를 직접 사용할 수 있습니다.
                // Stateful Widget에서는 `widget.context.mounted` 또는 `mounted` 사용

                await DatabaseHelper().deleteAsset(asset.id!); // DB에서 종목 삭제

                // DB 작업 완료 후, AssetCard 위젯이 여전히 트리에 있는지 확인
                if (context.mounted) {
                  // !!! mounted 체크 추가 !!!
                  onAssetDeleted(); // 삭제 후 부모 위젯에 알림 (Assets 목록 갱신)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${asset.name} 종목이 삭제되었습니다.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
