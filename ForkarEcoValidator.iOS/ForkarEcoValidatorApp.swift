import SwiftUI
import AVFoundation

// MARK: - Validation Result Model
struct ValidatedEcoClaim: Identifiable {
    let id = UUID()
    let userId: String
    let userName: String
    let points: Int
    let token: String
    let timestamp: Date
    let status: ValidationStatus
}

enum ValidationStatus {
    case approved
    case rejected(String)
}

// MARK: - Eco Validator App Main View
struct ValidatorContentView: View {
    @State private var isScanning = false
    @State private var recentValidations: [ValidatedEcoClaim] = []
    @State private var stationName: String = "Punto Verde Parque Principal"
    @State private var selectedPointsToAward: Int = 50
    @State private var scannedCode: String = ""
    @State private var showSuccessAlert = false
    @State private var lastClaim: ValidatedEcoClaim? = nil
    
    // Set of used dynamic tokens to prevent double-spending
    @State private var processedTokens = Set<String>()
    
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("🌿")
                            Text("ECO VALIDATOR")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                                .tracking(1.5)
                        }
                        Text(stationName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { isScanning = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 16/255, green: 185/255, blue: 129/255), Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.4), radius: 8, y: 3)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.04))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Quick Action Scanner Card
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.2),
                                                Color.blue.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.4), lineWidth: 1.5)
                                    )
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                                    
                                    Text("Escanear Código QR de Usuario")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Verifica y acredita puntos ecológicos en tiempo real")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    Button(action: { isScanning = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "bolt.fill")
                                            Text("Iniciar Escáner de Validación")
                                        }
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .background(Color(red: 16/255, green: 185/255, blue: 129/255))
                                        .cornerRadius(12)
                                        .shadow(color: Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.4), radius: 8, y: 3)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(24)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Selector de Puntos a Otorgar
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PUNTOS POR RETO / ACCIÓN")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            HStack(spacing: 10) {
                                PointOptionButton(points: 30, title: "Bici / Caminata", selected: selectedPointsToAward == 30) {
                                    selectedPointsToAward = 30
                                }
                                PointOptionButton(points: 50, title: "Punto Verde", selected: selectedPointsToAward == 50) {
                                    selectedPointsToAward = 50
                                }
                                PointOptionButton(points: 70, title: "Punto RAEE", selected: selectedPointsToAward == 70) {
                                    selectedPointsToAward = 70
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Historial de Validaciones
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("HISTORIAL DE VALIDACIONES")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(recentValidations.count) validados")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                            }
                            .padding(.horizontal)
                            
                            if recentValidations.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No se han validado códigos en esta sesión")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            } else {
                                ForEach(recentValidations) { claim in
                                    ValidationRow(claim: claim)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .sheet(isPresented: $isScanning) {
            CameraValidatorScannerView { qrData in
                validateAndProcessQRCode(qrData)
            }
        }
        .alert("Validación Exitosa 🌿", isPresented: $showSuccessAlert) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            if let claim = lastClaim {
                Text("¡Se han acreditado +\(claim.points) Puntos Eco al usuario \"\(claim.userName)\" con éxito!")
            } else {
                Text("Puntos acreditados.")
            }
        }
    }
    
    // MARK: - Validation Logic (Decodifica el QR aleatorio y previene reuso)
    private func validateAndProcessQRCode(_ qrString: String) {
        guard let url = URL(string: qrString), url.scheme == "forkar_eco" else {
            // Manejo de QR genérico o con formato directo
            let components = URLComponents(string: qrString)
            let user = components?.queryItems?.first(where: { $0.name == "user" })?.value ?? "Usuario QR"
            let name = components?.queryItems?.first(where: { $0.name == "name" })?.value?.removingPercentEncoding ?? user
            let token = components?.queryItems?.first(where: { $0.name == "token" })?.value ?? UUID().uuidString.prefix(8).description
            
            completeValidation(userId: user, userName: name, points: selectedPointsToAward, token: token)
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let userId = components?.queryItems?.first(where: { $0.name == "user" })?.value ?? "forkar_user"
        let userName = components?.queryItems?.first(where: { $0.name == "name" })?.value?.removingPercentEncoding ?? "Usuario Forkar"
        let token = components?.queryItems?.first(where: { $0.name == "token" })?.value ?? UUID().uuidString.prefix(8).description
        let ptsStr = components?.queryItems?.first(where: { $0.name == "pts" })?.value
        let pts = Int(ptsStr ?? "") ?? selectedPointsToAward
        
        // Verificar si el token ya fue usado (Anti-fraude de QR estático)
        if processedTokens.contains(token) {
            let failedClaim = ValidatedEcoClaim(
                userId: userId,
                userName: userName,
                points: 0,
                token: token,
                timestamp: Date(),
                status: .rejected("Código ya canjeado")
            )
            recentValidations.insert(failedClaim, at: 0)
            return
        }
        
        processedTokens.insert(token)
        completeValidation(userId: userId, userName: userName, points: pts, token: token)
    }
    
    private func completeValidation(userId: String, userName: String, points: Int, token: String) {
        let claim = ValidatedEcoClaim(
            userId: userId,
            userName: userName,
            points: points,
            token: token,
            timestamp: Date(),
            status: .approved
        )
        
        lastClaim = claim
        recentValidations.insert(claim, at: 0)
        showSuccessAlert = true
    }
}

// MARK: - Point Option Selector
struct PointOptionButton: View {
    let points: Int
    let title: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("+\(points)")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(selected ? .white : Color(red: 16/255, green: 185/255, blue: 129/255))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selected ? .white.opacity(0.9) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selected
                ? AnyView(Color(red: 16/255, green: 185/255, blue: 129/255))
                : AnyView(Color.white.opacity(0.04))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selected ? Color(red: 16/255, green: 185/255, blue: 129/255) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Validation Row
struct ValidationRow: View {
    let claim: ValidatedEcoClaim
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        claim.status == .approved
                        ? Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.2)
                        : Color.red.opacity(0.2)
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: claim.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(claim.status == .approved ? Color(red: 16/255, green: 185/255, blue: 129/255) : .red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(claim.userName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Text("Token: \(claim.token)")
                    Text("•")
                    Text(claim.timestamp, style: .time)
                }
                .font(.system(size: 11))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            if claim.status == .approved {
                Text("+\(claim.points) pts")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.15))
                    .cornerRadius(8)
            } else {
                Text("Rechazado")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.red)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

extension ValidationStatus: Equatable {
    static func == (lhs: ValidationStatus, rhs: ValidationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.approved, .approved): return true
        case (.rejected(let a), .rejected(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Camera Scanner Sheet
struct CameraValidatorScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    let onScanned: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Escáner de Validación de Estación")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255))
                }
                .padding()
                
                Spacer()
                
                // Visor de Cámara
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 16/255, green: 185/255, blue: 129/255), Color.white, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 260, height: 260)
                    
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 110))
                        .foregroundColor(Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.35))
                    
                    Rectangle()
                        .fill(Color(red: 16/255, green: 185/255, blue: 129/255))
                        .frame(width: 240, height: 2)
                        .shadow(color: Color(red: 16/255, green: 185/255, blue: 129/255), radius: 10)
                }
                
                Text("Apunta la cámara al código QR dinámico de la app Forkar del usuario")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Botón de Simulación para Pruebas Rápidas en Simulador
                Button(action: {
                    let randomToken = UUID().uuidString.prefix(8)
                    let simulated = "forkar_eco://claim?user=usr_8941&name=JeriX+Ortiz&pts=50&token=\(randomToken)&ts=\(Int(Date().timeIntervalSince1970))"
                    onScanned(simulated)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Simular Escaneo de QR Aleatorio")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 16/255, green: 185/255, blue: 129/255))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
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
