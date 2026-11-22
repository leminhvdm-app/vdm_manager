import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ManagerAppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String publishedAt;

  ManagerAppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
    required this.publishedAt,
  });

  factory ManagerAppUpdateInfo.fromMap(Map<String, dynamic> map) {
    return ManagerAppUpdateInfo(
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 1,
      versionName: map['versionName']?.toString() ?? '1.0.0',
      apkUrl: map['apkUrl']?.toString() ?? '',
      releaseNotes: map['releaseNotes']?.toString() ?? 'Bản cập nhật tính năng và sửa lỗi cho VDM Quản Lý.',
      forceUpdate: map['forceUpdate'] == true,
      publishedAt: map['publishedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'versionCode': versionCode,
      'versionName': versionName,
      'apkUrl': apkUrl,
      'releaseNotes': releaseNotes,
      'forceUpdate': forceUpdate,
      'publishedAt': publishedAt,
    };
  }
}

class ManagerAppUpdateService {
  static const int currentVersionCode = 2;
  static const String currentVersionName = "1.0.1";
  static const MethodChannel _installerChannel = MethodChannel('com.vdmgis.vn/app_installer');

  static const String defaultFirebaseBaseUrl =
      'https://vdm-gis-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Cài đặt file APK trực tiếp thông qua Package Installer của Android
  static Future<bool> installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final res = await _installerChannel.invokeMethod('installApk', {'filePath': filePath});
        return res == true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi gọi trình cài đặt APK: $e');
      return false;
    }
  }

  /// Lấy thông tin bản cập nhật mới nhất từ Firebase
  static Future<ManagerAppUpdateInfo?> fetchLatestUpdateInfo({String? baseUrl}) async {
    try {
      final base = (baseUrl != null && baseUrl.isNotEmpty) ? baseUrl : defaultFirebaseBaseUrl;
      final uri = Uri.parse('$base/vdm_gis/manager_app_update.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        return ManagerAppUpdateInfo.fromMap(map);
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra cập nhật từ Firebase: $e');
    }
    return null;
  }

  /// Đẩy cấu hình phiên bản mới lên Firebase
  static Future<bool> publishUpdateInfo(ManagerAppUpdateInfo info, {String? baseUrl}) async {
    try {
      final base = (baseUrl != null && baseUrl.isNotEmpty) ? baseUrl : defaultFirebaseBaseUrl;
      final uri = Uri.parse('$base/vdm_gis/manager_app_update.json');
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(info.toMap()),
      ).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi publish update info: $e');
      return false;
    }
  }

  /// Kiểm tra và hiển thị hộp thoại cập nhật tự động
  static Future<void> checkForUpdate(BuildContext context, {bool silent = false}) async {
    final info = await fetchLatestUpdateInfo();
    if (info == null) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kết nối máy chủ để kiểm tra bản cập nhật.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (info.versionCode > currentVersionCode) {
      if (context.mounted) {
        _showUpdateDialog(context, info);
      }
    } else {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bạn đang sử dụng phiên bản mới nhất của VDM Quản Lý (v$currentVersionName)!'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    }
  }

  static void _showUpdateDialog(BuildContext context, ManagerAppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) {
        double downloadProgress = 0.0;
        bool isDownloading = false;
        String statusText = '';
        int totalBytes = 0;
        int receivedBytes = 0;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAFAFA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.system_update_rounded, color: Color(0xFF1B5E20), size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'CẬP NHẬT VDM QUẢN LÝ',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hiện tại: v$currentVersionName',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.green),
                        Text('Mới: v${info.versionName}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Nội dung mới trong bản cập nhật:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        info.releaseNotes,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                      ),
                    ),
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: downloadProgress > 0 ? downloadProgress : null,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          statusText,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        Text(
                          '${(downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                if (!info.forceUpdate && !isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Để sau', style: TextStyle(color: Colors.black54)),
                  ),
                if (!isDownloading)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Cập nhật ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (info.apkUrl.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không tìm thấy liên kết tải bản cập nhật!'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isDownloading = true;
                        statusText = 'Đang bắt đầu tải gói cài đặt...';
                      });

                      try {
                        final tempDir = await getTemporaryDirectory();
                        final filePath = '${tempDir.path}/VDM_Manager_update_${info.versionCode}.apk';
                        final file = File(filePath);

                        final client = http.Client();
                        final request = http.Request('GET', Uri.parse(info.apkUrl));
                        request.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android; VDM_Manager)';
                        final response = await client.send(request);

                        if (response.statusCode != 200) {
                          throw 'Lỗi tải tệp: HTTP ${response.statusCode}';
                        }

                        totalBytes = response.contentLength ?? 0;
                        receivedBytes = 0;
                        final sink = file.openWrite();

                        await for (var chunk in response.stream) {
                          sink.add(chunk);
                          receivedBytes += chunk.length;
                          if (totalBytes > 0) {
                            setDialogState(() {
                              downloadProgress = receivedBytes / totalBytes;
                              final mbReceived = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
                              final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                              statusText = 'Đang tải: $mbReceived MB / $mbTotal MB';
                            });
                          }
                        }

                        await sink.flush();
                        await sink.close();
                        client.close();

                        setDialogState(() {
                          statusText = 'Tải xong! Đang mở trình cài đặt...';
                          downloadProgress = 1.0;
                        });

                        // Gọi Intent cài đặt trực tiếp
                        final ok = await installApk(file.path);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã tải APK về: ${file.path}. Vui lòng mở tệp để cài đặt.'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isDownloading = false;
                        });
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi tải bản cập nhật: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

