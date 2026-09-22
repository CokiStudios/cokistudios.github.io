import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 📱 HOME FEED VIEW — FORKAR FOR PC (macOS)
// Muro de publicaciones con estética Liquid Glass e integración CSMS
// ══════════════════════════════════════════════════════════════════

struct HomeFeedView: View {
    @EnvironmentObject var manager: SupabaseManager
    @Binding var selectedTab: NavigationTab
    
    @State private var selectedCategory: String = "all"
    @State private var searchQuery: String = ""
    @State private var showingCreatePost: Bool = false
    @State private var selectedPostForDetail: Post?
    
    var filteredPosts: [Post] {
        manager.posts.filter { post in
            let matchesCategory = (selectedCategory == "all" || post.categoryId == selectedCategory)
            let matchesSearch = searchQuery.isEmpty || 
                post.title.localizedCaseInsensitiveContains(searchQuery) ||
                post.content.localizedCaseInsensitiveContains(searchQuery) ||
                (post.authorName?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── TOP BAR DEL FEED ───
            HStack(spacing: 16) {
                // Buscador
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ForkarTheme.textSub)
                    TextField("Buscar publicaciones, tags o usuarios...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ForkarTheme.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ForkarTheme.border, lineWidth: 1)
                )
                .frame(maxWidth: 380)
                
                Spacer()
                
                // Botón de Refrescar
                Button(action: {
                    Task {
                        await manager.fetchPosts(categorySlug: selectedCategory)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ForkarTheme.text)
                        .frame(width: 32, height: 32)
                        .background(ForkarTheme.card)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Actualizar muro")
                
                // Botón Crear Publicación
                Button(action: {
                    showingCreatePost = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Crear Post")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ForkarTheme.brandGradient)
                    .cornerRadius(8)
                    .shadow(color: ForkarTheme.accent.opacity(0.3), radius: 8, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(ForkarTheme.bgSecondary)
            
            Divider().background(ForkarTheme.border)
            
            // ─── BARRA DE CATEGORÍAS (PILLS) ───
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(manager.categories, id: \.id) { cat in
                        CategoryPill(
                            category: cat,
                            isSelected: selectedCategory == cat.id || (selectedCategory == "all" && cat.id == "all"),
                            action: {
                                selectedCategory = cat.id
                                Task {
                                    await manager.fetchPosts(categorySlug: cat.id == "all" ? nil : cat.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }
            .background(ForkarTheme.bgTertiary.opacity(0.6))
            
            Divider().background(ForkarTheme.border)
            
            // ─── LISTADO DE PUBLICACIONES ───
            ScrollView {
                LazyVStack(spacing: 16) {
                    if manager.isLoadingPosts && manager.posts.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                .scaleEffect(1.2)
                            Text("Cargando muro de Forkar...")
                                .font(.system(size: 13))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if filteredPosts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ForkarTheme.textSub.opacity(0.4))
                            Text("No hay publicaciones en esta categoría")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                            Text("Sé el primero en publicar una historia o compartir con la comunidad.")
                                .font(.system(size: 12))
                                .foregroundColor(ForkarTheme.textSub)
                            Button("Crear Publicación") {
                                showingCreatePost = true
                            }
                            .buttonStyle(PlainButtonStyle())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ForkarTheme.accent)
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 320)
                    } else {
                        ForEach(filteredPosts) { post in
                            PostCardView(
                                post: post,
                                onOpenChat: {
                                    // Seleccionar canal o cambiar a pestaña CSMS
                                    selectedTab = .csms
                                },
                                onSelect: {
                                    selectedPostForDetail = post
                                }
                            )
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 820)
            }
            .frame(maxWidth: .infinity)
        }
        .background(ForkarTheme.bg)
        .onAppear {
            Task {
                if manager.posts.isEmpty {
                    await manager.fetchPosts()
                }
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostSheet(isPresented: $showingCreatePost)
                .environmentObject(manager)
        }
        .sheet(item: $selectedPostForDetail) { post in
            PostDetailSheet(post: post, onOpenCSMS: {
                selectedPostForDetail = nil
                selectedTab = .csms
            })
            .environmentObject(manager)
        }
    }
}

// ─── PÍLDORA DE CATEGORÍA ───
struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 11))
                Text(category.name)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? ForkarTheme.accent : ForkarTheme.card)
            .foregroundColor(isSelected ? .white : ForkarTheme.textSub)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? ForkarTheme.borderHighlight : ForkarTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ─── TARJETA DE PUBLICACIÓN (GLASSMORPHIC POST CARD) ───
struct PostCardView: View {
    let post: Post
    let onOpenChat: () -> Void
    let onSelect: () -> Void
    
    @State private var isLiked: Bool = false
    @State private var likesCount: Int = 0
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Autor, fecha y categoría
            HStack(spacing: 10) {
                Circle()
                    .fill(ForkarTheme.accent.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(authorInitials)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ForkarTheme.accent)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName ?? "Usuario de Forkar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ForkarTheme.text)
                    Text(formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(ForkarTheme.textSub)
                }
                
                Spacer()
                
                if let catId = post.categoryId {
                    Text(catId.replacingOccurrences(of: "cat-", with: "").capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ForkarTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ForkarTheme.accent.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            
            // Título y Contenido
            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .lineLimit(2)
                
                Text(post.content)
                    .font(.system(size: 13))
                    .foregroundColor(ForkarTheme.textSub)
                    .lineLimit(4)
                    .lineSpacing(3)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            // Imagen si existe
            if let img = post.imageUrl, let url = URL(string: img), !img.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 280)
                            .clipped()
                            .cornerRadius(10)
                    default:
                        EmptyView()
                    }
                }
            }
            
            Divider().background(ForkarTheme.border)
            
            // ─── BARRA DE ACCIONES CON EXTENSIÓN CSMS ───
            HStack(spacing: 16) {
                // Like
                Button(action: {
                    isLiked.toggle()
                    likesCount += isLiked ? 1 : -1
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : ForkarTheme.textSub)
                        Text("\(likesCount)")
                            .font(.system(size: 12))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Comentarios
                Button(action: onSelect) {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(ForkarTheme.textSub)
                        Text("\(post.commentsCount)")
                            .font(.system(size: 12))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 🔥 BOTÓN EXTENSIÓN CSMS: Conectar directamente por chat
                Button(action: onOpenChat) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 11))
                        Text("💬 Abrir en CSMS")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(ForkarTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ForkarTheme.accent.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ForkarTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Conectar y chatear sobre este tema en CSMS")
            }
            .font(.system(size: 12))
        }
        .padding(18)
        .background(isHovered ? ForkarTheme.cardHover : ForkarTheme.card)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isHovered ? ForkarTheme.borderHighlight : ForkarTheme.border, lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hover
            }
        }
        .onAppear {
            likesCount = post.likesCount
        }
    }
    
    private var authorInitials: String {
        let name = post.authorName ?? "U"
        return String(name.prefix(2)).uppercased()
    }
    
    private var formattedDate: String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = df.date(from: post.createdAt) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .short
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return "reciente"
    }
}
