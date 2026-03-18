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

import android.content.Intent
import org.haxe.extension.Extension

/**
 * JNI Extension for FNF: Plus Engine
 * Provides native Android functionality accessible from Haxe
 */
class PlusEngineExtension : Extension() {
    
    companion object {
        
        /**
         * Open File Manager Activity from Haxe
         * @param initialPath Optional initial directory path
         */
        @JvmStatic
        fun openFileManager(initialPath: String? = null) {
            val activity = Extension.mainActivity ?: return
            val intent = Intent(activity, FileManagerActivity::class.java)
            
            initialPath?.let {
                intent.putExtra(FileManagerActivity.EXTRA_INITIAL_PATH, it)
            }
            
            activity.startActivity(intent)
        }
        
        /**
         * Open File Manager to a specific location
         * @param location One of: "mods", "saves", "logs", "assets"
         */
        @JvmStatic
        fun openFileManagerLocation(location: String) {
            val activity = Extension.mainActivity ?: return
            val intent = Intent(activity, FileManagerActivity::class.java)
            
            intent.putExtra(FileManagerActivity.EXTRA_START_LOCATION, location)
            
            activity.startActivity(intent)
        }
        
        /**
         * Open mods folder directly
         */
        @JvmStatic
        fun openModsFolder() {
            openFileManagerLocation("mods")
        }
        
        /**
         * Open saves folder directly
         */
        @JvmStatic
        fun openSavesFolder() {
            openFileManagerLocation("saves")
        }
        
        /**
         * Open logs folder directly
         */
        @JvmStatic
        fun openLogsFolder() {
            openFileManagerLocation("logs")
        }
        
        /**
         * Open assets folder directly
         */
        @JvmStatic
        fun openAssetsFolder() {
            openFileManagerLocation("assets")
        }
        
        /**
         * Get app's external files directory path
         */
        @JvmStatic
        fun getExternalFilesPath(): String {
            val activity = Extension.mainActivity ?: return ""
            return activity.getExternalFilesDir(null)?.absolutePath ?: ""
        }
        
        /**
         * Get external storage directory path
         */
        @JvmStatic
        fun getExternalStoragePath(): String {
            return android.os.Environment.getExternalStorageDirectory().absolutePath
        }
        
        /**
         * Check if external storage is writable
         */
        @JvmStatic
        fun isExternalStorageWritable(): Boolean {
            return android.os.Environment.getExternalStorageState() == android.os.Environment.MEDIA_MOUNTED
        }
        
        /**
         * Get free space on external storage (in bytes)
         */
        @JvmStatic
        fun getExternalStorageFreeSpace(): Long {
            val stat = android.os.StatFs(android.os.Environment.getExternalStorageDirectory().path)
            return stat.availableBlocksLong * stat.blockSizeLong
        }

        /**
         * Show a native MD3 message box from Haxe.
         */
        @JvmStatic
        fun showMessageBox(title: String, message: String) {
            val activity = Extension.mainActivity ?: return
            activity.runOnUiThread {
                NativeUI.showDialog(
                    context = activity,
                    title = title,
                    message = message,
                    positiveText = "OK"
                )
            }
        }
    }
}
