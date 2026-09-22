import SwiftUI
import AppKit

// ══════════════════════════════════════════════════════════════════
// ✍️ CREATE POST SHEET — FORKAR FOR PC (macOS)
// Modal con categorías reales desde Supabase social_categories
// Soporte completo para adjuntar fotos y videos desde la Mac
// ══════════════════════════════════════════════════════════════════

struct CreatePostSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategoryId: String = ""
    @State private var imageUrl: String = ""
    @State private var videoUrl: String = ""
    
    // Adjuntos multimedia locales
    @State private var attachedFileURL: URL? = nil
    @State private var attachedFileName: String = ""
    @State private var isUploadingMedia: Bool = false
    @State private var uploadedMediaURL: String? = nil
    @State private var uploadedMediaType: String? = nil
    
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
                    
                    // Categoría real desde Supabase
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categoría")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        Picker("Categoría", selection: $selectedCategoryId) {
                            ForEach(manager.categories.filter { $0.slug != "all" }, id: \.id) { cat in
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
                            .frame(minHeight: 120)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ForkarTheme.border, lineWidth: 1)
                            )
                    }
                    
                    // ─── SECCIÓN FOTOS Y VIDEOS (SUBIDA NATIVA A SUPABASE) ───
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Multimedia (Fotos o Videos)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        HStack(spacing: 12) {
                            Button(action: selectMediaFile) {
                                HStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                    Text(uploadedMediaURL != nil ? "Cambiar Archivo" : "Subir Foto o Video de Mac")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(ForkarTheme.cardHover)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ForkarTheme.accent.opacity(0.6), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isUploadingMedia)
                            
                            if isUploadingMedia {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                    .scaleEffect(0.8)
                                Text("Subiendo a Supabase...")
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.accent)
                            }
                            
                            Spacer()
                        }
                        
                        // Vista previa de archivo adjunto
                        if uploadedMediaURL != nil {
                            HStack(spacing: 10) {
                                Image(systemName: uploadedMediaType == "video" ? "video.fill" : "photo.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(ForkarTheme.accent)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(attachedFileName.isEmpty ? "Archivo adjunto listo" : attachedFileName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ForkarTheme.text)
                                        .lineLimit(1)
                                    
                                    Text(uploadedMediaType == "video" ? "Video listo para publicar" : "Foto lista para publicar")
                                        .font(.system(size: 10))
                                        .foregroundColor(ForkarTheme.greenEco)
                                }
                                
                                Spacer()
                                
                                Button(action: clearMedia) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Quitar archivo")
                            }
                            .padding(10)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                        }
                        
                        // Campos de URL directa opcionales
                        DisclosureGroup("O ingresar URLs directas manualmente") {
                            VStack(spacing: 8) {
                                TextField("URL de Imagen (https://...)", text: $imageUrl)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 12))
                                    .padding(8)
                                    .background(ForkarTheme.card)
                                    .cornerRadius(6)
                                
                                TextField("URL de Video (https://...mp4)", text: $videoUrl)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 12))
                                    .padding(8)
                                    .background(ForkarTheme.card)
                                    .cornerRadius(6)
                            }
                            .padding(.top, 4)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(ForkarTheme.textSub)
                    }
                }
                .padding(24)
            }
            .onAppear {
                if selectedCategoryId.isEmpty, let first = manager.categories.first(where: { $0.slug != "all" }) {
                    selectedCategoryId = first.id
                }
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
                        Text("Publicar en Supabase")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(ForkarTheme.brandGradient)
                .cornerRadius(8)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting || isUploadingMedia)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ForkarTheme.bgSecondary)
        }
        .frame(minWidth: 520, minHeight: 520)
        .background(ForkarTheme.bg)
    }
    
    private func selectMediaFile() {
        let panel = NSOpenPanel()
        panel.title = "Selecciona una Foto o Video para tu Publicación"
        panel.prompt = "Subir"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowedFileTypes = ["jpg", "jpeg", "png", "webp", "gif", "heic", "mp4", "mov", "webm", "m4v"]
        
        if panel.runModal() == .OK, let selected = panel.url {
            self.attachedFileURL = selected
            self.attachedFileName = selected.lastPathComponent
            self.isUploadingMedia = true
            self.errorMessage = nil
            
            Task {
                do {
                    let (url, type) = try await manager.uploadMedia(fileURL: selected)
                    await MainActor.run {
                        self.uploadedMediaURL = url
                        self.uploadedMediaType = type
                        if type == "video" {
                            self.videoUrl = url
                        } else {
                            self.imageUrl = url
                        }
                        self.isUploadingMedia = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Error subiendo archivo: \(error.localizedDescription)"
                        self.isUploadingMedia = false
                    }
                }
            }
        }
    }
    
    private func clearMedia() {
        attachedFileURL = nil
        attachedFileName = ""
        uploadedMediaURL = nil
        uploadedMediaType = nil
        imageUrl = ""
        videoUrl = ""
    }
    
    private func submitPost() {
        isSubmitting = true
        errorMessage = nil
        
        let catId = selectedCategoryId.isEmpty ? (manager.categories.first(where: { $0.slug != "all" })?.id ?? "494f6ad4-8425-440b-a4de-103b0cdf6c41") : selectedCategoryId
        
        let finalImage = !imageUrl.trimmingCharacters(in: .whitespaces).isEmpty ? imageUrl : (uploadedMediaType == "image" ? uploadedMediaURL : nil)
        let finalVideo = !videoUrl.trimmingCharacters(in: .whitespaces).isEmpty ? videoUrl : (uploadedMediaType == "video" ? uploadedMediaURL : nil)
        
        Task {
            do {
                try await manager.createPost(
                    title: title.trimmingCharacters(in: .whitespaces),
                    content: content.trimmingCharacters(in: .whitespaces),
                    categoryId: catId,
                    imageUrl: finalImage,
                    videoUrl: finalVideo
                )
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}
