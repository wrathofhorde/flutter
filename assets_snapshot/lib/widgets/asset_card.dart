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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
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
          if (result == true && context.mounted) {
            onAssetUpdated();
          }
        },
        onLongPress: () {
          _showAssetOptions(context); // 길게 누르면 옵션 메뉴 표시 (기존 기능 유지)
        },
        child: Stack(
          // 아이콘을 카드 위에 겹쳐서 배치하기 위해 Stack 사용
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 종목명 (단독 한 줄)
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1, // 한 줄로 제한
                    overflow: TextOverflow.ellipsis, // 넘치면 ...으로 표시
                  ),
                  const SizedBox(height: 4), // 종목명과 부가 정보 사이의 간격
                  // 자산 유형과 투자 지역 (다음 줄)
                  Text(
                    '${asset.assetTypeInKorean} | ${asset.assetLocationInKorean}', // Asset 클래스의 getter 사용
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),

                  if (asset.memo != null && asset.memo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        asset.memo!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
            // 좌상단 편집 아이콘
            Positioned(
              bottom: 8, // 상단에서 여백
              left: 8, // 왼쪽에서 여백
              child: IconButton(
                icon: const Icon(Icons.edit, size: 24, color: Colors.blueGrey),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddAssetScreen(
                        accountId: asset.accountId,
                        asset: asset, // 기존 종목 정보를 전달하여 수정 모드 활성화
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    onAssetUpdated(); // 수정 후 목록 업데이트
                  }
                },
                // padding: EdgeInsets.zero, // IconButton의 기본 패딩 제거
                // constraints: const BoxConstraints(), // IconButton의 최소 크기 제한 제거
              ),
            ),
            // 우상단 삭제 아이콘
            Positioned(
              bottom: 8, // 상단에서 여백
              right: 8, // 오른쪽에서 여백
              child: IconButton(
                icon: const Icon(Icons.delete, size: 24, color: Colors.red),
                onPressed: () {
                  _confirmDelete(context);
                },
                // padding: EdgeInsets.zero, // IconButton의 기본 패딩 제거
                // constraints: const BoxConstraints(), // IconButton의 최소 크기 제한 제거
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 길게 눌렀을 때 옵션 표시 메서드 (기존 유지)
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
                  if (result == true && isMountedBeforePush) {
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
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                await DatabaseHelper().deleteAsset(asset.id!); // DB에서 종목 삭제
                if (context.mounted) {
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
