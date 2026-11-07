# -*- coding: utf-8 -*-
"""试 API 直改三项：releaseType=MANUAL / contentRightsDeclaration / 定价正确查法（2026-11-07）"""
import base64
import json
import sys
import time
import urllib.error
import urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

KEY_ID = "L3UHT69Y77"
ISSUER_ID = "98812827-46d0-4c8f-9b91-35d4f783e6df"
P8_PATH = r"E:\AI-Projects\个人成长\50-Skills\密钥\苹果\AuthKey_L3UHT69Y77.p8"
APP_ID = "6831010088"
VER_ID = "c5ece101-3157-4a29-9c3c-d80b1b40f1d7"
APPINFO_ID = "7ad34067-964e-4cd0-a940-44555885c5b7"
BASE = "https://api.appstoreconnect.apple.com/v1"

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import load_pem_private_key


def b64url(d):
    return base64.urlsafe_b64encode(d).rstrip(b"=").decode()


def make_jwt():
    key = load_pem_private_key(open(P8_PATH, "rb").read(), password=None)
    h = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    p = b64url(json.dumps({"iss": ISSUER_ID, "iat": int(time.time()),
                           "exp": int(time.time()) + 1200,
                           "aud": "appstoreconnect-v1"}).encode())
    sig = key.sign(f"{h}.{p}".encode(), ec.ECDSA(hashes.SHA256()))

    def raw(s):
        i = 2
        if s[1] & 0x80:
            i += s[1] & 0x7f

        def ri():
            nonlocal i
            i += 1
            ln = s[i]
            i += 1
            if ln & 0x80:
                n = ln & 0x7f
                ln = 0
                for _ in range(n):
                    ln = (ln << 8) | s[i]
                    i += 1
            v = int.from_bytes(s[i:i + ln], "big")
            i += ln
            return v.to_bytes(32, "big")

        return ri() + ri()

    return f"{h}.{p}.{b64url(raw(sig))}"


JWT = make_jwt()


def asc(path, method="GET", body=None):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": f"Bearer {JWT}",
        "Content-Type": "application/json",
    })
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                t = r.read()
                return r.status, (json.loads(t) if t else {})
        except urllib.error.HTTPError as e:
            t = e.read()
            try:
                return e.code, json.loads(t)
            except Exception:
                return e.code, {"_raw": t.decode("utf-8", "replace")[:500]}
        except Exception as e:
            if attempt == 2:
                return -1, {"_err": str(e)}
            time.sleep(2)


def err_text(r):
    if r.get("errors"):
        return " | ".join(f"{e.get('code')}: {e.get('detail')}" for e in r["errors"])[:400]
    return r.get("_raw") or r.get("_err") or json.dumps(r, ensure_ascii=False)[:300]


print("=" * 66)

# ---- 试1：PATCH releaseType=MANUAL（手动发布铁律）----
st, r = asc(f"/appStoreVersions/{VER_ID}", "PATCH", {
    "data": {"type": "appStoreVersions", "id": VER_ID,
             "attributes": {"releaseType": "MANUAL"}}})
print(f"[试1 releaseType=MANUAL] HTTP {st} " + ("" if st in (200, 204) else err_text(r)))
if st == 200:
    print(f"  回读 releaseType={r['data']['attributes'].get('releaseType')}")

# ---- 试2：PATCH contentRightsDeclaration（appInfoLocalizations 层）----
st, r = asc(f"/appInfos/{APPINFO_ID}/appInfoLocalizations?limit=10")
LOC_ID = None
if st == 200:
    for d in r.get("data", []):
        if d["attributes"].get("locale") == "en-US":
            LOC_ID = d["id"]
            break
print(f"  en-US appInfoLocalization id = {LOC_ID}")
if LOC_ID:
    st, r = asc(f"/appInfoLocalizations/{LOC_ID}", "PATCH", {
        "data": {"type": "appInfoLocalizations", "id": LOC_ID,
                 "attributes": {"contentRightsDeclaration": "2026 He Weijian"}}})
    print(f"[试2 版权=2026 He Weijian] HTTP {st} " + ("" if st in (200, 204) else err_text(r)))
    if st == 200:
        print(f"  回读 contentRightsDeclaration={r['data']['attributes'].get('contentRightsDeclaration')}")

# ---- 试3：定价正确查法 ----
st, r = asc(f"/apps/{APP_ID}/appPrices?limit=5")
print(f"[试3 appPrices子路径] HTTP {st}")
if st == 200:
    print("  " + json.dumps(r.get("data", []), ensure_ascii=False)[:400])
else:
    print("  " + err_text(r)[:200])

print("=" * 66)
print("（三项试改完成）")
