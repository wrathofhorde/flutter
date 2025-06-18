// lib/screens/asset_snapshot_list_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/models/asset_snapshot.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/asset_calculator_screen.dart'; // 스냅샷 추가/수정 화면으로 이동

class AssetSnapshotListScreen extends StatefulWidget {
  final Asset asset; // 이 종목의 스냅샷 목록을 보여줄 것임

  const AssetSnapshotListScreen({super.key, required this.asset});

  @override
  State<AssetSnapshotListScreen> createState() =>
      _AssetSnapshotListScreenState();
}

class _AssetSnapshotListScreenState extends State<AssetSnapshotListScreen> {
  List<AssetSnapshot> _snapshots = [];
  bool _isAscendingOrder = false; // 날짜 정렬 순서 (true: 오름차순, false: 내림차순)
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    final snapshots = await _dbHelper.getAssetSnapshotsByAssetId(
      widget.asset.id!,
    );
    setState(() {
      _snapshots = snapshots;
      _sortSnapshots(); // 로드 후 정렬 적용
    });
  }

  void _sortSnapshots() {
    _snapshots.sort((a, b) {
      final dateA = DateTime.parse(a.snapshotDate);
      final dateB = DateTime.parse(b.snapshotDate);
      return _isAscendingOrder
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });
  }

  Future<void> _navigateToCalculatorScreen({AssetSnapshot? snapshot}) async {
    // 스냅샷을 수정하는 경우 해당 스냅샷의 매수금액과 평가금액을 Asset의 임시 필드에 할당하여 전달
    // AssetCalculatorScreen에서 해당 값을 컨트롤러에 로드하도록 합니다.
    final Asset assetForEdit = widget.asset.copyWith(
      purchasePrice: snapshot?.purchasePrice,
      currentValue: snapshot?.currentValue,
    );

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetCalculatorScreen(
          asset: assetForEdit,
          onAssetUpdated: () {
            // 스냅샷이 업데이트될 때 (저장 버튼 누른 후) 이 리스트를 새로 고침
            _loadSnapshots();
          },
        ),
      ),
    );

    // AssetCalculatorScreen에서 true를 반환했다면 (저장 성공 시), 스냅샷 목록 새로고침
    // 그리고 이 화면을 호출한 상위 위젯에게도 변경사항이 있음을 알리기 위해 true를 반환
    if (result == true) {
      await _loadSnapshots(); // 스냅샷 목록을 갱신 (비동기 완료 기다림)
      // !!! 여기가 가장 중요: 이 화면을 닫으면서 `true`를 반환하여 `AssetCard`에 변경을 알림 !!!
      // 만약 Navigator.canPop(context)가 false인 경우 (예: 스택에 이전에 pop할 화면이 없는 경우)
      // pop을 호출하면 오류가 발생할 수 있으므로 확인하는 것이 안전하지만,
      // 일반적으로 Navigator.push로 들어온 화면은 pop 가능합니다.
      if (!mounted) return;
      if (context.mounted && Navigator.canPop(context)) {
        // 추가된 확인
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _confirmDelete(AssetSnapshot snapshot) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('스냅샷 삭제'),
          content: Text('${snapshot.snapshotDate} 날짜의 스냅샷을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteAssetSnapshot(snapshot.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('스냅샷이 삭제되었습니다.')));

        await _loadSnapshots(); // 삭제 후 목록 새로 고침

        if (!mounted) return;

        if (context.mounted && Navigator.canPop(context)) {
          // 추가된 확인
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        debugPrint('Failed to delete snapshot: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('스냅샷 삭제 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.asset.name} 스냅샷 기록'),
        actions: [
          IconButton(
            icon: Icon(
              _isAscendingOrder ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _isAscendingOrder ? '날짜 내림차순 정렬' : '날짜 오름차순 정렬',
            onPressed: () {
              setState(() {
                _isAscendingOrder = !_isAscendingOrder;
                _sortSnapshots();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '스냅샷 추가',
            onPressed: () => _navigateToCalculatorScreen(), // 스냅샷 추가로 이동
          ),
        ],
      ),
      body: _snapshots.isEmpty
          ? const Center(child: Text('저장된 스냅샷이 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _snapshots.length,
              itemBuilder: (context, index) {
                final snapshot = _snapshots[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.snapshotDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('매수: ${snapshot.purchasePrice}원'),
                              Text('평가: ${snapshot.currentValue}원'),
                              Text(
                                '수익률: ${snapshot.profitRate.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: snapshot.profitRate >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '변화율: ${snapshot.profitRateChange.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: snapshot.profitRateChange >= 0
                                      ? Colors.blue
                                      : Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                // 스냅샷 수정 (선택된 날짜로 계산기 화면 이동)
                                _navigateToCalculatorScreen(snapshot: snapshot);
                              },
                              tooltip: '수정',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(snapshot),
                              tooltip: '삭제',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
