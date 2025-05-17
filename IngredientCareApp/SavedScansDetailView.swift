//
//  SavedScansDetailView.swift
//  IngredientCareApp
//
//  Created by Student on 4/6/25.
//

import SwiftUI

struct SavedScanDetailView: View {
    let scan: ScanResult
    @Environment(\.dismiss) private var dismiss
    @State private var showMatchDetails = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let image = scan.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Toggle("Show Matching Details", isOn: $showMatchDetails)
                            .padding(.vertical)
                        
                        Text("Analyzed Ingredients:")
                            .font(.headline)
                        
                        if scan.analyzedIngredients.isEmpty {
                            Text("No ingredients were recognized or matched.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(scan.analyzedIngredients) { ingredient in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(ingredient.name)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text(ingredient.safety.rawValue)
                                            .foregroundColor(ingredient.safety.color)
                                            .fontWeight(.medium)
                                    }
                                    
                                    if showMatchDetails, let matchedWith = ingredient.matchedWith {
                                        Text("Matched with: \(matchedWith)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(ingredient.safety.color.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Summary:")
                                .font(.headline)
                                .padding(.top, 10)
                            
                            let safeCount = scan.analyzedIngredients.filter { $0.safety == .safe }.count
                            let cautionCount = scan.analyzedIngredients.filter { $0.safety == .conditional }.count
                            let harmfulCount = scan.analyzedIngredients.filter { $0.safety == .harmful }.count
                            let unknownCount = scan.analyzedIngredients.filter { $0.safety == .unknown }.count
                            
                            HStack {
                                Label("\(safeCount) Safe", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            
                            HStack {
                                Label("\(cautionCount) Use with caution", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Spacer()
                            }
                            
                            HStack {
                                Label("\(harmfulCount) Potentially harmful", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            if unknownCount > 0 {
                                HStack {
                                    Label("\(unknownCount) Unknown", systemImage: "questionmark.circle.fill")
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Scan Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

