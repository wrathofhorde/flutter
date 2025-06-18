// lib/screens/add_account_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/account.dart';

class AddAccountScreen extends StatefulWidget {
  // Account 객체를 선택적으로 받도록 변경합니다.
  final Account? account; // 기존 계좌를 수정할 경우 전달받을 Account 객체

  const AddAccountScreen({
    super.key,
    this.account, // account를 선택적(nullable) 매개변수로 정의
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    // 수정 모드일 경우, 전달받은 account 객체의 값을 컨트롤러에 미리 채웁니다.
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _descriptionController.text = widget.account!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now().toIso8601String(); // ISO 8601 형식 문자열

      // 수정 모드인지, 추가 모드인지 확인
      if (widget.account != null) {
        // 수정 모드: 기존 계좌 정보 업데이트
        final updatedAccount = Account(
          id: widget.account!.id, // 기존 ID 유지
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          createdAt: widget.account!.createdAt, // 기존 생성 시간 유지
          updatedAt: now, // 현재 시간으로 업데이트 시간 변경
        );
        await _dbHelper.updateAccount(updatedAccount);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계좌 정보가 수정되었습니다.')));
      } else {
        // 추가 모드: 새 계좌 생성
        final newAccount = Account(
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          createdAt: now,
          updatedAt: now,
        );
        await _dbHelper.insertAccount(newAccount);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('새 계좌가 추가되었습니다.')));
      }

      Navigator.of(context).pop(true); // 성공적으로 저장 후 true 반환하며 이전 화면으로 돌아감
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account == null ? '새 계좌 추가' : '계좌 수정')),
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
                  labelText: '계좌명',
                  hintText: '예: 주식 투자 계좌',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '계좌명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '메모 (선택 사항)',
                  hintText: '예: 비상금 투자 목적',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAccount,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50), // 버튼 높이
                ),
                child: Text(
                  widget.account == null ? '계좌 추가하기' : '계좌 수정하기',
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
