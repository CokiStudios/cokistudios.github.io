# pyloop-ai: AI & LLM Inference bridge for Looping
import json, urllib.request

class PyLoopAI:
    def __init__(self, endpoint="https://cokistudios.com/api/moderate"):
        self.endpoint = endpoint

    def prompt(self, system_prompt, user_message):
        """Send a prompt to the AI model and return response."""
        req_data = json.dumps({"title": system_prompt, "content": user_message}).encode("utf-8")
        req = urllib.request.Request(self.endpoint, data=req_data, headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                return json.loads(res.read().decode("utf-8"))
        except Exception as e:
            return {"error": str(e), "isSafe": True}

def init_module(vars_dict=None):
    return PyLoopAI()
