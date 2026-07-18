import SwiftUI

struct LoginView: View {
    @ObservedObject var manager = SupabaseManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var company = ""
    @State private var isSignUp = false
    @State private var loading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            CSDevelopTheme.bg
                .ignoresSafeArea()
            XtrapsBackground(strokeColor: CSDevelopTheme.accent.opacity(0.12))
                .ignoresSafeArea()
            
            // Top ambient light
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(CSDevelopTheme.primaryGradient)
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .opacity(0.15)
                        .offset(x: 50, y: -50)
                }
                Spacer()
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header logo & title
                    VStack(spacing: 12) {
                        Text("CS")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(CSDevelopTheme.primaryGradient)
                            .cornerRadius(20)
                            .shadow(color: CSDevelopTheme.accent.opacity(0.3), radius: 15)
                        
                        Text("Coki Studios")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(CSDevelopTheme.text)
                        
                        Text("Consola de Desarrolladores")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(CSDevelopTheme.textSub)
                    }
                    .padding(.top, 40)
                    
                    // Input Card
                    VStack(spacing: 20) {
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(CSDevelopTheme.red)
                                Text(error)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(CSDevelopTheme.red)
                                Spacer()
                            }
                            .padding()
                            .background(CSDevelopTheme.red.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CSDevelopTheme.red.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NOMBRE COMPLETO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(CSDevelopTheme.textMuted)
                                TextField("Tu Nombre", text: $fullName)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                    .foregroundColor(CSDevelopTheme.text)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EMPRESA / PROYECTO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(CSDevelopTheme.textMuted)
                                TextField("Coki Studios LLC (opcional)", text: $company)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                    .foregroundColor(CSDevelopTheme.text)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CORREO ELECTRÓNICO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(CSDevelopTheme.textMuted)
                            TextField("desarrollador@miapp.com", text: $email)
                                .padding()
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                .foregroundColor(CSDevelopTheme.text)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CONTRASEÑA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(CSDevelopTheme.textMuted)
                            SecureField("Mínimo 6 caracteres", text: $password)
                                .padding()
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                .foregroundColor(CSDevelopTheme.text)
                        }
                        
                        Button(action: handleAction) {
                            HStack {
                                Spacer()
                                if loading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Registrarse" : "Entrar a la consola")
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(CSPrimaryButton())
                        .disabled(loading)
                    }
                    .padding(24)
                    .background(CSDevelopTheme.card)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(CSDevelopTheme.border, lineWidth: 1)
                    )
                    
                    // Switch mode button
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Text(isSignUp ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes una cuenta de desarrollador? Regístrate")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(CSDevelopTheme.accent)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func handleAction() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Ingresa todos los campos requeridos."
            return
        }
        
        loading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    var metadata: [String: String] = [:]
                    if !fullName.isEmpty { metadata["full_name"] = fullName }
                    if !company.isEmpty { metadata["company"] = company }
                    metadata["role"] = "developer"
                    
                    try await manager.register(email: email, password: password, metadata: metadata)
                } else {
                    try await manager.login(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                loading = false
            }
        }
    }
}

#Preview {
    LoginView()
}
