# pyloop-ai: Local MLX & Edge AI Inference bridge for Looping
import json, urllib.parse, urllib.request


class PyLoopAI:
    def __init__(
        self,
        endpoint="http://127.0.0.1:8080/v1/chat/completions",
        fallback_endpoint="https://cokistudios.com/api/coki",
        model="auto",
    ):
        self.endpoint = endpoint
        self.fallback_endpoint = fallback_endpoint
        self.model = model

    def _resolve_model(self):
        if self.model and self.model != "auto":
            return self.model
        p = urllib.parse.urlsplit(self.endpoint)
        try:
            with urllib.request.urlopen(f"{p.scheme}://{p.netloc}/v1/models", timeout=2) as res:
                items = [m.get("id", "") for m in json.loads(res.read().decode("utf-8")).get("data", []) if m.get("id")]
                return next((m for m in items if "coki-looping" in m), items[-1] if items else "default_model")
        except Exception:
            return "default_model"

    def prompt(self, system_prompt, user_message):
        """Send a prompt to local MLX (127.0.0.1:8080) with optional Coki Edge fallback."""
        mlx_payload = json.dumps({
            "model": self._resolve_model(),
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
            "temperature": 0.25,
        }).encode("utf-8")
        try:
            req = urllib.request.Request(
                self.endpoint,
                data=mlx_payload,
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=20) as res:
                data = json.loads(res.read().decode("utf-8"))
                choices = data.get("choices") or []
                if choices:
                    return {"answer": choices[0]["message"]["content"], "engine": "MLX Local 7B"}
        except Exception:
            pass

        req_data = json.dumps({"query": user_message, "context": system_prompt}).encode("utf-8")
        req = urllib.request.Request(
            self.fallback_endpoint,
            data=req_data,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                return json.loads(res.read().decode("utf-8"))
        except Exception as e:
            return {"error": str(e), "isSafe": True}


def init_module(vars_dict=None):
    return PyLoopAI()
