import Foundation

// MARK: - Native Cloudflare Edge OTA Publishing Service
public final class OTAService: @unchecked Sendable {
    public static let shared = OTAService()

    public var serverURL: String = ProcessInfo.processInfo.environment["CS_WEBS_URL"] ?? "https://webs.cokistudios.com"

    private init() {}

    /// Publishes a .c2 module over-the-air to CS WEBS Cloudflare Edge API
    public func publishModuleOTA(filePath: String, deviceTarget: String = "shine_all") async -> Result<String, Error> {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileName = fileURL.lastPathComponent

        guard FileManager.default.fileExists(atPath: filePath),
              let fileData = try? Data(contentsOf: fileURL) else {
            return .failure(NSError(domain: "OTAService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Archivo .c2 no encontrado: \(filePath)"]))
        }

        let endpointString = "\(serverURL)/api/v1/c2/upload"
        guard let url = URL(string: endpointString) else {
            return .failure(NSError(domain: "OTAService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL de servidor inválida: \(endpointString)"]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // File part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Target device part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"target_device\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(deviceTarget)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
            let respString = String(data: data, encoding: .utf8) ?? ""

            if statusCode >= 200 && statusCode < 300 {
                return .success("Publicación OTA exitosa [HTTP \(statusCode)] en Cloudflare Edge (\(serverURL)). Respuesta: \(respString)")
            } else {
                return .failure(NSError(domain: "OTAService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Error Cloudflare Edge [HTTP \(statusCode)]: \(respString)"]))
            }
        } catch {
            return .failure(error)
        }
    }
}
