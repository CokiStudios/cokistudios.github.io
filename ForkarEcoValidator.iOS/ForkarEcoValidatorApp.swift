import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Validation Result Model
struct ValidatedEcoClaim: Identifiable, Codable {
    let id: UUID
    let userId: String
    let userName: String
    let stationName: String
    let points: Int
    let co2EstimatedKg: Double
    let token: String
    let timestamp: Date
    let statusText: String
    let isApproved: Bool
    
    init(id: UUID = UUID(), userId: String, userName: String, stationName: String, points: Int, co2EstimatedKg: Double, token: String, timestamp: Date = Date(), isApproved: Bool, statusText: String) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.stationName = stationName
        self.points = points
        self.co2EstimatedKg = co2EstimatedKg
        self.token = token
        self.timestamp = timestamp
        self.isApproved = isApproved
        self.statusText = statusText
    }
}

// MARK: - Eco Station Definition
struct EcoStation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let typeName: String
    let icon: String
    let color: Color
    let defaultPts: Int
    let co2Multiplier: Double
}

// MARK: - Main Eco Validator View
struct ValidatorContentView: View {
    @State private var isScanning = false
    @State private var recentValidations: [ValidatedEcoClaim] = []
    @State private var selectedStationIndex = 0
    @State private var customStationName: String = "Punto Verde Parque Principal (Cota)"
    @State private var showSuccessAlert = false
    @State private var lastClaim: ValidatedEcoClaim? = nil
    @State private var totalValidatedPoints: Int = 0
    @State private var totalCO2KgSaved: Double = 0.0
    @State private var manualTokenInput: String = ""
    @State private var showManualInputSheet: Bool = false
    @State private var filterApprovedOnly: Bool = false
    
    // Set of used dynamic tokens to prevent double-spending
    @State private var processedTokens = Set<String>()
    
    let stations: [EcoStation] = [
        EcoStation(name: "Punto Verde Parque Principal", typeName: "Separación y Compostaje", icon: "leaf.fill", color: Color(red: 16/255, green: 185/255, blue: 129/255), defaultPts: 50, co2Multiplier: 0.05),
        EcoStation(name: "Estación Bici Cota Sostenible", typeName: "Movilidad Limpia", icon: "bicycle", color: Color(red: 59/255, green: 130/255, blue: 246/255), defaultPts: 30, co2Multiplier: 0.06),
        EcoStation(name: "Punto RAEE Electrónicos", typeName: "Reciclaje de Hardware", icon: "bolt.batteryblock.fill", color: Color(red: 245/255, green: 158/255, blue: 11/255), defaultPts: 70, co2Multiplier: 0.08),
        EcoStation(name: "Centro de Acopio Municipal", typeName: "Acopio Masivo y Plásticos", icon: "arrow.3.trianglepath", color: Color(red: 139/255, green: 92/255, blue: 246/255), defaultPts: 60, co2Multiplier: 0.055)
    ]
    
    var currentStation: EcoStation {
        stations[selectedStationIndex]
    }
    
    var filteredValidations: [ValidatedEcoClaim] {
        if filterApprovedOnly {
            return recentValidations.filter { $0.isApproved }
        }
        return recentValidations
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Liquid Dark Theme
                Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()
                
                // Ambient Glow
                VStack {
                    Circle()
                        .fill(currentStation.color.opacity(0.12))
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(y: -100)
                    Spacer()
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Station Selector Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Text("🌿")
                                    Text("FORKAR ECO VALIDATOR")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                                        .tracking(2.0)
                                }
                                Spacer()
                                Button(action: { showManualInputSheet = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "keyboard")
                                        Text("Manual")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Station Pill Selection
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(0..<stations.count, id: \.self) { idx in
                                        let st = stations[idx]
                                        let isSel = (idx == selectedStationIndex)
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                selectedStationIndex = idx
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: st.icon)
                                                    .font(.system(size: 13, weight: .bold))
                                                Text(st.name)
                                                    .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                            }
                                            .foregroundColor(isSel ? .white : .gray)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                isSel
                                                ? st.color
                                                : Color.white.opacity(0.05)
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isSel ? st.color : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        
                        // Live Scanner Action Card
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                currentStation.color.opacity(0.25),
                                                Color.black.opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        currentStation.color.opacity(0.6),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                
                                VStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(currentStation.color.opacity(0.2))
                                            .frame(width: 84, height: 84)
                                        
                                        Image(systemName: "camera.viewfinder")
                                            .font(.system(size: 42, weight: .semibold))
                                            .foregroundColor(currentStation.color)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("Validar Código QR Forkar")
                                            .font(.system(size: 20, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("Estación activa: \(currentStation.name)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    Button(action: { isScanning = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "bolt.fill")
                                            Text("Abrir Escáner Ultra-Rápido")
                                        }
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(currentStation.color)
                                        .cornerRadius(14)
                                        .shadow(color: currentStation.color.opacity(0.4), radius: 12, y: 4)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 4)
                                }
                                .padding(24)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Live Session Stats Summary
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PUNTOS TOTALES")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.gray)
                                    .tracking(1.0)
                                Text("+\(totalValidatedPoints) pts")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CO₂ MITIGADO")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.gray)
                                    .tracking(1.0)
                                Text(String(format: "%.2f kg", totalCO2KgSaved))
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                        
                        // History Section with Filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("HISTORIAL DE VALIDACIONES")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.gray)
                                    .tracking(1.0)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation { filterApprovedOnly.toggle() }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: filterApprovedOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                        Text(filterApprovedOnly ? "Aprobados" : "Todos (\(recentValidations.count))")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            if filteredValidations.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("Sin validaciones registradas")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("Escanea un código QR generado en la app Forkar para acreditar puntos instantáneamente.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 30)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 36)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
                                .padding(.horizontal, 16)
                            } else {
                                LazyVStack(spacing: 10) {
                                    ForEach(filteredValidations) { claim in
                                        EnhancedValidationRow(claim: claim)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Eco Validator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isScanning) {
                CameraValidatorScannerView(currentStation: currentStation) { qrData in
                    validateAndProcessQRCode(qrData)
                }
            }
            .sheet(isPresented: $showManualInputSheet) {
                ManualTokenInputSheet(currentStation: currentStation) { token in
                    validateManualToken(token)
                }
            }
            .alert("Validación Exitosa 🌿", isPresented: $showSuccessAlert) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                if let claim = lastClaim {
                    Text("¡Se han acreditado +\(claim.points) Puntos Eco (\(String(format: "%.2f", claim.co2EstimatedKg)) kg CO₂) a \"\(claim.userName)\" en \(claim.stationName)!")
                } else {
                    Text("Puntos acreditados con éxito.")
                }
            }
        }
    }
    
    // MARK: - Validation Engine
    private func validateAndProcessQRCode(_ qrString: String) {
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        guard let url = URL(string: qrString), url.scheme == "forkar_eco" else {
            // Decodificación de códigos QR genéricos o texto sin formato
            let components = URLComponents(string: qrString)
            let user = components?.queryItems?.first(where: { $0.name == "user" })?.value ?? "Usuario QR"
            let name = components?.queryItems?.first(where: { $0.name == "name" })?.value?.removingPercentEncoding ?? user
            let token = components?.queryItems?.first(where: { $0.name == "token" })?.value ?? UUID().uuidString.prefix(8).description
            
            completeValidation(userId: user, userName: name, points: currentStation.defaultPts, token: token)
            generator.notificationOccurred(.success)
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let userId = components?.queryItems?.first(where: { $0.name == "user" })?.value ?? "forkar_user"
        let userName = components?.queryItems?.first(where: { $0.name == "name" })?.value?.removingPercentEncoding ?? "Usuario Forkar"
        let token = components?.queryItems?.first(where: { $0.name == "token" })?.value ?? UUID().uuidString.prefix(8).description
        let ptsStr = components?.queryItems?.first(where: { $0.name == "pts" })?.value
        let pts = Int(ptsStr ?? "") ?? currentStation.defaultPts
        
        // Anti-Fraud: Verificación de un solo uso por Token Dinámico
        if processedTokens.contains(token) {
            let failedClaim = ValidatedEcoClaim(
                userId: userId,
                userName: userName,
                stationName: currentStation.name,
                points: 0,
                co2EstimatedKg: 0.0,
                token: token,
                isApproved: false,
                statusText: "Rechazado: Código ya canjeado"
            )
            recentValidations.insert(failedClaim, at: 0)
            generator.notificationOccurred(.error)
            AudioServicesPlaySystemSound(1053) // Error sound
            return
        }
        
        processedTokens.insert(token)
        completeValidation(userId: userId, userName: userName, points: pts, token: token)
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(1054) // Success chime
    }
    
    private func validateManualToken(_ token: String) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return }
        
        let simString = "forkar_eco://claim?user=manual_user&name=Usuario+Manual&pts=\(currentStation.defaultPts)&token=\(cleanToken)&ts=\(Int(Date().timeIntervalSince1970))"
        validateAndProcessQRCode(simString)
    }
    
    private func completeValidation(userId: String, userName: String, points: Int, token: String) {
        let co2Kg = Double(points) * currentStation.co2Multiplier
        let claim = ValidatedEcoClaim(
            userId: userId,
            userName: userName,
            stationName: currentStation.name,
            points: points,
            co2EstimatedKg: co2Kg,
            token: token,
            isApproved: true,
            statusText: "Aprobado y Acreditado"
        )
        
        lastClaim = claim
        recentValidations.insert(claim, at: 0)
        totalValidatedPoints += points
        totalCO2KgSaved += co2Kg
        showSuccessAlert = true
    }
}

// MARK: - Enhanced Validation Row
struct EnhancedValidationRow: View {
    let claim: ValidatedEcoClaim
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        claim.isApproved
                        ? Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.15)
                        : Color.red.opacity(0.15)
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: claim.isApproved ? "checkmark.seal.fill" : "xmark.octagon.fill")
                    .font(.system(size: 20))
                    .foregroundColor(claim.isApproved ? Color(red: 16/255, green: 185/255, blue: 129/255) : .red)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(claim.userName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if claim.isApproved {
                        Text("+\(claim.points) pts")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                    } else {
                        Text("Rechazado")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                
                Text(claim.stationName)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    Text("Token: \(claim.token)")
                    Text("•")
                    Text(claim.timestamp, style: .time)
                    if claim.isApproved {
                        Text("•")
                        Text(String(format: "%.2f kg CO₂", claim.co2EstimatedKg))
                            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(claim.isApproved ? Color.white.opacity(0.06) : Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Native AVFoundation Live Camera Scanner
struct CameraValidatorScannerView: View {
    @Environment(\.dismiss) var dismiss
    let currentStation: EcoStation
    let onScanned: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Real AVFoundation Camera feed
            AVCameraPreviewView { code in
                onScanned(code)
                dismiss()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Escáner de Estación")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(currentStation.name)
                            .font(.system(size: 12))
                            .foregroundColor(currentStation.color)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Target Frame Box
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [currentStation.color, Color.white, currentStation.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 260, height: 260)
                    
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 120))
                        .foregroundColor(currentStation.color.opacity(0.3))
                }
                
                Text("Apunta al código QR dinámico de la app Forkar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                
                Spacer()
                
                // Quick Simulator Simulator button
                Button(action: {
                    let randomToken = UUID().uuidString.prefix(8)
                    let simulated = "forkar_eco://claim?user=usr_7721&name=JeriX+Ortiz&pts=\(currentStation.defaultPts)&token=\(randomToken)&ts=\(Int(Date().timeIntervalSince1970))"
                    onScanned(simulated)
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Simular Escaneo Dinámico (+\(currentStation.defaultPts) pts)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(currentStation.color)
                    .cornerRadius(14)
                    .shadow(color: currentStation.color.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - AVCamera Native Session Wrapper
struct AVCameraPreviewView: UIViewControllerRepresentable {
    let onCapture: (String) -> Void
    
    func makeUIViewController(context: Context) -> AVScannerViewController {
        let vc = AVScannerViewController()
        vc.onCodeScanned = onCapture
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVScannerViewController, context: Context) {}
}

class AVScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onCodeScanned: ((String) -> Void)?
    private var hasFoundCode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        self.previewLayer = layer
        self.captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasFoundCode,
              let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringVal = metadataObj.stringValue else {
            return
        }
        
        hasFoundCode = true
        captureSession?.stopRunning()
        DispatchQueue.main.async {
            self.onCodeScanned?(stringVal)
        }
    }
}

// MARK: - Manual Token Input Sheet
struct ManualTokenInputSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentStation: EcoStation
    let onSubmit: (String) -> Void
    @State private var tokenText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingresar Token del Usuario")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                        
                        TextField("Ej: 8A4F19DE", text: $tokenText)
                            .padding(14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                    }
                    .padding(.top, 20)
                    
                    Button(action: {
                        onSubmit(tokenText)
                        dismiss()
                    }) {
                        Text("Validar Token")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(tokenText.isEmpty ? Color.gray.opacity(0.3) : currentStation.color)
                            .cornerRadius(12)
                    }
                    .disabled(tokenText.isEmpty)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Entrada Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - App Entry Point
@main
struct ForkarEcoValidatorApp: App {
    var body: some Scene {
        WindowGroup {
            ValidatorContentView()
        }
    }
}
