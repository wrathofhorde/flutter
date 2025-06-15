// lib/screens/account_list_screen.dart

import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/screens/add_account_screen.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  late Future<List<Account>> _accountsFuture; // 계좌 목록을 비동기로 가져올 Future
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // 위젯 초기화 시 계좌 목록 로드
  }

  // 계좌 목록을 로드하는 함수
  void _loadAccounts() {
    setState(() {
      _accountsFuture = _dbHelper.getAccounts(); // DatabaseHelper에서 계좌 목록 가져오기
    });
  }

  // 계좌 삭제 로직
  void _deleteAccount(int id) async {
    await _dbHelper.deleteAccount(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계좌가 삭제되었습니다.')));
    _loadAccounts(); // 삭제 후 목록 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 계좌 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // 새 계좌 추가 화면으로 이동
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAccountScreen(),
                ),
              );
              // AddAccountScreen에서 true를 반환하면 계좌 목록 갱신
              if (result == true) {
                _loadAccounts();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture, // 비동기 작업
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터 로딩 중
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 오류 발생 시
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // 데이터가 없는 경우
            return const Center(child: Text('아직 등록된 계좌가 없습니다. 새 계좌를 추가해주세요!'));
          } else {
            // 데이터 로드 성공 시 목록 표시
            final List<Account> accounts = snapshot.data!;
            return ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  elevation: 2.0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      account.description ?? '설명 없음', // 설명이 없으면 '설명 없음' 표시
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        // 삭제 확인 다이얼로그
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('계좌 삭제'),
                            content: Text(
                              '${account.name} 계좌를 정말 삭제하시겠습니까? 관련 자산 및 스냅샷 정보도 모두 삭제됩니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteAccount(account.id!);
                                  Navigator.of(ctx).pop();
                                },
                                child: const Text(
                                  '삭제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // TODO: 계좌 상세 화면으로 이동 (추후 구현)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${account.name} 상세 정보 보기 (아직 미구현)'),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
