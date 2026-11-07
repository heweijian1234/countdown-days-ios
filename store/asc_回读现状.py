# -*- coding: utf-8 -*-
"""倒数日网页收尾前基线回读：版本状态/版权/发布方式/定价/审核联系人（只读，2026-11-07）"""
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

# 1. 版本状态 + 发布方式相关字段
st, r = asc(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=3")
if st == 200:
    for v in r.get("data", []):
        a = v["attributes"]
        print(f"[版本] {a.get('versionString')} id={v['id']} 状态={a.get('appStoreState')}")
        print(f"  releaseType={a.get('releaseType')}  "  # MANUAL=手动 / AFTER_APPROVAL=自动
              f"earliestReleaseDate={a.get('earliestReleaseDate')}")
        VER_ID = v["id"]
else:
    print(f"❌ 取版本失败 HTTP {st}: {err_text(r)}")
    VER_ID = None

# 2. appInfo 层（版权看 references 是否有、类别）
st, r = asc(f"/apps/{APP_ID}/appInfos?include=appInfoLocalizations&limit=5")
if st == 200:
    for d in r.get("data", []):
        print(f"[appInfo] id={d['id']}")
        APPINFO_ID = d["id"]
        # 版权单独查
    st2, r2 = asc(f"/apps/{APP_ID}/appInfos")
    if st2 == 200:
        for d in r2.get("data", []):
            print(f"  appInfo属性: {json.dumps(d.get('attributes', {}), ensure_ascii=False)}")
            APPINFO_ID = d["id"]
    # 类别
    st3, r3 = asc(f"/appInfos/{APPINFO_ID}/primaryCategory")
    if st3 == 200 and r3.get("data"):
        print(f"  主要类别: {r3['data'].get('id')}")
    # 版权（contentRightsDeclaration 通常在 appInfoLocalizations）
    st4, r4 = asc(f"/appInfos/{APPINFO_ID}/appInfoLocalizations?limit=10")
    if st4 == 200:
        locs = r4.get("data", [])
        print(f"  appInfoLocalizations 共 {len(locs)} 个 locale")
        for d in locs:
            cr = d.get("attributes", {}).get("contentRightsDeclaration")
            if cr:
                print(f"  版权[{d['attributes'].get('locale')}]: {cr}")
else:
    print(f"❌ 取 appInfos 失败 HTTP {st}: {err_text(r)}")

# 3. 定价
st, r = asc(f"/apps/{APP_ID}?include=prices")
if st == 200:
    inc = r.get("included", [])
    for d in inc:
        if d.get("type") == "appPrices":
            a = d.get("attributes", {})
            print(f"[定价] tier={a.get('priceTier')} — 空或0=免费")
else:
    print(f"❌ 取定价失败 HTTP {st}: {err_text(r)}")

# 4. 审核联系人
if VER_ID:
    st, r = asc(f"/appStoreVersions/{VER_ID}/appStoreReviewDetail")
    if st == 200:
        data = r.get("data")
        items = data if isinstance(data, list) else ([data] if isinstance(data, dict) else [])
        for d in items:
            a = d.get("attributes", {})
            print(f"[审核联系人] 名={a.get('contactFirstName')} {a.get('contactLastName')} / "
                  f"电话={a.get('contactPhone')} / 邮箱={a.get('contactEmail')}")
    else:
        print(f"⚠️ 取审核详情失败 HTTP {st}: {err_text(r)}")

# 5. 分级声明
if r := None:
    pass
st, r = asc(f"/apps/{APP_ID}/appInfos")
if st == 200 and r.get("data"):
    ai_id = r["data"][0]["id"]
    st2, r2 = asc(f"/appInfos/{ai_id}/ageRatingDeclaration")
    if st2 == 200:
        a = r2.get("data", {}).get("attributes", {})
        print(f"[分级] kidsAgeBand={a.get('kidsAgeBand')}")

print("=" * 66)
print("（只读基线完成）")
