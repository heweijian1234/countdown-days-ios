# -*- coding: utf-8 -*-
"""Countdown Widget - Days ASC 上架填料（照 GrindSnore 模板；跑前置条件：build 已传 ASC 且 VALID）
七语满填：en/ja/de/fr/es + zh-Hans/zh-Hant（健哥 2026-11-07 规矩：新 App 简繁从 v1 带）
"""
import time, json, base64, sys, hashlib, urllib.request
import os

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

KEY_ID = "L3UHT69Y77"
ISSUER_ID = "98812827-46d0-4c8f-9b91-35d4f783e6df"
P8_PATH = r"E:\AI-Projects\个人成长\50-Skills\密钥\苹果\AuthKey_L3UHT69Y77.p8"
APP_ID = "6831010088"   # Countdown Widget - Days
VER = "1.0"
STORE = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\countdown-days-ios\store"
PRIVACY_URL = "https://postwriter.cn/seo/countdowndays-privacy.html"
APP_NAME = "Countdown Widget - Days"

def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes

key = load_pem_private_key(open(P8_PATH, "rb").read(), password=None)
h = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
p = b64url(json.dumps({"iss": ISSUER_ID, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}).encode())
sig = key.sign(f"{h}.{p}".encode(), ec.ECDSA(hashes.SHA256()))
def raw(s):
    i = 2
    if s[1] & 0x80: i += s[1] & 0x7f
    def ri():
        nonlocal i
        i += 1; ln = s[i]; i += 1
        if ln & 0x80:
            n = ln & 0x7f; ln = 0
            for _ in range(n): ln = (ln << 8) | s[i]; i += 1
        v = int.from_bytes(s[i:i+ln], "big"); i += ln; return v.to_bytes(32, "big")
    return ri() + ri()
jwt = f"{h}.{p}.{b64url(raw(sig))}"

def asc(url, data=None, method=None, headers=None):
    body = json.dumps(data).encode() if data else None
    all_headers = {"Authorization": f"Bearer {jwt}", "Content-Type": "application/json"}
    if headers: all_headers.update(headers)
    req = urllib.request.Request(url, data=body, headers=all_headers, method=method or ("POST" if data else "GET"))
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.status, json.loads(resp.read() or b"{}")
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read() or b"{}")
        except Exception as ex:
            if attempt == 3: return -1, {"err": str(ex)}
            time.sleep(3)

EN_DESC = """How many days until the moments that matter?

Countdown Widget - Days puts every upcoming event right on your Home Screen — birthdays, trips, anniversaries, exams, weddings. One glance, zero taps.

• Home Screen widgets in small, medium and large sizes
• Your next event always at a glance — days, beautifully big
• Repeats yearly: birthdays and anniversaries count down again every year, set once
• Emoji icons and colors for every event
• Add, edit and reorder events in seconds
• Works offline — no account, no sign-in, nothing to set up

PRIVATE BY DESIGN
No account. No cloud. No ads. No analytics. No network access at all — your events never leave your device.

FREE AND SIMPLE
Unlimited events, all widget sizes, free. Deleting the app removes everything instantly — because nothing was ever sent anywhere."""

# 字符预算自查：subtitle≤30 keywords≤100（脚本跑前 assert）
LOCALES = {
    "en-US": {"subtitle": "Days until birthdays & trips",
              "keywords": "countdown,days until,birthday reminder,days counter,event,anniversary,trip,vacation,exam,date",
              "description": EN_DESC},
    "ja": {"subtitle": "誕生日や旅行の残り日数",
           "keywords": "カウントダウン,残り日数,誕生日,記念日,ウィジェット,旅行,イベント,日数",
           "description": "大切な日まであと何日？Countdown Widget - Days は、誕生日・旅行・記念日・試験・結婚式など、すべてのイベントをホーム画面に表示します。一目でわかる、タップ不要。\n\n• スモール・ミディアム・ラージのホーム画面ウィジェット\n• 次のイベントが常に一目でわかる——残り日数を大きく表示\n• 年間リピート：誕生日や記念日は毎年自動で再カウント、一度設定するだけ\n• イベントごとに絵文字アイコンとカラー\n• 数秒でイベントを追加・編集・並べ替え\n• オフラインで動作——アカウント不要、ログイン不要\n\nプライバシー設計：アカウントなし・クラウドなし・広告なし・分析なし。ネットワークアクセス自体がありません。イベントは端末から出ません。\n\n無料でシンプル：イベント無制限、全ウィジェットサイズ対応。"},
    "de-DE": {"subtitle": "Tage bis Geburtstage & Reisen",
           "keywords": "Countdown,Tage bis,Geburtstag Erinnerung,Widget,Jahrestag,Reise,Prüfung,Ereignis,Tageszähler",
           "description": "Wie viele Tage bis zu den Momenten, die zählen?\n\nCountdown Widget - Days zeigt jedes anstehende Ereignis direkt auf deinem Homescreen — Geburtstage, Reisen, Jahrestage, Prüfungen, Hochzeiten. Ein Blick, null Tipps.\n\n• Homescreen-Widgets in klein, mittel und groß\n• Dein nächstes Ereignis immer im Blick — Tageszahl schön groß\n• Jährliche Wiederholung: Geburtstage und Jahrestage zählen jedes Jahr neu herunter, einmal eingestellt\n• Emoji-Icons und Farben für jedes Ereignis\n• Ereignisse in Sekunden hinzufügen, bearbeiten, sortieren\n• Funktioniert offline — ohne Konto, ohne Anmeldung\n\nPRIVAT VON DESIGN: Kein Konto, keine Cloud, keine Werbung, keine Analyse, kein Netzwerkzugriff. Deine Ereignisse verlassen dein Gerät nie.\n\nKOSTENLOS UND EINFACH: Unbegrenzte Ereignisse, alle Widget-Größen."},
    "fr-FR": {"subtitle": "Jours avant anniversaires",
           "keywords": "compte à rebours,jours avant,anniversaire rappel,widget,date,voyage,examen,événement",
           "description": "Combien de jours avant les moments qui comptent ?\n\nCountdown Widget - Days affiche chaque événement à venir directement sur votre écran d'accueil — anniversaires, voyages, dates anniversaires, examens, mariages. Un coup d'œil, zéro tapotement.\n\n• Widgets d'écran d'accueil en petite, moyenne et grande taille\n• Votre prochain événement toujours visible — le nombre de jours, en grand\n• Répétition annuelle : anniversaires et fêtes recomptent chaque année, à régler une fois\n• Icônes emoji et couleurs pour chaque événement\n• Ajoutez, modifiez et réordonnez en secondes\n• Fonctionne hors ligne — sans compte, sans connexion\n\nCONFIDENTIALITÉ PAR CONCEPTION : aucun compte, aucun cloud, aucune pub, aucune analyse, aucun accès réseau. Vos événements ne quittent jamais votre appareil.\n\nGRATUIT ET SIMPLE : événements illimités, toutes les tailles de widgets."},
    "es-ES": {"subtitle": "Días para cumpleaños y viajes",
           "keywords": "cuenta regresiva,días para,cumpleaños recordatorio,widget,aniversario,viaje,examen,evento,contador",
           "description": "¿Cuántos días faltan para los momentos que importan?\n\nCountdown Widget - Days pone cada evento próximo en tu pantalla de inicio — cumpleaños, viajes, aniversarios, exámenes, bodas. Un vistazo, cero toques.\n\n• Widgets de pantalla de inicio en tamaño pequeño, mediano y grande\n• Tu próximo evento siempre a la vista — los días, bien grandes\n• Repetición anual: cumpleaños y aniversarios vuelven a contar cada año, se configura una vez\n• Iconos emoji y colores para cada evento\n• Añade, edita y reordena eventos en segundos\n• Funciona sin conexión — sin cuenta, sin registro\n\nPRIVACIDAD POR DISEÑO: sin cuenta, sin nube, sin anuncios, sin analíticas, sin acceso a red. Tus eventos nunca salen de tu dispositivo.\n\nGRATIS Y SIMPLE: eventos ilimitados, todos los tamaños de widget."},
    "zh-Hans": {"subtitle": "生日旅行倒数日小组件",
           "keywords": "倒数日,倒数,纪念日,生日提醒,小组件,桌面插件,天数,倒计时,恋爱,考试",
           "description": "距离重要日子还有多少天？\n\n倒数日小组件把每个即将到来的日子放上你的主屏幕——生日、旅行、纪念日、考试、婚礼。抬眼即见，无需点开。\n\n• 主屏幕小组件：小/中/大三种尺寸\n• 下一个大事一目了然——剩余天数大字显示\n• 每年循环：生日和纪念日每年自动重新倒数，设置一次即可\n• 每个事件可配 emoji 图标和颜色\n• 几秒完成添加、编辑、排序\n• 完全离线可用——无需注册，无需登录\n\n隐私设计：无账号、无云端、无广告、无分析、无任何联网权限。你的事件永远不离开设备。\n\n免费简洁：事件数量不限，全部小组件尺寸免费使用。删除 App 即彻底清除所有数据——因为数据从未被上传。"},
    "zh-Hant": {"subtitle": "生日旅行倒數日小工具",
           "keywords": "倒數日,倒數,紀念日,生日提醒,小工具,桌面插件,天數,倒數計時,戀愛,考試",
           "description": "距離重要日子還有多少天？\n\n倒數日小工具把每個即將到來的日子放上你的主畫面——生日、旅行、紀念日、考試、婚禮。抬眼即見，無需點開。\n\n• 主畫面小工具：小/中/大三種尺寸\n• 下一件大事一目瞭然——剩餘天數大字顯示\n• 每年循環：生日和紀念日每年自動重新倒數，設定一次即可\n• 每個事件可配 emoji 圖示和顏色\n• 幾秒完成新增、編輯、排序\n• 完全離線可用——無需註冊，無需登入\n\n隱私設計：無帳號、無雲端、無廣告、無分析、無任何網路權限。你的事件永遠不離開裝置。\n\n免費簡潔：事件數量不限，全部小工具尺寸免費使用。刪除 App 即徹底清除所有資料——因為資料從未被上傳。"},
}

# 字符预算 assert（30/100 硬限）
for loc, info in LOCALES.items():
    assert len(info["subtitle"]) <= 30, f"{loc} subtitle 超限: {len(info['subtitle'])}"
    assert len(info["keywords"]) <= 100, f"{loc} keywords 超限: {len(info['keywords'])}"
    print(f"budget {loc}: subtitle={len(info['subtitle'])}/30 keywords={len(info['keywords'])}/100 OK")

# 1. 版本
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=5")
vers = r.get("data", [])
if not vers:
    print("[1] 无版本（异常）"); sys.exit(1)
ver_id = vers[0]["id"]
if vers[0]["attributes"].get("versionString") != VER:
    st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}",
                {"data": {"type": "appStoreVersions", "id": ver_id, "attributes": {"versionString": VER}}}, method="PATCH")
print(f"[1] 版本 {VER} id={ver_id} state={vers[0]['attributes'].get('appStoreState')}")

# 2. App 信息层（语言注册+名称+副标题+隐私URL）——两层结构：subtitle在这层
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}?include=appInfos")
app_info_id = None
for inc in r.get("included", []):
    if inc["type"] == "appInfos":
        app_info_id = inc["id"]; break
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appInfos/{app_info_id}/appInfoLocalizations")
info_existing = {l["attributes"]["locale"]: l["id"] for l in r.get("data", [])}
for locale, info in LOCALES.items():
    attrs = {"name": APP_NAME, "subtitle": info["subtitle"], "privacyPolicyUrl": PRIVACY_URL}
    if locale in info_existing:
        st, rr = asc(f"https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/{info_existing[locale]}",
                     {"data": {"type": "appInfoLocalizations", "id": info_existing[locale], "attributes": attrs}}, method="PATCH")
    else:
        st, rr = asc("https://api.appstoreconnect.apple.com/v1/appInfoLocalizations", {"data": {
            "type": "appInfoLocalizations", "attributes": {"locale": locale, **attrs},
            "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info_id}}}}})
    print(f"[2] App信息 {locale}: {'OK' if st in (200, 201) else f'{st} ' + json.dumps(rr)[:200]}")

# 3. 版本文案层（description/keywords/supportUrl）——keywords在这层
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
existing = {l["attributes"]["locale"]: l["id"] for l in r.get("data", [])}
en_loc = None
for locale, info in LOCALES.items():
    payload = {"type": "appStoreVersionLocalizations", "attributes": {
        "locale": locale, "keywords": info["keywords"], "description": info["description"],
        "supportUrl": "https://postwriter.cn"}}
    if locale in existing:
        patch_attrs = {k: v for k, v in payload["attributes"].items() if k != "locale"}
        if locale == "en-US": en_loc = existing[locale]
        st, rr = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{existing[locale]}",
                     {"data": {"type": "appStoreVersionLocalizations", "id": existing[locale], "attributes": patch_attrs}}, method="PATCH")
    else:
        payload["relationships"] = {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}}
        st, rr = asc("https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations", {"data": payload})
        if locale == "en-US" and st in (200, 201): en_loc = rr["data"]["id"]
    print(f"[3] 版本文案 {locale}: {'OK' if st in (200, 201) else f'{st} ' + json.dumps(rr)[:200]}")

# 4. 截图上传（en-US locale，APP_IPHONE_67）
if not en_loc:
    st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
    for l in r.get("data", []):
        if l["attributes"]["locale"] == "en-US": en_loc = l["id"]
st, r = asc(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{en_loc}/appScreenshotSets")
set_id = None
for s in r.get("data", []):
    if s["attributes"].get("screenshotDisplayType") == "APP_IPHONE_67":
        set_id = s["id"]; break
if not set_id:
    st, r = asc("https://api.appstoreconnect.apple.com/v1/appScreenshotSets", {"data": {
        "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
        "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": en_loc}}}}})
    if st in (200, 201) and r.get("data"):
        d0 = r["data"]
        set_id = d0[0]["id"] if isinstance(d0, list) else d0["id"]
    else:
        print(f"[4] 截图集创建失败 {st} {json.dumps(r)[:300]}"); sys.exit(1)
print(f"[4] 截图集 {set_id}")
for i in range(1, 4):
    path = os.path.join(STORE, f"shot{i}.png")
    data = open(path, "rb").read()
    md5 = base64.b64encode(hashlib.md5(data).digest()).decode()
    st, r = asc("https://api.appstoreconnect.apple.com/v1/appScreenshots", {
        "data": {"type": "appScreenshots", "attributes": {"fileName": f"shot{i}.png", "fileSize": len(data)},
                 "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    if st not in (200, 201):
        print(f"  shot{i} reserve FAIL {st} {json.dumps(r)[:150]}"); continue
    upload = r["data"]["attributes"]["uploadOperations"][0]
    headers = {hh["name"]: hh["value"] for hh in upload.get("requestHeaders", [])}
    req = urllib.request.Request(upload["url"], data=data, headers=headers, method=upload["method"])
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            up_ok = resp.status in (200, 201)
    except Exception:
        up_ok = False
    if up_ok:
        st2, r2 = asc(f"https://api.appstoreconnect.apple.com/v1/appScreenshots/{r['data']['id']}",
                      {"data": {"type": "appScreenshots", "id": r["data"]["id"],
                                "attributes": {"uploaded": True, "sourceFileChecksum": md5}}}, method="PATCH")
        print(f"  shot{i}: {'OK' if st2 in (200, 201) else 'confirm FAIL'}")
    time.sleep(2)

print("[5] 完成——网页剩：年龄分级(全否)/版权2026 He Weijian/分类 Utilities/受监管医疗设备=否/隐私=不收集/价格免费/选build/审核联系人/发布=手动")
