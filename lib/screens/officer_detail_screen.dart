import 'package:flutter/material.dart';
import '../models/user_usage_model.dart';
import '../services/manager_api_service.dart';

class OfficerDetailScreen extends StatelessWidget {
  final UserUsageSummary user;
  final VoidCallback? onUserDeleted;

  const OfficerDetailScreen({super.key, required this.user, this.onUserDeleted});

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

  Future<void> _handleDelete(BuildContext context) async {
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
        content: Text('Bạn có chắc muốn xóa cán bộ "${user.hoVaTen}" khỏi Firebase? Hành động này không thể hoàn tác.'),
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

    if (confirmed == true && context.mounted) {
      final ok = await ManagerApiService.deleteUser(user.key);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa cán bộ "${user.hoVaTen}" khỏi Firebase.'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
        onUserDeleted?.call();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(user.hoVaTen);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom > 0
        ? MediaQuery.of(context).viewPadding.bottom
        : (MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 36.0);
    final bottomPadding = (bottomInset < 40.0 ? 40.0 : bottomInset) + 90.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Chi tiết Cán bộ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Xóa cán bộ khỏi Firebase',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          children: [
            // Header Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: avatarColor.withValues(alpha: 0.18),
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: avatarColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.hoVaTen,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.congTy,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.donVi,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    // KPI Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricItem(
                          icon: Icons.launch_rounded,
                          label: 'Số lần mở app',
                          value: '${user.tongSoLanMo} lần',
                          color: Colors.blue.shade700,
                        ),
                        _buildMetricItem(
                          icon: Icons.timer_outlined,
                          label: 'Tổng thời gian',
                          value: user.tongTimesSuDung,
                          color: Colors.teal.shade700,
                        ),
                        _buildMetricItem(
                          icon: Icons.access_time_rounded,
                          label: 'Lần cuối hoạt động',
                          value: user.lanCuoiHoatDong,
                          color: Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin Thiết bị
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_android_rounded, color: Color(0xFF1B5E20)),
                        SizedBox(width: 8),
                        Text(
                          'Thông số Thiết bị & Cài đặt',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow('Thiết bị:', user.thietBi.isNotEmpty ? user.thietBi : user.dienThoai),
                    if (user.hangMay.isNotEmpty) _buildDetailRow('Hãng máy:', user.hangMay),
                    if (user.model.isNotEmpty) _buildDetailRow('Model:', user.model),
                    if (user.heDieuHanh.isNotEmpty) _buildDetailRow('Hệ điều hành:', user.heDieuHanh),
                    _buildDetailRow('Times cài đặt:', user.timesCaiDat),
                    if (user.deviceTag.isNotEmpty) _buildDetailRow('Nhãn thiết bị:', user.deviceTag),
                    if (user.updatedAt.isNotEmpty) _buildDetailRow('Cập nhật lúc:', user.updatedAt),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lịch sử phiên hoạt động
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch sử phiên sử dụng (${user.sessions.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  Text(
                    'Gần nhất lên đầu',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (user.sessions.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Chưa có chi tiết từng phiên hoặc phiên đang chạy.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ...user.sessions.asMap().entries.map((entry) {
                final index = entry.key;
                final session = entry.value;
                return _buildSessionCard(session, index == 0);
              }),

            const SizedBox(height: 20),
            // Nút xóa cán bộ
            OutlinedButton.icon(
              onPressed: () => _handleDelete(context),
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              label: const Text('Xóa cán bộ này khỏi hệ thống Firebase', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(UserSessionItem session, bool isLatest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLatest
            ? BorderSide(color: Colors.green.shade400, width: 1.2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLatest ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        session.lanMo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLatest ? const Color(0xFF2E7D32) : Colors.black87,
                        ),
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MỚI NHẤT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Phiên này: ${session.thoiGianPhienNay}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bắt đầu: ${session.timesBatDau}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kết thúc: ${session.timesKetThuc}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lũy kế: ${session.tongTimesSuDung}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  session.dienThoai,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
