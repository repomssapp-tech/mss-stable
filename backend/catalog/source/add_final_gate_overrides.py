# -*- coding: utf-8 -*-
"""Final Localization Release Gate -- override entries for the remaining
real gaps found by audit_final_gate.py: common_catalog.json (4 search
keywords), enterprise_classification_catalog.json (5 names),
knowledge_catalog.json (18 titles), and 3 treds_catalog.json brand-name
leakage cases (transliterated, not left as untranslated English)."""
import json, os

CAT = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(CAT, "ta_overrides.json")
o = json.load(open(path, encoding="utf-8"))

COMMON_NEW = {
    "msmes": "MSMEs", "MSMEs": "MSMEs",
    "sidbi": "SIDBI",
    "mses": "MSEs", "MSEs": "MSEs",
    "wise": "வாரியாக",
}
o["common"].update(COMMON_NEW)

ENTC_NEW = {
    "Exporter": "ஏற்றுமதியாளர்",
    "Women Entrepreneur": "பெண் தொழில்முனைவோர்",
    "SC/ST Entrepreneur": "SC/ST தொழில்முனைவோர்",
    "Differently-Abled Entrepreneur": "மாற்றுத்திறனாளி தொழில்முனைவோர்",
    "Startup (DPIIT)": "தொடக்க நிறுவனம் (DPIIT)",
}
o["common"].update(ENTC_NEW)

KNOWLEDGE_TITLES = {
    "MSME FUNDING REFERENCE GUIDE (India)": "MSME நிதியுதவி குறிப்பு வழிகாட்டி (இந்தியா)",
    "MSME Funding Schemes & Agencies": "MSME நிதியுதவி திட்டங்கள் மற்றும் முகமைகள்",
    "✅ Suggested Documents for Application": "✅ விண்ணப்பத்திற்குப் பரிந்துரைக்கப்படும் ஆவணங்கள்",
    "Tamil Nadu State Agencies": "தமிழ்நாடு மாநில முகமைகள்",
    "SME IPO: A Strategic Gateway to Growth for Startups": "SME IPO: தொடக்க நிறுவனங்களின் வளர்ச்சிக்கான மூலோபாய நுழைவாயில்",
    "✅ Why Consider SME IPO?": "✅ SME IPO-ஐ ஏன் பரிசீலிக்க வேண்டும்?",
    "SME IPO Platforms": "SME IPO தளங்கள்",
    "Key Takeaways for MSMEs and Startups": "MSME-கள் மற்றும் தொடக்க நிறுவனங்களுக்கான முக்கிய கருத்துகள்",
    "Compendium of Schemes for MSMEs 2022": "MSME-களுக்கான திட்டங்களின் தொகுப்பு நூல் 2022",
    "1. Introduction": "1. அறிமுகம்",
    "2. Legal Framework": "2. சட்டக் கட்டமைப்பு",
    "3. Compliant Mechanisms & Structures": "3. இணக்கமான வழிமுறைகள் மற்றும் கட்டமைப்புகள்",
    "4. Implementation Roadmap & Best Practices": "4. செயல்படுத்தும் திட்டவரைபடம் மற்றும் சிறந்த நடைமுறைகள்",
    "5. Conclusion": "5. முடிவுரை",
    "1. Introduction & Current Challenges": "1. அறிமுகம் மற்றும் தற்போதைய சவால்கள்",
    "2. Role of Interoperability": "2. இயக்கூடுநிலையின் பங்கு",
    "3. Actionable Recommendations": "3. செயல்படுத்தக்கூடிய பரிந்துரைகள்",
    "4. Conclusion": "4. முடிவுரை",
}
o.setdefault("knowledge", {}).update(KNOWLEDGE_TITLES)

TREDS_BRAND_FIX = {
    "Receivables Exchange of India Limited": "ரிசீவபிள்ஸ் எக்ஸ்சேஞ்ச் ஆஃப் இந்தியா லிமிடெட் (RXIL)",
    "M1xchange": "எம்1எக்ஸ்சேஞ்ச் (M1xchange)",
    "Invoicemart": "இன்வாய்ஸ்மார்ட் (Invoicemart)",
}
o["treds"].update(TREDS_BRAND_FIX)

o["_meta"]["batch"] = o["_meta"].get("batch", 0) + 1
o["_meta"]["note"] += (f" Batch {o['_meta']['batch']} (2026-08-15, Final Localization "
                        "Release Gate): closed remaining common/enterprise_classification/"
                        "knowledge gaps + fixed 3 treds brand-name leakage cases "
                        "(transliterated instead of left verbatim).")

json.dump(o, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("ta_overrides.json updated:")
print("  common section size:", len(o["common"]))
print("  knowledge section size:", len(o.get("knowledge", {})))
print("  treds section size:", len(o["treds"]))
