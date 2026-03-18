/*
 * Copyright (C) 2026 Lenin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software.
 *
 * This Software may not be claimed as the original work of any other
 * individual or entity.
 *
 * Attribution to the original author is appreciated, but is not required.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 *
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package com.leninasto.plusengine

import android.content.Context
import android.media.MediaScannerConnection
import android.os.Handler
import android.os.Looper
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream

/**
 * Utilities for heavy file operations in FNF: Plus Engine
 */
object FileUtil {

    /**
     * Scans a file so it appears in Android Gallery/File Managers
     */
    fun scanFile(context: Context, path: String) {
        MediaScannerConnection.scanFile(context, arrayOf(path), null, null)
    }

    /**
     * Extracts a ZIP file to a destination folder
     * @param zipFile The ZIP file to extract
     * @param targetDir The destination directory
     * @param onProgress Callback for progress updates (0.0 to 1.0)
     */
    fun extractZip(zipFile: File, targetDir: File, onProgress: (Float) -> Unit, onComplete: (Boolean) -> Unit) {
        Thread {
            try {
                if (!targetDir.exists()) targetDir.mkdirs()
                val totalSize = zipFile.length()
                var extractedSize = 0L

                ZipInputStream(FileInputStream(zipFile)).use { zis ->
                    var entry: ZipEntry? = zis.nextEntry
                    while (entry != null) {
                        val newFile = File(targetDir, entry.name)
                        if (entry.isDirectory) {
                            newFile.mkdirs()
                        } else {
                            newFile.parentFile?.mkdirs()
                            FileOutputStream(newFile).use { fos ->
                                val buffer = ByteArray(4096)
                                var len: Int
                                while (zis.read(buffer).also { len = it } > 0) {
                                    fos.write(buffer, 0, len)
                                    extractedSize += len
                                    val progress = extractedSize.toFloat() / totalSize
                                    Handler(Looper.getMainLooper()).post { onProgress(progress) }
                                }
                            }
                        }
                        zis.closeEntry()
                        entry = zis.nextEntry
                    }
                }
                Handler(Looper.getMainLooper()).post { onComplete(true) }
            } catch (e: Exception) {
                e.printStackTrace()
                Handler(Looper.getMainLooper()).post { onComplete(false) }
            }
        }.start()
    }

    /**
     * Copy a file or directory recursively
     */
    fun copy(source: File, target: File, onComplete: (Boolean) -> Unit) {
        Thread {
            try {
                if (source.isDirectory) {
                    source.copyRecursively(target, overwrite = true)
                } else {
                    source.copyTo(target, overwrite = true)
                }
                Handler(Looper.getMainLooper()).post { onComplete(true) }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post { onComplete(false) }
            }
        }.start()
    }
}
