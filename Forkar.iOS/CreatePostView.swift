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
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(ForkarTheme.text)
                            
                            TextField("Escribe un título descriptivo...", text: $title)
                                .foregroundColor(ForkarTheme.text)
                                .padding(.horizontal, 4)
                                .shineInlineCard(borderLineWidth: 2.0, shadowOffset: 0.0, backgroundColor: ForkarTheme.card)
                            
                            // Content input
                            Text("Contenido")
                                .font(.system(size: 16, weight: .black))
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
                                    .padding(8)
                                    .frame(minHeight: 180)
                                    .scrollContentBackground(.hidden) // Required to make background color work on iOS 16+
                                    .shineInlineCard(borderLineWidth: 2.0, shadowOffset: 0.0, backgroundColor: ForkarTheme.card)
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
        
        do {
            _ = try await authManager.createPost(title: cleanTitle, content: cleanContent, categoryId: categoryId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
