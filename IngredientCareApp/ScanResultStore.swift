//
//  ScanResultStore.swift
//  IngredientCareApp
//
//  Created by Student on 4/2/25.
//

import Foundation
import SwiftUI

struct ScanResult: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var recognizedText: String
    var analyzedIngredients: [AnalyzedIngredient]
    var imageFileName: String
    
    // Property to load the image
    var image: UIImage? {
        loadImage(fileName: imageFileName)
    }
    
    private func loadImage(fileName: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }
        
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        if let imageData = try? Data(contentsOf: filePath) {
            return UIImage(data: imageData)
        }
        
        return nil
    }
}

@Observable
class ScanResultStore {
    var scanResults: [ScanResult] = []
    
    init() {
        //load from persistent storage when initialized
        loadFromDisk()
    }
    
    private func loadFromDisk() {
        do {
            let loadedResults = try ScanResultStore.loadScanResults()
            self.scanResults = loadedResults
        } catch {
            print("Error loading scan results: \(error)")
            self.scanResults = []
        }
    }
    
    func add(scanResult: ScanResult) {
        scanResults.append(scanResult)
        saveToDisk()
    }
    
    func delete(at offsets: IndexSet) {
        // Delete the image files first
        for index in offsets {
            let result = scanResults[index]
            deleteImage(fileName: result.imageFileName)
        }
        
        scanResults.remove(atOffsets: offsets)
        saveToDisk()
    }
    
    private func deleteImage(fileName: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: filePath)
        } catch {
            print("Error deleting image file: \(error)")
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        scanResults.move(fromOffsets: source, toOffset: destination)
        saveToDisk()
    }
    
    func saveToDisk() {
        do {
            try ScanResultStore.saveScanResults(scanResults)
        } catch {
            print("Error saving scan results: \(error)")
        }
    }
    
    // Save image to file system and return the filename
    static func saveImage(_ image: UIImage) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }
        
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Could not create JPEG data from image")
            return nil
        }
        
        do {
            try imageData.write(to: filePath)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    static func loadScanResults() throws -> [ScanResult] {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ScanResultStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("scanResults.plist")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("No existing scan results file found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode([ScanResult].self, from: data)
        } catch {
            print("Error reading scan results: \(error)")
            throw error
        }
    }
    
    static func saveScanResults(_ scanResults: [ScanResult]) throws {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ScanResultStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("scanResults.plist")
        
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(scanResults)
            try data.write(to: fileURL)
        } catch {
            print("Error saving scan results: \(error)")
            throw error
        }
    }
}
