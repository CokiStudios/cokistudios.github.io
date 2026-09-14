// ═══════════════════════════════════════════════════════════════
// 🦀 RUUPING RUNTIME — NATIVE PYTHON INTEROP BRIDGE
// Multiplatform Python Discovery & Bi-directional Variable Sync
// ═══════════════════════════════════════════════════════════════

use crate::value::Value;
use std::collections::HashMap;
use std::io::Write;
use std::process::{Command, Stdio};

pub struct PythonBridge {
    cached_cmd: Option<(String, Vec<String>)>,
}

impl PythonBridge {
    pub fn new() -> Self {
        let mut bridge = Self { cached_cmd: None };
        bridge.detect_python();
        bridge
    }

    pub fn detect_python(&mut self) -> Option<&(String, Vec<String>)> {
        if self.cached_cmd.is_some() {
            return self.cached_cmd.as_ref();
        }

        let candidates: Vec<(&str, Vec<&str>)> = if cfg!(windows) {
            vec![
                ("python", vec![]),
                ("py", vec!["-3"]),
                ("py", vec![]),
                ("python3", vec![]),
            ]
        } else {
            vec![
                ("python3", vec![]),
                ("python", vec![]),
                ("py", vec![]),
            ]
        };

        for (exe, args) in candidates {
            let mut cmd = Command::new(exe);
            for arg in &args {
                cmd.arg(arg);
            }
            cmd.arg("-c").arg("import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')");
            cmd.stdout(Stdio::piped()).stderr(Stdio::null());

            if let Ok(output) = cmd.output() {
                if output.status.success() {
                    let ver = String::from_utf8_lossy(&output.stdout).trim().to_string();
                    if ver.starts_with("3.") || ver.starts_with("2.7") {
                        let owned_args: Vec<String> = args.into_iter().map(|s| s.to_string()).collect();
                        self.cached_cmd = Some((exe.to_string(), owned_args));
                        return self.cached_cmd.as_ref();
                    }
                }
            }
        }

        None
    }

    pub fn execute_block(
        &mut self,
        py_code: &str,
        variables: &mut HashMap<String, Value>,
    ) -> Result<String, String> {
        let (exe, args) = match self.detect_python() {
            Some(pair) => (pair.0.clone(), pair.1.clone()),
            None => return Err("Python executable not found in system PATH.".to_string()),
        };

        let vars_json = serde_json::to_string(variables).unwrap_or_else(|_| "{}".to_string());

        let bootstrap = format!(
            r#"
import sys, json, os, math
try:
    looping_vars = json.loads(os.environ.get('LOOPING_VARS_JSON', '{{}}'))
    for _k, _v in looping_vars.items():
        globals()[_k] = _v
except Exception:
    looping_vars = {{}}

def looping_set(key, val):
    looping_vars[key] = val
    globals()[key] = val
    sys.stdout.write(f"__LOOPING_SET__:" + json.dumps({{'k': str(key), 'v': val}}) + "\n")
    sys.stdout.flush()

{}
"#,
            py_code
        );

        let mut cmd = Command::new(&exe);
        for arg in &args {
            cmd.arg(arg);
        }
        cmd.arg("-");
        cmd.env("LOOPING_VARS_JSON", vars_json);
        cmd.stdin(Stdio::piped());
        cmd.stdout(Stdio::piped());
        cmd.stderr(Stdio::piped());

        let mut child = cmd.spawn().map_err(|e| e.to_string())?;

        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(bootstrap.as_bytes()).map_err(|e| e.to_string())?;
        }

        let output = child.wait_with_output().map_err(|e| e.to_string())?;
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if !output.status.success() && !stderr.is_empty() {
            return Err(stderr.trim().to_string());
        }

        let mut user_output = Vec::new();
        for line in stdout.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("__LOOPING_SET__:") {
                let json_part = &trimmed["__LOOPING_SET__:".len()..];
                if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(json_part) {
                    if let (Some(k), Some(v)) = (parsed.get("k").and_then(|k| k.as_str()), parsed.get("v")) {
                        if let Ok(val) = serde_json::from_value::<Value>(v.clone()) {
                            variables.insert(k.to_string(), val);
                        }
                    }
                }
            } else {
                user_output.push(line);
            }
        }

        Ok(user_output.join("\n"))
    }

    pub fn eval_expr(&mut self, expr: &str, variables: &HashMap<String, Value>) -> Option<Value> {
        let (exe, args) = self.detect_python()?;
        let vars_json = serde_json::to_string(variables).unwrap_or_else(|_| "{}".to_string());

        let bootstrap = format!(
            r#"
import sys, json, os, math
try:
    looping_vars = json.loads(os.environ.get('LOOPING_VARS_JSON', '{{}}'))
    for _k, _v in looping_vars.items():
        globals()[_k] = _v
except Exception:
    pass
try:
    _res = eval({:?})
    print(json.dumps(_res))
except Exception:
    sys.exit(1)
"#,
            expr
        );

        let mut cmd = Command::new(exe);
        for arg in args {
            cmd.arg(arg);
        }
        cmd.arg("-");
        cmd.env("LOOPING_VARS_JSON", vars_json);
        cmd.stdin(Stdio::piped());
        cmd.stdout(Stdio::piped());
        cmd.stderr(Stdio::null());

        let mut child = cmd.spawn().ok()?;
        if let Some(mut stdin) = child.stdin.take() {
            let _ = stdin.write_all(bootstrap.as_bytes());
        }

        let output = child.wait_with_output().ok()?;
        if output.status.success() {
            let res_str = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if let Ok(v) = serde_json::from_str::<Value>(&res_str) {
                return Some(v);
            }
        }

        None
    }
}
