import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 👤 PROFILE VIEW — FORKAR FOR PC (macOS)
// Perfil de usuario, estadísticas de comunidad y gestión de sesión
// ══════════════════════════════════════════════════════════════════

struct ProfileView: View {
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var emailInput: String = ""
    @State private var passwordInput: String = ""
    @State private var isSigningIn: Bool = false
    @State private var authErrorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if manager.isAuthenticated, let user = manager.currentUser {
                    // ─── PERFIL AUTENTICADO ───
                    VStack(spacing: 16) {
                        Circle()
                            .fill(ForkarTheme.brandGradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String((user.fullName ?? user.email ?? "U").prefix(2)).uppercased())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 12, y: 4)
                        
                        VStack(spacing: 4) {
                            Text(user.fullName ?? "Usuario Forkar")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            
                            Text(user.email ?? "")
                                .font(.system(size: 13))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        
                        if let bio = user.bio {
                            Text(bio)
                                .font(.system(size: 13))
                                .foregroundColor(ForkarTheme.text)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        // Estadísticas
                        HStack(spacing: 40) {
                            VStack(spacing: 3) {
                                Text("\(manager.posts.filter { $0.userId == user.id }.count)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text("Publicaciones")
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                            
                            VStack(spacing: 3) {
                                Text("\(user.followersCount ?? 12)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text("Seguidores")
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                            
                            VStack(spacing: 3) {
                                Text("\(user.followingCount ?? 8)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text("Siguiendo")
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                        }
                        .padding(.vertical, 12)
                        
                        // Botón Cerrar Sesión
                        Button(action: {
                            manager.signOut()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.square")
                                Text("Cerrar Sesión")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(32)
                    .frame(maxWidth: 580)
                    .background(ForkarTheme.card)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
                } else {
                    // ─── FORMULARIO DE INICIO DE SESIÓN ───
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ForkarTheme.accent)
                        
                        VStack(spacing: 4) {
                            Text("Iniciar Sesión en Forkar")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            Text("Ingresa con tu cuenta de Coki Studios para interactuar en el feed y CSMS.")
                                .font(.system(size: 12))
                                .foregroundColor(ForkarTheme.textSub)
                                .multilineTextAlignment(.center)
                        }
                        
                        if let err = authErrorMessage {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        VStack(spacing: 12) {
                            TextField("Correo electrónico", text: $emailInput)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(10)
                                .background(ForkarTheme.bgTertiary)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ForkarTheme.border, lineWidth: 1))
                            
                            SecureField("Contraseña", text: $passwordInput)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(10)
                                .background(ForkarTheme.bgTertiary)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ForkarTheme.border, lineWidth: 1))
                        }
                        
                        Button(action: handleSignIn) {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Entrar a Forkar PC")
                                        .font(.system(size: 13, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(ForkarTheme.brandGradient)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(emailInput.isEmpty || passwordInput.isEmpty || isSigningIn)
                        
                        // Modo Invitado Demo
                        Button(action: {
                            manager.currentUser = UserProfile(
                                id: "guest-pc-user",
                                email: "invitado@cokistudios.com",
                                fullName: "Invitado Forkar PC",
                                avatarUrl: nil,
                                bio: "Explorando la versión nativa de Forkar para macOS/PC",
                                followersCount: 5,
                                followingCount: 3
                            )
                            manager.isAuthenticated = true
                        }) {
                            Text("Continuar como Invitado")
                                .font(.system(size: 12))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(32)
                    .frame(maxWidth: 420)
                    .background(ForkarTheme.card)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .background(ForkarTheme.bg)
    }
    
    private func handleSignIn() {
        isSigningIn = true
        authErrorMessage = nil
        
        Task {
            do {
                try await manager.signIn(email: emailInput, password: passwordInput)
            } catch {
                authErrorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }
}
