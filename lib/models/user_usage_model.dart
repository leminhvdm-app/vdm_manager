class UserSessionItem {
  final String sessionKey;
  final String lanMo;
  final String timesBatDau;
  final String timesKetThuc;
  final String thoiGianPhienNay;
  final String tongTimesSuDung;
  final String dienThoai;
  final String thietBi;
  final String deviceTag;
  final String maCaiDat;
  final String updatedAt;

  UserSessionItem({
    required this.sessionKey,
    required this.lanMo,
    required this.timesBatDau,
    required this.timesKetThuc,
    required this.thoiGianPhienNay,
    required this.tongTimesSuDung,
    required this.dienThoai,
    required this.thietBi,
    required this.deviceTag,
    required this.maCaiDat,
    required this.updatedAt,
  });

  factory UserSessionItem.fromMap(String key, Map<String, dynamic> map) {
    return UserSessionItem(
      sessionKey: key,
      lanMo: map['Lần mở app'] as String? ?? map['lanMo'] as String? ?? key,
      timesBatDau: map['Times bắt đầu'] as String? ?? map['timesBatDau'] as String? ?? '--',
      timesKetThuc: map['Times kết thúc'] as String? ?? map['timesKetThuc'] as String? ?? '--',
      thoiGianPhienNay: map['Thời gian dùng phiên này'] as String? ?? map['thoiGianPhienNay'] as String? ?? '--',
      tongTimesSuDung: map['Tổng Times sử dụng'] as String? ?? map['tongTimesSuDung'] as String? ?? '--',
      dienThoai: map['Điện thoại'] as String? ?? map['dienThoai'] as String? ?? '--',
      thietBi: map['Thiết bị'] as String? ?? map['thietBi'] as String? ?? '--',
      deviceTag: map['deviceTag'] as String? ?? '',
      maCaiDat: map['Mã cài đặt'] as String? ?? map['maCaiDat'] as String? ?? map['installCode'] as String? ?? '--',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }
}

class UserUsageSummary {
  final String key;
  final String hoVaTen;
  final String congTy;
  final String donVi;
  final String dienThoai;
  final String thietBi;
  final String hangMay;
  final String model;
  final String heDieuHanh;
  final String timesCaiDat;
  final String tongTimesSuDung;
  final int tongSoLanMo;
  final String lanCuoiHoatDong;
  final String deviceTag;
  final String maCaiDat;
  final String updatedAt;
  final List<UserSessionItem> sessions;

  UserUsageSummary({
    required this.key,
    required this.hoVaTen,
    required this.congTy,
    required this.donVi,
    required this.dienThoai,
    required this.thietBi,
    required this.hangMay,
    required this.model,
    required this.heDieuHanh,
    required this.timesCaiDat,
    required this.tongTimesSuDung,
    required this.tongSoLanMo,
    required this.lanCuoiHoatDong,
    required this.deviceTag,
    required this.maCaiDat,
    required this.updatedAt,
    required this.sessions,
  });

  String get initials {
    final clean = _removeVietnameseAccents(hoVaTen.trim());
    final parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'VDM';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    if (parts.length == 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}${parts.last[0]}'.toUpperCase();
  }

  static String _removeVietnameseAccents(String str) {
    var withAccents = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    var noAccents = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    var result = str;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], noAccents[i]);
    }
    return result;
  }

  factory UserUsageSummary.fromFirebaseUserNode(String userKey, Map<String, dynamic> node) {
    Map<String, dynamic>? summaryMap;
    if (node['Tong_Quan'] is Map) {
      summaryMap = Map<String, dynamic>.from(node['Tong_Quan'] as Map);
    }

    final List<UserSessionItem> sessionsList = [];
    node.forEach((k, v) {
      if (k != 'Tong_Quan' && v is Map) {
        sessionsList.add(UserSessionItem.fromMap(k, Map<String, dynamic>.from(v)));
      }
    });

    // Sắp xếp các phiên: Lần mới nhất lên trước
    sessionsList.sort((a, b) => b.sessionKey.compareTo(a.sessionKey));

    final latestSession = sessionsList.isNotEmpty ? sessionsList.first : null;

    final name = summaryMap?['Họ và Tên'] as String? ??
        summaryMap?['hoVaTen'] as String? ??
        latestSession?.sessionKey ??
        userKey;

    final company = summaryMap?['Công ty'] as String? ?? summaryMap?['congTy'] as String? ?? '--';
    final unit = summaryMap?['Đơn vị'] as String? ?? summaryMap?['donVi'] as String? ?? '--';
    final phone = summaryMap?['Điện thoại'] as String? ?? summaryMap?['dienThoai'] as String? ?? latestSession?.dienThoai ?? '--';
    final device = summaryMap?['Thiết bị'] as String? ?? summaryMap?['thietBi'] as String? ?? latestSession?.thietBi ?? '--';
    final mfg = summaryMap?['Hãng sản xuất'] as String? ?? summaryMap?['hangMay'] as String? ?? '';
    final model = summaryMap?['Model'] as String? ?? summaryMap?['model'] as String? ?? '';
    final os = summaryMap?['Hệ điều hành'] as String? ?? summaryMap?['heDieuHanh'] as String? ?? '';
    final installTime = summaryMap?['Times cài đặt'] as String? ?? summaryMap?['timesCaiDat'] as String? ?? '--';
    final totalDuration = summaryMap?['Tổng Times sử dụng'] as String? ?? summaryMap?['tongTimesSuDung'] as String? ?? '--';
    final openCount = (summaryMap?['Tổng số lần mở app'] as num?)?.toInt() ??
        (summaryMap?['tongSoLanMo'] as num?)?.toInt() ??
        sessionsList.length;
    final lastActive = summaryMap?['Lần cuối hoạt động'] as String? ??
        summaryMap?['lanCuoiHoatDong'] as String? ??
        latestSession?.timesKetThuc ??
        '--';
    final tag = summaryMap?['deviceTag'] as String? ?? latestSession?.deviceTag ?? '';
    final maCaiDat = summaryMap?['Mã cài đặt'] as String? ??
        summaryMap?['maCaiDat'] as String? ??
        summaryMap?['installCode'] as String? ??
        latestSession?.maCaiDat ??
        '--';
    final updateTime = summaryMap?['updatedAt'] as String? ?? latestSession?.updatedAt ?? '';

    return UserUsageSummary(
      key: userKey,
      hoVaTen: name,
      congTy: company,
      donVi: unit,
      dienThoai: phone,
      thietBi: device,
      hangMay: mfg,
      model: model,
      heDieuHanh: os,
      timesCaiDat: installTime,
      tongTimesSuDung: totalDuration,
      tongSoLanMo: openCount,
      lanCuoiHoatDong: lastActive,
      deviceTag: tag,
      maCaiDat: maCaiDat,
      updatedAt: updateTime,
      sessions: sessionsList,
    );
  }
}
