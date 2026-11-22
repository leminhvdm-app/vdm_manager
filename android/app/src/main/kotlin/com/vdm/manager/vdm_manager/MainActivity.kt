package com.vdm.manager.vdm_manager

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vdmgis.vn/app_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "Tệp APK không tồn tại tại $filePath", null)
                            return@setMethodCallHandler
                        }

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            val apkUri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                file
                            )
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_PATH", "Đường dẫn tệp APK là null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
