import SwiftUI
import AppKit

@main
struct ShineLoopLauncherApp: App {
    var body: some Scene {
        WindowGroup {
            LauncherView()
                .frame(minWidth: 1080, idealWidth: 1280, minHeight: 680, idealHeight: 800)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Holo Loop OS") {
                Button("Reiniciar Launcher") {
                    SoundSynthesizer.shared.playBootChime()
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Silenciar / Reactivar Audio") {
                    SoundSynthesizer.shared.isMuted.toggle()
                }
                .keyboardShortcut("m", modifiers: .command)

                Button("Probar Tono Looping") {
                    SoundSynthesizer.shared.playBootChime()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }

            CommandMenu("Consola") {
                Button("Alternar Modo Vista (Carrusel / Cuadrícula)") {
                    // Triggered via keyboard shortcut X or Command+V
                }
                .keyboardShortcut("v", modifiers: .command)

                Button("Navegar Siguiente") {
                    // Triggered via Arrow Right
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Navegar Anterior") {
                    // Triggered via Arrow Left
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
            }
        }
    }
}
