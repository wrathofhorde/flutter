// lib/screens/asset_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/models/asset_snapshot.dart'; // AssetSnapshot 모델 임포트
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 intl 패키지 필요

class AssetCalculatorScreen extends StatefulWidget {
  final Asset asset; // 계산할 종목 정보
  final VoidCallback onAssetUpdated; // 자산 업데이트 시 호출할 콜백

  const AssetCalculatorScreen({
    super.key,
    required this.asset,
    required this.onAssetUpdated,
  });

  @override
  State<AssetCalculatorScreen> createState() => _AssetCalculatorScreenState();
}

class _AssetCalculatorScreenState extends State<AssetCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _currentValueController = TextEditingController();
  double _profitRate = 0.0;
  double _profitRateChange = 0.0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    // 기존 값이 있다면 컨트롤러에 설정 (int -> String)
    if (widget.asset.purchasePrice != null) {
      _purchasePriceController.text = widget.asset.purchasePrice!.toString();
    }
    if (widget.asset.currentValue != null) {
      _currentValueController.text = widget.asset.currentValue!.toString();
    }

    // initState에서 _calculateProfit()을 호출하기 전에,
    // _updateProfitRateChangeDisplay()를 호출하여 초기 수익률 및 변화율을 계산하도록 변경합니다.
    // _calculateProfit()은 이제 불필요하거나, _updateProfitRateChangeDisplay() 안에서 호출되도록 통합할 수 있습니다.
    // 여기서는 단순히 _updateProfitRateChangeDisplay()를 호출하여 시작합니다.
    _updateProfitRateChangeDisplay();
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  Future<void> _saveAssetData() async {
    if (!_formKey.currentState!.validate()) {
      return; // 유효성 검사 실패 시 저장하지 않음
    }

    final int? purchase = int.tryParse(_purchasePriceController.text);
    final int? current = int.tryParse(_currentValueController.text);

    if (purchase == null || current == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('매수금액과 평가금액을 올바르게 입력해주세요.')));
      return;
    }

    final double calculatedProfitRate = purchase == 0
        ? 0.0
        : ((current - purchase) / purchase) * 100;

    // 1. Asset(종목) 자체의 정보 업데이트 (purchasePrice, currentValue, lastProfitRate)
    final updatedAsset = Asset(
      id: widget.asset.id,
      accountId: widget.asset.accountId,
      name: widget.asset.name,
      assetType: widget.asset.assetType,
      assetLocation: widget.asset.assetLocation, // !!! 이 줄을 추가합니다 !!!
      memo: widget.asset.memo,
      purchasePrice: purchase,
      currentValue: current,
      lastProfitRate:
          calculatedProfitRate, // 현재 계산된 수익률을 다음을 위한 lastProfitRate로 저장
    );

    try {
      await _dbHelper.updateAsset(updatedAsset); // Asset 테이블 업데이트

      // 2. AssetSnapshot 저장 (오늘 날짜 기준)
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 이전 스냅샷의 수익률 가져오기 (수익률 변화율 계산용)
      AssetSnapshot? previousSnapshot;
      List<AssetSnapshot> allSnapshots = await _dbHelper
          .getAssetSnapshotsByAssetId(widget.asset.id!);
      if (allSnapshots.isNotEmpty) {
        // 가장 최근 스냅샷이 오늘이 아니라면, 그 스냅샷을 이전 스냅샷으로 간주
        // (오늘 스냅샷을 업데이트하는 경우는 previousSnapshot이 달라짐)
        if (allSnapshots.last.snapshotDate == today) {
          if (allSnapshots.length > 1) {
            previousSnapshot = allSnapshots[allSnapshots.length - 2];
          }
        } else {
          previousSnapshot = allSnapshots.last;
        }
      }

      final double profitRateChangeForSnapshot = (previousSnapshot != null)
          ? (calculatedProfitRate - previousSnapshot.profitRate)
          : 0.0; // 최초 스냅샷의 변화율은 0%

      final newSnapshot = AssetSnapshot(
        assetId: widget.asset.id!,
        snapshotDate: today,
        purchasePrice: purchase,
        currentValue: current,
        profitRate: calculatedProfitRate,
        profitRateChange: profitRateChangeForSnapshot,
      );

      await _dbHelper.insertAssetSnapshot(
        newSnapshot,
      ); // AssetSnapshot 테이블에 저장 (UPSERT)

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종목 정보 및 스냅샷이 성공적으로 저장되었습니다.')),
      );
      widget.onAssetUpdated(); // 부모 위젯에 업데이트 알림
      Navigator.of(context).pop(true); // 성공 시 true 반환
    } catch (e) {
      debugPrint('Failed to save asset data and snapshot: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('정보 저장 실패: $e')));
    }
  }

  Future<void> _updateProfitRateChangeDisplay() async {
    final int? purchase = int.tryParse(_purchasePriceController.text);
    final int? current = int.tryParse(_currentValueController.text);

    if (purchase != null && current != null && purchase != 0) {
      final double newProfitRate = ((current - purchase) / purchase) * 100;
      AssetSnapshot? previousSnapshot;

      // 가장 최근 스냅샷 (오늘 날짜 제외)을 찾아 이전 수익률로 사용
      List<AssetSnapshot> allSnapshots = await _dbHelper
          .getAssetSnapshotsByAssetId(widget.asset.id!);

      // 오늘 날짜 스냅샷이 있다면, 그 직전 스냅샷을 찾음
      // 오늘 날짜 스냅샷이 없다면, 가장 마지막 스냅샷을 이전 스냅샷으로 사용
      if (allSnapshots.isNotEmpty) {
        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (allSnapshots.last.snapshotDate == today) {
          if (allSnapshots.length > 1) {
            previousSnapshot = allSnapshots[allSnapshots.length - 2];
          }
        } else {
          previousSnapshot = allSnapshots.last;
        }
      }

      setState(() {
        _profitRate = newProfitRate;
        if (previousSnapshot != null) {
          _profitRateChange = newProfitRate - previousSnapshot.profitRate;
        } else {
          _profitRateChange = 0.0;
        }
      });
    } else {
      setState(() {
        _profitRate = 0.0;
        _profitRateChange = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.asset.name} 분석 및 스냅샷')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.asset.name} (${widget.asset.assetType.name})',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 여기에 assetLocation도 함께 표시할 수 있습니다.
              // 예: Text('${widget.asset.name} (${widget.asset.assetType.name} | ${_assetLocationToKorean(widget.asset.assetLocation)})'),
              // _assetLocationToKorean 헬퍼 함수가 필요합니다.
              // String _assetLocationToKorean(AssetLocation location) {
              //   switch (location) {
              //     case AssetLocation.domestic: return '국내';
              //     case AssetLocation.overseas: return '해외';
              //   }
              // }
              if (widget.asset.memo != null && widget.asset.memo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '메모: ${widget.asset.memo}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '매수금액',
                  border: OutlineInputBorder(),
                  hintText: '정수만 입력하세요 (예: 100000)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '매수금액을 입력해주세요.';
                  }
                  if (int.tryParse(value) == null) {
                    return '유효한 정수를 입력해주세요.';
                  }
                  if (int.tryParse(value)! <= 0) {
                    // 매수금액은 0보다 커야 함
                    return '매수금액은 0보다 커야 합니다.';
                  }
                  return null;
                },
                onChanged: (_) =>
                    _updateProfitRateChangeDisplay(), // 입력 시마다 계산 및 변화율 표시 업데이트
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _currentValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '평가금액',
                  border: OutlineInputBorder(),
                  hintText: '정수만 입력하세요 (예: 120000)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '평가금액을 입력해주세요.';
                  }
                  if (int.tryParse(value) == null) {
                    return '유효한 정수를 입력해주세요.';
                  }
                  return null;
                },
                onChanged: (_) =>
                    _updateProfitRateChangeDisplay(), // 입력 시마다 계산 및 변화율 표시 업데이트
              ),
              const SizedBox(height: 24.0),
              _buildResultCard(
                title: '수익률',
                value: '${_profitRate.toStringAsFixed(2)}%',
                color: _profitRate >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16.0),
              _buildResultCard(
                title: '수익률 변화율',
                value: '${_profitRateChange.toStringAsFixed(2)}%',
                color: _profitRateChange >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _saveAssetData,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // 버튼 높이
                ),
                child: const Text('저장하기', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
