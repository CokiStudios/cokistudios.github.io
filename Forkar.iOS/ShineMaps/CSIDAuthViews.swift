import SwiftUI

public struct CSIDAuthSheet: View {
    @ObservedObject var csidManager = CSIDManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isLoginMode = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    public var body: some View {
        ZStack {
            ShineMapsTheme.bgDark
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack(spacing: 14) {
                    Text("CS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                        .frame(width: 44, height: 44)
                        .background(ShineMapsTheme.cardGlass)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(ShineMapsTheme.borderSubtle, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coki Studios ID")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ShineMapsTheme.textPrimary)
                        Text("Cuenta universal Shine Maps")
                            .font(.system(size: 12))
                            .foregroundColor(ShineMapsTheme.textSub)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ShineMapsTheme.textSub)
                    }
                }
                .padding(.top, 10)

                // Mode Tabs
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLoginMode = true
                            errorMessage = nil
                        }
                    } label: {
                        Text("Iniciar Sesión")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isLoginMode ? ShineMapsTheme.cyanPrimary : ShineMapsTheme.textSub)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(isLoginMode ? ShineMapsTheme.cardGlass : Color.clear)
                            .cornerRadius(12)
                            .overlay(
                                isLoginMode ? RoundedRectangle(cornerRadius: 12).stroke(ShineMapsTheme.cyanPrimary.opacity(0.3), lineWidth: 1) : nil
                            )
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLoginMode = false
                            errorMessage = nil
                        }
                    } label: {
                        Text("Crear CS ID")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(!isLoginMode ? ShineMapsTheme.cyanPrimary : ShineMapsTheme.textSub)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(!isLoginMode ? ShineMapsTheme.cardGlass : Color.clear)
                            .cornerRadius(12)
                            .overlay(
                                !isLoginMode ? RoundedRectangle(cornerRadius: 12).stroke(ShineMapsTheme.cyanPrimary.opacity(0.3), lineWidth: 1) : nil
                            )
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.4))
                .cornerRadius(16)

                // Input Fields
                VStack(spacing: 12) {
                    if !isLoginMode {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundColor(ShineMapsTheme.cyanPrimary)
                                .frame(width: 20)
                            TextField("Nombre completo", text: $name)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                                .foregroundColor(ShineMapsTheme.textPrimary)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(ShineMapsTheme.cardGlass)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShineMapsTheme.borderSubtle, lineWidth: 1))
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                            .frame(width: 20)
                        TextField("Correo electrónico", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(ShineMapsTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(ShineMapsTheme.cardGlass)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShineMapsTheme.borderSubtle, lineWidth: 1))

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(ShineMapsTheme.cyanPrimary)
                            .frame(width: 20)
                        SecureField("Contraseña", text: $password)
                            .textContentType(isLoginMode ? .password : .newPassword)
                            .foregroundColor(ShineMapsTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(ShineMapsTheme.cardGlass)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShineMapsTheme.borderSubtle, lineWidth: 1))
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(ShineMapsTheme.roseAccent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Submit Button
                Button {
                    submitAuth()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(ShineMapsTheme.bgDark)
                        } else {
                            Text(isLoginMode ? "Acceder con CS ID" : "Crear Cuenta CS ID")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(ShineMapsTheme.bgDark)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ShineMapsTheme.cyanPrimary)
                    .cornerRadius(14)
                    .shadow(color: ShineMapsTheme.cyanPrimary.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .disabled(isLoading)

                Spacer()
            }
            .padding(24)
        }
    }

    private func submitAuth() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanEmail.contains("@") else {
            errorMessage = "Ingresa un correo electrónico válido"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            return
        }
        if !isLoginMode && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Ingresa tu nombre completo"
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isLoginMode {
                    _ = try await csidManager.login(email: cleanEmail, pass: password)
                } else {
                    _ = try await csidManager.signUp(email: cleanEmail, pass: password, name: name)
                }
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

public struct CSIDProfileSheet: View {
    @ObservedObject var csidManager = CSIDManager.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        ZStack {
            ShineMapsTheme.bgDark
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // User Avatar Circle
                Text(csidManager.currentUser?.initial ?? "CS")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(ShineMapsTheme.cyanPrimary)
                    .frame(width: 80, height: 80)
                    .background(ShineMapsTheme.cardGlass)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ShineMapsTheme.cyanPrimary.opacity(0.4), lineWidth: 2))
                    .shadow(color: ShineMapsTheme.cyanPrimary.opacity(0.2), radius: 14, x: 0, y: 6)
                    .padding(.top, 20)

                VStack(spacing: 4) {
                    Text(csidManager.currentUser?.name ?? "Usuario Coki")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ShineMapsTheme.textPrimary)

                    Text(csidManager.currentUser?.email ?? "user@cokistudios.com")
                        .font(.system(size: 14))
                        .foregroundColor(ShineMapsTheme.textSub)
                }

                // Verified Badge
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                    Text("Sesión activa CS ID")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShineMapsTheme.cyanPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(ShineMapsTheme.cardGlass)
                .cornerRadius(20)

                Divider()
                    .background(ShineMapsTheme.borderSubtle)

                // Logout Button
                Button {
                    csidManager.logout()
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Cerrar sesión CS ID")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(ShineMapsTheme.roseAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(ShineMapsTheme.cardGlass)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShineMapsTheme.roseAccent.opacity(0.3), lineWidth: 1))
                }

                // Close Button
                Button {
                    dismiss()
                } label: {
                    Text("Cerrar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ShineMapsTheme.textSub)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }

                Spacer()
            }
            .padding(24)
        }
    }
}
