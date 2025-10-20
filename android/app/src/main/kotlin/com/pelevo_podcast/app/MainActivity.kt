package com.pelevo_podcast.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.pelevo_podcast.app/memory"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPageSize" -> {
                    result.success(getSystemPageSize())
                }
                "optimizeMemory" -> {
                    optimizeMemoryFor16KB()
                    result.success(true)
                }
                "is16KBPageSizeSupported" -> {
                    result.success(is16KBPageSizeSupported())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun getSystemPageSize(): Int {
        return try {
            // For Android 15+ (API 35+), assume 16KB pages
            // For older versions, assume 4KB pages
            val pageSize = if (android.os.Build.VERSION.SDK_INT >= 35) 16384 else 4096
            pageSize
        } catch (e: Exception) {
            4096 // Default to 4KB if detection fails
        }
    }
    
    private fun is16KBPageSizeSupported(): Boolean {
        return getSystemPageSize() >= 16384
    }
    
    private fun optimizeMemoryFor16KB() {
        // Optimize memory allocation for 16KB pages
        try {
            System.gc()
            Runtime.getRuntime().gc()
        } catch (e: Exception) {
            // Ignore exceptions during garbage collection
        }
    }
}