import 'dart:convert';
import 'dart:io';
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

  /// Tải dữ liệu từ endpoint với cache-busting timestamp
  static Future<http.Response> _fetchFresh(String endpoint) async {
    final separator = endpoint.contains('?') ? '&' : '?';
    final freshUrl = '$endpoint${separator}t=${DateTime.now().millisecondsSinceEpoch}';
    return await http.get(
      Uri.parse(freshUrl),
      headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
    ).timeout(const Duration(seconds: 8));
  }

  /// Tải dữ liệu toàn diện từ Firebase
  static Future<ManagerDataBundle> fetchAllData({bool forceFresh = true}) async {
    try {
      final base = baseUrl;

      // 1. Tải danh sách Cán bộ (Ưu tiên /vdm_gis/thong_tin_su_dung_app.json)
      http.Response usersRes = await _fetchFresh('$base/vdm_gis/thong_tin_su_dung_app.json');
      if (usersRes.body == 'null' || usersRes.body.isEmpty) {
        // Fallback kiểm tra node root nếu chưa có ở /vdm_gis/
        final rootUsersRes = await _fetchFresh('$base/thong_tin_su_dung_app.json');
        if (rootUsersRes.statusCode == 200 && rootUsersRes.body != 'null' && rootUsersRes.body.isNotEmpty) {
          usersRes = rootUsersRes;
        }
      }

      // 2. Tải danh sách Thiết bị (Ưu tiên /vdm_gis/thiet_bi_cai_dat.json)
      http.Response devicesRes = await _fetchFresh('$base/vdm_gis/thiet_bi_cai_dat.json');
      if (devicesRes.body == 'null' || devicesRes.body.isEmpty) {
        final rootDevRes = await _fetchFresh('$base/thiet_bi_cai_dat.json');
        if (rootDevRes.statusCode == 200 && rootDevRes.body != 'null' && rootDevRes.body.isNotEmpty) {
          devicesRes = rootDevRes;
        }
      }

      // 3. Tải danh sách Tập dữ liệu rừng (/vdm_gis/datasets.json)
      http.Response datasetsRes = await _fetchFresh('$base/vdm_gis/datasets.json');
      if (datasetsRes.body == 'null' || datasetsRes.body.isEmpty) {
        final rootDsRes = await _fetchFresh('$base/datasets.json');
        if (rootDsRes.statusCode == 200 && rootDsRes.body != 'null' && rootDsRes.body.isNotEmpty) {
          datasetsRes = rootDsRes;
        }
      }

      final List<UserUsageSummary> usersList = [];
      if (usersRes.statusCode == 200 && usersRes.body.isNotEmpty && usersRes.body != 'null') {
        final dynamic raw = jsonDecode(usersRes.body);
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

      // Sắp xếp người dùng theo số lần mở app giảm dần
      usersList.sort((a, b) => b.tongSoLanMo.compareTo(a.tongSoLanMo));

      final List<InstalledDeviceItem> devicesList = [];
      if (devicesRes.statusCode == 200 && devicesRes.body.isNotEmpty && devicesRes.body != 'null') {
        final dynamic raw = jsonDecode(devicesRes.body);
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
      if (datasetsRes.statusCode == 200 && datasetsRes.body.isNotEmpty && datasetsRes.body != 'null') {
        final dynamic raw = jsonDecode(datasetsRes.body);
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

      final bundle = ManagerDataBundle(
        users: usersList,
        devices: devicesList,
        datasets: datasetsList,
        fetchedAt: DateTime.now(),
        isFromCache: false,
      );

      // Cập nhật lại cache offline với dữ liệu mới nhất (nếu người dùng xóa trên Firebase, cache cũng được xóa đồng bộ)
      await _saveLocalCache(usersRes.body, devicesRes.body, datasetsRes.body);

      return bundle;
    } catch (e) {
      // Nếu mất kết nối mạng hoặc lỗi server, tải từ cache offline
      final cachedBundle = await _loadLocalCache();
      if (cachedBundle != null) {
        return cachedBundle;
      }
      rethrow;
    }
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
