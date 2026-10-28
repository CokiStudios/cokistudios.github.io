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
#if canImport(FoundationModels) && !os(watchOS) && !os(tvOS)
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
        engine: "Coki with Apple Intelligence (Neural Engine)"
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
    /// Exclusively powered by Apple Foundation Models on macOS 27 Apple Silicon with structured prompt execution (title + message context).
    func checkContent(_ content: String, title: String? = nil) async -> ModerationResult {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard !trimmedContent.isEmpty || !trimmedTitle.isEmpty else {
            return .safe
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Step 1: Immediate local Anti-Evasion detection across both title and message (<1ms)
        var evasionWords = detectEvasions(in: trimmedContent)
        if !trimmedTitle.isEmpty {
            let titleEvasions = detectEvasions(in: trimmedTitle)
            evasionWords.append(contentsOf: titleEvasions)
            evasionWords = Array(Set(evasionWords))
        }
        
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
        
        // Fast-path: Questions or commands directed to Coki assistant with no profanities are completely safe
        let lower = trimmedContent.lowercased()
        if lower.hasPrefix("/coki") || lower.hasPrefix("@coki") {
            let tokens = lower.components(separatedBy: .whitespacesAndNewlines)
            let hasProfanity = tokens.contains { commonProfanities.contains($0) }
            if !hasProfanity {
                return .safe
            }
        }
        
        // Step 2: Apple Foundation Models deep contextual analysis on iOS 27 / iPadOS 27 / macOS 27 Neural Engine
        #if canImport(FoundationModels) && !os(watchOS) && !os(tvOS)
        if #available(iOS 27.0, macOS 27.0, *) {
            if let result = await analyzeWithAppleFoundationModel(content: trimmedContent, title: trimmedTitle.isEmpty ? nil : trimmedTitle) {
                lastResult = result
                return result
            }
        }
        #endif
        
        // Step 3: Cloudflare Workers AI (Llama 3.2) on edge for fallback or earlier OS releases
        if let workersResult = await analyzeWithWorkersAI(content: trimmedContent, title: trimmedTitle.isEmpty ? nil : trimmedTitle) {
            lastResult = workersResult
            return workersResult
        }
        
        // Step 4: Universal on-device fallback (NaturalLanguage + Lexicon) for offline resilience
        let combined = trimmedTitle.isEmpty ? trimmedContent : "\(trimmedTitle)\n\(trimmedContent)"
        let result = analyzeWithFallback(combined)
        lastResult = result
        return result
    }
    
    #if canImport(FoundationModels) && !os(watchOS) && !os(tvOS)
    @available(iOS 27.0, macOS 27.0, *)
    private func analyzeWithAppleFoundationModel(content: String, title: String? = nil) async -> ModerationResult? {
        guard SystemLanguageModel.default.isAvailable else {
            return nil
        }
        
        #if os(macOS)
        let platformName = "macOS 27"
        #elseif os(iOS)
        let platformName = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS 27" : "iOS 27"
        #else
        let platformName = "Apple OS"
        #endif
        
        do {
            let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
            let session = LanguageModelSession(
                model: model,
                instructions: """
                You are Coki with Apple Intelligence, the on-device safety moderator and community copilot running locally on Apple Silicon (\(platformName)).
                Your job is to analyze posts, comments, and messages in the Forkar community (Spanish and English).
                You evaluate both the TITLE and the BODY/MESSAGE for:
                1. Severe toxicity, genuine insults, harassment, hate speech, and threats.
                2. Deliberate vulgar double entendres ("chistes de doble sentido", albures) intended to harass or make vulgar sexual jokes.
                3. Evasion attempts: letter stretching (e.g. 'maricooon'), spaced-out characters (e.g. 'P U T A'), leetspeak (e.g. 'p3nd3jo'), and split context across title and message.
                
                CRITICAL GUARDRAILS TO PREVENT FALSE POSITIVES:
                - NEVER flag legitimate technical, computing, vehicular, automotive, transit, or educational words.
                - Words such as 'terminal' (computer terminal or bus/transport terminal), 'consola', 'servidor', 'socket', 'puerto', 'batería', 'freno', 'motor', 'carro', 'kill' (as in kill process), 'execute', 'ruta', 'parada', 'estación', etc., are COMPLETELY SAFE AND HARMLESS.
                - Questions, commands to Coki (e.g., starting with '/Coki' or '@Coki', 'qué es...', 'cómo funciona...'), programming topics, and everyday conversational language are ALWAYS SAFE (isSafe: true).
                - Do NOT assume a benign word is an ambiguous insult or evasion. Only flag content when there is CLEAR, OBVIOUS, AND UNMISTAKABLE malice, offensive vulgarity, or toxic intent. If in doubt, mark as safe.
                
                Respond ONLY with a JSON object in this exact format:
                {"isSafe": false, "flaggedWords": ["word1", "word2"], "reason": "Breve explicación en español de por qué se detuvo la publicación"}
                or if completely safe:
                {"isSafe": true, "flaggedWords": [], "reason": "Contenido respetuoso"}
                Do not include markdown ticks or additional commentary.
                """
            )
            
            // Build structured contextual prompt with specific post title and message
            let prompt: String
            if let title = title, !title.isEmpty {
                prompt = """
                Evalúa la siguiente publicación para la comunidad Forkar:
                📌 TÍTULO DE LA PUBLICACIÓN: "\(title)"
                📝 CONTENIDO DEL MENSAJE: "\(content)"
                
                Analiza el título y el mensaje en conjunto. ¿Cumple con las normas comunitarias o contiene ataques, toxicidad, insultos, evasión de filtros o chistes de doble sentido (albures / insinuaciones sexuales vulgares)?
                """
            } else {
                prompt = """
                Evalúa el siguiente mensaje para la comunidad Forkar:
                💬 MENSAJE: "\(content)"
                
                ¿Cumple con las normas comunitarias o contiene ataques, toxicidad, insultos, evasión de filtros o chistes de doble sentido (albures / insinuaciones sexuales vulgares)?
                """
            }
            
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
                    engine: "Coki with Apple Intelligence (\(platformName) Neural Engine)"
                )
            }
        } catch {
            let desc = error.localizedDescription.lowercased()
            // If the system guardrails blocked the prompt as unsafe, it is definitely toxic
            if desc.contains("unsafe") || desc.contains("guardrail") || desc.contains("refusal") {
                return ModerationResult(
                    isSafe: false,
                    flaggedWords: ["contenido_inseguro"],
                    reason: "Bloqueado por los filtros de seguridad de hardware de Coki with Apple Intelligence.",
                    engine: "Coki with Apple Intelligence (\(platformName) Security Shield)"
                )
            }
            print("Coki with Apple Intelligence moderation warning: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Summarizes encrypted CSMS chat room messages on-device using Coki with Apple Intelligence
    func summarizeChat(messages: [String], roomName: String) async -> String {
        guard !messages.isEmpty else {
            return "No hay suficientes mensajes para generar un resumen."
        }
        
        #if canImport(FoundationModels) && !os(watchOS) && !os(tvOS)
        if #available(iOS 27.0, macOS 27.0, *) {
            if SystemLanguageModel.default.isAvailable {
                do {
                    #if os(macOS)
                    let platform = "macOS 27"
                    #elseif os(iOS)
                    let platform = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS 27" : "iOS 27"
                    #else
                    let platform = "Apple Silicon"
                    #endif
                    
                    let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You are Coki with Apple Intelligence, the vehicular copilot running on \(platform).
                        Your task is to summarize conversations from the Forkar encrypted community.
                        Be concise, friendly, and extract the key takeaways (agreements, road alerts, meetup points, departures).
                        Answer in Spanish in 2 to 3 bullet points with relevant emojis.
                        """
                    )
                    let recentMessages = messages.suffix(15).joined(separator: "\n")
                    let prompt = "Resume los puntos clave de la sala '\(roomName)':\n\(recentMessages)"
                    let response = try await session.respond(to: prompt)
                    return response.content
                } catch {
                    print("Coki chat summarization fallback: \(error.localizedDescription)")
                }
            }
        }
        #endif
        
        let count = min(messages.count, 5)
        let sample = messages.suffix(count)
        return "✨ Resumen de Coki with Apple Intelligence (\(count) mensajes recientes):\n" + sample.map { "• \($0.prefix(60))..." }.joined(separator: "\n")
    }
    
    /// Diagnoses vehicular warning lights or maintenance symptoms on-device with Coki with Apple Intelligence
    func diagnoseVehicle(issueDescription: String) async -> String {
        let clean = issueDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return "Por favor describe el síntoma o testigo para que Coki pueda analizarlo."
        }
        
        #if canImport(FoundationModels) && !os(watchOS) && !os(tvOS)
        if #available(iOS 27.0, macOS 27.0, *) {
            if SystemLanguageModel.default.isAvailable {
                do {
                    #if os(macOS)
                    let platform = "macOS 27"
                    #elseif os(iOS)
                    let platform = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS 27" : "iOS 27"
                    #else
                    let platform = "Apple Silicon"
                    #endif
                    
                    let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You are Coki with Apple Intelligence, the automotive diagnostic copilot running on \(platform).
                        Analyze vehicular warning lights, mechanical sounds, eco-efficiency tips, or maintenance questions.
                        Provide:
                        1. Diagnóstico probable.
                        2. Nivel de gravedad (Bajo / Moderado / Crítico).
                        3. Acción recomendada para el conductor de Forkar.
                        Answer in Spanish concisely with automotive clarity.
                        """
                    )
                    let prompt = "Diagnostica este síntoma o testigo vehicular: \(clean)"
                    let response = try await session.respond(to: prompt)
                    return response.content
                } catch {
                    print("Coki vehicular diagnosis fallback: \(error.localizedDescription)")
                }
            }
        }
        #endif
        
        return "🚗 Diagnóstico Coki with Apple Intelligence:\n• Síntoma: \(clean)\n• Gravedad: Moderada\n• Recomendación: Verifica niveles de fluidos y programa una revisión con tu comunidad Forkar."
    }
    
    /// Real-time contextual response in CSMS chat rooms using Coki with Apple Intelligence
    func askCokiAI(query: String, context: String? = nil) async -> String {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return "¡Hola! Soy Coki with Apple Intelligence 🤖. Puedes preguntarme sobre cualquier cosa: programación, terminales, ciencia, ideas o dudas generales. Escribe tu consulta después de /Coki."
        }
        
        #if canImport(FoundationModels) && !os(watchOS) && !os(tvOS)
        if #available(iOS 27.0, macOS 27.0, *) {
            if SystemLanguageModel.default.isAvailable {
                do {
                    #if os(macOS)
                    let platform = "macOS 27"
                    #elseif os(iOS)
                    let platform = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS 27" : "iOS 27"
                    #else
                    let platform = "Apple Silicon"
                    #endif
                    
                    let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
                    let session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You are Coki with Apple Intelligence, the official versatile AI assistant of Coki Studios running on \(platform) Neural Engine.
                        You assist users with any topic:
                        - Software engineering, terminals, command-line tools (Zsh, Bash), Swift, web development, debugging, and system design
                        - Science, general knowledge, philosophy, everyday reasoning, and productivity
                        - Creative ideas, explanations, and advice
                        - Mobility and sustainability if the user asks about it
                        Never restrict yourself to only cars or vehicles.
                        Be insightful, friendly, concise, and practical.
                        Always respond in Spanish in 2 to 4 clear sentences with relevant emojis.
                        """
                    )
                    let prompt = context != nil ? "Pregunta de un usuario en el chat '\(context!)': \(clean)" : clean
                    let response = try await session.respond(to: prompt)
                    return response.content
                } catch {
                    print("Coki AI FoundationModels error: \(error.localizedDescription)")
                }
            }
        }
        #endif
        
        // Edge Fallback via Cloudflare Workers AI (/api/coki)
        if let edgeResponse = await askWorkersAICoki(query: clean, context: context) {
            return edgeResponse
        }
        
        return smartCokiResponse(for: clean)
    }
    
    private func askWorkersAICoki(query: String, context: String? = nil) async -> String? {
        guard let url = URL(string: "https://cokistudios.com/api/coki") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.0
        
        let payload: [String: Any] = [
            "query": query,
            "context": context ?? "general"
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["answer"] as? String, !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return answer.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private func smartCokiResponse(for query: String) -> String {
        let lower = query.lowercased()
        
        // 1. Terminales, CLI y Sistemas
        if lower.contains("terminal") || lower.contains("consola") || lower.contains("bash") || lower.contains("zsh") || lower.contains("cli") || lower.contains("command line") {
            return "🖥️ Coki AI: Una terminal es una interfaz de línea de comandos (CLI) que te permite interactuar directamente con el sistema operativo ejecutando instrucciones de texto. En macOS y Linux se suele usar Zsh o Bash para automatizar tareas, compilar código y gestionar procesos de forma rápida y potente."
        }
        
        // 2. Programación, Swift, código y bugs
        if lower.contains("swift") || lower.contains("swiftui") {
            return "💻 Coki AI: Swift es un lenguaje moderno, tipado y de alto rendimiento diseñado por Apple para crear apps en iOS, macOS, watchOS y visionOS. Con SwiftUI puedes armar interfaces completamente reactivas y declarativas con excelente rendimiento nativo."
        }
        if lower.contains("python") || lower.contains("javascript") || lower.contains("typescript") || lower.contains("codigo") || lower.contains("código") || lower.contains("programar") || lower.contains("bug") || lower.contains("git") {
            return "⚡ Coki AI: En desarrollo de software, la clave está en mantener funciones puras, código modular y un manejo defensivo de errores. Si tienes un bug o quieres diseñar una arquitectura, dime qué estás implementando y lo resolvemos juntos."
        }
        
        // 3. Coki Studios / Quién eres / Saludos
        if lower.contains("quien eres") || lower.contains("quién eres") || lower.contains("que eres") || lower.contains("qué eres") || lower.contains("que haces") || lower.contains("qué haces") {
            return "🤖 ¡Hola! Soy Coki with Apple Intelligence, el asistente inteligente universal de Coki Studios. Puedo ayudarte con programación, terminales, dudas científicas, ideas creativas, tecnología y temas generales. ¡Pregúntame lo que necesites!"
        }
        if lower.contains("hola") || lower.contains("buenos dias") || lower.contains("buenos días") || lower.contains("buenas tardes") || lower.contains("hey") {
            return "👋 ¡Hola! ¿Cómo estás hoy? Estoy aquí para ayudarte con lo que necesites: resolver dudas técnicas, explorar ideas o charlar sobre cualquier tema. ¿De qué te gustaría hablar?"
        }
        if lower.contains("gracias") || lower.contains("genial") || lower.contains("crack") {
            return "🚀 ¡Con gusto! Me alegra poder ayudarte. Si tienes cualquier otra pregunta o necesitas una mano con otro proyecto, aquí me tienes."
        }
        
        // 4. Qué es... / Conceptos generales
        if lower.hasPrefix("que es") || lower.hasPrefix("qué es") || lower.contains("significa") || lower.contains("concepto") {
            return "💡 Coki AI: Para entender \"\(query)\", es útil analizar su principio fundamental. Es un concepto clave con aplicaciones teóricas y prácticas; cuéntame en qué contexto lo estás utilizando y te daré una explicación precisa paso a paso."
        }
        
        // 5. Automoción y Movilidad (SÓLO si el usuario pregunta explícitamente por vehículos o baterías)
        if lower.contains("bateria") || lower.contains("batería") || lower.contains("carga") {
            return "🔋 Coki AI: Para cuidar la vida útil de baterías (de tus dispositivos o autos eléctricos), procura mantenerlas entre el 20% y el 80% y evitar temperaturas extremas prolongadas."
        }
        if lower.contains("freno") || lower.contains("llanta") || lower.contains("neumatico") || lower.contains("carro") || lower.contains("auto") || lower.contains("vehiculo") || lower.contains("vehículo") {
            return "🚗 Coki AI: Mantener una adecuada presión de neumáticos y una conducción progresiva reduce desgastes mecánicos, optimiza el consumo de energía y mejora la seguridad en el camino."
        }
        if lower.contains("ruta") || lower.contains("viaje") || lower.contains("mapa") {
            return "🗺️ Coki AI: Para una buena ruta, planifica paradas estratégicas, verifica el tráfico en tiempo real y optimiza tus trayectos para un viaje cómodo y eficiente."
        }
        
        // 6. Respuesta universal inteligente por defecto
        return "✨ Coki with Apple Intelligence: \"\(query)\" es una consulta muy interesante. Como asistente de Coki Studios, estoy preparado para responderte sobre programación, sistemas, ciencia o cualquier tema general. Puedes formularme preguntas directas con /Coki y te ayudaré con gusto 💡."
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
    
    /// Real-time edge moderation via Cloudflare Workers AI (@cf/meta/llama-3.2-3b-instruct)
    /// Powered for iOS (iOS 26 and below, iOS 27) and platforms without local Apple Foundation Models.
    private func analyzeWithWorkersAI(content: String, title: String? = nil) async -> ModerationResult? {
        guard let url = URL(string: "https://cokistudios.com/api/moderate") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0
        
        var payload: [String: String] = ["content": content]
        if let title = title, !title.isEmpty {
            payload["title"] = title
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            
            struct WorkersAIResponse: Decodable {
                let isSafe: Bool
                let flaggedWords: [String]?
                let reason: String?
                let engine: String?
            }
            
            let decoded = try JSONDecoder().decode(WorkersAIResponse.self, from: data)
            let flagged = decoded.isSafe ? [] : (decoded.flaggedWords ?? [])
            let engine = decoded.engine ?? "Cloudflare Workers AI (Llama 3.2)"
            let reason = decoded.reason ?? (decoded.isSafe ? "Contenido verificado y respetuoso." : "Contenido inapropiado detectado.")
            
            return ModerationResult(
                isSafe: decoded.isSafe,
                flaggedWords: flagged,
                reason: reason,
                engine: engine
            )
        } catch {
            print("Workers AI moderation network fallback: \(error.localizedDescription)")
            return nil
        }
    }
    
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
