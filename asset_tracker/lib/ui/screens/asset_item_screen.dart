import 'package:asset_tracker/ui/screens/record_list_screen.dart';
import 'package:flutter/material.dart';
import '../../models/asset_model.dart';
import '../../services/database_service.dart';

class AssetItemScreen extends StatefulWidget {
  final Account account;

  const AssetItemScreen({super.key, required this.account});

  @override
  State<AssetItemScreen> createState() => _AssetItemScreenState();
}

class _AssetItemScreenState extends State<AssetItemScreen> {
  List<AssetItem> _assets = [];

  @override
  void initState() {
    super.initState();
    _refreshAssets();
  }

  Future<void> _refreshAssets() async {
    final data = await DatabaseService.getAssetsByAccount(widget.account.id);
    setState(() => _assets = data);
  }

  void _showAddAssetDialog() {
    final nameController = TextEditingController();
    String selectedType = 'STOCK'; // 기본값

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // 팝업 내 드롭다운 상태 관리를 위해 필요
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${widget.account.name} 종목 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: '종목명 (예: 삼성전자, S&P500)',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'STOCK', child: Text('주식/ETF')),
                  DropdownMenuItem(value: 'CASH', child: Text('현금/예적금')),
                  DropdownMenuItem(value: 'WRAP', child: Text('랩어카운트')),
                  DropdownMenuItem(value: 'LOAN', child: Text('대출/부채')),
                ],
                onChanged: (val) => setDialogState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: '자산 종류'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await DatabaseService.addAssetItem(
                    widget.account.id,
                    name,
                    selectedType,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _refreshAssets();
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.account.name} 보유 종목')),
      body: _assets.isEmpty
          ? const Center(child: Text('등록된 종목이 없습니다.'))
          : ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final asset = _assets[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getIconForType(asset.type)),
                  ),
                  title: Text(asset.name),
                  subtitle: Text(asset.type),
                  trailing: const Icon(Icons.show_chart),
                  // lib/ui/screens/asset_item_screen.dart 내의 onTap 수정
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecordListScreen(assetItem: asset),
                      ),
                    ).then((_) => _refreshAssets());
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssetDialog,
        label: const Text('종목 추가'),
        icon: const Icon(Icons.add_chart),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'STOCK':
        return Icons.trending_up;
      case 'CASH':
        return Icons.attach_money;
      case 'LOAN':
        return Icons.money_off;
      default:
        return Icons.category;
    }
  }
}
