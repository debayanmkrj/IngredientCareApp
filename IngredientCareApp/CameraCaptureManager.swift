//
//  CameraCaptureManager.swift
//  IngredientCareApp
//
//  Created by Student on 4/2/25.
//
import Foundation
import SwiftUI
import AVFoundation
import Vision
import UIKit
import Photos

let deviceTypes: [AVCaptureDevice.DeviceType] = [
    .builtInWideAngleCamera,
    .builtInUltraWideCamera,
    .builtInTelephotoCamera,
]

@Observable
class CameraCaptureManager: NSObject {
    var session = AVCaptureSession()
    var preview: Preview?
    var capturedImage: UIImage?
    var recognizedText: String = ""
    var isCapturing = false
    var isProcessing = false
    var availableCameras: [AVCaptureDevice] = []
    
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var currentCaptureDevice: AVCaptureDevice?
    private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var videoRotationAngleForHorizonLevelPreviewObservation: NSKeyValueObservation?
    private let photoQueue = DispatchQueue(label: "photoQueue", qos: .userInitiated)
    private var activePhotoDelegate: PhotoCaptureDelegate?
    
    var captureCompletion: (() -> Void)?
    var canvasFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    override init() {
        super.init()
        print("CameraCaptureManager initialized")
        Task {
            await checkCameraPermission()
            configureSession()
        }
    }
    
    private func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Authorized to use camera")
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("Camera access \(granted ? "granted" : "denied")")
        default:
            print("Not authorized to use camera")
        }
    }
    
    func discoverCameras() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        
        print("DiscoverySession found \(discoverySession.devices.count) cameras")
        for device in discoverySession.devices {
            print("-------------------")
            print("uniqueID: \(device.uniqueID)")
            print("modelID: \(device.modelID)")
            print("name: \(device.localizedName)")
            print("manufacturer: \(device.manufacturer)")
            print("device type: \(device.deviceType.rawValue)")
            switch device.position {
                case .front: print("device position: front")
                case .back: print("device position: back")
                case .unspecified: print("device position: unspecified")
                default: print("device position: unknown")
            }
        }
        
        return discoverySession.devices
    }
    
    private func configureSession() {
        availableCameras = discoverCameras()
        print("Configuring camera...")
        
        var readyToRun = false
        defer {
            session.commitConfiguration()
            if readyToRun {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.session.startRunning()
                    print("Session started running")
                }
            }
        }
        
        session.beginConfiguration()
        session.sessionPreset = .photo
        preview = Preview(session: session, gravity: .resizeAspect)
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )
        
        guard let videoDevice = discovery.devices.first else {
            print("Could not find any camera")
            return
        }
        
        do {
            print("Creating device input for \(videoDevice.localizedName)")
            let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(captureDeviceInput) {
                print("Adding device input to session")
                session.addInput(captureDeviceInput)
                videoDeviceInput = captureDeviceInput
                currentCaptureDevice = videoDevice
                photoOutput.maxPhotoQualityPrioritization = .quality
                photoOutput.isResponsiveCaptureEnabled = photoOutput.isResponsiveCaptureSupported
                photoOutput.isFastCapturePrioritizationEnabled = photoOutput.isFastCapturePrioritizationSupported
                
                if session.canAddOutput(photoOutput) {
                    print("Adding photo output to session")
                    session.addOutput(photoOutput)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.createDeviceRotationCoordinator()
                        if let self = self, let previewLayer = self.preview?.previewLayer {
                            let frame = previewLayer.frame
                            if frame.width < frame.height {
                                self.checkPreviewSize(orientation: .portrait)
                            } else {
                                self.checkPreviewSize(orientation: .landscapeLeft)
                            }
                        }
                    }
                    
                    readyToRun = true
                } else {
                    print("Cannot add photo output to session")
                }
            } else {
                print("Cannot add input to session")
            }
        } catch {
            print("Error creating capture device input: \(error)")
        }
    }
    
    func checkPreviewSize(orientation: UIDeviceOrientation) {
        guard let activeFormat = currentCaptureDevice?.activeFormat else { return }
        print("videoDevice dimensions: \(activeFormat.formatDescription.dimensions)")
        guard let previewLayer = preview?.previewLayer else { return }
        let frame = previewLayer.frame
        print("frame: \(frame)")
        
        canvasFrame = calculateCanvasFrame(activeFormat: activeFormat, previewLayer: previewLayer, orientation: orientation)
        print("canvasFrame = \(canvasFrame)")
    }
    
    private func calculateCanvasFrame(activeFormat: AVCaptureDevice.Format, previewLayer: AVCaptureVideoPreviewLayer, orientation: UIDeviceOrientation) -> CGRect {
        let frame = previewLayer.frame
        
        let captureW = Double(activeFormat.formatDescription.dimensions.width)
        let captureH = Double(activeFormat.formatDescription.dimensions.height)
        let aspectRatio = captureW / captureH
        
        if orientation == .portrait || orientation == .portraitUpsideDown {
            let w = min(frame.width, frame.height)
            let frameH = max(frame.width, frame.height)
            let h = w * aspectRatio
            let x = 0.0
            let y = (frameH - h) / 2.0
            return CGRect(x: x, y: y, width: w, height: h)
        } else {
            let h = min(frame.width, frame.height)
            let frameW = max(frame.width, frame.height)
            let w = h * aspectRatio
            let x = (frameW - w) / 2.0
            let y = 0.0
            return CGRect(x: x, y: y, width: w, height: h)
        }
    }
    
    private func createDeviceRotationCoordinator() {
        guard let videoDeviceInput = videoDeviceInput else { return }
        
        videoDeviceRotationCoordinator = AVCaptureDevice.RotationCoordinator(
            device: videoDeviceInput.device,
            previewLayer: preview?.previewLayer
        )
        
        preview?.previewLayer.connection?.videoRotationAngle = videoDeviceRotationCoordinator?.videoRotationAngleForHorizonLevelPreview ?? 0
        
        videoRotationAngleForHorizonLevelPreviewObservation = videoDeviceRotationCoordinator?.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: .new
        ) { [weak self] _, change in
            guard let self = self, let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }
            self.preview?.previewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
        }
    }
    
    func capturePhoto() {
        guard session.isRunning else {
            print("Session is not running")
            return
        }
        
        isCapturing = true
        isProcessing = true
        print("Starting photo capture...")
        let settings = createOptimalPhotoSettings()
        
        photoQueue.async { [weak self] in
            guard let self = self,
                  let connection = self.photoOutput.connection(with: .video),
                  let rotationCoordinator = self.videoDeviceRotationCoordinator else {
                DispatchQueue.main.async {
                    self?.isCapturing = false
                    self?.isProcessing = false
                }
                return
            }
            connection.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
            
            // Create a delegate that will handle the capture completion
            let photoDelegate = PhotoCaptureDelegate(
                settings: settings,
                completionHandler: { [weak self] image in
                    DispatchQueue.main.async {
                        self?.capturedImage = image
                        self?.isCapturing = false
                    }
                },
                textRecognitionHandler: { [weak self] text in
                    DispatchQueue.main.async {
                        self?.recognizedText = text
                        self?.isProcessing = false
                        
                        // Call completion handler if set
                        if let completion = self?.captureCompletion {
                            completion()
                            self?.captureCompletion = nil
                        }
                    }
                }
            )
            
            self.activePhotoDelegate = photoDelegate
            self.photoOutput.capturePhoto(with: settings, delegate: photoDelegate)
        }
    }
    
    // Method to create optimal photo settings
    private func createOptimalPhotoSettings() -> AVCapturePhotoSettings {
        var photoSettings = AVCapturePhotoSettings()
        
        // Capture HEIF photos when supported for better quality/size ratio
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        // Set to highest quality
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        photoSettings.photoQualityPrioritization = .quality
        
        return photoSettings
    }
    
    func capturePhotoWithCompletion(completion: @escaping () -> Void) {
        captureCompletion = completion
        capturePhoto()
    }
    
    func changeCameraInput(device: AVCaptureDevice) {
        print("Changing camera to \(device.localizedName)")
        
        session.beginConfiguration()
        
        // Remove existing input
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Add new input
        do {
            let newVideoInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(newVideoInput) {
                session.addInput(newVideoInput)
                videoDeviceInput = newVideoInput
                currentCaptureDevice = device
                
                // Update rotation coordinator
                DispatchQueue.main.async { [weak self] in
                    self?.createDeviceRotationCoordinator()
                }
            } else {
                print("Could not add video input for device: \(device.localizedName)")
                // Re-add the original input if possible
                if let originalInput = videoDeviceInput, session.canAddInput(originalInput) {
                    session.addInput(originalInput)
                }
            }
        } catch {
            print("Error creating input for device \(device.localizedName): \(error)")
            if let originalInput = videoDeviceInput, session.canAddInput(originalInput) {
                session.addInput(originalInput)
            }
        }
        session.commitConfiguration()
    }
    
    func isCurrentInput(device: AVCaptureDevice) -> Bool {
        return currentCaptureDevice?.uniqueID == device.uniqueID
    }
}
