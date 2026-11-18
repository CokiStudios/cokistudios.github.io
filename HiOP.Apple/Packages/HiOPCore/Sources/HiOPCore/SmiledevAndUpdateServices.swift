import Foundation

public actor SmiledevRegistryService {
    public static let moduleRegistryURLs = [
        URL(string: "https://repo.cokistudios.com/modules?format=json")!,
        URL(string: "https://cokistudios.github.io/modules")!
    ]

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchLiveModules() async throws -> [SmileModuleItem] {
        var lastError: Error?
        for url in Self.moduleRegistryURLs {
            do {
                var req = URLRequest(url: url)
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                req.timeoutInterval = 12
                let (data, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    continue
                }
                let decoded = try JSONDecoder().decode([SmileModuleItem].self, from: data)
                return decoded
            } catch {
                lastError = error
            }
        }
        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}

public actor EngineUpdateService {
    public static let manifestMirrors = [
        URL(string: "https://engine.cokistudios.com/latest.json")!,
        URL(string: "https://repo.cokistudios.com/engine/latest.json")!,
        URL(string: "https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/engine/latest.json")!
    ]

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchLatestManifest() async throws -> (manifest: EngineLatestManifest, sourceURL: URL) {
        var lastError: Error?
        for url in Self.manifestMirrors {
            do {
                var req = URLRequest(url: url)
                req.cachePolicy = .reloadIgnoringLocalCacheData
                req.timeoutInterval = 12
                let (data, response) = try await session.data(for: req)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    continue
                }
                let manifest = try JSONDecoder().decode(EngineLatestManifest.self, from: data)
                return (manifest, url)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
}
