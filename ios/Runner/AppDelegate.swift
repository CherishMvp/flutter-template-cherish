import Flutter
import PhotosUI
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example/live_photo_preview",
                                           binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "previewLivePhoto" {
                guard let args = call.arguments as? [String: String],
                      let heicPath = args["heicPath"],
                      let movPath = args["movPath"]
                else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing HEIC or MOV paths", details: nil))
                    return
                }
                self?.showLivePhotoPreview(heicPath: heicPath, movPath: movPath, result: result)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func showLivePhotoPreview(heicPath: String, movPath: String, result: @escaping FlutterResult) {
    // 创建 LivePhoto 预览页面，并传递 onDismiss 回调
    let livePhotoView = LivePhotoPreviewOverlayView(
        heicPath: heicPath,
        movPath: movPath,
        onDismiss: { [weak self] in
            // 调用 dismiss 来关闭 SwiftUI 页面
            self?.dismissPresentedViewController()
            result(nil) // 回调通知 Flutter 预览已关闭
        }
    )

    let hostingController = UIHostingController(rootView: livePhotoView)
    hostingController.modalPresentationStyle = .fullScreen

    // 使用 rootViewController 展示 UIHostingController
    if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
        rootViewController.present(hostingController, animated: true, completion: nil)
    }
}

    // Helper 方法：关闭当前展示的页面
    private func dismissPresentedViewController() {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController,
        let presented = rootViewController.presentedViewController {
            presented.dismiss(animated: true, completion: nil)
        }
    }

}
