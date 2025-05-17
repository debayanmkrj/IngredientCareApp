//
//  PhotoCaptureDelegate.swift
//  IngredientCareApp
//
//  Created by Student on 4/7/25.
//

import Foundation
import AVFoundation
import Photos
import UIKit
import Vision

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private var settings: AVCapturePhotoSettings
    private var photoData: Data?
    private var completionHandler: ((UIImage?) -> Void)?
    private var textRecognitionHandler: ((String) -> Void)?
    
    init(settings: AVCapturePhotoSettings, completionHandler: @escaping (UIImage?) -> Void, textRecognitionHandler: @escaping (String) -> Void) {
        self.settings = settings
        self.photoData = nil
        self.completionHandler = completionHandler
        self.textRecognitionHandler = textRecognitionHandler
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("didFinishProcessingPhoto")
        if let error = error {
            print("Photo processing error: \(error.localizedDescription)")
            completionHandler?(nil)
            return
        }
        
        photoData = photo.fileDataRepresentation()
        
        guard let imageData = photoData else {
            print("Failed to get photo data representation")
            completionHandler?(nil)
            return
        }
        
        // Create image from data
        guard let image = UIImage(data: imageData) else {
            print("Failed to create image from data")
            completionHandler?(nil)
            return
        }
        
        // Save the image to photo library
        saveToPhotoLibrary(image)
        
        // Perform text recognition
        recognizeText(in: image)
        
        // Call the completion handler with the image
        completionHandler?(image)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("didFinishCapture")
        if let error = error {
            print("Photo capture finished with error: \(error.localizedDescription)")
            return
        }
    }
    
    private func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("No permission to save to photo library")
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    print("Image saved to photo library")
                } else if let error = error {
                    print("Error saving to photo library: \(error)")
                }
            }
        }
    }
    
    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            textRecognitionHandler?("")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Text recognition error: \(error)")
                DispatchQueue.main.async {
                    self.textRecognitionHandler?("")
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text observations found")
                DispatchQueue.main.async {
                    self.textRecognitionHandler?("")
                }
                return
            }
            
            print("Found \(observations.count) text observations")
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: ", ")
            
            print("Recognized text: \(recognizedText)")
            
            DispatchQueue.main.async {
                self.textRecognitionHandler?(recognizedText)
            }
        }
        
        // Configure the text recognition request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition request: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.textRecognitionHandler?("")
            }
        }
    }
}
