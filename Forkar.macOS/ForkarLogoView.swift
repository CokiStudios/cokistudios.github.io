import SwiftUI
import AppKit

// ══════════════════════════════════════════════════════════════════
// 🌟 FORKAR LOGO VIEW — ICONO OFICIAL DE FORKAR (Forkman Golden Neon)
// Carga nativa de alta resolución desde forkar-icon.png
// ══════════════════════════════════════════════════════════════════

struct ForkarLogoView: View {
    var size: CGFloat = 32
    var showGlow: Bool = false
    
    var body: some View {
        Group {
            if let image = loadForkarIcon() {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                    .shadow(color: showGlow ? Color(hex: "#F59E0B").opacity(0.4) : Color.clear, radius: 8, y: 2)
            } else {
                // Fallback elegante con la paleta de Forkar
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#D97706"), Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: size * 0.65, weight: .bold))
                            .foregroundColor(.black)
                    )
            }
        }
    }
    
    private func loadForkarIcon() -> NSImage? {
        // 1. Recursos empaquetados dentro del Bundle .app
        if let url = Bundle.main.url(forResource: "forkar-icon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        
        // 2. Ruta local del proyecto
        let fm = FileManager.default
        let currentDir = fm.currentDirectoryPath
        let candidates = [
            "\(currentDir)/Forkar.macOS/forkar-icon.png",
            "\(currentDir)/assets/forkar-icon.png",
            Bundle.main.bundlePath + "/Contents/Resources/forkar-icon.png",
            Bundle.main.bundlePath + "/Contents/MacOS/forkar-icon.png"
        ]
        
        for candidate in candidates {
            if fm.fileExists(atPath: candidate), let img = NSImage(contentsOfFile: candidate) {
                return img
            }
        }
        return nil
    }
}
