@preconcurrency import AVFoundation
import SwiftUI

/// A camera-based QR code scanner sheet for exhibition and testing simulation.
public struct QRCodeScannerSheet: View {
  @Environment(\.dismiss) private var dismiss
  public let onCodeScanned: (String) -> Void

  @State private var hasPermission = false
  @State private var permissionDenied = false

  public init(onCodeScanned: @escaping (String) -> Void) {
    self.onCodeScanned = onCodeScanned
  }

  public var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        if hasPermission {
          QRScannerCameraView { code in
            onCodeScanned(code)
            dismiss()
          }
          .ignoresSafeArea()

          // Viewfinder Overlay
          VStack(spacing: 20) {
            Spacer()

            ZStack {
              RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                .frame(width: 250, height: 250)

              Image(systemName: "viewfinder")
                .font(.system(size: 240, weight: .ultraLight))
                .foregroundStyle(Color.white.opacity(0.3))
            }

            Text("Point camera at a Site QR code")
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(Color.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(.ultraThinMaterial, in: Capsule())

            Spacer()
          }
        } else if permissionDenied {
          VStack(spacing: 16) {
            Image(systemName: "camera.fill")
              .font(.system(size: 44))
              .foregroundStyle(.secondary)

            Text("Camera Access Required")
              .font(.headline)
              .foregroundStyle(.white)

            Text("Please allow camera access in Settings to scan site QR codes during the exhibition.")
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.7))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
          }
        } else {
          ProgressView()
            .tint(.white)
        }
      }
      .navigationTitle("Scan Site QR")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .preferredColorScheme(.dark)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
          .foregroundStyle(.white)
        }
      }
      .task {
        await checkCameraPermission()
      }
    }
  }

  private func checkCameraPermission() async {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      hasPermission = true
    case .notDetermined:
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      if granted {
        hasPermission = true
      } else {
        permissionDenied = true
      }
    case .denied, .restricted:
      permissionDenied = true
    @unknown default:
      permissionDenied = true
    }
  }
}

// MARK: - UIViewControllerRepresentable

private struct QRScannerCameraView: UIViewControllerRepresentable {
  let onCodeScanned: (String) -> Void

  func makeUIViewController(context: Context) -> QRScannerViewController {
    let controller = QRScannerViewController()
    controller.onCodeScanned = onCodeScanned
    return controller
  }

  func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

// MARK: - View Controller

private final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  var onCodeScanned: ((String) -> Void)?

  private let captureSession = AVCaptureSession()
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var hasFoundCode = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    setupCaptureSession()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !captureSession.isRunning {
      captureSession.startRunning()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if captureSession.isRunning {
      captureSession.stopRunning()
    }
  }

  private func setupCaptureSession() {
    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

    do {
      let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
      guard captureSession.canAddInput(videoInput) else { return }
      captureSession.addInput(videoInput)

      let metadataOutput = AVCaptureMetadataOutput()
      guard captureSession.canAddOutput(metadataOutput) else { return }
      captureSession.addOutput(metadataOutput)

      metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
      metadataOutput.metadataObjectTypes = [.qr]

      let preview = AVCaptureVideoPreviewLayer(session: captureSession)
      preview.videoGravity = .resizeAspectFill
      view.layer.addSublayer(preview)
      self.previewLayer = preview
    } catch {
      return
    }
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard !hasFoundCode,
      let metadataObject = metadataObjects.first,
      let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
      let stringValue = readableObject.stringValue
    else { return }

    hasFoundCode = true
    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    onCodeScanned?(stringValue)
  }
}
