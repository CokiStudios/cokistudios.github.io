# Looping Code (v1.1 / Arch 3.0A) — Complete Learning & Mastery Guide

> **Official Nomenclature**: `Looping` (`[prod]`), `Omega Looping` (`[omega]`), `Alpha! Looping` (`[alpha]`)  
> **Engine Architecture**: Native C++17 Universal Engine + `Invis. Compile` (`LPBN v3.0A` Binary Pipeline)

---

## Module 1: Variables, Constants & String Interpolation
```looping
// Immutable & mutable bindings
val studio = "Coki Studios"
let version = 3.0
mut score = 100
score += 50
fast_assign := 42

// String interpolation with $"..." or "...{expr}..."
print($"Welcome to {studio} — Looping Arch {version} (Score: {score})")
```

## Module 2: Functions, Lambdas, Defaults & Pipe Operators
```looping
// Expression-bodied function with default argument
fn boost(x, factor = 2) => x * factor + 10

// Block-bodied function
fn classify(power) {
    if (power >= 100) {
        return "OMEGA"
    }
    return "STANDARD"
}

// Pipe operator (|>) chains transformations left-to-right
val tier = 45 |> boost(3) |> classify()
print($"Tier: {tier}")
```

## Module 3: Control Flow, Ranges & Pattern Matching (`match`)
```looping
// Inclusive (..=) and exclusive (..) ranges with step
mut total = 0
for (i in 1..=10 step 2) {
    total += i
}

// Pattern matching with multi-value arms, ranges & guards
val grade = 96
match grade {
    100 => print("Perfect S+")
    90..=99 if grade >= 95 => print("Rank S (Honors)")
    80..=89 => print("Rank A")
    _ => print("Keep training")
}
```

## Module 4: Collections, Maps, Destructuring & Functional Pipelines
```looping
let nums = [1, 2, 3, 4, 5, 6]
let [first, second, ...rest] = nums

val evens_squared = nums
    |> filter(fn(n) => n % 2 == 0)
    |> map(fn(n) => n * n)
print($"Evens squared: {evens_squared} | Sum: {math.sum(evens_squared)}")

let config = {"engine": "Looping", "fps": 240, "invis": true}
print($"Engine: {config["engine"]} @ {config["fps"]}Hz")
```

## Module 5: Error Handling (`try / catch / throw`) & Null Coalescing (`??`)
```looping
let custom_title = null
val active_title = custom_title ?? "Default Coki Window"

try {
    assert(active_title.len() > 0, "Title must not be empty")
} catch (err) {
    print($"Recovered from error: {err}")
}
```

## Module 6: Cryptography, CS ID (PKCE S256) & CSMS E2EE
```looping
use "csid"
use "csms"

val digest = crypto.sha256("CokiStudios")
val room_key = crypto.csms_key("room_global_01")
val encrypted_packet = csms.encrypt("room_global_01", "Hello Secure World")
print($"CSMS Packet: {encrypted_packet}")
```

## Module 7: Native UI Windows, Reactive Cards & Declarative SwiftUI
```looping
define app "TelemetryStudio" version 3.0:
window "Telemetry Studio" (960x600) target xui

view MainDashboard {
    @state counter = 1
    VStack(spacing: 12) {
        Text("Coki Studios — Looping SwiftUI").font(.title).fontWeight(.bold).foregroundColor(.cyan)
        Text("Active Nodes: $counter").font(.headline)
        Button("Scale Cluster") { counter += 1 }.buttonStyle(.borderedProminent)
    }.padding(20)
}
```

## Module 8: 3D Quantum Engine & 120Hz Sub-Stepping Physics
```looping
define game3d "QuantumArena" version 3.0:
scene3d.world(name: "Nexus", size: (180, 80, 180), sky: "cyber_night", fog: 0.01, grid: true)
camera3d.set(mode: "chase", pos: (0, 8, -16), target: (0, 2, 10), fov: 65)
physics3d.config(gravity: -25.0, substeps: 4, friction: 0.88, bounce: 0.15)
spawn3d.player "Pilot" at (0, 2, 0) size (1.2, 2.2, 1.2) color "#38bdf8" speed 14
spawn3d.crystal "CoreShard" at (0, 3, 12) size (1.2, 2.0, 1.2) color "#a855f7" spin 2.4
```

## Module 9: `Invis. Compile` Binary Architecture (`.loop` -> Binary File)
`Invis. Compile` converts any `.loop` source file into a cryptographically sealed `LPBN v3.0A` binary file with zero plaintext source exposure.

### 9.1 In-Language Syntax
```looping
// 1. Compile current script invisibly into build/<script>.bin
invis. compile

// 2. Compile a specific .loop file to a standalone native binary for XUI
invis. compile "sample_loop_projects/hi.loop" to "build/hi.bin" for xui

// 3. Programmatic API via built-in invis.* module
val bin_path = invis.compile("app.loop", "build/app.bin", "xui")
print(invis.verify(bin_path))  // true
print(invis.info(bin_path))    // Map with format, sha256, crc32, standalone
```

### 9.2 CLI Commands
```zsh
# Compile .loop to a standalone native binary executable (.bin)
looping invis app.loop -o build/app.bin --target xui

# Execute the binary directly from zsh or via looping
./build/app.bin
looping build/app.bin

# Compile to a compact LPBN binary container (.loopb)
looping invis app.loop -o build/app.loopb --compact
```
