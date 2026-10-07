# pyloop-requests: HTTP Client for Looping
import urllib.request, urllib.parse, json

class HTTPClient:
    def get(self, url, headers=None):
        req = urllib.request.Request(url, headers=headers or {})
        with urllib.request.urlopen(req, timeout=15) as res:
            return {"status": res.status, "data": res.read().decode("utf-8")}

    def get_json(self, url, headers=None):
        r = self.get(url, headers)
        return json.loads(r["data"])

    def post_json(self, url, payload, headers=None):
        h = {"Content-Type": "application/json"}
        if headers: h.update(headers)
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(url, data=data, headers=h, method="POST")
        with urllib.request.urlopen(req, timeout=15) as res:
            return {"status": res.status, "data": json.loads(res.read().decode("utf-8"))}

def init_module(vars_dict=None):
    return HTTPClient()
