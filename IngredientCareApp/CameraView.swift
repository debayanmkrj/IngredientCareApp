//
//  CameraView.swift
//  IngredientCareApp
//
//  Created by Student on 4/6/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    var captureManager: CameraCaptureManager
    var onDismiss: () -> Void
    var onCapture: () -> Void
    
    @State private var showingCameraOptions = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if let preview = captureManager.preview {
                preview
                    .ignoresSafeArea()
            }
            
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .padding()
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Camera selector button
                    if captureManager.availableCameras.count > 1 {
                        Button(action: {
                            showingCameraOptions = true
                        }) {
                            Image(systemName: "camera.badge.ellipsis")
                                .font(.title)
                                .padding()
                                .foregroundColor(.white)
                        }
                        .actionSheet(isPresented: $showingCameraOptions) {
                            ActionSheet(
                                title: Text("Select Camera"),
                                buttons: captureManager.availableCameras.map { camera in
                                    .default(Text(camera.localizedName)) {
                                        captureManager.changeCameraInput(device: camera)
                                    }
                                } + [.cancel()]
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Capture button
                Button(action: {
                    captureManager.capturePhotoWithCompletion {
                        onCapture()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 20)
                .disabled(captureManager.isCapturing)
            }
        }
    }
}

#Preview {
    CameraView(captureManager: CameraCaptureManager(), onDismiss: {}, onCapture: {})
}
