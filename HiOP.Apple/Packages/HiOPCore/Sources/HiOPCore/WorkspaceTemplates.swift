import Foundation

public enum WorkspaceTemplates {
    public static let arch31APresets: [TemplatePreset] = [
        TemplatePreset(
            title: "CyberOdyssey 3D (Arch 3.1A)",
            fileName: "cyber_odyssey_3d.loop",
            summary: "Escena 3D Z-Buffer + iluminación Blinn-Phong + física 120Hz",
            code: """
            define game3d "CyberOdyssey3D" version 1.1:
                scene3d.world(name: "NeonCircuit3D", size: (180, 80, 180), sky: "cyber_night", fog: 0.010, grid: true)
                camera3d.set(mode: "chase", pos: (0, 8, -16), target: (0, 2, 10), fov: 64, smooth: 0.14)
                light3d.directional(dir: (-0.4, -1.0, -0.35), color: "#ffffff", intensity: 1.1)
                physics3d.config(gravity: -26.0, substeps: 4, friction: 0.86, bounce: 0.15)

                spawn3d.player("Pilot3D", at: (0, 2, 0), mesh: "hovercraft", speed: 24, jump: 16, color: "#38bdf8")
                spawn3d.box(at: (0, -0.5, 14), size: (14, 1.2, 28), color: "#6366f1")
                spawn3d.crystal(at: (0, 3.2, 14), points: 250, color: "#fbbf24")
                spawn3d.enemy("Sentinel3D", at: (0, 2.5, 28), range: (-8, 8), speed: 9, health: 60, color: "#ef4444")
                spawn3d.portal(at: (0, 3.5, 42), radius: 3.8, label: "OMEGA GATE", color: "#c084fc")
                say("CyberOdyssey 3D activo en C++17 Nativo!")
            """
        ),
        TemplatePreset(
            title: "Arcade 2D Plataformas",
            fileName: "arcade_2d_apple.loop",
            summary: "Juego 2D con gravedad, plataformas móviles, monedas y portal",
            code: """
            define game "AppleArcade2D" version 1.1:
                game.world(width: 1100, height: 420)
                game.gravity(980)
                spawn.player(name: "Hero", at: (90, 290), speed: 280, jump: 460, health: 100, color: "#00f5d4")
                spawn.platform(at: (60, 340), size: (220, 18), color: "#6366f1")
                spawn.moving_platform(at: (320, 250), size: (150, 16), range: (280, 540), speed: 95, color: "#38bdf8")
                spawn.coin(at: (390, 190), points: 150)
                spawn.coin(at: (610, 170), points: 250)
                spawn.enemy(name: "Forkbot", at: (680, 340), range: (600, 860), speed: 85, health: 40, color: "#f43f5e")
                spawn.portal(at: (980, 310), label: "META", color: "#c084fc")
                say("Arcade 2D ejecutándose con motor ASM + C++17")
            """
        ),
        TemplatePreset(
            title: "Ventana Dinámica + Zero-Python",
            fileName: "native_ui_panel.loop",
            summary: "UI declarativa + py!() nativo sin dependencia externa",
            code: """
            @app "hiOP Panel" v"3.1A"
            set ui_profile to "metal4"
            window.create("hiOP Studio Telemetry", 860, 540)

            val raiz = py!(round(math.sqrt(144) + math.pi, 2))
            py! {
                import math
                energia = 0
                for i in range(1, 5):
                    energia += i * 15
            }

            draw card at (24, 24) size (320, 120) title "Motor Zero-Python" text $"Raíz={raiz} | Energía={energia}"
            draw button at (24, 165) text "Impulsar Sistema" action "boost_action"
            say($"Panel listo -> Raíz={raiz}, Energía={energia}")
            """
        ),
        TemplatePreset(
            title: "Quantum Telemetry & CSMS E2EE",
            fileName: "quantum_csms.loop",
            summary: "Pattern match, álgebra lineal y cifrado CSMS E2EE",
            code: """
            @app "CS Quantum Telemetry" v"3.1A"
            fn format_agent(name, rank = "Architect") => $"{rank} {name}"

            let lead = format_agent("Jerix")
            mut scores = [88, 96, 74, 100]
            scores.push(99)
            let dot = math.dot([3, 4, 0], [6, 8, 0])
            let packet = crypto.csms_payload("apple-room", "Verified Native Sync")

            say($"Lead={lead} | Dot={dot} | Packet={packet}")
            """
        )
    ]
}
