import SwiftUI

// ══════════════════════════════════════════════════════════════════
// ✍️ CREATE POST SHEET — FORKAR FOR PC (macOS)
// Modal moderno para redactar nuevas publicaciones con categorías
// ══════════════════════════════════════════════════════════════════

struct CreatePostSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategoryId: String = "cat-general"
    @State private var imageUrl: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(ForkarTheme.accent)
                    Text("Nueva Publicación")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                }
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ForkarTheme.textSub)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ForkarTheme.bgSecondary)
            
            Divider().background(ForkarTheme.border)
            
            // Contenido del Formulario
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let err = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(err)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Categoría
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categoría")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        Picker("Categoría", selection: $selectedCategoryId) {
                            ForEach(manager.categories.filter { $0.id != "all" }, id: \.id) { cat in
                                Text(cat.name).tag(cat.id)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Título
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Título")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        TextField("Ej: Novedades sobre la próxima ruta eco o proyecto...", text: $title)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ForkarTheme.border, lineWidth: 1)
                            )
                    }
                    
                    // Cuerpo de la publicación
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Contenido")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        TextEditor(text: $content)
                            .font(.system(size: 13))
                            .padding(8)
                            .frame(minHeight: 140)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ForkarTheme.border, lineWidth: 1)
                            )
                    }
                    
                    // URL de Imagen opcional
                    VStack(alignment: .leading, spacing: 6) {
                        Text("URL de Imagen (Opcional)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        TextField("https://ejemplo.com/foto.jpg", text: $imageUrl)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ForkarTheme.border, lineWidth: 1)
                            )
                    }
                }
                .padding(24)
            }
            
            Divider().background(ForkarTheme.border)
            
            // Footer: Cancelar y Publicar
            HStack {
                Button("Cancelar") {
                    isPresented = false
                }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 12))
                .foregroundColor(ForkarTheme.textSub)
                
                Spacer()
                
                Button(action: submitPost) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Publicar Ahora")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(ForkarTheme.brandGradient)
                .cornerRadius(8)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ForkarTheme.bgSecondary)
        }
        .frame(minWidth: 500, minHeight: 480)
        .background(ForkarTheme.bg)
    }
    
    private func submitPost() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await manager.createPost(
                    title: title.trimmingCharacters(in: .whitespaces),
                    content: content.trimmingCharacters(in: .whitespaces),
                    categoryId: selectedCategoryId,
                    imageUrl: imageUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : imageUrl
                )
                isPresented = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
