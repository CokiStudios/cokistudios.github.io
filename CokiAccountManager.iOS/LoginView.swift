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
            CokiTheme.bg
                .ignoresSafeArea()
            XtrapsBackground(strokeColor: CokiTheme.accent.opacity(0.12))
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Logo Branding
                    VStack(spacing: 12) {
                        Text("C")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(CokiTheme.accent)
                            .cornerRadius(16)
                            .shadow(color: CokiTheme.accent.opacity(0.4), radius: 15, y: 5)
                        
                        Text("Coki ID")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(CokiTheme.text)
                        
                        Text("Tu llave de entrada a todos nuestros juegos y comunidades")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CokiTheme.textSub)
                    }
                    
                    // Form Card
                    VStack(spacing: 20) {
                        Text(isRegistering ? "Crear Cuenta" : "Iniciar Sesión")
                            .font(.headline)
                            .foregroundColor(CokiTheme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if !isRegistering {
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
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundColor(CokiTheme.text)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(CokiTheme.border, lineWidth: 1)
                                    )
                                }
                                
                                Button(action: {
                                    Task {
                                        await handleOAuth(provider: "github")
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "terminal.fill")
                                        Text("Continuar con GitHub")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(CokiTheme.border, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.bottom, 4)
                            
                            HStack {
                                VStack { Divider().background(CokiTheme.border) }
                                Text("o usa tu correo")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(CokiTheme.textMuted)
                                    .padding(.horizontal, 4)
                                VStack { Divider().background(CokiTheme.border) }
                            }
                        }
                        
                        if isRegistering {
                            CustomTextField(
                                icon: "person.fill",
                                placeholder: "Nombre Completo",
                                text: $name
                            )
                            
                            CustomTextField(
                                icon: "quote.bubble.fill",
                                placeholder: "Un lema o biografía (opcional)",
                                text: $company
                            )
                        }
                        
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Correo Electrónico",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    CustomTextField(
                                        icon: "lock.fill",
                                        placeholder: "Contraseña",
                                        text: $password,
                                        autocapitalization: .never
                                    )
                                } else {
                                    CustomSecureField(
                                        icon: "lock.fill",
                                        placeholder: "Contraseña",
                                        text: $password
                                    )
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(CokiTheme.textSub)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
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
                                    Text(isRegistering ? "Crear mi Coki ID" : "Iniciar sesión")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                        .padding(.top, 10)
                    }
                    .glassCard()
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
                            .foregroundColor(CokiTheme.accent)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Custom TextField Components
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CokiTheme.textSub)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(CokiTheme.text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CokiTheme.border, lineWidth: 1)
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
                .foregroundColor(CokiTheme.textSub)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .foregroundColor(CokiTheme.text)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.none)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CokiTheme.border, lineWidth: 1)
        )
    }
}
