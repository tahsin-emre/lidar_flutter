package com.example.lidar_flutter

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper
import java.util.Random
import java.io.File
import java.nio.FloatBuffer
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// ARCore sınıfları
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.Frame
import com.google.ar.core.exceptions.UnavailableException

class MainActivity: FlutterActivity() {
    private val SCAN_SERVICE_CHANNEL = "lidar_flutter/scan_service"
    private val SCAN_EVENT_CHANNEL = "lidar_flutter/scan_events"
    private val AR_SCANNER_CHANNEL = "lidar_flutter/ar_scanner"
    private var scanHandler: ScanHandler? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create scan handler
        scanHandler = ScanHandler(context)
        
        // Set up method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCAN_SERVICE_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "checkDeviceSupport" -> {
                    checkDeviceSupport(result)
                }
                "initializeScan" -> {
                    scanHandler?.initializeScan(result)
                }
                "startScan" -> {
                    scanHandler?.startScan(result)
                }
                "pauseScan" -> {
                    scanHandler?.pauseScan(result)
                }
                "resumeScan" -> {
                    scanHandler?.resumeScan(result)
                }
                "completeScan" -> {
                    val format = call.argument<String>("format") ?: "glb"
                    scanHandler?.completeScan(format, result)
                }
                "cancelScan" -> {
                    scanHandler?.cancelScan(result)
                }
                "getPointCloudData" -> {
                    scanHandler?.getPointCloudData(result)
                }
                "getAvailableModels" -> {
                    getAvailableModels(result)
                }
                "deleteModel" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        deleteModel(path, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up AR scanner channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AR_SCANNER_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startScanning" -> {
                    scanHandler?.startScanning(result)
                }
                "pauseSession" -> {
                    scanHandler?.pauseSession(result)
                }
                "resumeSession" -> {
                    scanHandler?.resumeSession(result)
                }
                "processPointCloudData" -> {
                    scanHandler?.processAndExportModel(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCAN_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    scanHandler?.setEventSink(events)
                }
                
                override fun onCancel(arguments: Any?) {
                    scanHandler?.setEventSink(null)
                }
            }
        )
    }
    
    private fun checkDeviceSupport(result: MethodChannel.Result) {
        // ARCore desteğini kontrol et
        val availability = ArCoreApk.getInstance().checkAvailability(context)
        val isSupported = availability.isSupported
        result.success(isSupported)
    }
    
    private fun getAvailableModels(result: MethodChannel.Result) {
        // Modelleri ara
        val models = mutableListOf<String>()
        val filesDir = context.filesDir
        
        filesDir.listFiles()?.forEach { file ->
            if (file.isFile && (file.name.endsWith(".glb") || file.name.endsWith(".gltf") || file.name.endsWith(".obj"))) {
                models.add(file.absolutePath)
            }
        }
        
        result.success(models)
    }
    
    private fun deleteModel(path: String, result: MethodChannel.Result) {
        val file = File(path)
        val deleted = if (file.exists()) file.delete() else false
        result.success(deleted)
    }
}

/**
 * Handles the AR scanning functionality
 */
class ScanHandler(private val context: android.content.Context) {
    private var eventSink: EventChannel.EventSink? = null
    private var isScanning = false
    private val handler = Handler(Looper.getMainLooper())
    private val random = Random()
    
    // ARCore değişkenleri
    private var arSession: Session? = null
    private val pointCloudData = mutableListOf<FloatArray>()
    
    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }
    
    // ARCore oturumunu başlat
    fun initializeArSession(): Boolean {
        try {
            // ARCore kullanılabilirliğini kontrol et
            if (ArCoreApk.getInstance().requestInstall(null, true) == ArCoreApk.InstallStatus.INSTALLED) {
                // ARCore yüklü, oturum oluştur
                arSession = Session(context)
                
                // Derinlik API'sini etkinleştir
                val config = arSession?.config
                config?.depthMode = Config.DepthMode.AUTOMATIC
                arSession?.configure(config)
                
                return true
            }
        } catch (e: UnavailableException) {
            // ARCore kullanılamıyor
            println("ARCore unavailable: ${e.message}")
        }
        
        return false
    }
    
    fun initializeScan(result: MethodChannel.Result) {
        if (initializeArSession()) {
            result.success(null)
        } else {
            // ARCore kullanılamıyorsa, simülasyon modunu etkinleştir
            handler.postDelayed({
                result.success(null)
            }, 1000)
        }
    }
    
    // AR Scanner özel yöntemleri
    fun startScanning(result: MethodChannel.Result) {
        isScanning = true
        pointCloudData.clear()
        
        // Tarama başladı etkinliği
        val event = HashMap<String, Any>()
        event["type"] = "scanStatus"
        event["status"] = "started"
        eventSink?.success(event)
        
        result.success(null)
    }
    
    fun pauseSession(result: MethodChannel.Result) {
        arSession?.pause()
        result.success(null)
    }
    
    fun resumeSession(result: MethodChannel.Result) {
        try {
            arSession?.resume()
            result.success(null)
        } catch (e: Exception) {
            result.error("SESSION_ERROR", "Error resuming session: ${e.message}", null)
        }
    }
    
    fun processAndExportModel(result: MethodChannel.Result) {
        // Nokta bulutu verilerini işle ve 3D model oluştur
        Thread {
            // Model dosyası oluştur (gerçekte nokta bulutu verilerinden model oluşturulmalı)
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val fileName = "scan_$timestamp.glb"
            val filePath = File(context.filesDir, fileName).absolutePath
            
            // Basit bir OBJ dosyası oluştur (gerçekte nokta bulutu işlenmeli)
            createSampleModelFile(filePath)
            
            // Sonucu ana iş parçacığında döndür
            handler.post {
                result.success(filePath)
            }
        }.start()
    }
    
    private fun createSampleModelFile(filePath: String): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                file.createNewFile()
            }
            return true
        } catch (e: Exception) {
            println("Error creating model file: ${e.message}")
            return false
        }
    }
    
    fun startScan(result: MethodChannel.Result) {
        isScanning = true
        
        // Tarama ilerlemesi simülasyonu başlat
        startProgressSimulation()
        
        result.success(null)
    }
    
    fun pauseScan(result: MethodChannel.Result) {
        isScanning = false
        result.success(null)
    }
    
    fun resumeScan(result: MethodChannel.Result) {
        isScanning = true
        
        // İlerleme simülasyonunu devam ettir
        startProgressSimulation()
        
        result.success(null)
    }
    
    fun completeScan(format: String, result: MethodChannel.Result) {
        isScanning = false
        
        // Model dosyası oluştur
        processAndExportModel(result)
    }
    
    fun cancelScan(result: MethodChannel.Result) {
        isScanning = false
        pointCloudData.clear()
        result.success(null)
    }
    
    fun getPointCloudData(result: MethodChannel.Result) {
        // Nokta bulutu verilerini string listesine dönüştür
        val points = pointCloudData.map { point ->
            "${point[0]},${point[1]},${point[2]}"
        }
        
        result.success(points)
    }
    
    private fun collectPointCloudData(frame: Frame) {
        // ARCore frame'inden nokta bulutu verilerini topla
        val pointCloud = frame.acquirePointCloud()
        val buffer = pointCloud.points
        
        // Buffer'dan noktaları al
        val numPoints = buffer.remaining() / 4
        for (i in 0 until numPoints step 10) { // Her 10 noktadan birini al (optimize etmek için)
            if (pointCloudData.size >= 10000) break // Maksimum nokta sayısını sınırla
            
            val point = FloatArray(3)
            point[0] = buffer.get()
            point[1] = buffer.get()
            point[2] = buffer.get()
            buffer.get() // Confidence değerini atla
            
            // Nokta bulutu listesine ekle
            pointCloudData.add(point)
        }
        
        pointCloud.release()
    }
    
    private fun startProgressSimulation() {
        if (!isScanning) return
        
        // Nokta bulutu toplama ve ilerleme simülasyonu
        handler.postDelayed({
            if (isScanning) {
                // Rastgele nokta ekle (gerçek uygulamada ARCore'dan alınır)
                if (pointCloudData.size < 10000) {
                    val point = FloatArray(3)
                    point[0] = random.nextFloat() * 2 - 1
                    point[1] = random.nextFloat() * 2 - 1
                    point[2] = random.nextFloat() * 5
                    pointCloudData.add(point)
                }
                
                // İlerleme olayını gönder
                val progress = pointCloudData.size.toDouble() / 5000.0
                val clampedProgress = progress.coerceIn(0.0, 1.0)
                
                val event = HashMap<String, Any>()
                event["type"] = "scanProgress"
                event["progress"] = clampedProgress
                
                eventSink?.success(event)
                
                // Devam et
                startProgressSimulation()
            }
        }, 100)
    }
} 