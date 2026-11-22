import 'package:flutter/material.dart';
import '../constants/app_version.dart';
import '../services/manager_api_service.dart';
import '../services/manager_app_update_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const SettingsScreen({super.key, required this.onSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ManagerApiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final success = await ManagerApiService.testFirebaseConnection(_urlController.text);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testResult = success
            ? 'Kết nối Firebase thành công!'
            : 'Không thể kết nối tới URL này. Vui lòng kiểm tra lại mạng hoặc URL.';
      });
    }
  }

  void _saveSettings() {
    ManagerApiService.customFirebaseBaseUrl = _urlController.text.trim();
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cấu hình Firebase!'),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
    Navigator.of(context).pop();
  }

  void _resetDefault() {
    setState(() {
      _urlController.text = ManagerApiService.defaultFirebaseBaseUrl;
      _testResult = null;
    });
  }

  Future<void> _handleClearCache() async {
    await ManagerApiService.clearLocalCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa sạch bộ nhớ cache ngoại tuyến!'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
      widget.onSaved();
    }
  }

  Future<void> _handleResetAllFirebase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Reset sạch Firebase?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ danh sách Cán bộ thực địa và Thiết bị đã lưu trên Firebase (không ảnh hưởng dữ liệu bản đồ Lô rừng). Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ManagerApiService.clearAllUsersAndDevices();
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã làm sạch toàn bộ dữ liệu người dùng trên Firebase!'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
        widget.onSaved();
      }
    }
  }

  Future<void> _handleClearAllDatasetsFirebase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa toàn bộ Dữ liệu rừng?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Hành động này sẽ xóa VĨNH VIỄN toàn bộ tất cả các tập dữ liệu bản đồ Lô rừng đang lưu trên Firebase. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Xóa Hết'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ManagerApiService.clearAllDatasets();
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa sạch toàn bộ tập dữ liệu rừng trên Firebase!'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom > 0
        ? MediaQuery.of(context).viewPadding.bottom
        : (MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 36.0);
    final bottomPadding = (bottomInset < 40.0 ? 40.0 : bottomInset) + 90.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Cài đặt Kết nối',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_sync_rounded, color: Color(0xFF1B5E20)),
                        SizedBox(width: 8),
                        Text(
                          'Firebase Realtime Database',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'URL cơ sở dữ liệu đồng bộ với VDM GIS và các thiết bị thực địa:',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Firebase Database URL',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'https://xxx-default-rtdb.asia-southeast1.firebasedatabase.app',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_find_rounded),
                            label: Text(_isTesting ? 'Đang thử...' : 'Kiểm tra'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _resetDefault,
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Mặc định'),
                        ),
                      ],
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _testSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                              color: _testSuccess ? Colors.green.shade700 : Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _testSuccess ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cleaning_services_rounded, color: Color(0xFF1B5E20)),
                        SizedBox(width: 8),
                        Text(
                          'Quản lý Dữ liệu & Bộ nhớ đệm',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _handleClearCache,
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('Xóa sạch Cache ngoại tuyến trên máy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _handleResetAllFirebase,
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      label: const Text('Làm sạch toàn bộ cán bộ & thiết bị trên Firebase', style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _handleClearAllDatasetsFirebase,
                      icon: const Icon(Icons.folder_delete_rounded, color: Colors.deepOrange),
                      label: const Text('Xóa toàn bộ tất cả Lô rừng trên Firebase', style: TextStyle(color: Colors.deepOrange)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF1B5E20)),
                        SizedBox(width: 8),
                        Text(
                          'Thông tin Ứng dụng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAppInfoRow('Tên ứng dụng:', 'VDM Quản Lý (Admin Tool)'),
                    _buildAppInfoRow('Phiên bản:', AppVersion.versionName),
                    _buildAppInfoRow('Nhà phát triển:', 'Lê Minh'),
                    _buildAppInfoRow('Liên hệ:', 'leminh.vdm@gmail.com'),
                    _buildAppInfoRow('Hệ sinh thái:', 'VDM GIS - Lâm nghiệp 4.0'),
                    _buildAppInfoRow('Quy tắc giao diện:', 'Không che khuất bởi phím điều hướng hệ thống'),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ManagerAppUpdateService.checkForUpdate(context, silent: false);
                        },
                        icon: const Icon(Icons.system_update_rounded),
                        label: const Text(
                          'Kiểm tra bản cập nhật mới',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Lưu cấu hình',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
