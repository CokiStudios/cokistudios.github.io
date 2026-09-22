import SwiftUI
import AVKit
import AppKit

// ══════════════════════════════════════════════════════════════════
// 🔍 POST DETAIL SHEET — FORKAR FOR PC (macOS)
// Detalle de publicación con comentarios reales guardados en Supabase
// ══════════════════════════════════════════════════════════════════

struct PostDetailSheet: View {
    let post: Post
    let onOpenCSMS: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var manager: SupabaseManager
    
    @State private var comments: [PostComment] = []
    @State private var newCommentText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var isLoadingComments: Bool = true
    @State private var errorMessage: String?
    
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
                                Text(String(post.authorName.prefix(2)).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ForkarTheme.accent)
                            )
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(post.authorName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ForkarTheme.text)
                            Text(post.formattedDate)
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
                    
                    // ─── MULTIMEDIA: FOTO O VIDEO ───
                    if let vid = post.videoUrl, let vUrl = URL(string: vid), !vid.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            VideoPlayer(player: AVPlayer(url: vUrl))
                                .frame(height: 340)
                                .cornerRadius(12)
                            
                            Button(action: { NSWorkspace.shared.open(vUrl) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("Abrir video en reproductor externo")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ForkarTheme.accent)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else if let img = post.imageUrl, let url = URL(string: img), !img.isEmpty {
                        let isVid = img.hasSuffix(".mp4") || img.hasSuffix(".mov") || img.hasSuffix(".webm") || img.hasSuffix(".m4v")
                        if isVid {
                            VideoPlayer(player: AVPlayer(url: url))
                                .frame(height: 340)
                                .cornerRadius(12)
                        } else {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 380)
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            NSWorkspace.shared.open(url)
                                        }
                                        .help("Click para abrir en tamaño original")
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    
                    Divider().background(ForkarTheme.border)
                    
                    // Sección Comentarios Reales
                    HStack {
                        Text("Comentarios (\(comments.count))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ForkarTheme.text)
                        Spacer()
                        if isLoadingComments {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ForkarTheme.accent))
                                .scaleEffect(0.7)
                        }
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    
                    if comments.isEmpty && !isLoadingComments {
                        Text("Aún no hay comentarios en esta publicación. ¡Sé el primero en participar!")
                            .font(.system(size: 12))
                            .foregroundColor(ForkarTheme.textSub)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ForkarTheme.accent)
                                    Spacer()
                                    Text(comment.formattedDate)
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
            
            // Entrada para nuevo comentario en Supabase
            HStack(spacing: 10) {
                TextField("Escribe un comentario público...", text: $newCommentText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ForkarTheme.card)
                    .cornerRadius(8)
                
                Button(action: addComment) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Text("Enviar")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(ForkarTheme.accent)
                .cornerRadius(8)
                .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(16)
            .background(ForkarTheme.bgSecondary)
        }
        .frame(minWidth: 540, minHeight: 600)
        .background(ForkarTheme.bg)
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        isLoadingComments = true
        Task {
            let fetched = await manager.fetchComments(postId: post.id)
            self.comments = fetched
            self.isLoadingComments = false
        }
    }
    
    private func addComment() {
        let text = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        newCommentText = ""
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let newComment = try await manager.addComment(postId: post.id, content: text)
                comments.append(newComment)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
