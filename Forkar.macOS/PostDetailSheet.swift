import SwiftUI

// ══════════════════════════════════════════════════════════════════
// 🔍 POST DETAIL SHEET — FORKAR FOR PC (macOS)
// Vista detallada de publicación con comentarios y enlace rápido a CSMS
// ══════════════════════════════════════════════════════════════════

struct PostDetailSheet: View {
    let post: Post
    let onOpenCSMS: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var comments: [PostComment] = []
    @State private var newCommentText: String = ""
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header del Sheet
            HStack {
                Text("Detalle de Publicación")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ForkarTheme.text)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ForkarTheme.textSub)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ForkarTheme.bgSecondary)
            
            Divider().background(ForkarTheme.border)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Autor
                    HStack(spacing: 12) {
                        Circle()
                            .fill(ForkarTheme.accent.opacity(0.3))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Text(String(post.authorName?.prefix(2) ?? "U").uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForkarTheme.accent)
                            )
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(post.authorName ?? "Usuario de Forkar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                            Text(post.createdAt)
                                .font(.system(size: 11))
                                .foregroundColor(ForkarTheme.textSub)
                        }
                        
                        Spacer()
                        
                        // Acción rápida para chatear con el autor mediante CSMS
                        Button(action: onOpenCSMS) {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Chatear en CSMS")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ForkarTheme.brandGradient)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Título y Cuerpo
                    Text(post.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    
                    Text(post.content)
                        .font(.system(size: 14))
                        .foregroundColor(ForkarTheme.textSub)
                        .lineSpacing(5)
                    
                    if let img = post.imageUrl, let url = URL(string: img), !img.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 360)
                                    .cornerRadius(12)
                            default:
                                EmptyView()
                            }
                        }
                    }
                    
                    Divider().background(ForkarTheme.border)
                    
                    // Sección Comentarios
                    Text("Comentarios (\(comments.count))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ForkarTheme.text)
                    
                    if comments.isEmpty {
                        Text("Aún no hay comentarios. ¡Sé el primero en responder!")
                            .font(.system(size: 12))
                            .foregroundColor(ForkarTheme.textSub)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(comment.authorName ?? "Usuario")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ForkarTheme.accent)
                                    Spacer()
                                    Text(comment.createdAt)
                                        .font(.system(size: 10))
                                        .foregroundColor(ForkarTheme.textSub)
                                }
                                Text(comment.content)
                                    .font(.system(size: 13))
                                    .foregroundColor(ForkarTheme.text)
                            }
                            .padding(12)
                            .background(ForkarTheme.card)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
            }
            
            Divider().background(ForkarTheme.border)
            
            // Entrada para nuevo comentario
            HStack(spacing: 10) {
                TextField("Escribe un comentario público...", text: $newCommentText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ForkarTheme.card)
                    .cornerRadius(8)
                
                Button(action: addComment) {
                    Text("Enviar")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ForkarTheme.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(16)
            .background(ForkarTheme.bgSecondary)
        }
        .frame(minWidth: 540, minHeight: 600)
        .background(ForkarTheme.bg)
    }
    
    private func addComment() {
        let text = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        newCommentText = ""
        
        let comment = PostComment(
            id: UUID().uuidString,
            postId: post.id,
            userId: manager.currentUser?.id ?? "anonymous",
            content: text,
            authorName: manager.currentUser?.fullName ?? "Tú",
            authorAvatar: manager.currentUser?.avatarUrl,
            createdAt: "Ahora"
        )
        comments.append(comment)
    }
}
