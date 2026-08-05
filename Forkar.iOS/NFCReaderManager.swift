import SwiftUI
internal import Combine
import CoreNFC

class NFCReaderManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var lastScannedActionId: String? = nil
    @Published var statusMessage: String = ""
    @Published var isScanning = false
    
    var onTagScanned: ((String) -> Void)?
    
    private var session: NFCNDEFReaderSession?
    
    func startScan(completion: @escaping (String) -> Void) {
        self.onTagScanned = completion
        
        #if targetEnvironment(simulator)
        // Modo depuración para el simulador de iOS: abre opciones simuladas de NFC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showSimulatorTagPicker()
        }
        #else
        // Dispositivo Físico Real con antena NFC
        guard NFCNDEFReaderSession.readingAvailable else {
            statusMessage = "NFC no está disponible en este dispositivo."
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "🌿 Acerca tu iPhone al Tag NFC físico de Forkar Eco"
        session?.begin()
        isScanning = true
        #endif
    }
    
    private func showSimulatorTagPicker() {
        // En el simulador simula la lectura instantánea de un Tag NFC real aleatorio o seleccionado
        let sampleTags = [
            "forkar://eco?action=raee",
            "forkar://eco?action=bici",
            "forkar://eco?action=verde"
        ]
        let randomTag = sampleTags.randomElement() ?? "forkar://eco?action=verde"
        self.lastScannedActionId = randomTag
        self.onTagScanned?(randomTag)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if let payloadString = String(data: record.payload, encoding: .utf8) {
                    // Limpiar el payload si incluye código de idioma (ej: enUS)
                    let cleanPayload = cleanNFCPayload(payloadString)
                    DispatchQueue.main.async {
                        self.lastScannedActionId = cleanPayload
                        self.onTagScanned?(cleanPayload)
                    }
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.statusMessage = "Escaneo finalizado: \(error.localizedDescription)"
        }
    }
    
    private func cleanNFCPayload(_ raw: String) -> String {
        if raw.contains("forkar://") || raw.contains("http") {
            return raw
        }
        // Si viene con prefijo de lenguaje NDEF (en / es)
        if raw.count > 3 {
            let index = raw.index(raw.startIndex, offsetBy: 3)
            return String(raw[index...])
        }
        return raw
    }
}
