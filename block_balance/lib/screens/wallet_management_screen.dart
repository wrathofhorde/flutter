import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_helper.dart';
import '../services/csv_service.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CsvService _csvService = CsvService();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();

  // 네트워크 선택을 위한 변수
  String _selectedNetwork = 'ETHEREUM';
  final List<String> _networks = ['ETHEREUM', 'POLYGON'];

  String? _selectedFilePath;
  int? _selectedWalletId;
  List<Map<String, dynamic>> _wallets = [];

  @override
  void initState() {
    super.initState();
    _refreshWallets();
  }

  Future<void> _refreshWallets() async {
    final data = await _dbHelper.fetchAll(
      'SELECT * FROM wallets ORDER BY id DESC',
    );
    setState(() {
      _wallets = data;
      if (_wallets.isEmpty) _selectedWalletId = null;
    });
  }

  // 지갑 등록 로직 (네트워크 값 포함)
  void _addWallet() async {
    String address = _addressController.text.trim();
    String alias = _aliasController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지갑 주소를 입력해 주세요.')));
      return;
    }

    await _dbHelper.execute(
      'INSERT INTO wallets (address, network, alias) VALUES (?, ?, ?)',
      [
        address.toLowerCase(),
        _selectedNetwork,
        alias.isEmpty ? '이름 없음' : alias,
      ],
    );

    _addressController.clear();
    _aliasController.clear();
    _refreshWallets();
    FocusScope.of(context).unfocus();
  }

  void _removeWallet(int id) async {
    await _dbHelper.execute('DELETE FROM wallets WHERE id = ?', [id]);
    _refreshWallets();
  }

  Future<void> _pickCSVFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      setState(() => _selectedFilePath = result.files.single.path);
    }
  }

  // 1. 등록 양식 섹션 함수
  Widget _buildRegistrationForm() {
    return Row(
      children: [
        // 지갑 주소 입력
        Expanded(
          flex: 3,
          child: TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: '지갑 주소 (0x...)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 네트워크 선택 드롭다운
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedNetwork,
            decoration: const InputDecoration(
              labelText: '네트워크',
              border: OutlineInputBorder(),
            ),
            items: _networks
                .map((net) => DropdownMenuItem(value: net, child: Text(net)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedNetwork = val!;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        // 별칭 입력
        Expanded(
          flex: 2,
          child: TextField(
            controller: _aliasController,
            decoration: const InputDecoration(
              labelText: '별칭',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _addWallet,
          icon: const Icon(Icons.add),
          label: const Text('등록'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // 2. CSV 섹션 함수
  Widget _buildCsvSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '트랜잭션 데이터 업데이트',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedFilePath ?? '업로드할 CSV 파일을 선택하세요.',
                  style: TextStyle(
                    color: _selectedFilePath == null
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickCSVFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('파일 탐색'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedFilePath != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedWalletId == null
                    ? Colors.grey
                    : Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _selectedWalletId == null
                  ? null
                  : () async {
                      final selectedWallet = _wallets.firstWhere(
                        (w) => w['id'] == _selectedWalletId,
                      );
                      final String walletNetwork =
                          selectedWallet['network']; // 지갑에 등록된 네트워크

                      await _csvService.importCsv(
                        _selectedFilePath!,
                        _selectedWalletId!,
                        walletNetwork,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('데이터베이스 동기화가 완료되었습니다.')),
                        );
                      }
                    },
              child: Text(
                _selectedWalletId == null ? '지갑을 먼저 선택하세요' : '데이터베이스 동기화 시작',
              ),
            ),
          ),
      ],
    );
  }

  // 지갑이 없을 때 안내 UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 지갑이 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '상단 양식을 통해 추적할 지갑을 먼저 등록해 주세요.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 등록 양식 섹션 (상단)
          const Text(
            '새 지갑 등록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRegistrationForm(), // 별도 함수로 분리해서 깔끔하게 관리

          const SizedBox(height: 32),

          // 2. 등록된 지갑 목록 섹션 (중간) - 여기가 질문하신 부분입니다!
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '등록된 지갑 목록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '클릭하여 CSV 업로드 대상 선택',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _wallets.isEmpty
                ? _buildEmptyState() // 지갑 없을 때
                : ListView.builder(
                    itemCount: _wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = _wallets[index];
                      final bool isSelected = _selectedWalletId == wallet['id'];
                      final String network = wallet['network'] ?? 'ETHEREUM';

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isSelected ? Colors.indigo[50] : Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected
                                ? Colors.indigo
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () =>
                              setState(() => _selectedWalletId = wallet['id']),
                          leading: CircleAvatar(
                            backgroundColor: network == 'ETHEREUM'
                                ? Colors.blue[700]
                                : Colors.purple[700],
                            child: Text(
                              network[0], // 'E' 또는 'P' 표시
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                wallet['alias'] ?? '이름 없음',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildNetworkBadge(network), // 네트워크 뱃지 표시
                            ],
                          ),
                          subtitle: Text(
                            wallet['address'],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeWallet(wallet['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 40),

          // 3. CSV 업로드 섹션 (하단)
          _buildCsvSection(),
        ],
      ),
    );
  }

  // 네트워크에 따른 뱃지 UI
  Widget _buildNetworkBadge(String network) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: network == 'ETHEREUM' ? Colors.blue[100] : Colors.purple[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        network,
        style: TextStyle(
          fontSize: 10,
          color: network == 'ETHEREUM' ? Colors.blue[900] : Colors.purple[900],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
