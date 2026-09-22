import SwiftUI
import AVKit

// ══════════════════════════════════════════════════════════════════
// 📱 HOME FEED VIEW — FORKAR FOR PC (macOS)
// Muro dinámico sincronizado en tiempo real con Supabase social_posts
// ══════════════════════════════════════════════════════════════════

struct HomeFeedView: View {
    @EnvironmentObject var manager: SupabaseManager
    @Binding var selectedTab: NavigationTab
    
    @State private var selectedCategoryId: String = "all"
    @State private var searchQuery: String = ""
    @State private var showingCreatePost: Bool = false
    @State private var selectedPostForDetail: Post?
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── TOP BAR DEL FEED ───
            HStack(spacing: 16) {
                // Buscador en tiempo real
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ForkarTheme.textSub)
                    TextField("Buscar en el muro (título, contenido)...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .onSubmit {
                            Task {
                                await manager.fetchPosts(
                                    categoryId: selectedCategoryId == "all" ? nil : selectedCategoryId,
                                    searchQuery: searchQuery
                                )
                            }
                        }
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
                        await manager.fetchPosts(
                            categoryId: selectedCategoryId == "all" ? nil : selectedCategoryId,
                            searchQuery: searchQuery.isEmpty ? nil : searchQuery
                        )
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
            
            // ─── BARRA DE CATEGORÍAS REALES (social_categories) ───
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Botón "Todos"
                    Button(action: {
                        selectedCategoryId = "all"
                        Task { await manager.fetchPosts(categoryId: nil, searchQuery: searchQuery.isEmpty ? nil : searchQuery) }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 11))
                            Text("Todos")
                                .font(.system(size: 12, weight: selectedCategoryId == "all" ? .bold : .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(selectedCategoryId == "all" ? ForkarTheme.accent : ForkarTheme.card)
                        .foregroundColor(selectedCategoryId == "all" ? .white : ForkarTheme.textSub)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedCategoryId == "all" ? ForkarTheme.borderHighlight : ForkarTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ForEach(manager.categories, id: \.id) { cat in
                        if cat.slug != "all" {
                            Button(action: {
                                selectedCategoryId = cat.id
                                Task {
                                    await manager.fetchPosts(categoryId: cat.id, searchQuery: searchQuery.isEmpty ? nil : searchQuery)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: cat.color))
                                        .frame(width: 8, height: 8)
                                    Text(cat.name)
                                        .font(.system(size: 12, weight: selectedCategoryId == cat.id ? .bold : .medium))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(selectedCategoryId == cat.id ? Color(hex: cat.color).opacity(0.3) : ForkarTheme.card)
                                .foregroundColor(selectedCategoryId == cat.id ? .white : ForkarTheme.textSub)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedCategoryId == cat.id ? Color(hex: cat.color) : ForkarTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }
            .background(ForkarTheme.bgTertiary.opacity(0.6))
            
            Divider().background(ForkarTheme.border)
            
            // ─── LISTADO DE PUBLICACIONES REALES ───
            ScrollView {
                LazyVStack(spacing: 16) {
                    if manager.isLoadingPosts && manager.posts.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                .scaleEffect(1.2)
                            Text("Sincronizando muro con Supabase...")
                                .font(.system(size: 13))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if manager.posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ForkarTheme.textSub.opacity(0.4))
                            Text("No se encontraron publicaciones")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                            Text("Sé el primero en compartir noticias o proyectos con la comunidad.")
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
                        ForEach(manager.posts) { post in
                            PostCardView(
                                post: post,
                                onOpenChat: {
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

// ─── TARJETA DE PUBLICACIÓN REAL ───
struct PostCardView: View {
    let post: Post
    let onOpenChat: () -> Void
    let onSelect: () -> Void
    
    @EnvironmentObject var manager: SupabaseManager
    @State private var isHovered: Bool = false
    @State private var likesCount: Int = 0
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Autor, fecha y categoría real
            HStack(spacing: 10) {
                // Avatar con fallback
                if let avatar = post.authorAvatar, let url = URL(string: avatar) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        default:
                            authorInitialsBadge
                        }
                    }
                } else {
                    authorInitialsBadge
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ForkarTheme.text)
                    Text(post.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(ForkarTheme.textSub)
                }
                
                Spacer()
                
                if let cat = post.category {
                    Text(cat.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: cat.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: cat.color).opacity(0.15))
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
            
            // Multimedia: Foto o Video nativo
            if let videoStr = post.videoUrl, let vUrl = URL(string: videoStr), !videoStr.isEmpty {
                PostVideoThumbnailView(url: vUrl)
            } else if let img = post.imageUrl, let url = URL(string: img), !img.isEmpty {
                let lower = img.lowercased()
                let isVid = lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".webm") || lower.hasSuffix(".m4v")
                if isVid {
                    PostVideoThumbnailView(url: url)
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 280)
                                .clipped()
                                .cornerRadius(10)
                                .onTapGesture {
                                    onSelect()
                                }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            
            Divider().background(ForkarTheme.border)
            
            // ─── ACCIONES CONECTADAS A SUPABASE ───
            HStack(spacing: 16) {
                // Like interactivo
                Button(action: {
                    isLiked.toggle()
                    likesCount += isLiked ? 1 : -1
                    Task {
                        await manager.toggleLike(postId: post.id)
                    }
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
                
                // 🔥 BOTÓN EXTENSIÓN CSMS: Conectar directamente
                Button(action: onOpenChat) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 11))
                        Text("💬 Debatir en CSMS")
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
                .help("Abrir chat para debatir este tema")
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
            isLiked = manager.userLikedPostIds.contains(post.id)
        }
    }
    
    private var authorInitialsBadge: some View {
        Circle()
            .fill(ForkarTheme.accent.opacity(0.3))
            .frame(width: 36, height: 36)
            .overlay(
                Text(String(post.authorName.prefix(2)).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ForkarTheme.accent)
            )
    }
}

// ─── REPRODUCTOR DE VIDEO PARA EL MURO ───
struct PostVideoThumbnailView: View {
    let url: URL
    @State private var isPlaying: Bool = false
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = player, isPlaying {
                VideoPlayer(player: player)
                    .frame(height: 260)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Button(action: {
                                let p = AVPlayer(url: url)
                                self.player = p
                                self.isPlaying = true
                                p.play()
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 46))
                                    .foregroundColor(ForkarTheme.accent)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("Reproducir Video")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

