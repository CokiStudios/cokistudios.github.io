import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: SupabaseManager
    
    @State private var posts: [Post] = []
    @State private var categories: [Category] = []
    @State private var selectedCategory: Category? = nil
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var showCreatePost = false
    @State private var showLogin = false
    @State private var showSetupWizard = false
    
    var body: some View {
        MultiplatformNavigationStack {
            ZStack {
                ForkarTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: ForkarTheme.accent, opacity: 0.65, rainbow: true)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBarView(text: $searchQuery)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .onChange(of: searchQuery) {
                            Task {
                                await loadPosts()
                            }
                        }
                    
                    // Categories horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // "All" Category
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = nil
                                    Task { await loadPosts() }
                                }
                            }) {
                                Text("Todos")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .foregroundColor(selectedCategory == nil ? .white : ForkarTheme.text)
                                    .background(
                                        ZStack {
                                            if selectedCategory == nil {
                                                ForkarTheme.primaryGradient
                                            } else {
                                                ForkarTheme.card
                                            }
                                        }
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(selectedCategory == nil ? 0.6 : 0.2), Color.white.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: selectedCategory == nil ? ForkarTheme.accent.opacity(0.35) : Color.clear, radius: 8, y: 3)
                            }
                            
                            ForEach(categories) { category in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                        Task { await loadPosts() }
                                    }
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
                                    .foregroundColor(selectedCategory?.id == category.id ? .white : ForkarTheme.text)
                                    .background(
                                        ZStack {
                                            if selectedCategory?.id == category.id {
                                                category.themeColor
                                            } else {
                                                ForkarTheme.card
                                            }
                                        }
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(selectedCategory?.id == category.id ? 0.6 : 0.2), Color.white.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: selectedCategory?.id == category.id ? category.themeColor.opacity(0.35) : Color.clear, radius: 8, y: 3)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    
                    // Feed
                    if isLoading && posts.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                            .scaleEffect(1.2)
                        Spacer()
                    } else if posts.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up.slash")
                                .font(.system(size: 48))
                                .foregroundColor(ForkarTheme.textSub)
                            Text("No hay publicaciones")
                                .font(.headline)
                                .foregroundColor(ForkarTheme.text)
                            Text("Sé el primero en compartir algo en Forkar.")
                                .font(.subheadline)
                                .foregroundColor(ForkarTheme.textSub)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(posts) { post in
                                ZStack {
                                    PostCardView(post: post)
                                    
                                    NavigationLink(destination: PostDetailView(post: post)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onDelete(perform: deletePostAtIndex)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await loadData()
                        }
                    }
                }
                
                // Floating Action Button to create a post
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ShineColorButton(iconSystemName: "plus", iconColor: .white) {
                            if authManager.isLoggedIn {
                                showCreatePost = true
                            } else {
                                showLogin = true
                            }
                        }
                        .padding()
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("F")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(ForkarTheme.primaryGradient)
                            .cornerRadius(6)
                        
                        Text("Forkar")
                            .font(.headline)
                            .foregroundColor(ForkarTheme.text)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost, onDismiss: {
                Task { await loadPosts() }
            }) {
                CreatePostView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showLogin) {
                NavigationView {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .sheet(isPresented: $showSetupWizard) {
                SetupWizardView()
                    .environmentObject(authManager)
            }
            .onAppear {
                Task {
                    await loadData()
                }
            }
            .onChange(of: authManager.isLoggedIn) {
                Task {
                    await loadData()
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            categories = try await authManager.fetchCategories()
            posts = try await authManager.fetchPosts(categoryId: selectedCategory?.id, query: searchQuery)
            await MainActor.run {
                checkSetupWizard()
            }
        } catch {
            print("Error loading data: \(error)")
        }
        isLoading = false
    }
    
    private func checkSetupWizard() {
        if authManager.isLoggedIn {
            if let meta = authManager.currentUser?.user_metadata {
                let name = meta.full_name ?? ""
                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showSetupWizard = true
                }
            } else {
                showSetupWizard = true
            }
        }
    }
        private func loadPosts() async {
        do {
            var fetched = try await authManager.fetchPosts(categoryId: selectedCategory?.id, query: searchQuery)
            if let userTastes = authManager.currentUser?.user_metadata?.company?.components(separatedBy: ",") {
                fetched = authManager.rankPostsByTaste(posts: fetched, preferences: userTastes)
            }
            posts = fetched
        } catch {
            print("Error loading posts: \(error)")
        }
    }
    
    private func deletePostAtIndex(at offsets: IndexSet) {
        for index in offsets {
            let post = posts[index]
            if post.user_id == authManager.currentUser?.id {
                Task {
                    do {
                        try await authManager.deletePost(postId: post.id)
                        await loadPosts()
                    } catch {
                        print("Error deleting post: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Search Bar View Component
struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ForkarTheme.textSub)
            
            TextField("Buscar en Forkar...", text: $text)
                .foregroundColor(ForkarTheme.text)
                .font(.system(size: 14))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ForkarTheme.textSub)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ForkarTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Post Row View with Liquid Glass Aesthetic
struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Author Info + Category Tag
            HStack {
                // Author Avatar/Initials
                if let avatarURL = post.author_avatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        CircleAvatarPlaceholder(initials: post.initials)
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                } else {
                    CircleAvatarPlaceholder(initials: post.initials)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author_name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ForkarTheme.text)
                    Text(post.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(ForkarTheme.textSub)
                }
                
                Spacer()
                
                // Category Tag
                if let cat = post.category {
                    Text(cat.name)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(cat.themeColor.opacity(0.15))
                        .foregroundColor(cat.themeColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(cat.themeColor.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            // Title & Content Preview
            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .lineLimit(2)
                
                Text(post.content)
                    .font(.system(size: 13))
                    .foregroundColor(ForkarTheme.textSub)
                    .lineLimit(3)
            }
            
            // Media preview indicator if present
            if post.image_url != nil || post.video_url != nil {
                HStack(spacing: 6) {
                    Image(systemName: post.video_url != nil ? "video.fill" : "photo.fill")
                        .font(.system(size: 11))
                    Text(post.video_url != nil ? "Video adjunto" : "Foto adjunta")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(ForkarTheme.accent)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(ForkarTheme.accent.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
                .background(ForkarTheme.border)
                .padding(.top, 2)
            
            // Footer: Stats (Likes, Comments)
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "heart")
                    Text("\(post.likes_count)")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ForkarTheme.textSub)
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                    Text("\(post.comments_count)")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ForkarTheme.textSub)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            ZStack {
                if #available(iOS 15.0, macOS 12.0, *) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ForkarTheme.card)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

struct CircleAvatarPlaceholder: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(ForkarTheme.accent)
            .frame(width: 34, height: 34)
            .background(ForkarTheme.accent.opacity(0.15))
            .clipShape(Circle())
            .overlay(Circle().stroke(ForkarTheme.accent.opacity(0.3), lineWidth: 1))
    }
}
