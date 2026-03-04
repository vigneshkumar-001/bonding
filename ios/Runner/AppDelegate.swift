import Flutter
import UIKit
import AVFoundation  // Needed for microphone/camera access

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    // Request permissions on app launch
    requestPermissions { granted in
        if granted {
            print("✅ Microphone (and Camera if video) permission granted")
            // Initialize Zego SDK here if needed
        } else {
            print("❌ Permission denied. Inform user to enable it in Settings")
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Permission Helper
  private func requestPermissions(completion: @escaping (Bool) -> Void) {
      // Request Microphone
      AVAudioSession.sharedInstance().requestRecordPermission { microphoneGranted in
          // Optional: request camera if video is used
          AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
              DispatchQueue.main.async {
                  let allGranted = microphoneGranted && cameraGranted
                  completion(allGranted)
              }
          }
      }
  }
}

// import Flutter
// import UIKit
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }
