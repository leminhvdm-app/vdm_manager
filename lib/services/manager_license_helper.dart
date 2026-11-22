/// Thuật toán tạo Mã kích hoạt đồng bộ giữa App Quản lý và App Thực địa
class ManagerLicenseHelper {
  static const String _secretSalt = "VDM_GIS_FOREST_2026_LICENSE_SECRET";

  /// Sinh mã kích hoạt từ Mã cài đặt của máy
  /// Ví dụ: VDM-7A8B-9C2D -> 6829-4153
  static String generateActivationKey(String installCode) {
    if (installCode.isEmpty || installCode == '--') return '--';

    final clean = installCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final combined = "$clean$_secretSalt";

    int hash1 = 0x811c9dc5;
    const prime = 0x01000193;
    for (var i = 0; i < combined.length; i++) {
      hash1 ^= combined.codeUnitAt(i);
      hash1 = (hash1 * prime) & 0xFFFFFFFF;
    }

    int hash2 = 0x55555555;
    for (var i = 0; i < combined.length; i++) {
      hash2 = ((hash2 << 5) + hash2) ^ combined.codeUnitAt(i);
      hash2 &= 0xFFFFFFFF;
    }

    final part1 = ((hash1.abs() % 9000) + 1000).toString();
    final part2 = ((hash2.abs() % 9000) + 1000).toString();
    return '$part1-$part2';
  }
}
