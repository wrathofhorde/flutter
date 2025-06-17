// lib/screens/add_asset_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/database/database_helper.dart';

class AddAssetScreen extends StatefulWidget {
  final int accountId;
  final Asset? asset; // 기존 종목을 수정할 경우 사용 (null이면 새로운 종목)

  const AddAssetScreen({super.key, required this.accountId, this.asset});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  AssetType? _selectedAssetType;
  AssetLocation? _selectedAssetLocation; // !!! 새 필드 추가 !!!

  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.asset!.name;
      _memoController.text = widget.asset!.memo ?? '';
      _selectedAssetType = widget.asset!.assetType;
      _selectedAssetLocation = widget.asset!.assetLocation; // !!! 기존 값 로드 !!!
    } else {
      // 새로운 종목 추가 시 기본값 설정 (선택 사항)
      _selectedAssetType = AssetType.stock; // 기본 종목 유형
      _selectedAssetLocation = AssetLocation.domestic; // !!! 기본 투자 지역 (국내) !!!
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      final asset = Asset(
        id: _isEditing ? widget.asset!.id : null,
        accountId: widget.accountId,
        name: _nameController.text,
        assetType: _selectedAssetType!,
        assetLocation: _selectedAssetLocation!, // !!! 선택된 지역 저장 !!!
        memo: _memoController.text.isNotEmpty ? _memoController.text : null,
        // purchasePrice, currentValue, lastProfitRate는 AssetCalculatorScreen에서 관리되므로 여기서는 null (혹은 기본값)
        purchasePrice: _isEditing ? widget.asset!.purchasePrice : null,
        currentValue: _isEditing ? widget.asset!.currentValue : null,
        lastProfitRate: _isEditing ? widget.asset!.lastProfitRate : null,
      );

      try {
        if (_isEditing) {
          await _dbHelper.updateAsset(asset);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('종목 정보가 업데이트되었습니다.')));
        } else {
          await _dbHelper.insertAsset(asset);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('새로운 종목이 추가되었습니다.')));
        }
        Navigator.of(context).pop(true); // 성공 시 true 반환
      } catch (e) {
        debugPrint('Failed to save asset: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('종목 저장 실패: $e')));
      }
    }
  }

  // AssetType enum 값을 한글 텍스트로 변환
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

  // AssetLocation enum 값을 한글 텍스트로 변환
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '종목 수정' : '새 종목 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '종목명',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black), // 라벨 색상
                  hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
                  filled: true, // 배경 채우기 활성화
                  fillColor: Colors.white, // 배경 색상 (필요시 조절)
                ),
                style: const TextStyle(color: Colors.black),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '종목명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // AssetType 선택 드롭다운
              DropdownButtonFormField<AssetType>(
                value: _selectedAssetType,
                decoration: const InputDecoration(
                  labelText: '자산 유형',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black), // 라벨 색상
                  hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
                  filled: true, // 배경 채우기 활성화
                  fillColor: Colors.white, // 배경 색상 (필요시 조절)
                ),
                dropdownColor: Colors.white, // !!! 드롭다운 메뉴의 배경색 설정 !!!
                iconEnabledColor: Colors.black, // 드롭다운 아이콘 (화살표) 색상
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ), // !!! 선택된 항목의 텍스트 색상 !!!
                items: AssetType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_assetTypeToKorean(type)), // 한글 표시
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssetType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '자산 유형을 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // !!! AssetLocation 선택 드롭다운 추가 !!!
              DropdownButtonFormField<AssetLocation>(
                value: _selectedAssetLocation,
                decoration: const InputDecoration(
                  labelText: '투자 지역',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black), // 라벨 색상
                  hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
                  filled: true, // 배경 채우기 활성화
                  fillColor: Colors.white, // 배경 색상 (필요시 조절)
                ),
                dropdownColor: Colors.white, // !!! 드롭다운 메뉴의 배경색 설정 !!!
                iconEnabledColor: Colors.black, // 드롭다운 아이콘 (화살표) 색상
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ), // !!! 선택된 항목의 텍스트 색상 !!!
                items: AssetLocation.values.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(_assetLocationToKorean(location)), // 한글 표시
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssetLocation = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '투자 지역을 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택 사항)',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black), // 라벨 색상
                  hintStyle: TextStyle(color: Colors.grey), // 힌트 텍스트 색상
                  filled: true, // 배경 채우기 활성화
                  fillColor: Colors.white, // 배경 색상 (필요시 조절)
                ),
                maxLines: 3,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveAsset,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  _isEditing ? '종목 정보 업데이트' : '종목 추가하기',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
