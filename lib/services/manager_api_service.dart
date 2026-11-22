import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/user_usage_model.dart';
import '../models/installed_device_model.dart';
import '../models/cloud_dataset_model.dart';

class ManagerDataBundle {
  final List<UserUsageSummary> users;
  final List<InstalledDeviceItem> devices;
  final List<CloudDatasetItem> datasets;
  final DateTime fetchedAt;
  final bool isFromCache;

  ManagerDataBundle({
    required this.users,
    required this.devices,
    required this.datasets,
    required this.fetchedAt,
    this.isFromCache = false,
  });

  int get totalOfficerCount => users.length;
  int get totalDeviceCount => devices.length;
  int get totalPlotCount => datasets.fold(0, (acc, item) => acc + item.plotCount);
  int get totalOpenCount => users.fold(0, (acc, item) => acc + item.tongSoLanMo);
}

class ManagerApiService {
  static const String defaultFirebaseBaseUrl =
      'https://vdm-gis-default-rtdb.asia-southeast1.firebasedatabase.app';

  static String customFirebaseBaseUrl = defaultFirebaseBaseUrl;

  static String get baseUrl {
    if (customFirebaseBaseUrl.trim().isEmpty) {
      return defaultFirebaseBaseUrl;
    }
    var clean = customFirebaseBaseUrl.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  /// Tải dữ liệu từ endpoint với cache-busting timestamp và timeout linh hoạt
  static Future<http.Response> _fetchFresh(String endpoint, {Duration timeout = const Duration(seconds: 15)}) async {
    final separator = endpoint.contains('?') ? '&' : '?';
    final freshUrl = '$endpoint${separator}t=${DateTime.now().millisecondsSinceEpoch}';
    return await http.get(
      Uri.parse(freshUrl),
      headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
    ).timeout(timeout);
  }

  /// Tải danh sách Tập dữ liệu rừng tối ưu (Ưu tiên metadata siêu nhẹ, tránh tải toàn bộ polygon nặng gây timeout)
  static Future<List<CloudDatasetItem>> _fetchDatasets(String base) async {
    final List<CloudDatasetItem> datasetsList = [];
    try {
      // 1. Thử tải từ node metadata siêu nhẹ (1KB, phản hồi ngay lập tức trong 0.2s)
      final metaRes = await _fetchFresh('$base/vdm_gis/dataset_metadata.json', timeout: const Duration(seconds: 8));
      if (metaRes.statusCode == 200 && metaRes.body != 'null' && metaRes.body.isNotEmpty) {
        final dynamic raw = jsonDecode(metaRes.body);
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              datasetsList.add(CloudDatasetItem.fromMap(k.toString(), Map<String, dynamic>.from(v)));
            }
          });
          if (datasetsList.isNotEmpty) return datasetsList;
        }
      }
    } catch (_) {}

    try {
      // 2. Thử truy vấn shallow để lấy danh sách key cực nhanh (không tải toàn bộ polygon tọa độ nặng)
      final shallowRes = await _fetchFresh('$base/vdm_gis/datasets.json?shallow=true', timeout: const Duration(seconds: 8));
      if (shallowRes.statusCode == 200 && shallowRes.body != 'null' && shallowRes.body.isNotEmpty) {
        final dynamic raw = jsonDecode(shallowRes.body);
        if (raw is Map) {
          final keys = raw.keys.map((e) => e.toString()).toList();
          final futures = keys.map((key) async {
            try {
              final encKey = Uri.encodeComponent(key);
              final gNameRes = await _fetchFresh('$base/vdm_gis/datasets/$encKey/groupName.json', timeout: const Duration(seconds: 6));
              final pCountRes = await _fetchFresh('$base/vdm_gis/datasets/$encKey/plotCount.json', timeout: const Duration(seconds: 6));
              final dTagRes = await _fetchFresh('$base/vdm_gis/datasets/$encKey/deviceTag.json', timeout: const Duration(seconds: 6));
              final upAtRes = await _fetchFresh('$base/vdm_gis/datasets/$encKey/updatedAt.json', timeout: const Duration(seconds: 6));

              String gName = key;
              if (gNameRes.statusCode == 200 && gNameRes.body != 'null') {
                try { gName = jsonDecode(gNameRes.body).toString(); } catch (_) { gName = gNameRes.body.replaceAll('"', ''); }
              }
              int pCount = 0;
              if (pCountRes.statusCode == 200 && pCountRes.body != 'null') {
                pCount = int.tryParse(pCountRes.body) ?? 0;
              }
              String dTag = '--';
              if (dTagRes.statusCode == 200 && dTagRes.body != 'null') {
                try { dTag = jsonDecode(dTagRes.body).toString(); } catch (_) { dTag = dTagRes.body.replaceAll('"', ''); }
              }
              String upAt = '';
              if (upAtRes.statusCode == 200 && upAtRes.body != 'null') {
                try { upAt = jsonDecode(upAtRes.body).toString(); } catch (_) { upAt = upAtRes.body.replaceAll('"', ''); }
              }

              return CloudDatasetItem(
                datasetKey: key,
                groupName: gName,
                deviceTag: dTag,
                plotCount: pCount,
                poiCount: 0,
                updatedAt: upAt,
              );
            } catch (_) {
              return CloudDatasetItem(
                datasetKey: key,
                groupName: key,
                deviceTag: '--',
                plotCount: 0,
                poiCount: 0,
                updatedAt: '',
              );
            }
          });

          final results = await Future.wait(futures);
          return results;
        }
      }
    } catch (_) {}

    return datasetsList;
  }

  /// Tải dữ liệu toàn diện từ Firebase (Song song, chịu lỗi cao, không bao giờ bị đơ vì tập dữ liệu lớn)
  static Future<ManagerDataBundle> fetchAllData({bool forceFresh = true}) async {
    final base = baseUrl;
    String usersBody = '';
    String devicesBody = '';
    String datasetsBody = '';

    // 1. Tải danh sách Cán bộ (vdm_gis/thong_tin_su_dung_app.json)
    final Future<List<UserUsageSummary>> usersFuture = () async {
      final List<UserUsageSummary> list = [];
      try {
        http.Response res = await _fetchFresh('$base/vdm_gis/thong_tin_su_dung_app.json');
        if (res.body == 'null' || res.body.isEmpty) {
          final rootRes = await _fetchFresh('$base/thong_tin_su_dung_app.json');
          if (rootRes.statusCode == 200 && rootRes.body != 'null' && rootRes.body.isNotEmpty) {
            res = rootRes;
          }
        }
        if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
          usersBody = res.body;
          final dynamic raw = jsonDecode(res.body);
          if (raw is Map) {
            raw.forEach((k, v) {
              if (v is Map) {
                list.add(UserUsageSummary.fromFirebaseUserNode(
                  k.toString(),
                  Map<String, dynamic>.from(v),
                ));
              }
            });
          }
        }
        list.sort((a, b) => b.tongSoLanMo.compareTo(a.tongSoLanMo));
      } catch (e) {
        debugPrint('Lỗi tải Cán bộ từ Firebase: $e');
      }
      return list;
    }();

    // 2. Tải danh sách Thiết bị (vdm_gis/thiet_bi_cai_dat.json)
    final Future<List<InstalledDeviceItem>> devicesFuture = () async {
      final List<InstalledDeviceItem> list = [];
      try {
        http.Response res = await _fetchFresh('$base/vdm_gis/thiet_bi_cai_dat.json');
        if (res.body == 'null' || res.body.isEmpty) {
          final rootRes = await _fetchFresh('$base/thiet_bi_cai_dat.json');
          if (rootRes.statusCode == 200 && rootRes.body != 'null' && rootRes.body.isNotEmpty) {
            res = rootRes;
          }
        }
        if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
          devicesBody = res.body;
          final dynamic raw = jsonDecode(res.body);
          if (raw is Map) {
            raw.forEach((k, v) {
              if (v is Map) {
                list.add(InstalledDeviceItem.fromMap(
                  k.toString(),
                  Map<String, dynamic>.from(v),
                ));
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Lỗi tải Thiết bị từ Firebase: $e');
      }
      return list;
    }();

    // 3. Tải danh sách Tập dữ liệu rừng tối ưu (Không tải polygon nặng)
    final Future<List<CloudDatasetItem>> datasetsFuture = _fetchDatasets(base);

    // Chạy đồng thời cả 3 tác vụ song song
    final results = await Future.wait([usersFuture, devicesFuture, datasetsFuture]);
    final usersList = results[0] as List<UserUsageSummary>;
    final devicesList = results[1] as List<InstalledDeviceItem>;
    final datasetsList = results[2] as List<CloudDatasetItem>;

    // Nếu không lấy được cán bộ hay thiết bị (có thể do rớt mạng), thử lấy từ bộ nhớ đệm offline
    if (usersList.isEmpty && devicesList.isEmpty) {
      final cachedBundle = await _loadLocalCache();
      if (cachedBundle != null && (cachedBundle.users.isNotEmpty || cachedBundle.devices.isNotEmpty)) {
        return cachedBundle;
      }
      // Kiểm tra kết nối mạng
      final isOnline = await testFirebaseConnection(base);
      if (!isOnline) {
        throw Exception('Không thể kết nối đến máy chủ Firebase. Vui lòng kiểm tra lại mạng 4G/Wifi hoặc URL máy chủ trong phần Cài đặt.');
      }
    }

    final bundle = ManagerDataBundle(
      users: usersList,
      devices: devicesList,
      datasets: datasetsList,
      fetchedAt: DateTime.now(),
      isFromCache: false,
    );

    // Lưu vào bộ nhớ đệm offline
    if (usersBody.isNotEmpty || devicesBody.isNotEmpty) {
      await _saveLocalCache(usersBody, devicesBody, datasetsBody);
    }

    return bundle;
  }

  /// Xóa vĩnh viễn cán bộ khỏi Firebase trực tiếp trên app
  static Future<bool> deleteUser(String userKey) async {
    try {
      final base = baseUrl;
      final encodedKey = Uri.encodeComponent(userKey);
      await Future.wait([
        http.delete(Uri.parse('$base/vdm_gis/thong_tin_su_dung_app/$encodedKey.json')),
        http.delete(Uri.parse('$base/thong_tin_su_dung_app/$encodedKey.json')),
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xóa vĩnh viễn thiết bị khỏi Firebase trực tiếp trên app
  static Future<bool> deleteDevice(String deviceKey) async {
    try {
      final base = baseUrl;
      final encodedKey = Uri.encodeComponent(deviceKey);
      await Future.wait([
        http.delete(Uri.parse('$base/vdm_gis/thiet_bi_cai_dat/$encodedKey.json')),
        http.delete(Uri.parse('$base/thiet_bi_cai_dat/$encodedKey.json')),
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xóa toàn bộ dữ liệu người dùng và thiết bị trên Firebase (Reset sạch)
  static Future<bool> clearAllUsersAndDevices() async {
    try {
      final base = baseUrl;
      await Future.wait([
        http.delete(Uri.parse('$base/vdm_gis/thong_tin_su_dung_app.json')),
        http.delete(Uri.parse('$base/thong_tin_su_dung_app.json')),
        http.delete(Uri.parse('$base/vdm_gis/thiet_bi_cai_dat.json')),
        http.delete(Uri.parse('$base/thiet_bi_cai_dat.json')),
      ]);
      await clearLocalCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xóa vĩnh viễn tập dữ liệu rừng khỏi Firebase trực tiếp trên app
  static Future<bool> deleteDataset(String datasetKey) async {
    try {
      final base = baseUrl;
      final encodedKey = Uri.encodeComponent(datasetKey);
      await Future.wait([
        http.delete(Uri.parse('$base/vdm_gis/datasets/$encodedKey.json')),
        http.delete(Uri.parse('$base/datasets/$encodedKey.json')),
        http.delete(Uri.parse('$base/vdm_gis/dataset_metadata/$encodedKey.json')),
        http.delete(Uri.parse('$base/dataset_metadata/$encodedKey.json')),
      ]);
      await clearLocalCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xóa toàn bộ tất cả tập dữ liệu rừng trên Firebase
  static Future<bool> clearAllDatasets() async {
    try {
      final base = baseUrl;
      await Future.wait([
        http.delete(Uri.parse('$base/vdm_gis/datasets.json')),
        http.delete(Uri.parse('$base/datasets.json')),
        http.delete(Uri.parse('$base/vdm_gis/dataset_metadata.json')),
        http.delete(Uri.parse('$base/dataset_metadata.json')),
      ]);
      await clearLocalCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/vdm_manager_offline_cache.json');
  }

  static Future<void> _saveLocalCache(String usersJson, String devicesJson, String datasetsJson) async {
    try {
      final file = await _getCacheFile();
      final cacheData = {
        'cachedAt': DateTime.now().toIso8601String(),
        'users': usersJson,
        'devices': devicesJson,
        'datasets': datasetsJson,
      };
      await file.writeAsString(jsonEncode(cacheData));
    } catch (_) {}
  }

  static Future<void> clearLocalCache() async {
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<ManagerDataBundle?> _loadLocalCache() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '') ?? DateTime.now();

      final List<UserUsageSummary> usersList = [];
      final String? usersJson = map['users'] as String?;
      if (usersJson != null && usersJson.isNotEmpty && usersJson != 'null') {
        final dynamic raw = jsonDecode(usersJson);
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              usersList.add(UserUsageSummary.fromFirebaseUserNode(
                k.toString(),
                Map<String, dynamic>.from(v),
              ));
            }
          });
        }
      }

      final List<InstalledDeviceItem> devicesList = [];
      final String? devicesJson = map['devices'] as String?;
      if (devicesJson != null && devicesJson.isNotEmpty && devicesJson != 'null') {
        final dynamic raw = jsonDecode(devicesJson);
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              devicesList.add(InstalledDeviceItem.fromMap(
                k.toString(),
                Map<String, dynamic>.from(v),
              ));
            }
          });
        }
      }

      final List<CloudDatasetItem> datasetsList = [];
      final String? datasetsJson = map['datasets'] as String?;
      if (datasetsJson != null && datasetsJson.isNotEmpty && datasetsJson != 'null') {
        final dynamic raw = jsonDecode(datasetsJson);
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              datasetsList.add(CloudDatasetItem.fromMap(
                k.toString(),
                Map<String, dynamic>.from(v),
              ));
            }
          });
        }
      }

      return ManagerDataBundle(
        users: usersList,
        devices: devicesList,
        datasets: datasetsList,
        fetchedAt: cachedAt,
        isFromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Kích hoạt hoặc hủy kích hoạt / khóa thiết bị từ xa trên Firebase
  static Future<bool> setDeviceActivation(String deviceKey, bool isActivated, {String? installCode}) async {
    try {
      final base = baseUrl;
      final encKey = Uri.encodeComponent(deviceKey);
      final isBlocked = !isActivated;
      final patchPayload = {
        'isActivated': isActivated,
        'Đã kích hoạt': isActivated,
        'isBlocked': isBlocked,
        'Đã khóa': isBlocked,
        'trangThai': isActivated ? 'Đã kích hoạt' : 'Đã khóa',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final res = await http.patch(
        Uri.parse('$base/vdm_gis/thiet_bi_cai_dat/$encKey.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patchPayload),
      ).timeout(const Duration(seconds: 8));

      // Cập nhật song song node danh sách khóa và danh sách kích hoạt theo mã cài đặt
      if (installCode != null && installCode.isNotEmpty && installCode != '--') {
        final cleanCode = installCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
        await http.put(
          Uri.parse('$base/vdm_gis/danh_sach_khoa/$cleanCode.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(isBlocked),
        ).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 500));

        await http.put(
          Uri.parse('$base/vdm_gis/danh_sach_kich_hoat/$cleanCode.json'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(isActivated),
        ).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 500));
      }

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra kết nối tới Firebase
  static Future<bool> testFirebaseConnection(String url) async {
    try {
      var clean = url.trim();
      if (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      final testUri = Uri.parse('$clean/.json?shallow=true&t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(testUri).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
