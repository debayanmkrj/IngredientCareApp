//
//  ContentView.swift
//  IngredientCareApp
//
//  Created by Student on 4/2/25.
//

import SwiftUI

struct ContentView: View {
    @State private var captureManager = CameraCaptureManager()
    @State private var viewModel = IngredientViewModel()
    @State private var scanResultStore = ScanResultStore()
    
    @State private var showingCamera = false
    @State private var showingResults = false
    @State private var showingSavedScans = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if showingResults {
                        ResultsView(
                            capturedImage: captureManager.capturedImage,
                            recognizedText: captureManager.recognizedText,
                            viewModel: viewModel,
                            onClose: {
                                saveCurrentScan()
                             
                                withAnimation {
                                    showingResults = false
                                    captureManager.capturedImage = nil
                                    captureManager.recognizedText = ""
                                }
                            },
                            onScan: {
                                withAnimation {
                                    showingResults = false
                                    showingCamera = true
                                }
                            },
                            onCancel: {
                                withAnimation {
                                    showingResults = false
                                    captureManager.capturedImage = nil
                                    captureManager.recognizedText = ""
                                }
                            }
                        )
                    } else {
                        VStack(spacing: 30) {
                            Spacer()
                            
                            Image(systemName: "text.viewfinder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.accentColor)
                            
                            Text("Ingredient Scanner")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Scan food product ingredient lists to check their safety.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            VStack(spacing: 15) {
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    Label("Scan Ingredients", systemImage: "camera")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    showingSavedScans = true
                                }) {
                                    Label("\(scanResultStore.scanResults.count) Saved Scans", systemImage: "list.bullet")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("Ingredient Care")
                            .font(.headline)
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.headline)
                    }
                }
            }
            
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(
                    captureManager: captureManager,
                    onDismiss: {
                        showingCamera = false
                    },
                    onCapture: {
                        showingCamera = false
                        viewModel.analyzeIngredients(from: captureManager.recognizedText)
                        showingResults = true
                    }
                )
            }
            .sheet(isPresented: $showingSavedScans) {
                SavedScansView(store: scanResultStore)
            }
        }
    }
    
    private func saveCurrentScan() {
        guard let capturedImage = captureManager.capturedImage else { return }
        guard let imageFileName = ScanResultStore.saveImage(capturedImage) else {
            print("Failed to save image")
            return
        }
        let scanResult = ScanResult(
            date: Date(),
            recognizedText: captureManager.recognizedText,
            analyzedIngredients: viewModel.analyzedIngredients,
            imageFileName: imageFileName
        )
        
        scanResultStore.add(scanResult: scanResult)
    }
}

#Preview {
    ContentView()
}




