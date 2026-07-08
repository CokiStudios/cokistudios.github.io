import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var categories: [Category] = []
    @State private var selectedCategoryId: UUID? = nil
    
    @State private var title = ""
    @State private var content = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isFetchingCategories = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ForkarTheme.bg
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
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(categories) { category in
                                            Button(action: {
                                                selectedCategoryId = category.id
                                            }) {
                                                HStack(spacing: 6) {
                                                    Circle()
                                                        .fill(category.themeColor)
                                                        .frame(width: 8, height: 8)
                                                    
                                                    Text(category.name)
                                                        .font(.system(size: 13, weight: .bold))
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(selectedCategoryId == category.id ? category.themeColor : ForkarTheme.card)
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedCategoryId == category.id ? Color.clear : ForkarTheme.border, lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Title input
                            Text("Título")
                                .font(.headline)
                                .foregroundColor(ForkarTheme.text)
                            
                            TextField("Escribe un título descriptivo...", text: $title)
                                .foregroundColor(ForkarTheme.text)
                                .padding()
                                .background(ForkarTheme.card)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ForkarTheme.border, lineWidth: 1)
                                )
                            
                            // Content input
                            Text("Contenido")
                                .font(.headline)
                                .foregroundColor(ForkarTheme.text)
                            
                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text("Escribe aquí los detalles de tu publicación...")
                                        .foregroundColor(ForkarTheme.textMuted)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 18)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $content)
                                    .foregroundColor(ForkarTheme.text)
                                    .padding(10)
                                    .frame(minHeight: 180)
                                    .scrollContentBackground(.hidden) // Required to make background color work on iOS 16+
                                    .background(ForkarTheme.card)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ForkarTheme.border, lineWidth: 1)
                                    )
                            }
                            
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
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading)
                    .padding()
                }
            }
            .navigationTitle("Crear Publicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(ForkarTheme.text)
                }
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
        
        do {
            _ = try await authManager.createPost(title: cleanTitle, content: cleanContent, categoryId: categoryId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
