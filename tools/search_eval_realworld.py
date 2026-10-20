"""Build the real-world-phrased evaluation set (fresh, never used for tuning).

Queries are written the way people phrase scheme searches online (patterns
taken from scheme-guide pages and search suggestions: "loan without collateral
for street vendors", "free LPG connection for poor women"), each aimed at one
specific scheme and none a bare generic word like "loan" or "scheme". Scheme ids
are written as <pack><NNN> (CEN/MAH/TN + number) and expanded to catalog ids.
A deterministic third of the queries get one realistic typo.

Writes frontend/test/fixtures/search_eval/realworld_queries.json; each row has
split = dev | test (alternating) so weights can be tuned on dev and checked on
test.
"""

import json
import random
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
OUT = (
    Path(__file__).resolve().parent.parent
    / "frontend/test/fixtures/search_eval/realworld_queries.json"
)

EN = [
    ("collateral free loan for street vendors", "CEN078"),
    ("free LPG connection for poor women", "CEN084"),
    ("how to apply for udyam registration certificate online", "CEN124"),
    ("subsidy on rooftop solar for homes free electricity", "CEN208"),
    ("research fellowship for disabled students", "CEN265"),
    ("free coaching for SC OBC students competitive exams", "CEN266"),
    ("savings account for girl child high interest tax benefit", "CEN116"),
    ("marriage assistance for orphan girls tamil nadu", "TN005"),
    ("widow remarriage financial help", "TN011"),
    ("free sewing machine for poor women", "TN032"),
    ("free bus travel for women tamil nadu", "TN053"),
    ("monthly 1000 rupees for women heads of family", "TN021"),
    ("stamp duty refund for new industrial unit tamil nadu", "TN030"),
    ("single window approval for starting a factory tamil nadu", "TN034"),
    ("seed grant for startup idea tamil nadu", "TN043"),
    ("working women hostel accommodation", "CEN096"),
    ("one stop centre for women facing violence", "CEN074"),
    ("women helpline 181", "CEN135"),
    ("creche for children of working mothers", "CEN076"),
    ("maternity cash benefit for first child", "CEN082"),
    ("pucca house for houseless rural families", "CEN261"),
    ("village road connectivity programme", "CEN262"),
    ("free ration wheat rice for poorest families", "CEN236"),
    ("support for natural farming farmers", "CEN204"),
    ("fishermen boat and insurance support", "CEN205"),
    ("agri clinic agri business centre for agriculture graduates", "CEN243"),
    ("help to form a farmer producer organisation", "CEN220"),
    ("cold storage and value addition infrastructure", "CEN259"),
    ("dairy and livestock entrepreneurship support", "CEN218"),
    ("textile skilling training for weavers", "CEN216"),
    ("ITI craftsmen training certificate", "CEN229"),
    ("internship for youth with monthly allowance in top companies", "CEN198"),
    ("incentive for first job new employees EPFO", "CEN197"),
    ("residential school for scheduled caste students in top schools", "CEN212"),
    ("college students skill training naan mudhalvan", "TN026"),
    ("monthly 1000 rupees to girls from government school in college", "TN025"),
    ("export credit insurance premium reimbursement maharashtra", "MAH072"),
    ("patent filing cost rebate for startups maharashtra", "MAH031"),
    ("exit and winding up help for failed startups", "MAH027"),
    ("grant for women led startups maharashtra", "MAH017"),
    ("hackathon to solve government problems", "MAH012"),
    ("power tariff subsidy one rupee per unit msme maharashtra", "MAH049"),
    ("provident fund reimbursement for employing workers in manufacturing", "MAH050"),
    ("reimbursement of listing expenses on SME exchange maharashtra", "MAH053"),
    ("technical textile parks maharashtra", "MAH067"),
    ("drone and robotics policy for startups maharashtra", "MAH078"),
    ("fintech startups corpus fund", "MAH037"),
    ("interest subvention for exporters cheaper pre shipment credit", "CEN177"),
    ("advance authorisation duty free raw material for export production", "CEN222"),
    ("credit card for micro enterprises", "CEN188"),
    ("first time women SC ST entrepreneurs term loan up to 2 crore", "CEN189"),
    ("work shed for khadi artisans", "CEN163"),
    ("pottery making unit rural assistance", "CEN080"),
    ("agarbatti making unit assistance", "CEN223"),
    ("beekeeping subsidy honey production", "CEN009"),
    ("chappal shoe making training for artisans", "CEN167"),
    ("coir industry women self employment", "CEN047"),
    ("loan for buying capital equipment technology upgrade small units", "CEN003"),
    ("reimbursement of lab testing fee for small exporters", "CEN157"),
    ("mentoring for startups tamil nadu", "TN024"),
]

HI = [
    ("रेहड़ी पटरी वालों को बिना गारंटी लोन", "CEN078"),
    ("गरीब महिलाओं को मुफ्त गैस कनेक्शन", "CEN084"),
    ("घर की छत पर सोलर लगाने पर सब्सिडी और मुफ्त बिजली", "CEN208"),
    ("बेटी के नाम पर बचत खाता ज्यादा ब्याज", "CEN116"),
    ("पहले बच्चे के जन्म पर गर्भवती महिला को नकद सहायता", "CEN082"),
    ("बेघर परिवारों को गांव में पक्का मकान", "CEN261"),
    ("गांव को पक्की सड़क से जोड़ने की योजना", "CEN262"),
    ("सबसे गरीब परिवारों को मुफ्त अनाज", "CEN236"),
    ("प्राकृतिक खेती करने वाले किसानों को मदद", "CEN204"),
    ("मछुआरों और मछली पालकों के लिए योजना", "CEN205"),
    ("किसान उत्पादक संगठन बनाने के लिए सहायता", "CEN220"),
    ("युवाओं के लिए बड़ी कंपनियों में इंटर्नशिप और मासिक भत्ता", "CEN198"),
    ("पहली नौकरी पर नए कर्मचारियों के लिए प्रोत्साहन राशि", "CEN197"),
    ("आईटीआई प्रशिक्षण और शिल्पकार प्रमाणपत्र", "CEN229"),
    ("दिव्यांग विद्यार्थियों के लिए शोध फेलोशिप", "CEN265"),
    ("एससी ओबीसी छात्रों के लिए प्रतियोगी परीक्षा की मुफ्त कोचिंग", "CEN266"),
    ("कामकाजी महिलाओं के रहने के लिए छात्रावास", "CEN096"),
    ("हिंसा झेल रही महिलाओं के लिए एक ही जगह सहायता केंद्र", "CEN074"),
    ("कामकाजी माताओं के बच्चों के लिए पालनाघर", "CEN076"),
    ("महिलाओं के लिए हेल्पलाइन 181", "CEN135"),
    ("पहली बार उद्यम शुरू करने वाली महिलाओं और अनुसूचित जाति जनजाति को ऋण", "CEN189"),
    ("सूक्ष्म उद्यमों के लिए क्रेडिट कार्ड", "CEN188"),
    ("निर्यातकों को सस्ता कर्ज ब्याज में छूट", "CEN177"),
    ("खादी कारीगरों के लिए कार्यशाला शेड", "CEN163"),
    ("मधुमक्खी पालन के लिए मदद", "CEN009"),
    ("अगरबत्ती बनाने की इकाई", "CEN223"),
    ("डेयरी और पशुपालन में उद्यमी बनने के लिए सहायता", "CEN218"),
    ("रेशम उद्योग के विकास की योजना", "CEN215"),
    ("बुनकरों और कपड़ा क्षेत्र के कारीगरों को प्रशिक्षण", "CEN216"),
    ("सफाई कर्मचारियों के लिए मशीन से सीवर सफाई", "CEN214"),
]

TA = [
    ("தெருவோர வியாபாரிகளுக்கு பிணையில்லா கடன்", "CEN078"),
    ("ஏழைப் பெண்களுக்கு இலவச எரிவாயு இணைப்பு", "CEN084"),
    ("வீட்டு மாடியில் சோலார் அமைக்க மானியம்", "CEN208"),
    ("பெண் குழந்தைகளுக்கான சேமிப்புத் திட்டம்", "CEN116"),
    ("கர்ப்பிணிப் பெண்களுக்கு முதல் குழந்தைக்கு பண உதவி", "CEN082"),
    ("வீடற்ற குடும்பங்களுக்கு கிராமத்தில் வீடு கட்ட உதவி", "CEN261"),
    ("கிராமங்களுக்கு சாலை இணைப்பு திட்டம்", "CEN262"),
    ("ஏழைக் குடும்பங்களுக்கு இலவச உணவு தானியம்", "CEN236"),
    ("இயற்கை விவசாயம் செய்யும் விவசாயிகளுக்கு உதவி", "CEN204"),
    ("மீனவர்களுக்கு படகு மற்றும் காப்பீடு உதவி", "CEN205"),
    ("இளைஞர்களுக்கு பெரிய நிறுவனங்களில் பயிற்சி மற்றும் மாத உதவித்தொகை", "CEN198"),
    ("மாற்றுத்திறனாளி மாணவர்களுக்கு ஆராய்ச்சி உதவித்தொகை", "CEN265"),
    ("வன்முறையால் பாதிக்கப்பட்ட பெண்களுக்கு ஒரே இடத்தில் உதவி மையம்", "CEN074"),
    ("பணிபுரியும் தாய்மார்களின் குழந்தைகளுக்கான காப்பகம்", "CEN076"),
    ("பெண்களுக்கான உதவி எண் 181", "CEN135"),
    ("முதல் முறை தொழில் தொடங்கும் பெண்கள் பட்டியல் சாதியினருக்கு கடன்", "CEN189"),
    ("சிறு தொழில்களுக்கான கடன் அட்டை", "CEN188"),
    ("ஏற்றுமதியாளர்களுக்கு வட்டி மானியம்", "CEN177"),
    ("காதி கைவினைஞர்களுக்கு பணிக்கூடம்", "CEN163"),
    ("தேனீ வளர்ப்புக்கு உதவி", "CEN009"),
    ("கால்நடை தொழில் முனைவோருக்கு உதவி", "CEN218"),
    ("பட்டுப்புழு வளர்ப்பு தொழில் வளர்ச்சி", "CEN215"),
    ("நெசவாளர்களுக்கு ஜவுளி துறை பயிற்சி", "CEN216"),
    ("தொழிற்சாலை தொடங்க ஒரே இடத்தில் அனுமதி", "TN034"),
    ("புதிய தொழிலுக்கு முத்திரைத் தாள் கட்டணம் திரும்பப் பெறுதல்", "TN030"),
    ("பெண்களுக்கு இலவச தையல் இயந்திரம்", "TN032"),
    ("பெண்களுக்கு இலவச பேருந்து பயணம்", "TN053"),
    ("குடும்பத் தலைவிகளுக்கு மாதம் ஆயிரம் ரூபாய்", "TN021"),
    ("அரசுப் பள்ளியில் படித்த மாணவிகளுக்கு கல்லூரியில் மாதம் ரூபாய் ஆயிரம்", "TN025"),
    ("விதவை மறுமணத்திற்கு நிதி உதவி", "TN011"),
]


def full_id(short):
    return f"{short[:-3]}2026-{short[-3:]}"


def is_mark(ch):
    c = ord(ch)
    return (
        0x0900 <= c <= 0x0903
        or 0x093A <= c <= 0x094F
        or 0x0BBE <= c <= 0x0BCD
        or c == 0x0B82
    )


def add_typo(query, rng):
    """Drop one letter from a longer word, the commonest typing slip."""
    words = query.split(" ")
    cands = [i for i, w in enumerate(words) if len(w) >= 5 and w.isalpha()]
    if not cands:
        return query
    i = rng.choice(cands)
    w = words[i]
    spots = [
        k for k in range(1, len(w) - 1) if not is_mark(w[k]) and not is_mark(w[k - 1])
    ]
    if not spots:
        return query
    k = rng.choice(spots)
    words[i] = w[:k] + w[k + 1 :]
    return " ".join(words)


def main():
    rng = random.Random(2026)
    rows = []
    for lang, items in (("en", EN), ("hi", HI), ("ta", TA)):
        for n, (query, short) in enumerate(items):
            typed = add_typo(query, rng) if n % 3 == 1 else query
            rows.append(
                {
                    "lang": lang,
                    "level": 2,
                    "typo": typed != query,
                    "query": typed,
                    "clean": query,
                    "expected": full_id(short),
                    "split": "dev" if n % 2 == 0 else "test",
                }
            )
    OUT.write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    print(len(rows), "queries ->", OUT)


main()
