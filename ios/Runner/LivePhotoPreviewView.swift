//
//  LivePhotoPreviewView.swift
//  Runner
//
//  Created by cherish on 2024/10/27.
//

import PhotosUI
import SwiftUI

struct LivePhotoPreviewView: UIViewRepresentable {
    let heicPath: String
    let movPath: String

    func makeUIView(context: Context) -> PHLivePhotoView {
        let livePhotoView = PHLivePhotoView()

        // 加载 Live Photo
        loadLivePhoto(heicPath: heicPath, movPath: movPath) { livePhoto in
            DispatchQueue.main.async {
                livePhotoView.livePhoto = livePhoto
                livePhotoView.isMuted = false
            }
        }
        return livePhotoView
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {}

    private func loadLivePhoto(heicPath: String, movPath: String, completion: @escaping (PHLivePhoto?) -> Void) {
        let imageURL = URL(fileURLWithPath: heicPath)
        let videoURL = URL(fileURLWithPath: movPath)

        PHLivePhoto.request(withResourceFileURLs: [imageURL, videoURL],
                            placeholderImage: nil,
                            targetSize: .zero,
                            contentMode: .aspectFit) { livePhoto, _ in
            completion(livePhoto)
        }
    }
}

struct LivePhotoPreviewOverlayView: View {
    let heicPath: String
    let movPath: String
    let onDismiss: () -> Void // 关闭页面的回调

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Live Photo 预览区域
            // LivePhotoPreviewView(heicPath: heicPath, movPath: movPath)
            //     .edgesIgnoringSafeArea(.all) // 全屏显示
            LivePhotoPreviewView(heicPath: heicPath, movPath: movPath)
            .aspectRatio(contentMode: .fit) // 设置内容模式为适应
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // 设置框架大小
            // Live Photo 图标
            Image(systemName: "livephoto")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(.gray)
                .padding([.bottom, .leading], 20) // 设置按钮的位置
                .padding(.top, 50) // 设置按钮的位置
                .position(x: 30, y: 50) // 左上角定位
                .onTapGesture {
                    print("Live Photo icon tapped!") // 点击事件 (可选)
                }

            // 右上角关闭按钮
            Button(action: {
                onDismiss() // 点击按钮关闭页面
            }) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.gray)
                    .padding()
            }
            .padding([.bottom, .trailing], 20) // 设置按钮的位置
            .padding(.top, 50) // 设置按钮的位置
            .position(x: UIScreen.main.bounds.width - 30, y: 50) // 右上角定位
        }
    }
}


