//
//  AppleContentModerator.swift
//  Forkar
//
//  Created by Coki Studios on 28/09/2026.
//  Exclusive Apple Foundation Models (macOS 27.0+) On-Device Content Safety & Moderation
//

import Foundation
import SwiftUI
internal import Combine
#if os(macOS)
import FoundationModels
#endif
import NaturalLanguage

struct ModerationResult: Sendable, Equatable {
    let isSafe: Bool
    let flaggedWords: [String]
    let reason: String
    let engine: String
    
    static let safe = ModerationResult(
        isSafe: true,
        flaggedWords: [],
        reason: "Contenido verificado y respetuoso.",
        engine: "Apple Foundation Models (macOS 27)"
    )
}

@MainActor
final class AppleContentModerator: ObservableObject {
    static let shared = AppleContentModerator()
    
    @Published var isAnalyzing: Bool = false
    @Published var lastResult: ModerationResult? = nil
    
    // Fallback dictionary for instant heuristic pass / offline iOS
    private let commonProfanities: Set<String> = [
        "idiota", "estupido", "estúpido", "imbecil", "imbécil", "estupida", "estúpida",
        "pendejo", "pendeja", "mierda", "puta", "puto", "bastardo", "maldito", "maldita",
        "cabron", "cabrón", "cabrona", "zorra", "perra", "culero", "hdp", "chupala",
        "coño", "gilipollas", "maricon", "maricón", "tarado", "tarada", "inútil", "inutil",
        "bastard", "bitch", "asshole", "fuck", "fucking", "shit", "dick", "cunt", "motherfucker"
    ]
    
    private init() {}
    
    /// Analyzes text on-device for toxic content, slurs, profanity, and offensive language.
    /// Exclusively powered by Apple Foundation Models on macOS 27 Apple Silicon.
    func checkContent(_ text: String) async -> ModerationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .safe
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        #if os(macOS)
        if #available(macOS 27.0, *) {
            if let result = await analyzeWithAppleFoundationModel(trimmed) {
                lastResult = result
                return result
            }
        }
        #endif
        
        // Universal fallback for iOS or when model is warming up
        let result = analyzeWithFallback(trimmed)
        lastResult = result
        return result
    }
    
    #if os(macOS)
    @available(macOS 27.0, *)
    private func analyzeWithAppleFoundationModel(_ text: String) async -> ModerationResult? {
        guard SystemLanguageModel.default.isAvailable else {
            return nil
        }
        
        do {
            let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are the Forkar on-device safety moderator running locally on Apple Silicon (macOS 27).
                Your job is to analyze user text (in Spanish or English) for profanity, insults, toxicity, harassment, and hate speech.
                Respond ONLY with a JSON object in this exact format:
                {"isSafe": false, "flaggedWords": ["word1", "word2"], "reason": "Breve explicación en español"}
                or if completely safe:
                {"isSafe": true, "flaggedWords": [], "reason": "Contenido respetuoso"}
                Do not include markdown ticks or additional commentary.
                """
            )
            
            let prompt = "Analiza el siguiente texto de usuario: \"\(text)\""
            let response = try await session.respond(to: prompt)
            let cleanedJSON = extractJSON(from: response.content)
            
            struct RawOutput: Decodable {
                let isSafe: Bool
                let flaggedWords: [String]?
                let reason: String?
            }
            
            if let data = cleanedJSON.data(using: .utf8),
               let parsed = try? JSONDecoder().decode(RawOutput.self, from: data) {
                let flagged = parsed.isSafe ? [] : (parsed.flaggedWords ?? [])
                let reason = parsed.reason ?? (parsed.isSafe ? "Contenido verificado y respetuoso." : "Contenido inapropiado detectado.")
                
                return ModerationResult(
                    isSafe: parsed.isSafe,
                    flaggedWords: flagged,
                    reason: reason,
                    engine: "Apple Intelligence (macOS 27 Neural Engine)"
                )
            }
        } catch {
            let desc = error.localizedDescription.lowercased()
            // If the system guardrails blocked the prompt as unsafe, it is definitely toxic
            if desc.contains("unsafe") || desc.contains("guardrail") || desc.contains("refusal") {
                return ModerationResult(
                    isSafe: false,
                    flaggedWords: ["contenido_inseguro"],
                    reason: "Bloqueado por los filtros de seguridad de hardware de Apple Intelligence.",
                    engine: "Apple Foundation Models (Security Shield)"
                )
            }
            print("Apple Foundation Model moderation warning: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func extractJSON(from raw: String) -> String {
        var str = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("```json") {
            str = String(str.dropFirst(7))
        } else if str.hasPrefix("```") {
            str = String(str.dropFirst(3))
        }
        if str.hasSuffix("```") {
            str = String(str.dropLast(3))
        }
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    #endif
    
    /// Fast on-device lexical & NaturalLanguage fallback for iOS and offline resilience
    private func analyzeWithFallback(_ text: String) -> ModerationResult {
        let lower = text.lowercased()
        
        // Tokenize words
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = lower
        
        var detected: [String] = []
        tokenizer.enumerateTokens(in: lower.startIndex..<lower.endIndex) { range, _ in
            let word = String(lower[range])
            if commonProfanities.contains(word) {
                detected.append(word)
            }
            return true
        }
        
        if !detected.isEmpty {
            let unique = Array(Set(detected))
            return ModerationResult(
                isSafe: false,
                flaggedWords: unique,
                reason: "Se detectaron palabras inapropiadas o lenguaje ofensivo: \(unique.joined(separator: ", "))",
                engine: "On-Device NaturalLanguage"
            )
        }
        
        return ModerationResult(
            isSafe: true,
            flaggedWords: [],
            reason: "Contenido verificado.",
            engine: "On-Device NaturalLanguage"
        )
    }
    
    /// Masks flagged words with asterisks while keeping initial letters
    func sanitize(_ text: String, replacing flaggedWords: [String]) -> String {
        var sanitized = text
        for word in flaggedWords where !word.isEmpty {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: sanitized.utf16.count)
                let matches = regex.matches(in: sanitized, options: [], range: range)
                for match in matches.reversed() {
                    if let swiftRange = Range(match.range, in: sanitized) {
                        let original = String(sanitized[swiftRange])
                        if original.count <= 2 {
                            sanitized.replaceSubrange(swiftRange, with: String(repeating: "*", count: original.count))
                        } else {
                            let first = original.prefix(1)
                            let last = original.suffix(1)
                            let masked = first + String(repeating: "*", count: original.count - 2) + last
                            sanitized.replaceSubrange(swiftRange, with: masked)
                        }
                    }
                }
            }
        }
        return sanitized
    }
}
