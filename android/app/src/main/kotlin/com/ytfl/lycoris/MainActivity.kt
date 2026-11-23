package com.ytfl.lycoris

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ytfl.lycoris/saf_storage"
    private var pendingFolderResult: MethodChannel.Result? = null
    private val FOLDER_PICKER_REQUEST_CODE = 9921

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> {
                    if (pendingFolderResult != null) {
                        result.error("BUSY", "Folder picker already active", null)
                        return@setMethodCallHandler
                    }
                    pendingFolderResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                        )
                    }
                    startActivityForResult(intent, FOLDER_PICKER_REQUEST_CODE)
                }

                "verifyWritable" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr.isNullOrEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        val treeUri = Uri.parse(uriStr)
                        val docDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                        if (docDir == null || !docDir.canWrite()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        // Test writing and deleting probe file
                        val probeName = ".lycoris_probe_${System.currentTimeMillis()}.tmp"
                        val probe = docDir.createFile("text/plain", probeName)
                        if (probe != null && probe.exists()) {
                            probe.delete()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        Log.e("LycorisSAF", "verifyWritable failed: ${e.message}", e)
                        result.success(false)
                    }
                }

                "rotateAndSaveBackup" -> {
                    val uriStr = call.argument<String>("uri")
                    val content = call.argument<String>("content")
                    val currentFileName = call.argument<String>("currentFileName") ?: "lycoris_backup_current.json"
                    val previousFileName = call.argument<String>("previousFileName") ?: "lycoris_backup_previous.json"

                    if (uriStr.isNullOrEmpty() || content == null) {
                        result.error("INVALID_ARGS", "Missing URI or content", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val treeUri = Uri.parse(uriStr)
                        val docDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                            ?: throw Exception("Could not open directory for URI: $uriStr")

                        // 1. Delete existing previous backup if it exists
                        val oldPrev = docDir.findFile(previousFileName)
                        if (oldPrev != null && oldPrev.exists()) {
                            oldPrev.delete()
                        }

                        // 2. Rotate current to previous if current exists
                        val currentFile = docDir.findFile(currentFileName)
                        if (currentFile != null && currentFile.exists()) {
                            var renamed = false
                            try {
                                renamed = currentFile.renameTo(previousFileName)
                            } catch (e: Exception) {
                                Log.w("LycorisSAF", "renameTo failed, falling back to copy", e)
                            }
                            if (!renamed) {
                                val prevFile = docDir.createFile("application/json", previousFileName)
                                if (prevFile != null) {
                                    contentResolver.openInputStream(currentFile.uri)?.use { input ->
                                        contentResolver.openOutputStream(prevFile.uri, "wt")?.use { output ->
                                            input.copyTo(output)
                                        }
                                    }
                                    currentFile.delete()
                                }
                            }
                        }

                        // 3. Write new current backup
                        var newCurrent = docDir.findFile(currentFileName)
                        if (newCurrent == null) {
                            newCurrent = docDir.createFile("application/json", currentFileName)
                        }
                        if (newCurrent == null) {
                            throw Exception("Failed to create backup file $currentFileName")
                        }

                        contentResolver.openOutputStream(newCurrent.uri, "wt")?.use { os ->
                            os.write(content.toByteArray(Charsets.UTF_8))
                            os.flush()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("LycorisSAF", "rotateAndSaveBackup failed: ${e.message}", e)
                        result.error("WRITE_ERROR", e.message, null)
                    }
                }

                "readBackupFile" -> {
                    val uriStr = call.argument<String>("uri")
                    val fileName = call.argument<String>("fileName")
                    if (uriStr.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "Missing URI or fileName", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val treeUri = Uri.parse(uriStr)
                        val docDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                            ?: throw Exception("Could not open directory for URI: $uriStr")
                        val file = docDir.findFile(fileName)
                            ?: throw Exception("File not found: $fileName")

                        val text = contentResolver.openInputStream(file.uri)?.use { stream ->
                            stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                        }
                        result.success(text)
                    } catch (e: Exception) {
                        Log.e("LycorisSAF", "readBackupFile failed: ${e.message}", e)
                        result.error("READ_ERROR", e.message, null)
                    }
                }

                "getBackupInfo" -> {
                    val uriStr = call.argument<String>("uri")
                    val currentFileName = call.argument<String>("currentFileName") ?: "lycoris_backup_current.json"
                    val previousFileName = call.argument<String>("previousFileName") ?: "lycoris_backup_previous.json"

                    if (uriStr.isNullOrEmpty()) {
                        result.success(mapOf(
                            "hasCurrent" to false,
                            "currentSize" to 0L,
                            "currentModified" to null,
                            "hasPrevious" to false,
                            "previousSize" to 0L,
                            "previousModified" to null
                        ))
                        return@setMethodCallHandler
                    }

                    try {
                        val treeUri = Uri.parse(uriStr)
                        val docDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                        if (docDir == null || !docDir.exists()) {
                            result.success(mapOf(
                                "hasCurrent" to false,
                                "currentSize" to 0L,
                                "currentModified" to null,
                                "hasPrevious" to false,
                                "previousSize" to 0L,
                                "previousModified" to null
                            ))
                            return@setMethodCallHandler
                        }

                        val current = docDir.findFile(currentFileName)
                        val previous = docDir.findFile(previousFileName)

                        result.success(mapOf(
                            "hasCurrent" to (current != null && current.exists()),
                            "currentSize" to (current?.length() ?: 0L),
                            "currentModified" to (if (current != null && current.lastModified() > 0) current.lastModified() else null),
                            "hasPrevious" to (previous != null && previous.exists()),
                            "previousSize" to (previous?.length() ?: 0L),
                            "previousModified" to (if (previous != null && previous.lastModified() > 0) previous.lastModified() else null)
                        ))
                    } catch (e: Exception) {
                        Log.e("LycorisSAF", "getBackupInfo failed: ${e.message}", e)
                        result.error("INFO_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == FOLDER_PICKER_REQUEST_CODE) {
            val res = pendingFolderResult
            pendingFolderResult = null
            if (resultCode == Activity.RESULT_OK && data != null && data.data != null) {
                val uri: Uri = data.data!!
                val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                try {
                    contentResolver.takePersistableUriPermission(uri, takeFlags)
                } catch (e: Exception) {
                    Log.e("LycorisSAF", "Failed to take persistable URI permission for $uri", e)
                }

                val docFile = DocumentFile.fromTreeUri(applicationContext, uri)
                val displayName = docFile?.name ?: uri.lastPathSegment ?: "Backup Folder"

                res?.success(mapOf(
                    "uri" to uri.toString(),
                    "displayName" to displayName
                ))
            } else {
                res?.success(null)
            }
        }
    }
}
