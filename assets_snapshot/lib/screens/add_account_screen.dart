// lib/screens/add_account_screen.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/database/database_helper.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addAccount() async {
    if (_formKey.currentState!.validate()) {
      final String now = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      final newAccount = Account(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await _dbHelper.insertAccount(newAccount);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계좌가 성공적으로 추가되었습니다!')));
        Navigator.pop(context, true);
      } catch (e) {
        String errorMessage = '계좌 추가 실패: $e';
        if (e.toString().contains('UNIQUE constraint failed: Accounts.name')) {
          errorMessage = '이미 같은 이름의 계좌가 존재합니다. 다른 이름을 사용해주세요.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 계좌 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                // === 수정 시작 ===
                decoration: InputDecoration(
                  // const 키워드 제거
                  labelText: '계좌명 (필수)',
                  border: OutlineInputBorder(), // 테마에서 제공하는 기본 테두리 스타일 적용
                  filled: true, // 이 부분을 true로 설정해야 테마의 fillColor가 적용됩니다.
                ),
                style: TextStyle(color: Colors.black), // 입력되는 글씨 색상을 검정색으로 명시
                // === 수정 끝 ===
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '계좌명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                // === 수정 시작 ===
                decoration: InputDecoration(
                  // const 키워드 제거
                  labelText: '설명 (선택 사항)',
                  border: OutlineInputBorder(),
                  filled: true, // 이 부분을 true로 설정해야 테마의 fillColor가 적용됩니다.
                ),
                style: TextStyle(color: Colors.black), // 입력되는 글씨 색상을 검정색으로 명시
                // === 수정 끝 ===
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _addAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text('계좌 추가하기', style: TextStyle(fontSize: 18.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
