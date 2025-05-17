//
//  IngredientModel.swift
//  IngredientCareApp
//
//  Created by Student on 4/2/25.
//

import Foundation
import SwiftUI

struct IngredientData: Codable {
    let safe_ingredients: [String]
    let conditionally_allowed: [String]
    let harmful_ingredients: [String]
}

enum IngredientSafety: String, Codable {
    case safe = "Safe"
    case conditional = "Use with caution"
    case harmful = "Potentially harmful"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .safe:
            return Color.green
        case .conditional:
            return Color.yellow
        case .harmful:
            return Color.red
        case .unknown:
            return Color.gray
        }
    }
}

struct AnalyzedIngredient: Identifiable, Codable {
    var id = UUID()
    var name: String
    var safety: IngredientSafety
    var matchedWith: String?
}

@Observable
class IngredientViewModel {
    var ingredientData: IngredientData?
    var analyzedIngredients: [AnalyzedIngredient] = []
    
    // Common food label text that should be ignored during matching - Generated from sample food ingredient images
    private let nonIngredientPatterns = [
        "\\d+\\s*[gG]\\b", // 10g
        "\\d+\\s*[mM][gG]\\b", // 200mg
        "\\d+\\s*[mM][lL]\\b", // 100ml
        "\\d+\\s*[kK][gG]\\b", // 1kg
        "\\d+\\s*[lL]\\b", // 2L
        "\\d+\\s*[oO][zZ]\\b", // 8oz
        "\\d+\\s*[fF][lL]\\s*[oO][zZ]\\b", // 16 fl oz
        "\\d+\\.\\d+\\s*[gGmMkKlLoOzZ]+\\b", // 0.5g, 1.5mg
        "\\d+%\\s*", // 10%
        "\\([^)]*\\)", // content in parentheses like (for color)
        "\\bcontains\\s+\\d+%\\s*", // contains 2%
        "\\bless\\s+than\\s+\\d+%\\s*", // less than 2%
        "\\bfrom\\s+", // from
        "\\bfortified\\s+with\\s+", // fortified with
        "\\benriched\\s+with\\s+", // enriched with
        "\\madded\\s+for\\s+", // added for
        "\\badded\\s+to\\s+", // added to
        "\\bfor\\s+freshness\\b", // for freshness
        "\\bfor\\s+color\\b", // for color
        "\\bto\\s+preserve\\b", // to preserve
        "\\bto\\s+maintain\\b", // to maintain
        "\\bto\\s+improve\\b", // to improve
    ]
    
    init() {
        loadIngredientData()
    }
    
    func loadIngredientData() {
        // Load the JSON data from the app bundle
        if let path = Bundle.main.path(forResource: "ingredients_data", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            do {
                ingredientData = try JSONDecoder().decode(IngredientData.self, from: data)
                print("Successfully loaded \(ingredientData?.safe_ingredients.count ?? 0) safe ingredients")
                print("Successfully loaded \(ingredientData?.conditionally_allowed.count ?? 0) conditional ingredients")
                print("Successfully loaded \(ingredientData?.harmful_ingredients.count ?? 0) harmful ingredients")
            } catch {
                print("Error decoding JSON: \(error)")
            }
        } else {
            print("Could not find or load ingredients_data.json")
        }
    }
    
    func analyzeIngredients(from text: String) {
        guard let data = ingredientData else {
            print("No ingredient data available")
            return
        }
        
        let processedText = cleanIngredientsText(text)
        let rawIngredients = splitIntoIngredients(processedText)
        print("Extracted \(rawIngredients.count) ingredients from text")
      
        analyzedIngredients = rawIngredients.map { ingredient in
            analyzeIngredient(ingredient, data: data)
        }
        
        print("Analysis complete - \(analyzedIngredients.count) ingredients analyzed")
    }
    
    private func cleanIngredientsText(_ text: String) -> String {
        var cleanedText = text.replacingOccurrences(of: "INGREDIENTS:", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "Ingredients:", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "ingredients:", with: "")
        
        for pattern in nonIngredientPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                cleanedText = regex.stringByReplacingMatches(
                    in: cleanedText,
                    options: [],
                    range: NSRange(location: 0, length: cleanedText.utf16.count),
                    withTemplate: " "
                )
            }
        }
        cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func splitIntoIngredients(_ text: String) -> [String] {
        let components = text.components(separatedBy: CharacterSet(charactersIn: ",.;:"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return components
    }
    
    private func normalizeIngredient(_ ingredient: String) -> String {
        var normalized = ingredient.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalized.hasSuffix("s") && normalized.count > 3 {
            normalized = String(normalized.dropLast())
        }
        
        let descriptors = ["organic", "natural", "raw", "fresh", "dried", "powdered", "ground",
                           "refined", "pure", "whole", "sliced", "diced", "chopped", "crushed"]
        
        for descriptor in descriptors {
            normalized = normalized.replacingOccurrences(of: "\\b\(descriptor)\\s+", with: "", options: .regularExpression)
        }
        
        return normalized
    }
    
    private func analyzeIngredient(_ ingredientName: String, data: IngredientData) -> AnalyzedIngredient {
        let normalizedIngredient = normalizeIngredient(ingredientName)
        
        // Try partial matching with safe ingredients
        if let matchedSafe = findBestMatch(normalizedIngredient, in: data.safe_ingredients) {
            return AnalyzedIngredient(name: ingredientName, safety: .safe, matchedWith: matchedSafe)
        }
        
        // Try partial matching with harmful ingredients
        if let matchedHarmful = findBestMatch(normalizedIngredient, in: data.harmful_ingredients) {
            return AnalyzedIngredient(name: ingredientName, safety: .harmful, matchedWith: matchedHarmful)
        }
        
        // Try partial matching with conditionally allowed ingredients
        if let matchedConditional = findBestMatch(normalizedIngredient, in: data.conditionally_allowed) {
            return AnalyzedIngredient(name: ingredientName, safety: .conditional, matchedWith: matchedConditional)
        }
        
        // If no match found, return as unknown
        return AnalyzedIngredient(name: ingredientName, safety: .unknown, matchedWith: nil)
    }
    
    private func findBestMatch(_ ingredient: String, in list: [String]) -> String? {
        // First try direct contains
        for item in list {
            let normalizedItem = item.lowercased()
            
            // Check if the ingredient directly contains the item
            if ingredient.contains(normalizedItem) {
                return item
            }
            
            // Check if the item directly contains the ingredient
            if normalizedItem.contains(ingredient) {
                return item
            }
        }
        
        // Then try word-by-word matching for compounds
        let ingredientWords = ingredient.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if ingredientWords.count > 1 {
            for item in list {
                let itemWords = item.lowercased().components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                
                // Check if there's a significant overlap in words
                let commonWords = Set(ingredientWords).intersection(Set(itemWords))
                if commonWords.count >= min(2, ingredientWords.count) {
                    return item
                }
            }
        }
        
        return nil
    }
}
