import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var company = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            // Background
            ForkarTheme.bg
                .ignoresSafeArea()
            XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12), rainbow: true)
                .ignoresSafeArea()
            
            // Grid Effect from the web
            VStack {
                Spacer()
                HStack {
                    Spacer()
                }
            }
            .background(
                Image(systemName: "circle.grid.3x3.fill")
                    .resizable()
                    .opacity(0.015)
                    .foregroundColor(ForkarTheme.accent)
            )
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Logo Branding
                    VStack(spacing: 12) {
                        Text("F")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(ForkarTheme.accent)
                            .cornerRadius(16)
                            .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 15, y: 5)
                        
                        Text("Forkar")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        
                        Text("Conéctate con otros jugadores y comparte tus ideas")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    
                    // Form Card
                    VStack(spacing: 20) {
                        Text(isRegistering ? "Crear Cuenta" : "Iniciar Sesión")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if isRegistering {
                            CustomTextField(
                                icon: "person.fill",
                                placeholder: "Nombre Completo",
                                text: $name
                            )
                            
                            CustomTextField(
                                icon: "quote.bubble.fill",
                                placeholder: "Biografía / Estado (opcional)",
                                text: $company
                            )
                        } else {
                            // OAuth Social Buttons (Google and GitHub)
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await handleOAuth(provider: "google")
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "safari.fill")
                                        Text("Continuar con Google")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .foregroundColor(ForkarTheme.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(ForkarTheme.card)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    Task {
                                        await handleOAuth(provider: "github")
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "terminal.fill")
                                        Text("Continuar con GitHub")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.bottom, 4)
                            
                            HStack {
                                VStack { Divider().background(ForkarTheme.border) }
                                Text("o usa tu correo")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ForkarTheme.textMuted)
                                    .padding(.horizontal, 4)
                                VStack { Divider().background(ForkarTheme.border) }
                            }
                        }
                        
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Correo electrónico",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Contraseña",
                            text: $password
                        )
                        
                        if !isRegistering {
                            HStack {
                                Spacer()
                                Button("¿Olvidaste tu contraseña?") {
                                    // TODO: Password reset
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ForkarTheme.accent)
                            }
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        // Submit button
                        Button(action: {
                            Task {
                                await handleAuth()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isRegistering ? "Crear cuenta" : "Iniciar sesión")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .background(ForkarTheme.primaryGradient)
                            .cornerRadius(12)
                            .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 10, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isLoading)
                        .padding(.top, 10)
                    }
                    .padding(24)
                    .liquidGlass(cornerRadius: 24, glowColor: ForkarTheme.accent)
                    .padding(.horizontal)
                    
                    // Switch login / register
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            errorMessage = ""
                        }
                    }) {
                        Text(isRegistering ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate gratis")
                            .font(.footnote)
                            .foregroundColor(ForkarTheme.accent)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func handleAuth() async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Completa todos los campos"
            return
        }
        
        if isRegistering && name.isEmpty {
            errorMessage = "Completa tu nombre"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            if isRegistering {
                try await authManager.signUp(email: email, password: password, name: name, company: company)
            } else {
                try await authManager.login(email: email, password: password)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func handleOAuth(provider: String) async {
        isLoading = true
        errorMessage = ""
        do {
            try await authManager.signInWithOAuth(provider: provider)
            dismiss()
        } catch {
            let nsError = error as NSError
            if nsError.domain == ASWebAuthenticationSessionErrorDomain && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                isLoading = false
                return
            }
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Custom Native Field Components
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    #if os(iOS)
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    #else
    var keyboardType: DummyKeyboardType = .default
    var autocapitalization: DummyAutocapitalization = .sentences
    
    enum DummyKeyboardType {
        case `default`, emailAddress
    }
    enum DummyAutocapitalization {
        case sentences, never
    }
    #endif
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ForkarTheme.textSub)
                .frame(width: 20)
            
            #if os(iOS)
            TextField(placeholder, text: $text)
                .foregroundColor(ForkarTheme.text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(true)
            #else
            TextField(placeholder, text: $text)
                .foregroundColor(ForkarTheme.text)
                .disableAutocorrection(true)
            #endif
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(ForkarTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ForkarTheme.border, lineWidth: 1)
        )
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ForkarTheme.textSub)
                .frame(width: 20)
            
            #if os(iOS)
            SecureField(placeholder, text: $text)
                .foregroundColor(ForkarTheme.text)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.none)
            #else
            SecureField(placeholder, text: $text)
                .foregroundColor(ForkarTheme.text)
                .disableAutocorrection(true)
            #endif
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(ForkarTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ForkarTheme.border, lineWidth: 1)
        )
    }
}
