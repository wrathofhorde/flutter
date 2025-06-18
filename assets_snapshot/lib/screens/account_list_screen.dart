// lib/screens/account_list_screen.dart
import 'package:flutter/material.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/screens/add_account_screen.dart';
import 'package:assets_snapshot/screens/asset_list_screen.dart'; // AssetListScreen 임포트
import 'package:assets_snapshot/widgets/add_account_card.dart'; // AddAccountCard 임포트 (새로 추가)

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // 초기 계좌 목록 로드
  }

  // 데이터베이스에서 계좌 목록을 불러오는 비동기 메서드
  Future<void> _loadAccounts() async {
    try {
      final accounts = await _dbHelper.getAccounts();
      setState(() {
        _accounts = accounts;
      });
      debugPrint('Loaded accounts: ${_accounts.length} items');
    } catch (e) {
      debugPrint('Failed to load accounts: $e');
      if (!mounted) return; // 위젯이 마운트 해제되었는지 확인
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계좌를 불러오는 데 실패했습니다: $e')));
    }
  }

  // 계좌 정보 수정/추가 후 목록을 새로고침하는 콜백
  void _onAccountUpdated() {
    _loadAccounts();
  }

  // 계좌 삭제 후 목록을 새로고침하는 콜백
  void _onAccountDeleted() {
    _loadAccounts();
    if (!mounted) return; // 위젯이 마운트 해제되었는지 확인
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계좌가 삭제되었습니다.')));
  }

  // 계좌 옵션(수정/삭제) 바텀 시트 표시
  void _showAccountOptions(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('계좌명 수정'),
                onTap: () async {
                  Navigator.pop(bc); // 바텀 시트 닫기
                  final bool isMountedBeforePush =
                      context.mounted; // push 전 mounted 상태 저장
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddAccountScreen(
                        account: account, // 기존 계좌 정보를 전달하여 수정 모드 활성화
                      ),
                    ),
                  );
                  if (result == true && isMountedBeforePush) {
                    _onAccountUpdated(); // 수정 후 목록 업데이트
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('계좌 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bc); // 바텀 시트 닫기
                  _confirmDelete(context, account); // 삭제 확인 다이얼로그 호출
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 계좌 삭제 확인 다이얼로그
  void _confirmDelete(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('계좌 삭제'),
          content: Text(
            '${account.name} 계좌를 삭제하시겠습니까?\n이 계좌에 포함된 모든 종목 정보도 함께 삭제됩니다.',
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
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기 (즉시)
                await _dbHelper.deleteAccount(account.id!); // DB에서 계좌 삭제

                // DB 작업 완료 후, context가 유효한지 확인
                if (context.mounted) {
                  _onAccountDeleted(); // 삭제 후 목록 갱신 및 스낵바 표시
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계좌 목록'),
        actions: const [], // 앱바의 + 아이콘 제거
      ),
      body: _accounts.isEmpty
          ? const Center(
              child: Text(
                '등록된 계좌가 없습니다.\n새 계좌를 추가해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              // GridView.builder 유지
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 한 줄에 2개의 계좌 카드를 표시
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 1, // 카드 비율 조정
              ),
              itemCount: _accounts.length + 1, // 계좌 목록 + "새 계좌 추가" 타일
              itemBuilder: (context, index) {
                if (index == _accounts.length) {
                  // 마지막 인덱스에 "새 계좌 추가" 타일 배치
                  return AddAccountCard(
                    onRefreshAccounts: _onAccountUpdated, // 계좌 목록 갱신 콜백 전달
                  );
                }

                // 기존 계좌 카드 표시
                final account = _accounts[index];
                return FutureBuilder<Map<String, double>>(
                  future: _dbHelper.getAccountSummary(
                    account.id!,
                  ), // 계좌 ID로 요약 정보 요청
                  builder: (context, snapshot) {
                    double totalPurchase = 0.0;
                    double totalCurrent = 0.0;
                    double totalProfitRate = 0.0;

                    // 데이터 로드 완료 및 유효한 데이터가 있을 경우
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      totalPurchase = snapshot.data!['totalPurchasePrice']!;
                      totalCurrent = snapshot.data!['totalCurrentValue']!;
                      totalProfitRate = snapshot.data!['totalProfitRate']!;
                    } else if (snapshot.hasError) {
                      // 에러 발생 시 디버그 출력
                      debugPrint(
                        'Error loading account summary for ${account.name}: ${snapshot.error}',
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.all(
                        0,
                      ), // GridView에서 이미 패딩을 주므로 카드 자체 마진은 0
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () async {
                          // 계좌를 탭하면 해당 계좌의 자산 목록 화면으로 이동 (AssetListScreen)
                          final bool isMountedBeforePush =
                              context.mounted; // push 전 mounted mounted 상태 저장
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssetListScreen(
                                account: account, // 선택된 계좌 정보 전달
                                onAssetUpdated:
                                    _onAccountUpdated, // 자산 업데이트 시 계좌 목록도 갱신하도록 콜백 전달
                              ),
                            ),
                          );
                          if (result == true && isMountedBeforePush) {
                            _onAccountUpdated(); // AssetListScreen에서 변경사항 발생 시 계좌 목록 갱신
                          }
                        },
                        onLongPress: () {
                          _showAccountOptions(
                            context,
                            account,
                          ); // 길게 누르면 옵션 메뉴 표시
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                account.description ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Divider(color: Colors.grey.shade300), // 구분선
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '총 매수금액:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${totalPurchase.toStringAsFixed(0)} 원',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '총 평가금액:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${totalCurrent.toStringAsFixed(0)} 원',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '총 수익률:',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    '${totalProfitRate.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: totalProfitRate >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
