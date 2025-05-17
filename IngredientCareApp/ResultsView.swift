//
//  ResultsView.swift
//  IngredientCareApp
//
//  Created by Student on 4/6/25.
//

import SwiftUI

struct ResultsView: View {
    var capturedImage: UIImage?
    var recognizedText: String
    var viewModel: IngredientViewModel
    var onClose: () -> Void
    var onScan: () -> Void
    var onCancel: () -> Void
    
    @State private var showMatchDetails = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .shadow(radius: 4)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    
                    Toggle("Show Matching Details", isOn: $showMatchDetails)
                        .padding(.vertical)
                    
                    Text("Analyzed Ingredients:")
                        .font(.headline)
                    
                    if viewModel.analyzedIngredients.isEmpty {
                        Text("No ingredients were recognized or matched.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.analyzedIngredients) { ingredient in
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
                        
                        let safeCount = viewModel.analyzedIngredients.filter { $0.safety == .safe }.count
                        let cautionCount = viewModel.analyzedIngredients.filter { $0.safety == .conditional }.count
                        let harmfulCount = viewModel.analyzedIngredients.filter { $0.safety == .harmful }.count
                        let unknownCount = viewModel.analyzedIngredients.filter { $0.safety == .unknown }.count
                        
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
                
                Spacer(minLength: 20)
                
                HStack {
                    Button(action: onClose) {
                        Label("Save & Close", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: onScan) {
                        Label("Scan Again", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    onCancel()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResultsView(
            capturedImage: UIImage(systemName: "photo"),
            recognizedText: "Water, Sugar, Modified Corn Starch, Cocoa Powder, Salt, Natural Flavors, Red 40, BHA (as a preservative), Trans Fats 0.5g",
            viewModel: {
                let viewModel = IngredientViewModel()
                viewModel.analyzedIngredients = [
                    AnalyzedIngredient(name: "Water", safety: .safe, matchedWith: "Water"),
                    AnalyzedIngredient(name: "Sugar", safety: .conditional, matchedWith: "Refined White Sugar"),
                    AnalyzedIngredient(name: "Modified Corn Starch", safety: .conditional, matchedWith: "Modified Corn Starch"),
                    AnalyzedIngredient(name: "Cocoa Powder", safety: .safe, matchedWith: "Cocoa Powder"),
                    AnalyzedIngredient(name: "Salt", safety: .safe, matchedWith: "Salt"),
                    AnalyzedIngredient(name: "Natural Flavors", safety: .conditional, matchedWith: "Natural Flavor Extracts (like vanilla, almond)"),
                    AnalyzedIngredient(name: "Red 40", safety: .harmful, matchedWith: "Red 40"),
                    AnalyzedIngredient(name: "BHA (as a preservative)", safety: .harmful, matchedWith: "BHA"),
                    AnalyzedIngredient(name: "Trans Fats 0.5g", safety: .harmful, matchedWith: "Trans Fats")
                ]
                return viewModel
            }(),
            onClose: {},
            onScan: {},
            onCancel: {}
        )
    }
}
