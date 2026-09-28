import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: SupabaseManager
    
    @State private var userPosts: [Post] = []
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var isLoading = false
    @State private var showLogin = false
    @State private var showSetupWizard = false
    @State private var showLogoutConfirmation = false
    @State private var showMyQRCode = false
    
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
                                let displayName = user.resolvedName
                                let avatarURL = user.resolvedAvatarUrl
                                let initials = user.initials
                                
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
                                    
                                    Button(action: {
                                        showMyQRCode = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "qrcode")
                                            Text("Mi Código QR")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.emerald)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 14)
                                        .background(Color.emerald.opacity(0.12))
                                        .cornerRadius(10)
                                    }
                                    .padding(.top, 4)
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
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .liquidGlass(cornerRadius: 20, glowColor: ForkarTheme.accent)
                            .padding(.horizontal)
                            
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
                                        .liquidGlass(cornerRadius: 16, glowColor: ForkarTheme.accent)
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
                                showLogoutConfirmation = true
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
                                showLogoutConfirmation = true
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
                            #if os(macOS)
                            .frame(minWidth: 560, idealWidth: 640, maxWidth: 720, minHeight: 640, idealHeight: 740)
                            #endif
                    }
                    .sheet(isPresented: $showMyQRCode) {
                        MyEcoQRCodeSheet(
                            userId: user.id.uuidString,
                            userName: user.resolvedName,
                            points: UserDefaults.standard.integer(forKey: "forkar_eco_points")
                        )
                        #if os(macOS)
                        .frame(minWidth: 420, idealWidth: 480, minHeight: 480, idealHeight: 540)
                        #endif
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
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 32)
                    }
                }
            }
            .alert("¿Cerrar Sesión?", isPresented: $showLogoutConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Cerrar Sesión", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("¿Estás seguro de que quieres salir de tu cuenta de Coki Studios?")
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
                NavigationStack {
                    LoginView()
                        .environmentObject(authManager)
                }
                #if os(macOS)
                .frame(minWidth: 460, idealWidth: 500, maxWidth: 600, minHeight: 560, idealHeight: 640)
                #endif
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
