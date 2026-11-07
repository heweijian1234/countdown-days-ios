# -*- coding: utf-8 -*-
"""读 H（Hypermobility Log）的审核联系人信息 + 试给倒数日 API 创建同款（2026-11-07）"""
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
H_APP_ID = "6830034297"
CD_APP_ID = "6831010088"
CD_VER_ID = "c5ece101-3157-4a29-9c3c-d80b1b40f1d7"
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

# ---- 1. 读 H 的审核联系人 ----
st, r = asc(f"/apps/{H_APP_ID}/appStoreVersions?filter[platform]=IOS&limit=3")
H_VER = None
if st == 200:
    for v in r.get("data", []):
        H_VER = v["id"]
        print(f"[H版本] {v['attributes'].get('versionString')} id={H_VER} 状态={v['attributes'].get('appStoreState')}")
        break

H_CONTACT = {}
if H_VER:
    st, r = asc(f"/appStoreVersions/{H_VER}/appStoreReviewDetail")
    if st == 200:
        data = r.get("data")
        items = data if isinstance(data, list) else ([data] if isinstance(data, dict) else [])
        for d in items:
            a = d.get("attributes", {})
            H_CONTACT = {k: a.get(k) for k in
                         ("contactFirstName", "contactLastName", "contactEmail",
                          "contactPhone", "contactPhoneExtensionCountryCode" if a.get("contactPhoneExtensionCountryCode") else "contactPhone",
                          "demoAccountName", "demoAccountPassword", "demoAccountRequired",
                          "notes") if a.get(k) is not None}
            print("[H审核联系人] " + json.dumps(
                {k: v for k, v in H_CONTACT.items() if k != "notes"}, ensure_ascii=False))
    else:
        print(f"❌ 读H审核详情失败 HTTP {st}: {err_text(r)}")

# ---- 2. 试给倒数日创建审核详情（API 通道）----
if H_CONTACT:
    attrs = {k: H_CONTACT[k] for k in ("contactFirstName", "contactLastName",
                                        "contactEmail", "contactPhone") if k in H_CONTACT}
    st, r = asc("/appStoreReviewDetails", "POST", {
        "data": {"type": "appStoreReviewDetails",
                 "attributes": attrs,
                 "relationships": {
                     "appStoreVersion": {"data": {"type": "appStoreVersions", "id": CD_VER_ID}},
                 }}})
    print(f"[倒数日建审核联系人] HTTP {st} " + ("" if st in (200, 201) else err_text(r)))
    if st in (200, 201):
        a = r["data"]["attributes"]
        print(f"  回读: {a.get('contactFirstName')} {a.get('contactLastName')} / "
              f"{a.get('contactPhone')} / {a.get('contactEmail')}")

print("=" * 66)
