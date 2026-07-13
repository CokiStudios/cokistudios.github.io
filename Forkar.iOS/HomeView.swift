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
    
    var body: some View {
        NavigationView {
            ZStack {
                ForkarTheme.bg
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
                                withAnimation {
                                    selectedCategory = nil
                                    Task { await loadPosts() }
                                }
                            }) {
                                Text("Todos")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedCategory == nil ? ForkarTheme.accent : ForkarTheme.card)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedCategory == nil ? Color.clear : ForkarTheme.border, lineWidth: 1)
                                    )
                            }
                            
                            ForEach(categories) { category in
                                Button(action: {
                                    withAnimation {
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
                                    .background(selectedCategory?.id == category.id ? category.themeColor : ForkarTheme.card)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedCategory?.id == category.id ? Color.clear : ForkarTheme.border, lineWidth: 1)
                                    )
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
                        Button(action: {
                            if authManager.isLoggedIn {
                                showCreatePost = true
                            } else {
                                showLogin = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(ForkarTheme.primaryGradient)
                                .cornerRadius(28)
                                .shadow(color: ForkarTheme.accent.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
        } catch {
            print("Error loading data: \(error)")
        }
        isLoading = false
    }
    
    private func loadPosts() async {
        do {
            posts = try await authManager.fetchPosts(categoryId: selectedCategory?.id, query: searchQuery)
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
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ForkarTheme.textSub)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(ForkarTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ForkarTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Author & Category
            HStack {
                // Author Avatar/Initials
                if let avatarURL = post.author_avatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        CircleAvatarPlaceholder(initials: post.initials)
                    }
                    .frame(width: 32, height: 32)
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
                        .font(.system(size: 10, weight: .bold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(cat.themeColor.opacity(0.15))
                        .foregroundColor(cat.themeColor)
                        .cornerRadius(10)
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
            
            Divider()
                .background(ForkarTheme.border)
                .padding(.top, 4)
            
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
        .padding()
        .background(ForkarTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ForkarTheme.border, lineWidth: 1)
        )
    }
}

struct CircleAvatarPlaceholder: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(ForkarTheme.accent)
            .frame(width: 32, height: 32)
            .background(ForkarTheme.accent.opacity(0.15))
            .clipShape(Circle())
    }
}
