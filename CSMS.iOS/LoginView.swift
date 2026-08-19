import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var manager: SupabaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            ForkarTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 30)
                    
                    // Logo
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ForkarTheme.primaryGradient)
                                .frame(width: 72, height: 72)
                                .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 15, y: 6)
                            
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("CSMS")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(ForkarTheme.text)
                        
                        Text("Mensajería Privada Coki Studios")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    
                    // Form
                    VStack(spacing: 18) {
                        Text(isRegistering ? "Crear Cuenta" : "Iniciar Sesión")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if isRegistering {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Nombre")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ForkarTheme.textSub)
                                TextField("Tu nombre", text: $name)
                                    .padding(14)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(ForkarTheme.text)
                            }
                        } else {
                            // Google & GitHub OAuth Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    handleOAuth(provider: "google")
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "safari.fill")
                                        Text("Continuar con Google")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundColor(ForkarTheme.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    handleOAuth(provider: "github")
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "terminal.fill")
                                        Text("Continuar con GitHub")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.bottom, 6)
                            
                            HStack {
                                VStack { Divider().background(Color.white.opacity(0.15)) }
                                Text("o con tu correo")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(ForkarTheme.textSub)
                                    .padding(.horizontal, 4)
                                VStack { Divider().background(Color.white.opacity(0.15)) }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Correo Electrónico")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                            TextField("ejemplo@cokistudios.com", text: $email)
                                .padding(14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(ForkarTheme.text)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contraseña")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                            SecureField("••••••••", text: $password)
                                .padding(14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(ForkarTheme.text)
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        Button(action: handleAuth) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isRegistering ? "Registrarse" : "Entrar")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ForkarTheme.accent)
                            .cornerRadius(14)
                            .shadow(color: ForkarTheme.accent.opacity(0.3), radius: 10, y: 4)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, 8)
                        
                        Button(action: {
                            withAnimation {
                                isRegistering.toggle()
                                errorMessage = ""
                            }
                        }) {
                            Text(isRegistering ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ForkarTheme.accent)
                        }
                        .padding(.top, 6)
                    }
                    .padding(22)
                    .liquidGlass(cornerRadius: 20, glowColor: ForkarTheme.accent)
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func handleAuth() {
        errorMessage = ""
        isLoading = true
        Task {
            do {
                if isRegistering {
                    try await manager.signUp(email: email, password: password, name: name.isEmpty ? email : name)
                } else {
                    try await manager.login(email: email, password: password)
                }
                isLoading = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func handleOAuth(provider: String) {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                try await manager.signInWithOAuth(provider: provider)
                isLoading = false
                dismiss()
            } catch {
                let nsError = error as NSError
                if nsError.domain == ASWebAuthenticationSessionErrorDomain && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    isLoading = false
                    return
                }
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
