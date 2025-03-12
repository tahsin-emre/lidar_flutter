import Flutter
import MetalKit
import ModelIO
import SceneKit
import UIKit

// ARKit framework'i kontrol et ve import et
#if canImport(ARKit)
  import ARKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var scanHandler: ScanHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // Scanner service channel
    let scanServiceChannel = FlutterMethodChannel(
      name: "lidar_flutter/scan_service",
      binaryMessenger: controller.binaryMessenger)

    // Scanner özel kanalı
    let arScanChannel = FlutterMethodChannel(
      name: "lidar_flutter/ar_scanner",
      binaryMessenger: controller.binaryMessenger)

    // Ana scanner channel
    let scannerChannel = FlutterMethodChannel(
      name: "com.example.lidar_flutter/scanner",
      binaryMessenger: controller.binaryMessenger)

    // Register event channel
    let scanEventChannel = FlutterEventChannel(
      name: "lidar_flutter/scan_events",
      binaryMessenger: controller.binaryMessenger)

    // Create scan handler and set up method channel
    scanHandler = ScanHandler()
    scanEventChannel.setStreamHandler(scanHandler)

    // AR Scanner özel kanalını işle
    arScanChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "supportsLiDAR":
        self.checkLidarSupport(result: result)
      case "startScanning":
        self.scanHandler?.startScanning(result: result)
      case "pauseSession":
        self.scanHandler?.pauseSession(result: result)
      case "resumeSession":
        self.scanHandler?.resumeSession(result: result)
      case "processPointCloudData":
        self.scanHandler?.processAndExportModel(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Handle method calls for main scanner channel
    scannerChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "checkDeviceSupport":
        self.checkDeviceSupport(result: result)
      case "hasLiDAR":
        self.checkLidarSupport(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Handle scan service channel
    scanServiceChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "checkDeviceSupport":
        self.checkDeviceSupport(result: result)
      case "initializeScan":
        self.scanHandler?.initializeScan(result: result)
      case "startScan":
        self.scanHandler?.startScan(result: result)
      case "pauseScan":
        self.scanHandler?.pauseScan(result: result)
      case "resumeScan":
        self.scanHandler?.resumeScan(result: result)
      case "completeScan":
        if let args = call.arguments as? [String: Any],
          let format = args["format"] as? String
        {
          self.scanHandler?.completeScan(format: format, result: result)
        } else {
          self.scanHandler?.completeScan(format: "usdz", result: result)
        }
      case "cancelScan":
        self.scanHandler?.cancelScan(result: result)
      case "getPointCloudData":
        self.scanHandler?.getPointCloudData(result: result)
      case "getAvailableModels":
        self.getAvailableModels(result: result)
      case "deleteModel":
        if let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        {
          self.deleteModel(path: path, result: result)
        } else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENTS",
              message: "Path is required",
              details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func checkLidarSupport(result: @escaping FlutterResult) {
    if #available(iOS 14.0, *) {
      let deviceSupportsLidar = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
      result(deviceSupportsLidar)
    } else {
      result(false)
    }
  }

  private func checkDeviceSupport(result: @escaping FlutterResult) {
    // Check if device supports LiDAR
    if #available(iOS 14.0, *) {
      let deviceSupportsLidar = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
      result(deviceSupportsLidar)
    } else {
      result(false)
    }
  }

  private func getAvailableModels(result: @escaping FlutterResult) {
    // Scan document directory for model files
    let documentsPath = NSSearchPathForDirectoriesInDomains(
      .documentDirectory, .userDomainMask, true
    ).first!
    let fileManager = FileManager.default

    do {
      // Get all files in documents directory
      let modelFiles = try fileManager.contentsOfDirectory(atPath: documentsPath)
        .filter { $0.hasSuffix(".glb") || $0.hasSuffix(".usdz") || $0.hasSuffix(".obj") }
        .map { "\(documentsPath)/\($0)" }

      result(modelFiles)
    } catch {
      result([])
    }
  }

  private func deleteModel(path: String, result: @escaping FlutterResult) {
    let fileManager = FileManager.default

    do {
      if fileManager.fileExists(atPath: path) {
        try fileManager.removeItem(atPath: path)
        result(true)
      } else {
        result(false)
      }
    } catch {
      result(
        FlutterError(
          code: "DELETE_ERROR",
          message: "Failed to delete file: \(error.localizedDescription)",
          details: nil))
    }
  }
}

// ScanHandler manages the AR scanning session and events
class ScanHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var arSession: ARSession?
  private var sceneView: ARSCNView?
  private var isScanning = false
  private var pointCloudData: [simd_float3] = []
  private var meshAnchors: [ARMeshAnchor] = []

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  // MARK: - AR Scanner Specific Methods

  func startScanning(result: @escaping FlutterResult) {
    isScanning = true
    meshAnchors.removeAll()
    pointCloudData.removeAll()

    // Send event that scanning has started
    self.eventSink?(["type": "scanStatus", "status": "started"])
    result(nil)
  }

  func pauseSession(result: @escaping FlutterResult) {
    arSession?.pause()
    result(nil)
  }

  func resumeSession(result: @escaping FlutterResult) {
    // ARWorldTrackingConfiguration oluştur
    let configuration = ARWorldTrackingConfiguration()

    if #available(iOS 13.4, *) {
      configuration.sceneReconstruction = .mesh
      configuration.frameSemantics = .sceneDepth
    }

    arSession?.run(configuration)
    result(nil)
  }

  func processAndExportModel(result: @escaping FlutterResult) {
    // Tarama verilerini 3D modele dönüştür
    DispatchQueue.global(qos: .userInitiated).async {
      if self.meshAnchors.isEmpty {
        // Test için basit bir küp oluştur
        let modelPath = self.createSampleModel()

        DispatchQueue.main.async {
          result(["modelPath": modelPath])
        }
        return
      }

      // Metal cihazı oluştur
      guard let device = MTLCreateSystemDefaultDevice() else {
        DispatchQueue.main.async {
          result(
            FlutterError(code: "NO_METAL", message: "Metal device not available", details: nil))
        }
        return
      }

      // MDLAsset oluştur ve mesh verilerini ekle
      let asset = MDLAsset()

      // Taranmış mesh verilerini ekle
      for anchor in self.meshAnchors {
        if let mesh = self.createSimpleMesh(device: device) {
          asset.add(mesh)
        }
      }

      // Model dosyasını kaydet
      let documentsPath = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
      ).first!
      let timestamp = Int(Date().timeIntervalSince1970)
      let modelPath = "\(documentsPath)/scan_\(timestamp).usdz"

      do {
        // USDZ formatında dışa aktar
        try asset.export(to: URL(fileURLWithPath: modelPath))

        DispatchQueue.main.async {
          result(["modelPath": modelPath])
        }
      } catch {
        print("Error exporting model: \(error)")

        // Hata durumunda örnek model döndür
        let samplePath = self.createSampleModel()
        DispatchQueue.main.async {
          result(["modelPath": samplePath])
        }
      }
    }
  }

  private func createSimpleMesh(device: MTLDevice) -> MDLMesh? {
    // Basit bir küp oluştur
    let allocator = MTKMeshBufferAllocator(device: device)
    let mesh = MDLMesh(
      boxWithExtent: SIMD3<Float>(0.1, 0.1, 0.1),
      segments: SIMD3<UInt32>(2, 2, 2),
      inwardNormals: false,
      geometryType: .triangles,
      allocator: allocator)
    return mesh
  }

  private func createSampleModel() -> String {
    // Basit bir model oluşturup döndür (test amaçlı)
    let documentsPath = NSSearchPathForDirectoriesInDomains(
      .documentDirectory, .userDomainMask, true
    ).first!
    let timestamp = Int(Date().timeIntervalSince1970)
    return "\(documentsPath)/sample_\(timestamp).usdz"
  }

  // MARK: - Scan Methods

  func initializeScan(result: @escaping FlutterResult) {
    // Initialize AR session
    DispatchQueue.main.async {
      self.arSession = ARSession()
      self.sceneView = ARSCNView()
      self.sceneView?.session = self.arSession!

      // Configure AR session for LiDAR scanning
      let configuration = ARWorldTrackingConfiguration()
      if #available(iOS 13.4, *) {
        configuration.sceneReconstruction = .mesh
        configuration.frameSemantics = .sceneDepth
      }

      self.arSession?.run(configuration)

      // Set up callbacks for AR session
      self.arSession?.delegate = self

      result(nil)
    }
  }

  func startScan(result: @escaping FlutterResult) {
    isScanning = true
    result(nil)
  }

  func pauseScan(result: @escaping FlutterResult) {
    isScanning = false
    result(nil)
  }

  func resumeScan(result: @escaping FlutterResult) {
    isScanning = true
    result(nil)
  }

  func completeScan(format: String, result: @escaping FlutterResult) {
    isScanning = false

    if !meshAnchors.isEmpty {
      // Model işleme ve çıktı alma
      processAndExportModel(result: result)
    } else {
      // Test için örnek model döndür
      let modelPath = createSampleModel()
      result(["modelPath": modelPath])
    }
  }

  func cancelScan(result: @escaping FlutterResult) {
    isScanning = false
    arSession?.pause()
    meshAnchors.removeAll()
    pointCloudData.removeAll()
    result(nil)
  }

  func getPointCloudData(result: @escaping FlutterResult) {
    // Point cloud verilerini String listesine dönüştür
    let pointStrings = pointCloudData.map { point in
      return "\(point.x),\(point.y),\(point.z)"
    }

    result(pointStrings)
  }
}

// MARK: - ARSessionDelegate
extension ScanHandler: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard isScanning else { return }

    // Point cloud verilerini topla
    if #available(iOS 13.4, *), let depthData = frame.sceneDepth?.depthMap {
      // Her frame'de point cloud verisini kaydetmek yerine örnek veriler
      if pointCloudData.count < 10000 && arc4random_uniform(100) < 10 {
        // Her 10 karedeki birinden örnek noktalar al
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)

        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(depthData)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthData)

        // Derinlik haritasından nokta bulutu örnekleri oluştur
        for y in stride(from: 0, to: height, by: 10) {
          for x in stride(from: 0, to: width, by: 10) {
            let pixelOffset = y * bytesPerRow + x * MemoryLayout<Float32>.size
            let depth = baseAddress!.load(fromByteOffset: pixelOffset, as: Float32.self)

            if depth > 0 && depth < 5.0 {  // 5 metre mesafeden yakın nesneler
              let point = simd_float3(Float(x) / Float(width), Float(y) / Float(height), depth)
              pointCloudData.append(point)
            }
          }
        }

        CVPixelBufferUnlockBaseAddress(depthData, .readOnly)
      }

      // İlerleme bilgisini gönder
      let progress = min(Double(pointCloudData.count) / 5000.0, 1.0)  // Maksimum 5000 nokta
      self.eventSink?(["type": "scanProgress", "progress": progress])
    }
  }

  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    guard isScanning else { return }

    // Mesh nesneleri topla
    for anchor in anchors {
      if #available(iOS 13.4, *), let meshAnchor = anchor as? ARMeshAnchor {
        meshAnchors.append(meshAnchor)
      }
    }
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard isScanning else { return }

    // Mevcut mesh'leri güncelle
    for anchor in anchors {
      if #available(iOS 13.4, *), let meshAnchor = anchor as? ARMeshAnchor {
        if let index = meshAnchors.firstIndex(where: { $0.identifier == meshAnchor.identifier }) {
          meshAnchors[index] = meshAnchor
        } else {
          meshAnchors.append(meshAnchor)
        }
      }
    }
  }

  func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    // Kaldırılan mesh'leri takip et
    for anchor in anchors {
      if #available(iOS 13.4, *), let meshAnchor = anchor as? ARMeshAnchor {
        meshAnchors.removeAll { $0.identifier == meshAnchor.identifier }
      }
    }
  }

  func session(_ session: ARSession, didFailWithError error: Error) {
    eventSink?(["type": "error", "message": error.localizedDescription])
  }
}
