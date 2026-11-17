using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using HiOP.WinUI3.Models;

namespace HiOP.WinUI3.Services;

public sealed class WorkspaceService
{
    public string WorkspaceRoot { get; private set; }
    public string EngineRepoRoot { get; private set; }

    private static readonly HashSet<string> IgnoredDirectories = new(StringComparer.OrdinalIgnoreCase)
    {
        ".git", "node_modules", "bin", "obj", "build", "dist", ".vs",
        ".gradle", "DerivedData", ".theos", ".cache", "target", ".build",
        "Packages", "__pycache__", ".venv", ".smiledev", "AppPackages"
    };

    public WorkspaceService()
    {
        WorkspaceRoot = DetectDefaultWorkspaceRoot();
        EngineRepoRoot = DetectSiblingEngineRepo(WorkspaceRoot);
    }

    public void SetWorkspace(string path)
    {
        if (Directory.Exists(path))
        {
            WorkspaceRoot = Path.GetFullPath(path);
            var siblingEngine = DetectSiblingEngineRepo(WorkspaceRoot);
            if (!string.IsNullOrEmpty(siblingEngine))
            {
                EngineRepoRoot = siblingEngine;
            }
        }
    }

    private static string DetectDefaultWorkspaceRoot()
    {
        var candidates = new List<string>();

        // 1. Walk up from BaseDirectory (handles running from bin\x64\Debug\...)
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        for (int i = 0; i < 8 && dir != null; i++)
        {
            if (Directory.Exists(Path.Combine(dir.FullName, "sample_loop_projects")) ||
                File.Exists(Path.Combine(dir.FullName, "hiop-ide.html")))
            {
                return dir.FullName;
            }
            var siblingWeb = Path.Combine(dir.FullName, "cokistudios.github.io");
            if (Directory.Exists(siblingWeb))
            {
                return siblingWeb;
            }
            dir = dir.Parent;
        }

        // 2. Known user profile paths
        var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        candidates.Add(Path.Combine(userProfile, "AntiGravedad", "cokistudios.github.io"));
        candidates.Add(Path.Combine(userProfile, "cokistudios.github.io"));
        candidates.Add(Path.Combine(userProfile, "AntiGravedad", "engine"));

        foreach (var cand in candidates)
        {
            if (Directory.Exists(cand))
                return cand;
        }

        var fallback = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
            "HiOPStudioWorkspace");
        Directory.CreateDirectory(fallback);
        return fallback;
    }

    private static string DetectSiblingEngineRepo(string workspaceRoot)
    {
        try
        {
            var parent = Directory.GetParent(workspaceRoot)?.FullName;
            if (!string.IsNullOrEmpty(parent))
            {
                var eng = Path.Combine(parent, "engine");
                if (Directory.Exists(eng))
                    return eng;
            }
            if (File.Exists(Path.Combine(workspaceRoot, "cpp", "main.cpp")))
                return workspaceRoot;
        }
        catch { }

        var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        var known = Path.Combine(userProfile, "AntiGravedad", "engine");
        return Directory.Exists(known) ? known : string.Empty;
    }

    public ObservableCollection<FileNode> BuildWorkspaceTree(int maxDepth = 2)
    {
        var rootNodes = new ObservableCollection<FileNode>();
        if (!Directory.Exists(WorkspaceRoot))
            return rootNodes;

        // Prioritize key HiOP folders first if inside cokistudios.github.io
        var priorityDirs = new[] { "sample_loop_projects", "c2-modules", "modules", "loop_modules", "LoopingEngine", "HiOP.WinUI3" };
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var pName in priorityDirs)
        {
            var full = Path.Combine(WorkspaceRoot, pName);
            if (Directory.Exists(full))
            {
                seen.Add(full);
                rootNodes.Add(ScanDirectoryNode(full, 0, maxDepth));
            }
        }

        foreach (var subDir in Directory.GetDirectories(WorkspaceRoot).OrderBy(Path.GetFileName))
        {
            if (seen.Contains(subDir)) continue;
            var name = Path.GetFileName(subDir);
            if (string.IsNullOrEmpty(name) || name.StartsWith('.') || IgnoredDirectories.Contains(name))
                continue;
            // Only surface top-level directories relevant to code/projects to keep explorer snappy
            if (Directory.GetFiles(subDir, "*.loop", SearchOption.TopDirectoryOnly).Length > 0 ||
                Directory.GetFiles(subDir, "*.c2", SearchOption.TopDirectoryOnly).Length > 0 ||
                File.Exists(Path.Combine(subDir, "smile.json")) ||
                name is "docs" or "scripts" or "tools" or "UIConnect")
            {
                rootNodes.Add(ScanDirectoryNode(subDir, 0, maxDepth));
            }
        }

        foreach (var file in Directory.GetFiles(WorkspaceRoot).OrderBy(Path.GetFileName))
        {
            var ext = Path.GetExtension(file).ToLowerInvariant();
            if (ext is ".loop" or ".ruup" or ".c2" or ".json" or ".md")
            {
                rootNodes.Add(CreateFileNode(file, isDir: false));
            }
        }

        return rootNodes;
    }

    private FileNode ScanDirectoryNode(string dirPath, int depth, int maxDepth)
    {
        var node = CreateFileNode(dirPath, isDir: true);
        if (depth >= maxDepth)
            return node;

        try
        {
            foreach (var sub in Directory.GetDirectories(dirPath).OrderBy(Path.GetFileName))
            {
                var dName = Path.GetFileName(sub);
                if (string.IsNullOrEmpty(dName) || dName.StartsWith('.') || IgnoredDirectories.Contains(dName))
                    continue;
                node.Children.Add(ScanDirectoryNode(sub, depth + 1, maxDepth));
            }

            foreach (var file in Directory.GetFiles(dirPath).OrderBy(Path.GetFileName))
            {
                var fName = Path.GetFileName(file);
                if (fName.StartsWith('.')) continue;
                node.Children.Add(CreateFileNode(file, isDir: false));
            }
        }
        catch { }

        return node;
    }

    private static FileNode CreateFileNode(string path, bool isDir)
    {
        return new FileNode
        {
            Id = path,
            FullPath = path,
            Name = Path.GetFileName(path),
            IsDirectory = isDir,
            Extension = isDir ? string.Empty : Path.GetExtension(path).ToLowerInvariant()
        };
    }

    public List<string> FindInitialFilesToOpen()
    {
        var list = new List<string>();
        var candidates = new[]
        {
            Path.Combine(WorkspaceRoot, "sample_loop_projects", "loopize_3d_obj_csharp_demo.loop"),
            Path.Combine(WorkspaceRoot, "sample_loop_projects", "quantum_v28_showcase.loop"),
            Path.Combine(WorkspaceRoot, "sample_loop_projects", "swiftui_dashboard.loop"),
            Path.Combine(WorkspaceRoot, "c2-modules", "aurora_fold_flui.c2"),
            Path.Combine(WorkspaceRoot, "sample_loop_projects", "arcade.loop")
        };

        foreach (var c in candidates)
        {
            if (File.Exists(c))
                list.Add(c);
        }
        return list;
    }

    public static IReadOnlyList<(string Title, string FileName, string Description, string Code)> GetNewArch30ATemplates() =>
        new List<(string, string, string, string)>
        {
            (
                "Cyber Odyssey 3D (Arch 3.0A)",
                "cyber_odyssey_win.loop",
                "Motor Quantum 3D con Blinn-Phong, raycasting, C# & ProMotion",
                """
                # ==============================================================================
                # Cyber Odyssey 3D — Looping v1.1 (Arch 3.0A) & Quantum 3D Engine
                # hiOP Studio WinUI 3 Native
                # ==============================================================================
                @app "Cyber Odyssey 3D" v"3.0A"

                use "loop-math-3d"
                use "loop-game-plus"

                define game3d "Cyber Odyssey 3D" version 3.0:
                    scene3d.world(name: "Neo Tokyo Void", size: (220, 100, 220), sky: "nebula_void", fog: 0.008, grid: true)
                    camera3d.set(mode: "chase", pos: (0, 8, -16), target: (0, 2, 16), fov: 65, smooth: 0.14)
                    light3d.directional(dir: (-0.42, -0.92, -0.35), color: "#f8fafc", intensity: 1.15)
                    light3d.point(at: (0, 10, 18), color: "#00f5d4", intensity: 1.5, range: 65)

                    spawn3d.box("DeckPrincipal", at: (0, 0, 12), size: (34, 1.2, 52), color: "#1e293b")
                    spawn3d.player("PilotWindows", at: (0, 2.0, -4), speed: 24, jump: 16, health: 100, color: "#38bdf8")
                    spawn3d.obj("OmegaTitan", obj: "omega_titan.obj", at: (0, 3.6, 20), scale: 1.5, color: "#f43f5e")
                    spawn3d.obj("EnergyCrystal", obj: "cyber_crystal.obj", at: (-5, 2.5, 10), scale: 1.3, color: "#fbbf24")
                    spawn3d.obj("WarpGate", obj: "star_gate.obj", at: (0, 4.0, 32), scale: 1.4, color: "#c084fc")

                    out("🚀 Cyber Odyssey 3D inicializado en Arch 3.0A!")
                    audio.tone(587, 80)
                    audio.tone(880, 100)
                """
            ),
            (
                "Loopize++ .OBJ + C# MonoBehaviour",
                "loopize_win_demo.loop",
                "Scripting C# embebido + ECS + Wave Director + Wavefront .OBJ",
                """
                # ==============================================================================
                # loopize++ Showcase: Wavefront .OBJ + C# MonoBehaviour + ECS
                # ==============================================================================
                use "loopize++"
                use "csharp"

                define game3d "Loopize++ Starfleet Arena" version 3.0:
                    scene3d.world(name: "Orbit Sector 7", size: (220, 100, 220), sky: "nebula_void", fog: 0.007, grid: true)
                    lz_banner("Orbit Sector 7")

                    cs! {
                        public class StarfighterPilot : MonoBehaviour {
                            public float Shield = 100.0f;
                            public void Start() {
                                LoopingBridge.Set("cs_pilot_ready", true);
                                Console.WriteLine("[C# Start] StarfighterPilot online on Windows.");
                            }
                            public void Update(float dt) {
                                Scene3D.Rotate("Starfighter01", 0.0f, dt * 45.0f, 0.0f);
                                Shield = Mathf.Clamp(Shield + dt * 5.0f, 0.0f, 100.0f);
                            }
                        }
                    }

                    spawn3d.obj("Starfighter01", obj: "starfighter.obj", at: (0, 2.2, 6), scale: 1.5, color: "#38bdf8", cs: "StarfighterPilot")
                    spawn3d.obj("WarpGate", obj: "star_gate.obj", at: (0, 4.0, 30), scale: 1.8, color: "#c084fc")
                    lz_wave_rush(1, "valkyrie", 3, 95, "valkyrie_drone.obj")
                    lz_report()
                    out("⚡ C# + loopize++ activo en hiOP WinUI 3")
                """
            ),
            (
                "Quantum v2.8 & CSMS Crypto",
                "quantum_telemetry.loop",
                "Rangos ..=, pattern match, álgebra lineal, CSV y CSMS E2EE",
                """
                @app "CS Quantum Telemetry Arch 3.0A" v"3.0A"

                fn format_agent(name, rank = "Commander", clearance = 5) => $"{rank} {name} [L{clearance}]"
                fn is_prime_tier(x) => x >= 90

                let lead = format_agent("Jerix", "Architect", 9)
                out($"Agent Online: {lead}")

                mut scores = [88, 96, 74, 100, 92]
                scores.push(99)
                scores.sort()

                let top = scores[-1]
                let tier = match top {
                    100 => "SS+ Quantum Sync",
                    90..=99 => "S-Tier Optimal",
                    _ => "Nominal"
                }

                let dot = math.dot([3, 4, 0], [6, 8, 0])
                let packet = crypto.csms_payload("winui3-room", "Verified Telemetry OK")
                out($"Top={top} ({tier}) | Dot={dot} | Packet={packet}")

                create window with title "Quantum Telemetry Monitor" and size (720, 480)
                draw card at (30, 30) with size (660, 120) and title "TELEMETRÍA WINUI 3" and text $"Tier: {tier} | Dot: {dot}"
                audio.tone(528, 90)
                """
            ),
            (
                "SwiftUI Declarative View",
                "swiftui_win_preview.loop",
                "Vista declarativa transpilar SwiftUI / Component 2",
                """
                # Vista declarativa transpilar desde Looping v1.1 (Arch 3.0A)
                view TelemetryDashboardView {
                    @state pulses = 120
                    @state sync_active = true

                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cyan)
                            Text("hiOP Studio Quantum UI")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Badge("Arch 3.0A")
                        }
                        Divider()
                        Text("Operaciones por segundo: $pulses Hz")
                            .font(.subheadline)
                        Toggle("Sincronización CSMS E2EE", isOn: $sync_active)
                        Button("Impulsar Motor") {
                            pulses += 20
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(20)
                }
                """
            ),
            (
                "Component 2 (.c2) flUI Card",
                "shine_widget.c2",
                "Módulo visual declarativo Component 2 para Shine OS / CS WEBS",
                """
                # ✦ SHINE OS COMPONENT 2 (.c2) ✦
                component "HiOPMonitorCard" target "flui" {
                    device: "Shine f1 / WinUI Desktop"
                    family: "flui"
                    fps: 120
                    theme: "frosted_aqua_a17"
                    primary: "#00f5d4"
                    accent: "#38bdf8"
                    background: "#030508"

                    state {
                        mut nodes_online = 8
                        mut auto_sync = true
                    }

                    draw status_pill at (center, top) with text "● COMPONENT 2 • LIVE" and glow true
                    draw card at (24, 72) with title "CS ECOSYSTEM SYNC":
                        text $"Nodos activos: {nodes_online} | Sync: {auto_sync}"
                        button "DESPLEGAR OTA" action "deploy_ota"
                }
                """
            )
        };
}
