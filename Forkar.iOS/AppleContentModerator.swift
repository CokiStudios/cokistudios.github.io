//
//  AppleContentModerator.swift
//  Forkar
//
//  Created by Coki Studios on 28/09/2026.
//  Exclusive Apple Foundation Models (macOS 27.0+) On-Device Content Safety & Anti-Evasion Moderation
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
    
    // Comprehensive lexicon with common base profanities and inflections
    private let commonProfanities: Set<String> = [
        "idiota", "idiotas", "estupido", "estupidos", "estúpido", "estúpida", "estupida", "estupidas",
        "imbecil", "imbeciles", "imbécil", "imbéciles",
        "pendejo", "pendejos", "pendeja", "pendejas", "pendejada", "pendejadas",
        "mierda", "mierdas", "mierdoso", "mierdosa",
        "puta", "putas", "puto", "putos", "putita", "putitas", "putazo", "putazos",
        "bastardo", "bastardos", "maldito", "malditos", "maldita", "malditas",
        "cabron", "cabrones", "cabrón", "cabrona", "cabronas",
        "zorra", "zorras", "perra", "perras", "culero", "culeros", "culera", "culeras",
        "hdp", "hp", "chupala", "coño", "coños", "cono", "conos", "gilipollas",
        "maricon", "maricones", "maricón", "mariconazo", "marica", "maricas",
        "tarado", "tarados", "tarada", "taradas", "inutil", "inútil", "inutiles", "inútiles",
        "bastard", "bitch", "bitches", "asshole", "assholes", "fuck", "fucking", "shit",
        "dick", "cunt", "motherfucker"
    ]
    
    private init() {}
    
    /// Normalizes leetspeak substitutions and strips diacritics
    private func normalizeLeetspeak(_ text: String) -> String {
        let lower = text.lowercased()
        let map: [Character: Character] = [
            "0": "o", "1": "i", "!": "i", "|": "i", "3": "e",
            "4": "a", "@": "a", "5": "s", "$": "s", "7": "t", "8": "b"
        ]
        let s = lower.map { map[$0] ?? $0 }
        return String(s).folding(options: .diacriticInsensitive, locale: .current)
    }
    
    /// Collapses consecutive duplicated characters (e.g. "maricooon" -> "maricon", "puuuuta" -> "puta")
    private func collapseRepeats(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "([a-zA-Z])\\1{1,}", options: .caseInsensitive) else { return text }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }
    
    /// Detects intentional evasion attempts (e.g. letter stretching "maricooon", spaced-out characters "P U T A", "p . u . t . a", leetspeak "p3nd3j0", "m!erd@")
    func detectEvasions(in text: String) -> [String] {
        var detected = Set<String>()
        
        // 1. Detect spaced-out single characters (e.g. "P U T A", "p . u . t . a", "m a r i c o n", "H D P", "h-d-p")
        let spacedPattern = "(?:(?<=\\s)|^)[a-zA-Z0-9!@#\\$%\\*](?:[\\s\\._\\-\\*/]+[a-zA-Z0-9!@#\\$%\\*]){1,}(?=(?:\\s|$|[.,!?;:]))"
        if let spacedRegex = try? NSRegularExpression(pattern: spacedPattern, options: .caseInsensitive) {
            let nsRange = NSRange(location: 0, length: text.utf16.count)
            let matches = spacedRegex.matches(in: text, options: [], range: nsRange)
            for m in matches {
                let segment = (text as NSString).substring(with: m.range)
                let compact = segment.replacingOccurrences(of: "[\\s\\._\\-\\*/]", with: "", options: .regularExpression)
                let norm = collapseRepeats(normalizeLeetspeak(compact))
                if commonProfanities.contains(norm) {
                    detected.insert(norm)
                }
            }
        }
        
        // 2. Tokenize and analyze words for letter stretching and leetspeak (e.g. "maricooon", "p3nd3j0", "m!erd@", "estuuupido")
        let tokens = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        for token in tokens {
            let cleanToken = token.trimmingCharacters(in: CharacterSet(charactersIn: ",.?!;:\"'()[]{}"))
            guard !cleanToken.isEmpty else { continue }
            
            let norm = normalizeLeetspeak(cleanToken)
            let collapsed = collapseRepeats(norm)
            
            if commonProfanities.contains(norm) {
                detected.insert(norm)
            } else if commonProfanities.contains(collapsed) {
                detected.insert(collapsed)
            }
        }
        
        return Array(detected)
    }
    
    /// Analyzes text on-device for toxic content, slurs, profanity, evasion attempts, and offensive language.
    /// Exclusively powered by Apple Foundation Models on macOS 27 Apple Silicon with instant heuristic anti-evasion.
    func checkContent(_ text: String) async -> ModerationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .safe
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Step 1: Immediate local Anti-Evasion detection (catches "maricooon", "P U T A", "m!erd@", etc. in <1ms)
        let evasionWords = detectEvasions(in: trimmed)
        if !evasionWords.isEmpty {
            let result = ModerationResult(
                isSafe: false,
                flaggedWords: evasionWords,
                reason: "Se detectó lenguaje inapropiado o intento de evasión de seguridad: \(evasionWords.joined(separator: ", "))",
                engine: "On-Device Anti-Evasion Shield"
            )
            lastResult = result
            return result
        }
        
        // Step 2: Apple Foundation Models deep contextual analysis on macOS 27 Apple Silicon
        #if os(macOS)
        if #available(macOS 27.0, *) {
            if let result = await analyzeWithAppleFoundationModel(trimmed) {
                lastResult = result
                return result
            }
        }
        #endif
        
        // Step 3: Universal fallback for iOS or when model is warming up
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
                CRITICAL: Users may attempt to bypass moderation by:
                - Stretching letters (e.g. 'maricooon', 'putaaa', 'estuuupido')
                - Inserting spaces or punctuation between characters (e.g. 'P U T A', 'm.a.r.i.c.o.n', 'h-d-p')
                - Using leetspeak or symbol substitutions (e.g. 'p*ta', 'p3nd3jo', 'm@ricon', '1diota')
                You MUST recognize these evasion attempts and detect the underlying offensive words.
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
            let norm = normalizeLeetspeak(word)
            let collapsed = collapseRepeats(norm)
            
            if commonProfanities.contains(word) {
                detected.append(word)
            } else if commonProfanities.contains(norm) {
                detected.append(norm)
            } else if commonProfanities.contains(collapsed) {
                detected.append(collapsed)
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
    
    /// Masks flagged words with asterisks while keeping initial and trailing context,
    /// supporting both exact words and evasion variants (spaced out, stretched letters).
    func sanitize(_ text: String, replacing flaggedWords: [String]) -> String {
        var sanitized = text
        for word in flaggedWords where !word.isEmpty {
            // Build dynamic pattern that matches stretched or spaced-out representations
            let charPatterns = word.map { "\\Q\($0)\\E+" }.joined(separator: "[\\s\\._\\-\\*/]*")
            let pattern = "(?i)\\b\(charPatterns)\\b"
            
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: sanitized.utf16.count)
                let matches = regex.matches(in: sanitized, options: [], range: range)
                for match in matches.reversed() {
                    if let swiftRange = Range(match.range, in: sanitized) {
                        let original = String(sanitized[swiftRange])
                        let maskCount = max(original.count, 4)
                        sanitized.replaceSubrange(swiftRange, with: String(repeating: "*", count: maskCount))
                    }
                }
            } else {
                // Exact fallback replacement
                sanitized = sanitized.replacingOccurrences(of: word, with: "****", options: .caseInsensitive)
            }
        }
        return sanitized
    }
}
