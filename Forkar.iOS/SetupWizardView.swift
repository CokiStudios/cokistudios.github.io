import SwiftUI

struct SetupWizardView: View {
    @EnvironmentObject var authManager: SupabaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var step = 0
    @State private var fullName = ""
    @State private var avatarUrl = ""
    @State private var selectedRole = "Developer"
    @State private var company = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    let roles = [
        "Developer",
        "Designer",
        "Product Manager",
        "QA Engineer",
        "Student",
        "Founder / entrepreneur"
    ]
    
    var body: some View {
        ZStack {
            ForkarTheme.bg
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header (Progress Bar)
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index <= step ? ForkarTheme.accent : ForkarTheme.border)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Step Content
                switch step {
                case 0:
                    stepBasicInfo
                case 1:
                    stepProfessionalInfo
                default:
                    stepSuccess
                }
                
                Spacer()
                
                // Error Alert Banner
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if step > 0 && step < 2 {
                        Button("back_btn".localized) {
                            withAnimation { step -= 1 }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Button(action: {
                        nextStep()
                    }) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(step == 2 ? "finish_btn".localized : "next_btn".localized)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isNextDisabled || isSaving)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .interactiveDismissDisabled()
    }
    
    private var isNextDisabled: Bool {
        if step == 0 {
            return fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }
    
    private func nextStep() {
        if step == 0 {
            withAnimation { step += 1 }
        } else if step == 1 {
            saveProfile()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func saveProfile() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                let cleanAvatar = avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                try await authManager.updateProfile(
                    fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatarUrl: cleanAvatar.isEmpty ? nil : cleanAvatar,
                    company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                    role: selectedRole
                )
                await MainActor.run {
                    isSaving = false
                    withAnimation { step += 1 }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Step Subviews
    
    private var stepBasicInfo: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(ForkarTheme.accent)
                .padding(.bottom, 8)
            
            Text("welcome_title".localized)
                .font(.title2.bold())
                .foregroundColor(ForkarTheme.text)
            
            Text("welcome_subtitle".localized)
                .font(.subheadline)
                .foregroundColor(ForkarTheme.textSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("full_name_label".localized)
                    .font(.headline)
                    .foregroundColor(ForkarTheme.text)
                
                TextField("full_name_placeholder".localized, text: $fullName)
                    .padding()
                    .background(ForkarTheme.card)
                    .foregroundColor(ForkarTheme.text)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("avatar_url_label".localized)
                    .font(.headline)
                    .foregroundColor(ForkarTheme.text)
                
                TextField("avatar_url_placeholder".localized, text: $avatarUrl)
                    .padding()
                    .background(ForkarTheme.card)
                    .foregroundColor(ForkarTheme.text)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var stepProfessionalInfo: some View {
        VStack(spacing: 16) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 64))
                .foregroundColor(ForkarTheme.accent2)
                .padding(.bottom, 8)
            
            Text("role_title".localized)
                .font(.title2.bold())
                .foregroundColor(ForkarTheme.text)
            
            Text("role_subtitle".localized)
                .font(.subheadline)
                .foregroundColor(ForkarTheme.textSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("role_label".localized)
                    .font(.headline)
                    .foregroundColor(ForkarTheme.text)
                
                Menu {
                    Picker("select_role".localized, selection: $selectedRole) {
                        ForEach(roles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRole)
                            .foregroundColor(ForkarTheme.text)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(ForkarTheme.textSub)
                    }
                    .padding()
                    .background(ForkarTheme.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("company_label".localized)
                    .font(.headline)
                    .foregroundColor(ForkarTheme.text)
                
                TextField("company_placeholder".localized, text: $company)
                    .padding()
                    .background(ForkarTheme.card)
                    .foregroundColor(ForkarTheme.text)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ForkarTheme.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var stepSuccess: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ForkarTheme.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(ForkarTheme.green)
            }
            .padding(.bottom, 8)
            
            Text("finish_title".localized)
                .font(.title2.bold())
                .foregroundColor(ForkarTheme.text)
            
            Text("finish_subtitle".localized)
                .font(.subheadline)
                .foregroundColor(ForkarTheme.textSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
