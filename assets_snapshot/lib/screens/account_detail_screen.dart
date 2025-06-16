// lib/screens/account_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:assets_snapshot/models/account.dart';
import 'package:assets_snapshot/database/database_helper.dart';
import 'package:assets_snapshot/models/asset.dart'; // Asset 모델 임포트
import 'package:assets_snapshot/screens/add_asset_screen.dart'; // AddAssetScreen 임포트 (아직 만들지 않았지만 미리)

class AccountDetailScreen extends StatefulWidget {
  final Account account; // 이 화면으로 전달될 계좌 정보

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Asset> _assets = []; // 이 계좌에 속한 종목 리스트

  @override
  void initState() {
    super.initState();
    _loadAssets(); // 화면 초기화 시 종목 로드
  }

  // 특정 계좌의 종목들을 데이터베이스에서 불러오는 메서드
  Future<void> _loadAssets() async {
    try {
      final assets = await _dbHelper.getAssetsByAccountId(widget.account.id!);
      setState(() {
        _assets = assets;
      });
      debugPrint(
        'Loaded assets for account ${widget.account.name}: ${_assets.length} items',
      );
    } catch (e) {
      debugPrint('Failed to load assets: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('종목을 불러오는 데 실패했습니다: $e')));
    }
  }

  // 종목 추가 화면으로 이동하는 메서드
  void _navigateToAddAssetScreen() async {
    // AddAssetScreen으로 이동하며, 새로운 종목이 추가되면 true를 반환받음
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddAssetScreen(accountId: widget.account.id!), // 계좌 ID 전달
      ),
    );

    // 종목이 성공적으로 추가되었다면 (result가 true라면) 종목 리스트 갱신
    if (result == true) {
      _loadAssets();
    }
  }

  // 종목 삭제 메서드 (나중에 구현)
  Future<void> _deleteAsset(int assetId) async {
    try {
      await _dbHelper.deleteAsset(assetId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종목이 삭제되었습니다.')));
      _loadAssets(); // 삭제 후 리스트 갱신
    } catch (e) {
      debugPrint('Failed to delete asset: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('종목 삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} 상세'), // 계좌명으로 앱바 타이틀 설정
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddAssetScreen, // 종목 추가 화면으로 이동
            tooltip: '종목 추가',
          ),
        ],
      ),
      body: _assets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '아직 종목이 없습니다.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text('오른쪽 상단 + 버튼을 눌러 추가해주세요.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final asset = _assets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(asset.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('유형: ${asset.assetType.name}'), // enum의 name 속성 사용
                        if (asset.memo != null && asset.memo!.isNotEmpty)
                          Text('메모: ${asset.memo}'),
                        // 여기에 나중에 수량, 평균 매수가 등 추가 정보 표시 가능
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddAssetScreen(
                                  accountId: widget.account.id!,
                                  asset: asset, // 수정할 asset 객체를 전달
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadAssets(); // 수정 후 리스트 갱신
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('종목 삭제'),
                                content: Text('${asset.name} 종목을 정말 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteAsset(asset.id!); // 확인 후 삭제 메서드 호출
                                      Navigator.of(ctx).pop(); // 대화 상자 닫기
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
