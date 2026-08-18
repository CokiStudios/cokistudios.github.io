import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var categories: [Category] = []
    @State private var selectedCategoryId: UUID? = nil
    
    @State private var title = ""
    @State private var content = ""
    @State private var imageUrl = ""
    @State private var videoUrl = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isFetchingCategories = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ForkarTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12))
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Category selection label
                            Text("Selecciona una Categoría")
                                .font(.headline)
                                .foregroundColor(ForkarTheme.text)
                                .padding(.top)
                            
                            if isFetchingCategories {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(categories) { category in
                                            Button(action: {
                                                selectedCategoryId = category.id
                                            }) {
                                                HStack(spacing: 6) {
                                                    Circle()
                                                        .fill(category.themeColor)
                                                        .frame(width: 8, height: 8)
                                                        .overlay(Circle().stroke(Color.black, lineWidth: 1.0))
                                                    
                                                    Text(category.name)
                                                        .font(.system(size: 12, weight: .black))
                                                        .foregroundColor(selectedCategoryId == category.id ? .white : ForkarTheme.text)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(selectedCategoryId == category.id ? category.themeColor : ForkarTheme.card)
                                                .cornerRadius(6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.black, lineWidth: 2.0)
                                                )
                                                .shadow(color: .black, radius: 0, x: selectedCategoryId == category.id ? 1.5 : 2.5, y: selectedCategoryId == category.id ? 1.5 : 2.5)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                            
                            // Title input
                            Text("Título")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            
                            TextField("Escribe un título descriptivo...", text: $title)
                                .foregroundColor(ForkarTheme.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(ForkarTheme.card)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                            
                            // Content input
                            Text("Contenido")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            
                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text("Escribe aquí los detalles de tu publicación...")
                                        .font(.system(size: 14))
                                        .foregroundColor(ForkarTheme.textMuted)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $content)
                                    .foregroundColor(ForkarTheme.text)
                                    .padding(10)
                                    .frame(minHeight: 140)
                                    .scrollContentBackground(.hidden)
                                    .background(ForkarTheme.card)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                            }
                            
                            // Image URL input
                            Text("URL de Foto / Imagen (opcional)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            
                            TextField("https://ejemplo.com/imagen.jpg", text: $imageUrl)
                                .foregroundColor(ForkarTheme.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(ForkarTheme.card)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                            
                            // Video URL input
                            Text("URL de Video MP4 (opcional)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            
                            TextField("https://ejemplo.com/video.mp4", text: $videoUrl)
                                .foregroundColor(ForkarTheme.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(ForkarTheme.card)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ForkarTheme.border, lineWidth: 1))
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                    }
                    
                    // Publish Button
                    Button(action: {
                        Task {
                            await publishPost()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Publicar en la Comunidad")
                                    .font(.system(size: 15, weight: .black))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(ShineButtonStyle(backgroundColor: ForkarTheme.accent, borderLineWidth: 2.5, shadowOffset: 4.5))
                    .disabled(isLoading)
                    .padding()
                }
            }
            .navigationTitle("Crear Publicación")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(ForkarTheme.text)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(ForkarTheme.text)
                }
                #endif
            }
            .onAppear {
                Task {
                    await loadCategories()
                }
            }
        }
    }
    
    private func loadCategories() async {
        isFetchingCategories = true
        do {
            categories = try await authManager.fetchCategories()
            selectedCategoryId = categories.first?.id
        } catch {
            print("Error loading categories: \(error)")
        }
        isFetchingCategories = false
    }
    
    private func publishPost() async {
        guard let categoryId = selectedCategoryId else {
            errorMessage = "Selecciona una categoría"
            return
        }
        
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanTitle.isEmpty else {
            errorMessage = "Escribe un título"
            return
        }
        
        guard !cleanContent.isEmpty else {
            errorMessage = "Escribe algún contenido para tu publicación"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let cleanImage = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVideo = videoUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            _ = try await authManager.createPost(
                title: cleanTitle,
                content: cleanContent,
                categoryId: categoryId,
                imageUrl: cleanImage.isEmpty ? nil : cleanImage,
                videoUrl: cleanVideo.isEmpty ? nil : cleanVideo
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
