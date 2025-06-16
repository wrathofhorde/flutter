// lib/screens/add_asset_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assets_snapshot/models/asset.dart';
import 'package:assets_snapshot/database/database_helper.dart';

class AddAssetScreen extends StatefulWidget {
  final int accountId;
  final Asset? asset; // 수정할 Asset 객체 (선택 사항)

  // asset이 있으면 수정 모드, 없으면 추가 모드
  const AddAssetScreen({super.key, required this.accountId, this.asset});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  AssetType _selectedAssetType = AssetType.stock;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool get _isEditing => widget.asset != null; // 수정 모드인지 확인하는 getter

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // 수정 모드인 경우 기존 데이터로 필드 초기화
      _nameController.text = widget.asset!.name;
      _memoController.text = widget.asset!.memo ?? '';
      _selectedAssetType = widget.asset!.assetType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 종목을 추가하거나 업데이트하는 메서드
  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      final String now = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      final assetToSave = Asset(
        id: _isEditing ? widget.asset!.id : null, // 수정 모드면 기존 ID 사용
        accountId: widget.accountId,
        name: _nameController.text.trim(),
        assetType: _selectedAssetType,
        memo: _memoController.text.trim().isNotEmpty
            ? _memoController.text.trim()
            : null,
      );

      try {
        if (_isEditing) {
          // 수정 모드: 업데이트
          await _dbHelper.updateAsset(assetToSave);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('종목이 성공적으로 수정되었습니다!')));
        } else {
          // 추가 모드: 삽입
          await _dbHelper.insertAsset(assetToSave);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('종목이 성공적으로 추가되었습니다!')));
        }
        Navigator.pop(context, true); // 성공 시 true 반환하여 이전 화면 갱신
      } catch (e) {
        String action = _isEditing ? '수정' : '추가';
        String errorMessage = '종목 $action 실패: $e';
        if (e.toString().contains('UNIQUE constraint failed')) {
          errorMessage = '이미 해당 계좌에 같은 이름의 종목이 존재합니다.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        debugPrint('Error $action asset: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '종목 수정' : '새 종목 추가'), // 앱바 타이틀 변경
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '종목명 (필수)',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                style: TextStyle(color: Colors.black),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '종목명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<AssetType>(
                value: _selectedAssetType,
                decoration: InputDecoration(
                  labelText: '종목 유형 (필수)',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: AssetType.values.map((type) {
                  String displayText;
                  if (type == AssetType.etf) {
                    displayText = 'ETF';
                  } else if (type == AssetType.crypto) {
                    displayText = 'Crypto'; // 'Crypto'로 표시
                  } else if (type == AssetType.wrap) {
                    // 'wrap'을 'Wrap'으로 표시
                    displayText = 'Wrap';
                  } else {
                    displayText =
                        type.name[0].toUpperCase() + type.name.substring(1);
                  }

                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      displayText,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (AssetType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedAssetType = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return '종목 유형을 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _memoController,
                decoration: InputDecoration(
                  labelText: '메모 (선택 사항)',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                style: TextStyle(color: Colors.black),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveAsset, // _addAsset 대신 _saveAsset 호출
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: Text(
                  _isEditing ? '종목 수정하기' : '종목 추가하기', // 버튼 텍스트 변경
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
