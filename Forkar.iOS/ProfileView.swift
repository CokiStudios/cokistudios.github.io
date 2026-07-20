import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: SupabaseManager
    
    @State private var userPosts: [Post] = []
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var isLoading = false
    @State private var showLogin = false
    @State private var showSetupWizard = false
    
    var body: some View {
        MultiplatformNavigationStack {
            ZStack {
                ForkarTheme.bg
                    .ignoresSafeArea()
                XtrapsBackground(strokeColor: ForkarTheme.accent, opacity: 0.65)
                    .ignoresSafeArea()
                
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // User Info Card
                            VStack(spacing: 16) {
                                // Avatar
                                let meta = user.user_metadata
                                let displayName = meta?.full_name ?? meta?.name ?? user.email?.components(separatedBy: "@").first ?? "Usuario"
                                let avatarURL = meta?.avatar_url ?? meta?.picture
                                let initials = displayName.prefix(1).uppercased()
                                
                                if let avatar = avatarURL, let url = URL(string: avatar) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        CircleAvatarPlaceholder(initials: initials)
                                            .frame(width: 80, height: 80)
                                            .font(.system(size: 28, weight: .bold))
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(ForkarTheme.accent, lineWidth: 2))
                                } else {
                                    CircleAvatarPlaceholder(initials: initials)
                                        .frame(width: 80, height: 80)
                                        .font(.system(size: 28, weight: .bold))
                                        .overlay(Circle().stroke(ForkarTheme.accent, lineWidth: 2))
                                }
                                
                                VStack(spacing: 6) {
                                    Text(displayName)
                                        .font(.title2.bold())
                                        .foregroundColor(ForkarTheme.text)
                                    
                                    if let bio = user.user_metadata?.company, !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(bio)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(ForkarTheme.accent)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }
                                    
                                    Text(user.email ?? "")
                                        .font(.system(size: 12))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                
                                // Stats Row
                                HStack(spacing: 40) {
                                    VStack(spacing: 4) {
                                        Text("\(followersCount)")
                                            .font(.headline)
                                            .foregroundColor(ForkarTheme.text)
                                        Text("Seguidores")
                                            .font(.caption)
                                            .foregroundColor(ForkarTheme.textSub)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("\(followingCount)")
                                            .font(.headline)
                                            .foregroundColor(ForkarTheme.text)
                                        Text("Siguiendo")
                                            .font(.caption)
                                            .foregroundColor(ForkarTheme.textSub)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text("\(userPosts.count)")
                                            .font(.headline)
                                            .foregroundColor(ForkarTheme.text)
                                        Text("Publicaciones")
                                            .font(.caption)
                                            .foregroundColor(ForkarTheme.textSub)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            
                            // User's Posts list
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Mis Publicaciones")
                                    .font(.headline)
                                    .foregroundColor(ForkarTheme.text)
                                    .padding(.horizontal)
                                
                                if isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                        Spacer()
                                    }
                                    .padding()
                                } else if userPosts.isEmpty {
                                    Text("No has publicado nada aún.")
                                        .font(.subheadline)
                                        .foregroundColor(ForkarTheme.textSub)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 30)
                                        .glassCard()
                                        .padding(.horizontal)
                                } else {
                                    ForEach(userPosts) { post in
                                        NavigationLink(destination: PostDetailView(post: post)) {
                                            PostCardView(post: post)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await loadProfileData(userId: user.id)
                    }
                    .toolbar {
                        #if os(iOS)
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showSetupWizard = true
                            }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                authManager.logout()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "power")
                                    Text("Salir")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                            }
                        }
                        #else
                        ToolbarItem(placement: .navigation) {
                            Button(action: {
                                showSetupWizard = true
                            }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                authManager.logout()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "power")
                                    Text("Salir")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                            }
                        }
                        #endif
                    }
                    .sheet(isPresented: $showSetupWizard) {
                        SetupWizardView()
                            .environmentObject(authManager)
                    }
                } else {
                    // Not logged in view
                    VStack(spacing: 24) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(ForkarTheme.textSub)
                        
                        VStack(spacing: 8) {
                            Text("Tu Perfil en Forkar")
                                .font(.title2.bold())
                                .foregroundColor(ForkarTheme.text)
                            
                            Text("Inicia sesión para ver tu actividad, seguidores y publicaciones.")
                                .font(.subheadline)
                                .foregroundColor(ForkarTheme.textSub)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Iniciar Sesión / Registrarse")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 32)
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showLogin, onDismiss: {
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    Task {
                        await loadProfileData(userId: user.id)
                    }
                }
            }) {
                NavigationView {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    Task {
                        await loadProfileData(userId: user.id)
                    }
                }
            }
        }
    }
    
    private func loadProfileData(userId: UUID) async {
        isLoading = true
        do {
            // Load stats
            let stats = try await authManager.getFollowStats(userId: userId)
            followersCount = stats.followers
            followingCount = stats.following
            
            // Load user posts
            userPosts = try await authManager.fetchPosts(userId: userId)
        } catch {
            print("Error loading profile data: \(error)")
        }
        isLoading = false
    }
}
