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

  DateTime _selectedDate = DateTime.now(); // 날짜 선택을 위한 변수 추가

  @override
  void initState() {
    super.initState();
    // AssetCalculatorScreen이 스냅샷 수정 모드로 호출될 경우 해당 스냅샷의 값을 로드합니다.
    // 이는 AssetSnapshotListScreen에서 특정 스냅샷의 `purchasePrice`와 `currentValue`를
    // 임시로 Asset 객체에 할당하여 전달했기 때문입니다.
    if (widget.asset.purchasePrice != null) {
      _purchasePriceController.text = widget.asset.purchasePrice!.toString();
    }
    if (widget.asset.currentValue != null) {
      _currentValueController.text = widget.asset.currentValue!.toString();
    }

    // 초기 수익률 및 변화율 계산
    _updateProfitRateChangeDisplay();
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  // 날짜 선택 다이얼로그
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // 오늘 날짜까지만 선택 가능하도록 제한
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // 날짜가 변경되면 해당 날짜의 스냅샷이 있는지 확인하고 로드
      _loadSnapshotForSelectedDate(_selectedDate);
    }
  }

  // 선택된 날짜에 해당하는 스냅샷을 로드하여 입력 필드에 채움
  Future<void> _loadSnapshotForSelectedDate(DateTime date) async {
    final String targetDate = DateFormat('yyyy-MM-dd').format(date);
    final AssetSnapshot? existingSnapshot = await _dbHelper
        .getAssetSnapshotByDate(widget.asset.id!, targetDate);

    setState(() {
      if (existingSnapshot != null) {
        _purchasePriceController.text = existingSnapshot.purchasePrice
            .toString();
        _currentValueController.text = existingSnapshot.currentValue.toString();
      } else {
        // 해당 날짜에 스냅샷이 없으면 필드 초기화
        _purchasePriceController.clear();
        _currentValueController.clear();
      }
      // 날짜가 변경되었으므로 변화율 다시 계산 (필드 값에 따라)
      _updateProfitRateChangeDisplay();
    });
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
    // 이 업데이트는 '현재 시점'의 자산 값을 반영하는 것이므로,
    // 날짜 선택과 별개로 항상 최신 값으로 업데이트하는 것이 합리적입니다.
    final updatedAsset = Asset(
      id: widget.asset.id,
      accountId: widget.asset.accountId,
      name: widget.asset.name,
      assetType: widget.asset.assetType,
      assetLocation: widget.asset.assetLocation,
      memo: widget.asset.memo,
      purchasePrice: purchase,
      currentValue: current,
      lastProfitRate:
          calculatedProfitRate, // 현재 계산된 수익률을 다음을 위한 lastProfitRate로 저장
    );

    try {
      await _dbHelper.updateAsset(updatedAsset); // Asset 테이블 업데이트

      // 2. AssetSnapshot 저장 (선택된 날짜 기준)
      final String snapshotDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate);

      // 이전 스냅샷의 수익률 가져오기 (수익률 변화율 계산용)
      // 선택된 날짜 이전의 가장 최근 스냅샷을 찾아야 합니다.
      AssetSnapshot? previousSnapshot;
      List<AssetSnapshot> allSnapshots = await _dbHelper
          .getAssetSnapshotsByAssetId(widget.asset.id!);

      // 현재 선택된 날짜보다 이전인 스냅샷들 중 가장 최신 스냅샷을 찾습니다.
      // (오늘 날짜 이전 스냅샷의 profitRate를 가져와야 하므로 필터링)
      final List<AssetSnapshot> relevantSnapshots =
          allSnapshots
              .where(
                (s) => DateTime.parse(s.snapshotDate).isBefore(_selectedDate),
              )
              .toList()
            ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

      if (relevantSnapshots.isNotEmpty) {
        previousSnapshot = relevantSnapshots.last;
      }

      final double profitRateChangeForSnapshot = (previousSnapshot != null)
          ? (calculatedProfitRate - previousSnapshot.profitRate)
          : 0.0; // 최초 스냅샷의 변화율은 0%

      final newSnapshot = AssetSnapshot(
        assetId: widget.asset.id!,
        snapshotDate: snapshotDate,
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
        const SnackBar(content: Text('종목 스냅샷이 성공적으로 저장/업데이트되었습니다.')),
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
      List<AssetSnapshot> allSnapshots = await _dbHelper
          .getAssetSnapshotsByAssetId(widget.asset.id!);

      // 현재 선택된 날짜보다 이전인 스냅샷들 중 가장 최신 스냅샷을 찾습니다.
      final List<AssetSnapshot> relevantSnapshots =
          allSnapshots
              .where(
                (s) => DateTime.parse(s.snapshotDate).isBefore(_selectedDate),
              )
              .toList()
            ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

      if (relevantSnapshots.isNotEmpty) {
        previousSnapshot = relevantSnapshots.last;
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
                '${widget.asset.name} (${widget.asset.assetTypeInKorean} | ${widget.asset.assetLocationInKorean})', // Asset 모델의 getter 사용
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.asset.memo != null && widget.asset.memo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '메모: ${widget.asset.memo}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 24.0),
              // 날짜 선택 필드
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                    ),
                    decoration: const InputDecoration(
                      labelText: '스냅샷 날짜',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      labelStyle: TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '매수금액',
                  border: OutlineInputBorder(),
                  hintText: '정수만 입력하세요 (예: 100000)',
                ),
                style: TextStyle(color: Colors.black), // 입력되는 글씨 색상을 검정색으로 명시
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
                style: TextStyle(color: Colors.black), // 입력되는 글씨 색상을 검정색으로 명시
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
                color: _profitRateChange >= 0 ? Colors.blue : Colors.deepOrange,
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _saveAssetData,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // 버튼 높이
                ),
                child: const Text(
                  '스냅샷 추가/업데이트',
                  style: TextStyle(fontSize: 18),
                ),
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
