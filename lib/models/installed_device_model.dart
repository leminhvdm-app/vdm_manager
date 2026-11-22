import '../services/manager_license_helper.dart';

class InstalledDeviceItem {
  final String key;
  final String hoVaTen;
  final String congTy;
  final String donVi;
  final String dienThoai;
  final String tenThietBi;
  final String hangMay;
  final String model;
  final String heDieuHanh;
  final String timesCaiDat;
  final String lanCuoiMoApp;
  final String tongTimesSuDung;
  final int tongSoLanMo;
  final String maCaiDat;
  final String maKichHoat;
  final bool isActivated;
  final String updatedAt;

  InstalledDeviceItem({
    required this.key,
    required this.hoVaTen,
    required this.congTy,
    required this.donVi,
    required this.dienThoai,
    required this.tenThietBi,
    required this.hangMay,
    required this.model,
    required this.heDieuHanh,
    required this.timesCaiDat,
    required this.lanCuoiMoApp,
    required this.tongTimesSuDung,
    required this.tongSoLanMo,
    required this.maCaiDat,
    required this.maKichHoat,
    required this.isActivated,
    required this.updatedAt,
  });

  factory InstalledDeviceItem.fromMap(String key, Map<String, dynamic> map) {
    final rawMaCaiDat = map['Mã cài đặt'] as String? ??
        map['maCaiDat'] as String? ??
        map['installCode'] as String? ??
        '--';

    final isAct = map['isActivated'] as bool? ??
        map['Đã kích hoạt'] as bool? ??
        (map['trangThai'] == 'Đã kích hoạt');

    final rawMaKichHoat = map['Mã kích hoạt'] as String? ??
        map['maKichHoat'] as String? ??
        (rawMaCaiDat != '--' ? ManagerLicenseHelper.generateActivationKey(rawMaCaiDat) : '--');

    return InstalledDeviceItem(
      key: key,
      hoVaTen: map['Họ và Tên'] as String? ?? map['hoVaTen'] as String? ?? key,
      congTy: map['Công ty'] as String? ?? map['congTy'] as String? ?? '--',
      donVi: map['Đơn vị'] as String? ?? map['donVi'] as String? ?? '--',
      dienThoai: map['Điện thoại'] as String? ?? map['dienThoai'] as String? ?? '--',
      tenThietBi: map['Tên thiết bị'] as String? ?? map['tenThietBi'] as String? ?? '--',
      hangMay: map['Hãng máy'] as String? ?? map['hangMay'] as String? ?? '',
      model: map['Model'] as String? ?? map['model'] as String? ?? '',
      heDieuHanh: map['Hệ điều hành'] as String? ?? map['heDieuHanh'] as String? ?? '',
      timesCaiDat: map['Times cài đặt'] as String? ?? map['timesCaiDat'] as String? ?? '--',
      lanCuoiMoApp: map['Lần cuối mở app'] as String? ?? map['lanCuoiMoApp'] as String? ?? '--',
      tongTimesSuDung: map['Tổng Times sử dụng'] as String? ?? map['tongTimesSuDung'] as String? ?? '--',
      tongSoLanMo: (map['Tổng số lần mở app'] as num?)?.toInt() ??
          (map['tongSoLanMo'] as num?)?.toInt() ??
          0,
      maCaiDat: rawMaCaiDat,
      maKichHoat: rawMaKichHoat,
      isActivated: isAct,
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hoVaTen': hoVaTen,
      'congTy': congTy,
      'donVi': donVi,
      'dienThoai': dienThoai,
      'tenThietBi': tenThietBi,
      'hangMay': hangMay,
      'model': model,
      'heDieuHanh': heDieuHanh,
      'timesCaiDat': timesCaiDat,
      'lanCuoiMoApp': lanCuoiMoApp,
      'tongTimesSuDung': tongTimesSuDung,
      'tongSoLanMo': tongSoLanMo,
      'maCaiDat': maCaiDat,
      'maKichHoat': maKichHoat,
      'isActivated': isActivated,
      'updatedAt': updatedAt,
    };
  }
}
