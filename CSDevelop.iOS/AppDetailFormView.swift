import SwiftUI

struct AppDetailFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    // If editing, this is passed in
    var appToEdit: DeveloperApp? = nil
    
    @State private var name = ""
    @State private var website = ""
    @State private var urisRaw = ""
    @State private var logoUrl = ""
    
    @State private var loading = false
    @State private var errorMessage: String? = nil
    
    var isEditing: Bool {
        appToEdit != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CSDevelopTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: CSDevelopTheme.accent.opacity(0.12))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                        
                        // Main Fields Group
                        VStack(spacing: 20) {
                            // Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NOMBRE DE LA APLICACIÓN *")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(CSDevelopTheme.textMuted)
                                TextField("Mi Aplicación Increíble", text: $name)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                    .foregroundColor(CSDevelopTheme.text)
                            }
                            
                            // Website
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SITIO WEB")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(CSDevelopTheme.textMuted)
                                TextField("https://miapp.com", text: $website)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                    .foregroundColor(CSDevelopTheme.text)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                            }
                            
                            // Redirect URIs
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("URLS DE REDIRECCIÓN (REDIRECT URIS) *")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(CSDevelopTheme.textMuted)
                                    Spacer()
                                }
                                TextEditor(text: $urisRaw)
                                    .font(.system(size: 13, design: .monospaced))
                                    .padding(8)
                                    .frame(height: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                    .foregroundColor(CSDevelopTheme.text)
                                
                                Text("Una URL por línea. Deben ser exactas, por ejemplo:\nhttp://localhost:3000/callback o https://miapp.com/callback")
                                    .font(.system(size: 11))
                                    .foregroundColor(CSDevelopTheme.textMuted)
                                    .lineSpacing(2)
                            }
                            
                            // Logo URL
                            VStack(alignment: .leading, spacing: 6) {
                                Text("URL DEL LOGO (OPCIONAL)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(CSDevelopTheme.textMuted)
                                TextField("https://miapp.com/logo.png", text: $logoUrl)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CSDevelopTheme.border, lineWidth: 1))
                                    .foregroundColor(CSDevelopTheme.text)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                            }
                        }
                        .padding(20)
                        .background(CSDevelopTheme.card)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(CSDevelopTheme.border, lineWidth: 1)
                        )
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: saveApp) {
                                HStack {
                                    Spacer()
                                    if loading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(isEditing ? "Guardar cambios" : "Crear aplicación")
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(CSPrimaryButton())
                            .disabled(loading)
                            
                            Button("Cancelar") {
                                dismiss()
                            }
                            .buttonStyle(CSSecondaryButton())
                            .disabled(loading)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(isEditing ? "Editar App" : "Nueva App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(CSDevelopTheme.accent)
                }
            }
            .onAppear {
                if let app = appToEdit {
                    name = app.client_name
                    website = app.website_url ?? ""
                    urisRaw = app.redirect_uris.joined(separator: "\n")
                    logoUrl = app.logo_url ?? ""
                }
            }
        }
    }
    
    private func saveApp() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre de la aplicación es obligatorio."
            return
        }
        
        let redirectUris = urisRaw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !redirectUris.isEmpty else {
            errorMessage = "Añade al menos una URL de redirección válida."
            return
        }
        
        loading = true
        errorMessage = nil
        
        let webParam = website.trimmingCharacters(in: .whitespacesAndNewlines)
        let logoParam = logoUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                if let app = appToEdit {
                    try await SupabaseManager.shared.updateApp(
                        clientId: app.client_id,
                        name: trimmedName,
                        website: webParam.isEmpty ? nil : webParam,
                        redirectUris: redirectUris,
                        logoUrl: logoParam.isEmpty ? nil : logoParam
                    )
                } else {
                    try await SupabaseManager.shared.createApp(
                        name: trimmedName,
                        website: webParam.isEmpty ? nil : webParam,
                        redirectUris: redirectUris,
                        logoUrl: logoParam.isEmpty ? nil : logoParam
                    )
                }
                
                await MainActor.run {
                    dismiss()
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
    AppDetailFormView()
}
