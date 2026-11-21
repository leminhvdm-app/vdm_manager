import 'package:flutter/material.dart';
import '../models/user_usage_model.dart';
import '../models/installed_device_model.dart';
import '../models/cloud_dataset_model.dart';
import '../services/manager_api_service.dart';
import 'officer_detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ManagerDataBundle? _dataBundle;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedUnitFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bundle = await ManagerApiService.fetchAllData();
      if (mounted) {
        setState(() {
          _dataBundle = bundle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteUser(UserUsageSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa cán bộ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa cán bộ "${user.hoVaTen}" khỏi cơ sở dữ liệu Firebase không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ManagerApiService.deleteUser(user.key);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa cán bộ "${user.hoVaTen}" khỏi Firebase.'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _confirmDeleteDevice(InstalledDeviceItem device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa thiết bị?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa thiết bị của "${device.hoVaTen}" khỏi Firebase không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ManagerApiService.deleteDevice(device.key);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa thiết bị của "${device.hoVaTen}".'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _confirmDeleteDataset(CloudDatasetItem dataset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa dữ liệu rừng?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa vĩnh viễn tập dữ liệu "${dataset.groupName}" khỏi máy chủ Firebase không?'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Tên: ${dataset.groupName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('• Mã: ${dataset.datasetKey}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  Text('• Quy mô: ${dataset.plotCount} Lô rừng', style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dữ liệu sau khi xóa sẽ không thể phục hồi!',
              style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 12),
                Text('Đang xóa "${dataset.groupName}" trên Firebase...'),
              ],
            ),
            duration: const Duration(seconds: 15),
          ),
        );
      }

      final ok = await ManagerApiService.deleteDataset(dataset.datasetKey);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa thành công tập dữ liệu "${dataset.groupName}".'),
              backgroundColor: const Color(0xFF1B5E20),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa tập dữ liệu. Vui lòng kiểm tra lại mạng!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<String> _getAvailableUnits() {
    if (_dataBundle == null) return ['Tất cả'];
    final set = <String>{'Tất cả'};
    for (var u in _dataBundle!.users) {
      if (u.donVi.isNotEmpty && u.donVi != '--') {
        set.add(u.donVi);
      }
    }
    for (var d in _dataBundle!.devices) {
      if (d.donVi.isNotEmpty && d.donVi != '--') {
        set.add(d.donVi);
      }
    }
    return set.toList();
  }

  List<UserUsageSummary> _getFilteredUsers() {
    if (_dataBundle == null) return [];
    return _dataBundle!.users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.hoVaTen.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.dienThoai.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.donVi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.congTy.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesUnit = _selectedUnitFilter == 'Tất cả' || user.donVi == _selectedUnitFilter;

      return matchesSearch && matchesUnit;
    }).toList();
  }

  List<InstalledDeviceItem> _getFilteredDevices() {
    if (_dataBundle == null) return [];
    return _dataBundle!.devices.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.hoVaTen.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.tenThietBi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.donVi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.hangMay.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesUnit = _selectedUnitFilter == 'Tất cả' || d.donVi == _selectedUnitFilter;
      return matchesSearch && matchesUnit;
    }).toList();
  }

  List<CloudDatasetItem> _getFilteredDatasets() {
    if (_dataBundle == null) return [];
    return _dataBundle!.datasets.where((ds) {
      return _searchQuery.isEmpty ||
          ds.groupName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ds.datasetKey.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ds.deviceTag.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFE53935),
      const Color(0xFF8E24AA),
      const Color(0xFFFB8C00),
      const Color(0xFF00897B),
      const Color(0xFF3949AB),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Image.asset(
                'assets/icon_app.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VDM QUẢN LÝ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Giám sát người dùng & thiết bị thực địa',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới trực tiếp',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Cài đặt kết nối',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(onSaved: _loadData),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.people_alt_rounded, size: 20),
              text: 'Cán bộ (${_dataBundle?.users.length ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.phone_android_rounded, size: 20),
              text: 'Thiết bị (${_dataBundle?.devices.length ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.cloud_done_rounded, size: 20),
              text: 'Dữ liệu rừng (${_dataBundle?.datasets.length ?? 0})',
            ),
          ],
        ),
      ),
      // BẢO ĐẢM TOÀN BỘ GIAO DIỆN KHÔNG BỊ PHÍM ĐIỀU HƯỚNG CHE CHẮN
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1B5E20)),
                    SizedBox(height: 16),
                    Text('Đang đồng bộ trực tiếp với Firebase...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : _errorMessage != null && _dataBundle == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          const Text(
                            'Không thể kết nối Firebase',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF1B5E20),
                    child: Column(
                      children: [
                        // Status & Quick KPI Header
                        _buildSummaryHeader(),

                        // Search bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên, thiết bị, đơn vị...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),

                        // Unit filter chips
                        if (_tabController.index != 2) _buildUnitFilterBar(),

                        // Tab View Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildUsersList(),
                              _buildDevicesList(),
                              _buildDatasetsList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final bundle = _dataBundle;
    final isCache = bundle?.isFromCache ?? false;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCache ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCache ? 'Dữ liệu Ngoại tuyến (Cache)' : 'Trực tuyến Firebase',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCache ? Colors.orange.shade900 : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              if (bundle != null)
                Text(
                  'Cập nhật: ${_formatTime(bundle.fetchedAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKpiCard('Cán bộ', '${bundle?.totalOfficerCount ?? 0}', Icons.people, Colors.blue),
              const SizedBox(width: 8),
              _buildKpiCard('Thiết bị', '${bundle?.totalDeviceCount ?? 0}', Icons.smartphone, Colors.purple),
              const SizedBox(width: 8),
              _buildKpiCard('Lô rừng', '${bundle?.totalPlotCount ?? 0}', Icons.forest, Colors.green),
              const SizedBox(width: 8),
              _buildKpiCard('Lượt mở', '${bundle?.totalOpenCount ?? 0}', Icons.open_in_browser, Colors.amber.shade800),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitFilterBar() {
    final units = _getAvailableUnits();
    if (units.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: units.length,
        itemBuilder: (context, i) {
          final u = units[i];
          final isSelected = u == _selectedUnitFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(u, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              selectedColor: const Color(0xFF1B5E20),
              backgroundColor: Colors.white,
              onSelected: (selected) {
                if (selected) setState(() => _selectedUnitFilter = u);
              },
            ),
          );
        },
      ),
    );
  }

  double _getSafeBottomPadding(BuildContext ctx) {
    final bottomInset = MediaQuery.of(ctx).viewPadding.bottom > 0
        ? MediaQuery.of(ctx).viewPadding.bottom
        : (MediaQuery.of(ctx).padding.bottom > 0 ? MediaQuery.of(ctx).padding.bottom : 36.0);
    // Luôn bảo đảm ít nhất 130px khoảng đệm dưới để nội dung không bao giờ bị che khuất bởi phím điều hướng hệ thống (kể cả Android 15/16)
    return (bottomInset < 40.0 ? 40.0 : bottomInset) + 90.0;
  }

  Widget _buildUsersList() {
    final users = _getFilteredUsers();
    final bottomPadding = _getSafeBottomPadding(context);

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy cán bộ phù hợp từ khóa.'
                  : 'Chưa có cán bộ nào trên Firebase.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final avatarColor = _getAvatarColor(user.hoVaTen);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OfficerDetailScreen(user: user, onUserDeleted: _loadData),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarColor.withValues(alpha: 0.18),
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: avatarColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.hoVaTen,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.congTy,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.donVi,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa khỏi Firebase',
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                        onPressed: () => _confirmDeleteUser(user),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.thietBi.isNotEmpty ? user.thietBi : user.dienThoai,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${user.tongSoLanMo} lần mở',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.tongTimesSuDung,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Xem chi tiết >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
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
  }

  Widget _buildDevicesList() {
    final devices = _getFilteredDevices();
    final bottomPadding = _getSafeBottomPadding(context);

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_disabled_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy thiết bị phù hợp từ khóa.'
                  : 'Chưa có thiết bị nào cài đặt app trên Firebase.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final d = devices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.smartphone_rounded, color: Colors.purple.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.hoVaTen,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            d.tenThietBi,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xóa thiết bị này khỏi Firebase',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                      onPressed: () => _confirmDeleteDevice(d),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (d.heDieuHanh.isNotEmpty)
                  _buildDeviceRow(Icons.system_update_alt_rounded, 'HĐH: ${d.heDieuHanh}'),
                _buildDeviceRow(Icons.calendar_month_outlined, 'Cài đặt: ${d.timesCaiDat}'),
                _buildDeviceRow(Icons.history_rounded, 'Lần cuối mở: ${d.lanCuoiMoApp}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${d.tongSoLanMo} lần mở',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Dùng: ${d.tongTimesSuDung}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatasetsList() {
    final datasets = _getFilteredDatasets();
    final bottomPadding = _getSafeBottomPadding(context);

    if (datasets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terrain_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'Không có tập dữ liệu rừng nào trên máy chủ.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      itemCount: datasets.length,
      itemBuilder: (context, index) {
        final ds = datasets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.terrain_rounded, color: Colors.green.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ds.groupName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Mã tập tin: ${ds.datasetKey}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Xóa tập dữ liệu này khỏi máy chủ',
                      onPressed: () => _confirmDeleteDataset(ds),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.forest_rounded, size: 14, color: Colors.green.shade800),
                          const SizedBox(width: 4),
                          Text(
                            '${ds.plotCount} Lô rừng',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Text(
                            '${ds.poiCount} Mốc/POI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đồng bộ bởi: ${ds.deviceTag}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      ds.updatedAt.isNotEmpty
                          ? ds.updatedAt.split('.').first.replaceAll('T', ' ')
                          : '--',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
