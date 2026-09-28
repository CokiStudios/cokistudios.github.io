import SwiftUI
import AuthenticationServices

struct SetupWizardView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State
    @State private var step = 0
    @State private var fullName = ""
    @State private var avatarUrl = ""
    @State private var selectedRole = "Developer"
    @State private var company = ""
    @State private var selectedInterests: Set<String> = []
    @State private var showCustomAvatarInput = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var isExistingUser = false
    
    // Auth State (Step 0)
    @State private var isAuthenticating = false
    @State private var showCSIDForm = false
    @State private var csidEmail = ""
    @State private var csidPassword = ""
    @State private var isCreatingCSID = false
    
    // Total steps in wizard: 0 = Sign In (CSID/Google/GitHub), 1 = Profile, 2 = Role, 3 = Interests, 4 = Summary/Card
    private let totalSteps = 5
    
    // MARK: - Preset Models & Data
    
    struct PresetAvatar: Identifiable {
        let id: String
        let title: String
        let url: String
    }
    
    let presetAvatars: [PresetAvatar] = [
        PresetAvatar(id: "1", title: "Alex", url: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=240&auto=format&fit=crop&q=80"),
        PresetAvatar(id: "2", title: "Sofia", url: "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=240&auto=format&fit=crop&q=80"),
        PresetAvatar(id: "3", title: "Leo", url: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=240&auto=format&fit=crop&q=80"),
        PresetAvatar(id: "4", title: "Elena", url: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=240&auto=format&fit=crop&q=80"),
        PresetAvatar(id: "5", title: "David", url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=240&auto=format&fit=crop&q=80"),
        PresetAvatar(id: "6", title: "Lucia", url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=240&auto=format&fit=crop&q=80")
    ]
    
    struct RoleItem: Identifiable {
        let id: String
        let title: String
        let icon: String
        let description: String
        let color: Color
    }
    
    let roleOptions: [RoleItem] = [
        RoleItem(id: "Developer", title: "Developer", icon: "chevron.left.forwardslash.chevron.right", description: "Frontend, Backend, Mobile, Fullstack", color: ForkarTheme.accent),
        RoleItem(id: "Designer", title: "Designer", icon: "paintpalette.fill", description: "UI/UX, Interfaces, Prototipos y Diseño", color: .pink),
        RoleItem(id: "Product Manager", title: "Product Manager", icon: "chart.bar.xaxis", description: "Estrategia, Roadmap, Métricas, Agile", color: .orange),
        RoleItem(id: "QA Engineer", title: "QA Engineer", icon: "checkmark.shield.fill", description: "Testing, Automatización y Calidad", color: ForkarTheme.green),
        RoleItem(id: "Student", title: "Student", icon: "graduationcap.fill", description: "Estudiante, Autodidacta, Aprendizaje continuo", color: .cyan),
        RoleItem(id: "Founder / entrepreneur", title: "Founder / Lead", icon: "bolt.fill", description: "Startups, Liderazgo y Creación de productos", color: .yellow)
    ]
    
    let availableInterests: [String] = [
        "Swift & iOS",
        "SwiftUI",
        "AI & Machine Learning",
        "Backend & APIs",
        "Frontend & Web",
        "UI/UX Design",
        "Cloud & DevOps",
        "Open Source",
        "Cybersecurity",
        "Game Dev",
        "Eco Tech",
        "Mobile Multiplatform"
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            ForkarTheme.bg
                .ignoresSafeArea()
            
            XtrapsBackground(strokeColor: ForkarTheme.accent.opacity(0.12))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header: Close/Skip + Step Counter
                topNavigationBar
                
                // Animated Progress Bar
                progressBar
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                
                // Content Step
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch step {
                        case 0:
                            stepSignIn
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        case 1:
                            stepBasicInfo
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        case 2:
                            stepProfessionalInfo
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        case 3:
                            stepInterestsInfo
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        default:
                            stepSummaryCard
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                
                // Error Alert Banner
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                
                // Bottom Navigation Buttons
                bottomActionBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        ForkarTheme.bg.opacity(0.85)
                            .background(.ultraThinMaterial)
                    )
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            populateExistingData()
        }
    }
    
    // MARK: - Navigation Bar & Progress
    
    private var topNavigationBar: some View {
        HStack {
            Button(action: {
                triggerHaptic()
                UserDefaults.standard.set(true, forKey: "hasCompletedSetupWizard")
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text(isExistingUser ? "Cerrar" : "Saltar")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(ForkarTheme.textSub)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(ForkarTheme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ForkarTheme.border, lineWidth: 1)
                )
            }
            
            Spacer()
            
            // Step badge
            HStack(spacing: 6) {
                Image(systemName: stepIconName(for: step))
                    .font(.system(size: 11, weight: .bold))
                Text("Paso \(step + 1) de \(totalSteps)")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(ForkarTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ForkarTheme.accent.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(ForkarTheme.accent.opacity(0.25), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
    
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= step
                        ? ForkarTheme.primaryGradient
                        : LinearGradient(colors: [ForkarTheme.border, ForkarTheme.border], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: step)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Step 0: Sign In (CSID, Google, GitHub)
    
    private var stepSignIn: some View {
        VStack(spacing: 20) {
            // Header Branding
            VStack(spacing: 10) {
                // CSID Badge
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ForkarTheme.accent)
                    Text("CSID • Coki Studios Identity")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(ForkarTheme.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ForkarTheme.accent.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ForkarTheme.accent.opacity(0.3), lineWidth: 1)
                )
                
                Text("Bienvenido a Forkar")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .multilineTextAlignment(.center)
                
                Text("Inicia sesión con tu CSID de Forkar, Google o GitHub para sincronizar tu perfil, garaje y comunidad.")
                    .font(.system(size: 14))
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.top, 4)
            
            if let user = authManager.currentUser {
                // Estado de sesión activa
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ForkarTheme.green.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(ForkarTheme.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sesión iniciada con éxito")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ForkarTheme.text)
                            Text(user.email ?? "Usuario CSID")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(ForkarTheme.textSub)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(ForkarTheme.green.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ForkarTheme.green.opacity(0.25), lineWidth: 1)
                    )
                    
                    Button(action: {
                        triggerHaptic()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            step = 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Continuar con este Perfil")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ForkarTheme.primaryGradient)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        triggerHaptic()
                        Task {
                            await authManager.logout()
                        }
                    }) {
                        Text("Cambiar de cuenta")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ForkarTheme.accent)
                    }
                }
                .padding(18)
                .liquidGlass(cornerRadius: 20, glowColor: ForkarTheme.green)
            } else {
                // Proveedores de Autenticación
                VStack(spacing: 12) {
                    // Botón CSID / Forkar
                    Button(action: {
                        triggerHaptic()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showCSIDForm.toggle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ForkarTheme.primaryGradient)
                                    .frame(width: 36, height: 36)
                                Text("F")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign in with CSID or Forkar")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text("Cuenta oficial de Coki Studios")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ForkarTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Image(systemName: showCSIDForm ? "chevron.up" : "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .padding(14)
                        .background(ForkarTheme.card)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showCSIDForm ? ForkarTheme.accent : ForkarTheme.border, lineWidth: showCSIDForm ? 1.5 : 1)
                        )
                    }
                    
                    // Formulario expandible CSID
                    if showCSIDForm {
                        VStack(spacing: 12) {
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Correo o Usuario CSID",
                                text: $csidEmail
                            )
                            
                            CustomSecureField(
                                icon: "lock.fill",
                                placeholder: "Contraseña",
                                text: $csidPassword
                            )
                            
                            Button(action: {
                                handleCSIDAuth()
                            }) {
                                HStack {
                                    if isAuthenticating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(isCreatingCSID ? "Crear Cuenta CSID" : "Acceder con CSID")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(ForkarTheme.primaryGradient)
                                .cornerRadius(10)
                            }
                            .disabled(isAuthenticating)
                            
                            Button(action: {
                                withAnimation {
                                    isCreatingCSID.toggle()
                                    errorMessage = nil
                                }
                            }) {
                                Text(isCreatingCSID ? "¿Ya tienes CSID? Inicia sesión" : "¿No tienes CSID? Crear cuenta gratis")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(ForkarTheme.accent)
                            }
                            .padding(.top, 2)
                        }
                        .padding(14)
                        .background(ForkarTheme.card.opacity(0.8))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ForkarTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Botón Google
                    Button(action: {
                        triggerHaptic()
                        handleOAuth(provider: "google")
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "safari.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign in with Google")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text("Autenticación rápida de Google")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ForkarTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .padding(14)
                        .background(ForkarTheme.card)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ForkarTheme.border, lineWidth: 1)
                        )
                    }
                    .disabled(isAuthenticating)
                    
                    // Botón GitHub
                    Button(action: {
                        triggerHaptic()
                        handleOAuth(provider: "github")
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.85))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign in with GitHub")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForkarTheme.text)
                                Text("Para desarrolladores y proyectos open source")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ForkarTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        .padding(14)
                        .background(ForkarTheme.card)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ForkarTheme.border, lineWidth: 1)
                        )
                    }
                    .disabled(isAuthenticating)
                }
                .liquidGlass(cornerRadius: 22, glowColor: ForkarTheme.accent)
                
                // Opción continuar sin iniciar sesión
                Button(action: {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step = 1
                    }
                }) {
                    Text("o continuar configurando perfil sin iniciar sesión")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ForkarTheme.textSub)
                        .underline()
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Step 1: Basic Info & Avatar
    
    private var stepBasicInfo: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("welcome_title".localized)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .multilineTextAlignment(.center)
                
                Text("welcome_subtitle".localized)
                    .font(.system(size: 14))
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            
            // Live Avatar Display
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ForkarTheme.primaryGradient.opacity(0.2))
                        .frame(width: 96, height: 96)
                        .blur(radius: 8)
                    
                    if let url = URL(string: avatarUrl), !avatarUrl.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 88, height: 88)
                                    .clipShape(Circle())
                            case .failure:
                                avatarFallbackView
                            case .empty:
                                ProgressView()
                                    .frame(width: 88, height: 88)
                            @unknown default:
                                avatarFallbackView
                            }
                        }
                    } else {
                        avatarFallbackView
                    }
                }
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [ForkarTheme.accent, ForkarTheme.accent2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 92, height: 92)
                )
                
                Text("Vista previa de tu avatar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ForkarTheme.textMuted)
            }
            .padding(.vertical, 4)
            
            // Preset Avatars Selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Elige un avatar")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presetAvatars) { preset in
                            Button(action: {
                                triggerHaptic()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    avatarUrl = preset.url
                                }
                            }) {
                                ZStack {
                                    AsyncImage(url: URL(string: preset.url)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                                    
                                    if avatarUrl == preset.url {
                                        Circle()
                                            .stroke(ForkarTheme.accent, lineWidth: 3)
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(ForkarTheme.accent))
                                            .offset(x: 18, y: -18)
                                    }
                                }
                                .padding(2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Clear button if avatar is set
                        if !avatarUrl.isEmpty {
                            Button(action: {
                                triggerHaptic()
                                withAnimation {
                                    avatarUrl = ""
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16))
                                        .foregroundColor(ForkarTheme.textSub)
                                    Text("Quitar")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                .frame(width: 52, height: 52)
                                .background(ForkarTheme.card)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(ForkarTheme.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            
            // Custom URL Accordion Toggle
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showCustomAvatarInput.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showCustomAvatarInput ? "chevron.down" : "link")
                            .font(.system(size: 12, weight: .bold))
                        Text(showCustomAvatarInput ? "Ocultar URL personalizada" : "Usar URL de imagen personalizada")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(ForkarTheme.accent)
                }
                
                if showCustomAvatarInput {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .foregroundColor(ForkarTheme.textSub)
                        TextField("avatar_url_placeholder".localized, text: $avatarUrl)
                            .foregroundColor(ForkarTheme.text)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled(true)
                        
                        if !avatarUrl.isEmpty {
                            Button(action: { avatarUrl = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(ForkarTheme.textSub)
                            }
                        }
                    }
                    .padding(14)
                    .background(ForkarTheme.card)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 4)
            
            // Full Name Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("full_name_label".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .bold))
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(ForkarTheme.accent)
                    
                    TextField("full_name_placeholder".localized, text: $fullName)
                        .foregroundColor(ForkarTheme.text)
                        .disableAutocorrection(true)
                    
                    if !fullName.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ForkarTheme.green)
                            .font(.system(size: 16))
                    }
                }
                .padding(14)
                .background(ForkarTheme.card)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? ForkarTheme.border
                            : ForkarTheme.accent.opacity(0.4),
                            lineWidth: 1.2
                        )
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var avatarFallbackView: some View {
        ZStack {
            ForkarTheme.card
                .frame(width: 88, height: 88)
                .clipShape(Circle())
            
            let initials = fullName.isEmpty ? "F" : String(fullName.prefix(2).uppercased())
            Text(initials)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ForkarTheme.accent)
        }
    }
    
    // MARK: - Step 1: Professional Info & Role Cards
    
    private var stepProfessionalInfo: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("role_title".localized)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .multilineTextAlignment(.center)
                
                Text("role_subtitle".localized)
                    .font(.system(size: 14))
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            
            // Visual Role Cards
            VStack(alignment: .leading, spacing: 10) {
                Text("Selecciona tu especialidad")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .padding(.horizontal, 4)
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(roleOptions) { roleItem in
                        let isSelected = selectedRole == roleItem.id
                        Button(action: {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = roleItem.id
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(roleItem.color.opacity(isSelected ? 0.25 : 0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: roleItem.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(isSelected ? roleItem.color : ForkarTheme.textSub)
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ForkarTheme.accent)
                                            .font(.system(size: 16))
                                    }
                                }
                                
                                Text(roleItem.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(isSelected ? ForkarTheme.text : ForkarTheme.textSub)
                                
                                Text(roleItem.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(ForkarTheme.textMuted)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                isSelected
                                ? ForkarTheme.accent.opacity(0.08)
                                : ForkarTheme.card
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isSelected ? ForkarTheme.accent : ForkarTheme.border,
                                        lineWidth: isSelected ? 1.8 : 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Company / Institution Input
            VStack(alignment: .leading, spacing: 8) {
                Text("company_label".localized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                HStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(ForkarTheme.accent2)
                    
                    TextField("company_placeholder".localized, text: $company)
                        .foregroundColor(ForkarTheme.text)
                        .disableAutocorrection(true)
                    
                    if !company.isEmpty {
                        Button(action: { company = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ForkarTheme.textSub)
                        }
                    }
                }
                .padding(14)
                .background(ForkarTheme.card)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ForkarTheme.border, lineWidth: 1)
                )
                
                Text("Ejemplo: Apple, Google, Universidad, Freelance")
                    .font(.system(size: 11))
                    .foregroundColor(ForkarTheme.textMuted)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Step 2: Interests & Feed Personalization
    
    private var stepInterestsInfo: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(ForkarTheme.primaryGradient)
                    .padding(.bottom, 2)
                
                Text("Tus Intereses Tech")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                    .multilineTextAlignment(.center)
                
                Text("Selecciona los temas que más te interesan para personalizar las recomendaciones en tu feed.")
                    .font(.system(size: 14))
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            
            // Interest count banner
            HStack {
                Text("\(selectedInterests.count) temas seleccionados")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(selectedInterests.isEmpty ? ForkarTheme.textMuted : ForkarTheme.accent)
                Spacer()
                if !selectedInterests.isEmpty {
                    Button(action: {
                        triggerHaptic()
                        withAnimation {
                            selectedInterests.removeAll()
                        }
                    }) {
                        Text("Limpiar selección")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ForkarTheme.textSub)
                    }
                }
            }
            .padding(.horizontal, 6)
            
            // Interest Chips Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(availableInterests, id: \.self) { interest in
                    let isChosen = selectedInterests.contains(interest)
                    Button(action: {
                        triggerHaptic()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            if isChosen {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            if isChosen {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(interest)
                                .font(.system(size: 13, weight: isChosen ? .bold : .medium))
                        }
                        .foregroundColor(isChosen ? .white : ForkarTheme.text)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if isChosen {
                                    ForkarTheme.primaryGradient
                                } else {
                                    ForkarTheme.card
                                }
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isChosen ? Color.white.opacity(0.3) : ForkarTheme.border,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
            
            // Informational tip
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                Text("Podrás cambiar tus preferencias en cualquier momento desde tu perfil.")
                    .font(.system(size: 12))
                    .foregroundColor(ForkarTheme.textSub)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ForkarTheme.card)
            .cornerRadius(12)
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Step 3: Member Card & Summary
    
    private var stepSummaryCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(ForkarTheme.green.opacity(0.18))
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 34))
                        .foregroundColor(ForkarTheme.green)
                }
                
                Text("finish_title".localized)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                Text("finish_subtitle".localized)
                    .font(.system(size: 14))
                    .foregroundColor(ForkarTheme.textSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            
            // Interactive Glassmorphic Member ID Card Preview
            VStack(alignment: .leading, spacing: 16) {
                // Card Top Banner
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(ForkarTheme.primaryGradient)
                        Text("FORKAR DEVELOPER")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
                            .foregroundColor(ForkarTheme.accent)
                    }
                    
                    Spacer()
                    
                    Text("VERIFICADO")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ForkarTheme.green.opacity(0.2))
                        .foregroundColor(ForkarTheme.green)
                        .clipShape(Capsule())
                }
                
                // Profile Main Row
                HStack(spacing: 16) {
                    // Avatar in Card
                    ZStack {
                        if let url = URL(string: avatarUrl), !avatarUrl.isEmpty {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 68, height: 68)
                                        .clipShape(Circle())
                                default:
                                    cardAvatarFallback
                                }
                            }
                        } else {
                            cardAvatarFallback
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(ForkarTheme.primaryGradient, lineWidth: 2)
                            .frame(width: 72, height: 72)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fullName.isEmpty ? "Desarrollador" : fullName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                            .lineLimit(1)
                        
                        // Role Pill
                        HStack(spacing: 5) {
                            Image(systemName: roleIcon(for: selectedRole))
                                .font(.system(size: 10, weight: .bold))
                            Text(selectedRole)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(ForkarTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ForkarTheme.accent.opacity(0.12))
                        .clipShape(Capsule())
                        
                        if !company.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 10))
                                Text(company)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(ForkarTheme.textSub)
                            .lineLimit(1)
                        }
                    }
                }
                
                // Interests tags inside card
                if !selectedInterests.isEmpty {
                    Divider()
                        .background(ForkarTheme.border)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("INTERESES")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(ForkarTheme.textMuted)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(selectedInterests).prefix(4), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(ForkarTheme.textSub)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(ForkarTheme.card)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(ForkarTheme.border, lineWidth: 1))
                                }
                                if selectedInterests.count > 4 {
                                    Text("+\(selectedInterests.count - 4)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(ForkarTheme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 22, glowColor: ForkarTheme.accent)
            .padding(.horizontal, 4)
        }
    }
    
    private var cardAvatarFallback: some View {
        ZStack {
            ForkarTheme.card
                .frame(width: 68, height: 68)
                .clipShape(Circle())
            let initials = fullName.isEmpty ? "F" : String(fullName.prefix(2).uppercased())
            Text(initials)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ForkarTheme.accent)
        }
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button(action: {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step -= 1
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("back_btn".localized)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Button(action: {
                triggerHaptic()
                nextStep()
            }) {
                HStack(spacing: 6) {
                    if isSaving || isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(step == totalSteps - 1 ? (isExistingUser ? "Guardar Perfil" : "finish_btn".localized) : (step == 0 ? (authManager.currentUser != nil ? "Continuar con este Perfil" : "Continuar como Invitado") : "next_btn".localized))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        if step < totalSteps - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isNextDisabled || isSaving || isAuthenticating)
            .opacity((isNextDisabled || isAuthenticating) ? 0.6 : 1.0)
        }
    }
    
    // MARK: - Helpers & Actions
    
    private var isNextDisabled: Bool {
        if step == 0 {
            return isAuthenticating
        } else if step == 1 {
            return fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    private func nextStep() {
        if step < totalSteps - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                step += 1
            }
        } else {
            completeSetup()
        }
    }
    
    private func completeSetup() {
        isSaving = true
        errorMessage = nil
        
        // Build company string combined with interests for personalized feed matching
        let cleanCompany = company.trimmingCharacters(in: .whitespacesAndNewlines)
        let interestsList = Array(selectedInterests).sorted()
        
        let finalCompanyValue: String?
        if !cleanCompany.isEmpty && !interestsList.isEmpty {
            finalCompanyValue = "\(cleanCompany), \(interestsList.joined(separator: ", "))"
        } else if !cleanCompany.isEmpty {
            finalCompanyValue = cleanCompany
        } else if !interestsList.isEmpty {
            finalCompanyValue = interestsList.joined(separator: ", ")
        } else {
            finalCompanyValue = nil
        }
        
        Task {
            do {
                try await authManager.updateProfile(
                    fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl,
                    company: finalCompanyValue,
                    role: selectedRole
                )
                await MainActor.run {
                    triggerSuccessHaptic()
                    isSaving = false
                    UserDefaults.standard.set(true, forKey: "hasCompletedSetupWizard")
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func populateExistingData() {
        guard let user = authManager.currentUser?.user_metadata else { return }
        
        if let name = user.full_name ?? user.name, !name.isEmpty {
            fullName = name
            isExistingUser = true
        }
        if let avatar = user.avatar_url ?? user.picture, !avatar.isEmpty {
            avatarUrl = avatar
        }
        if let role = user.role, !role.isEmpty {
            selectedRole = role
        }
        if let comp = user.company, !comp.isEmpty {
            let parts = comp.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            var foundInterests: Set<String> = []
            var nonInterests: [String] = []
            
            for part in parts {
                if availableInterests.contains(part) {
                    foundInterests.insert(part)
                } else {
                    nonInterests.append(part)
                }
            }
            
            selectedInterests = foundInterests
            company = nonInterests.joined(separator: ", ")
        }
    }
    
    private func stepIconName(for stepIndex: Int) -> String {
        switch stepIndex {
        case 0: return "person.badge.key.fill"
        case 1: return "person.crop.circle"
        case 2: return "briefcase"
        case 3: return "sparkles"
        default: return "checkmark.seal"
        }
    }
    
    private func roleIcon(for roleId: String) -> String {
        roleOptions.first(where: { $0.id == roleId })?.icon ?? "person.fill"
    }
    
    // MARK: - OAuth & CSID Handlers
    
    private func handleOAuth(provider: String) {
        isAuthenticating = true
        errorMessage = nil
        Task {
            do {
                try await authManager.signInWithOAuth(provider: provider)
                await MainActor.run {
                    populateExistingData()
                    isAuthenticating = false
                    triggerSuccessHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step = 1
                    }
                }
            } catch {
                let nsError = error as NSError
                await MainActor.run {
                    isAuthenticating = false
                    if !(nsError.domain == ASWebAuthenticationSessionErrorDomain && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue) {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func handleCSIDAuth() {
        guard !csidEmail.isEmpty && !csidPassword.isEmpty else {
            errorMessage = "Ingresa tu CSID / Correo y contraseña"
            return
        }
        isAuthenticating = true
        errorMessage = nil
        
        let finalEmail = csidEmail.contains("@") ? csidEmail : "\(csidEmail.lowercased())@cokistudios.com"
        
        Task {
            do {
                if isCreatingCSID {
                    try await authManager.signUp(
                        email: finalEmail,
                        password: csidPassword,
                        name: fullName.isEmpty ? csidEmail.components(separatedBy: "@").first?.capitalized ?? "Usuario" : fullName,
                        company: "Coki Studios"
                    )
                } else {
                    try await authManager.login(email: finalEmail, password: csidPassword)
                }
                await MainActor.run {
                    populateExistingData()
                    isAuthenticating = false
                    triggerSuccessHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        step = 1
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func triggerHaptic() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
    
    private func triggerSuccessHaptic() {
        #if canImport(UIKit)
        let notif = UINotificationFeedbackGenerator()
        notif.notificationOccurred(.success)
        #endif
    }
}
