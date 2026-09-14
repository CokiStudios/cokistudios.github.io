# 🦀 Ruuping — The Blazing Fast Rust Engine for Looping Language

**Ruuping** is the official high-performance native Rust implementation of the **Looping** programming language, developed by **Holo Entertainment (Coki Studios)** for **Shine Loop Console** and **Holo Looping OoS**.

---

## ⚡ Key Highlights

- **🦀 100% Native Rust**: Zero-cost abstractions, memory safety without garbage collector pauses, and ultra-fast startup times (<2ms).
- **♾️ Complete Looping (.loop & .ruup) Compatibility**: Executes all existing Looping scripts, functions, loops, and math expressions.
- **🐍 Python Interoperability Bridge**: Bi-directional variable synchronization (`looping_vars` / `looping_set`) with native Windows & Linux Python launchers.
- **💻 Interactive REPL**: Real-time expression evaluation (`10 + 25 * 2`, `math.sqrt(144)`), multiline block buffering, memory variable inspector (`vars`), and instant cheatsheet (`help`).

---

## 🛠️ Building & Running Ruuping

### Prerequisites
Install Rust via [rustup.rs](https://rustup.rs) or using Windows Winget:
```powershell
winget install Rustlang.Rustup
```

### Build Binary
```powershell
cd ruuping
cargo build --release
```
The compiled native executable will be available at:
`ruuping/target/release/ruuping.exe`

---

## 🚀 Usage

```powershell
# Run a script directly
ruuping sample_loop_projects/python_interop_demo.loop

# Start interactive Rust REPL
ruuping repl

# Evaluate inline code
ruuping eval "set hero to 'Angel'; print 'Hello ' + hero + ' from Ruuping Rust!'"

# Show version
ruuping --version
```
