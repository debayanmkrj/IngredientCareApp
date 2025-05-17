//
//  SavedScansView.swift
//  IngredientCareApp
//
//  Created by Student on 4/6/25.
//

import SwiftUI

struct SavedScansView: View {
    var store: ScanResultStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScan: ScanResult?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.scanResults.sorted(by: { $0.date > $1.date })) { scan in
                    Button(action: {
                        selectedScan = scan
                    }) {
                        HStack {
                            if let image = scan.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            VStack(alignment: .leading) {
                                Text(scan.date, style: .date)
                                    .font(.headline)
                                
                                Text(scan.recognizedText.prefix(30) + (scan.recognizedText.count > 30 ? "..." : ""))
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                                
                                let safeCount = scan.analyzedIngredients.filter { $0.safety == .safe }.count
                                let cautionCount = scan.analyzedIngredients.filter { $0.safety == .conditional }.count
                                let harmfulCount = scan.analyzedIngredients.filter { $0.safety == .harmful }.count
                                
                                HStack {
                                    Text("\(safeCount)")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text("\(cautionCount)")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    
                                    Text("\(harmfulCount)")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete { indexSet in
                    store.delete(at: indexSet)
                }
            }
            .navigationTitle("Saved Scans")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(item: $selectedScan) { scan in
                SavedScanDetailView(scan: scan)
            }
        }
    }
}

