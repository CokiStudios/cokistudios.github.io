#!/usr/bin/env python3
"""
Coki Studios (CS) - Official Agent Client Protocol (ACP) Server for Xcode.
Implements the Apple Agent Client Protocol (ACP) standard over stdio via JSON-RPC 2.0.
"""

import sys
import json
import uuid
import subprocess
import os

# Ensure unbuffered stdin/stdout for real-time JSON-RPC streaming
sys.stdin.reconfigure(line_buffering=True)
sys.stdout.reconfigure(line_buffering=True)

AGY_BIN = "/Users/jerix/.local/bin/agy"
CS_RULES = """[System instructions: Eres Coki, el asistente de desarrollo y pair programmer oficial de Coki Studios en Xcode.
Reglas obligatorias de Coki Studios:
1. Zero Hardcoding: Conectar siempre con SupabaseManager (fetchPosts, fetchChatRooms, etc.). Prohibidos arrays estáticos o identidades inventadas.
2. Seguridad E2EE con respaldo por hardware: Usar Secure Enclave (CryptoKit.SecureEnclave en Apple) con AES-256-GCM y formato "🔒 enc:v1:<iv>:<ciphertext>".
3. Arquitectura Universal Multiplataforma (iOS + macOS + iPhone Duo): Un único target unificado, usando ForkarDuoManager, macOSSplitLayout y DuoControlDeckView.
4. Sincronización Xcode: Cualquier cambio en Forkar.iOS/ se sincroniza con /Users/jerix/Documents/Xcode/Forkar/Forkar/Forkar/.
5. Lenguaje: Español conciso, directo, técnico y con buenas prácticas de Swift 6 y SwiftUI.]"""

class CokiACPAgent:
    def __init__(self):
        self.sessions = {}

    def log(self, msg):
        sys.stderr.write(f"[Coki-ACP] {msg}\n")
        sys.stderr.flush()

    def send_response(self, req_id, result):
        msg = {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": result
        }
        raw = json.dumps(msg) + "\n"
        sys.stdout.write(raw)
        sys.stdout.flush()

    def send_error(self, req_id, code, message):
        msg = {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {
                "code": code,
                "message": message
            }
        }
        raw = json.dumps(msg) + "\n"
        sys.stdout.write(raw)
        sys.stdout.flush()

    def send_notification(self, method, params):
        msg = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        }
        raw = json.dumps(msg) + "\n"
        sys.stdout.write(raw)
        sys.stdout.flush()

    def handle_initialize(self, req_id, params):
        return self.send_response(req_id, {
            "protocolVersion": 1,
            "agentCapabilities": {
                "loadSession": True,
                "promptCapabilities": {
                    "image": True,
                    "audio": False,
                    "embeddedContext": True
                },
                "mcpCapabilities": {
                    "http": True,
                    "sse": True
                }
            },
            "agentInfo": {
                "name": "coki-acp",
                "title": "Coki Studios (CS) Agent",
                "version": "1.0.0"
            },
            "authMethods": []
        })

    def handle_session_new(self, req_id, params):
        sess_id = f"coki-sess-{uuid.uuid4().hex[:10]}"
        cwd = params.get("cwd") or os.getcwd()
        self.sessions[sess_id] = {
            "cwd": cwd,
            "mcpServers": params.get("mcpServers", [])
        }
        self.log(f"Created session {sess_id} with cwd: {cwd}")
        return self.send_response(req_id, {
            "sessionId": sess_id
        })

    def handle_session_prompt(self, req_id, params):
        sess_id = params.get("sessionId")
        session_data = self.sessions.get(sess_id, {})
        cwd = session_data.get("cwd") or os.getcwd()

        # Extract text from prompt array or string
        prompt_input = params.get("prompt", "")
        user_query = ""
        if isinstance(prompt_input, list):
            for part in prompt_input:
                if isinstance(part, dict):
                    if part.get("type") == "text":
                        user_query += part.get("text", "") + " "
                    elif "text" in part:
                        user_query += part.get("text", "") + " "
                elif isinstance(part, str):
                    user_query += part + " "
        elif isinstance(prompt_input, str):
            user_query = prompt_input

        user_query = user_query.strip()
        self.log(f"Received prompt for session {sess_id}: {user_query[:60]}...")

        full_prompt = f"{CS_RULES}\n\nConsulta del desarrollador en Xcode:\n{user_query}"

        # Execute Antigravity CLI in print mode
        answer_text = ""
        try:
            cmd = [AGY_BIN, "--effort", "low", "-p", full_prompt]
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=cwd
            )
            stdout, stderr = proc.communicate(timeout=60)
            if stdout:
                answer_text = stdout.strip()
            elif stderr:
                self.log(f"agy stderr: {stderr}")
                answer_text = f"Coki Studios Agent: {stderr.strip()}"
        except Exception as e:
            self.log(f"Execution error: {e}")
            answer_text = f"Coki Studios Agent: Ocurrió un error al procesar la solicitud: {str(e)}"

        if not answer_text:
            answer_text = "✨ Coki Studios Agent: Respuesta completada con éxito."

        # Stream update chunk to Xcode
        self.send_notification("session/update", {
            "sessionId": sess_id,
            "update": {
                "sessionUpdate": "agent_message_chunk",
                "content": {
                    "type": "text",
                    "text": answer_text
                }
            }
        })

        # Complete the turn
        return self.send_response(req_id, {
            "stopReason": "endTurn"
        })

    def run(self):
        self.log("Coki Studios ACP Agent started.")
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError as err:
                self.log(f"Malformed JSON: {err}")
                continue

            req_id = msg.get("id")
            method = msg.get("method")
            params = msg.get("params", {})

            if method == "initialize":
                self.handle_initialize(req_id, params)
            elif method == "session/new":
                self.handle_session_new(req_id, params)
            elif method == "session/prompt":
                self.handle_session_prompt(req_id, params)
            elif method == "session/cancel":
                if req_id is not None:
                    self.send_response(req_id, None)
            elif method == "ping":
                if req_id is not None:
                    self.send_response(req_id, "pong")
            else:
                self.log(f"Unhandled method: {method}")
                if req_id is not None:
                    self.send_response(req_id, None)

if __name__ == "__main__":
    agent = CokiACPAgent()
    agent.run()
