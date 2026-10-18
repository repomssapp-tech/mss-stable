# -*- coding: utf-8 -*-
"""Tamil Localization Completion Phase -- adds contextual override entries
(Task 1: SCH000218/SCH000219; Task 3: the 5 zero-coverage catalogs) to
ta_overrides.json, in the SAME format/method ("llm_contextual_translation")
already used for the existing 1147 scheme-section entries. Does not touch
any *_catalog.json file -- that happens in a separate apply step that runs
the existing build_i18n.py/localize_ta_d3.py translate() pipeline against
these entries.
"""
import json, os
from collections import OrderedDict

CAT = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(CAT, "ta_overrides.json")
o = json.load(open(path, encoding="utf-8"))

# ---- Task 1: SCH000218 (Stand-Up India), SCH000219 (PMFME) ----------------
SCHEME_NEW = {
    "PMFME": "PMFME",
    "Stand-Up India Scheme": "ஸ்டாண்ட்-அப் இந்தியா திட்டம்",
    "Stand-Up India": "ஸ்டாண்ட்-அப் இந்தியா",
    "Composite bank loan (term loan + working capital) of Rs 10 lakh to Rs 1 crore for SC/ST and women entrepreneurs setting up a new (greenfield) enterprise in manufacturing, services, agri-allied activities, or trading.":
        "உற்பத்தி, சேவைகள், விவசாயம் தொடர்பான நடவடிக்கைகள், அல்லது வர்த்தகத்தில் புதிய (கிரீன்ஃபீல்ட்) நிறுவனத்தைத் தொடங்கும் SC/ST மற்றும் பெண் தொழில்முனைவோருக்கு Rs 10 lakh முதல் Rs 1 crore வரையிலான கூட்டு வங்கிக் கடன் (கால கடன் + செயல்பாட்டு மூலதனம்).",
    "To facilitate bank loans between Rs 10 lakh and Rs 1 crore to at least one Scheduled Caste (SC) or Scheduled Tribe (ST) borrower and at least one woman borrower per bank branch, for setting up a greenfield enterprise.":
        "கிரீன்ஃபீல்ட் நிறுவனத்தைத் தொடங்குவதற்காக, ஒவ்வொரு வங்கிக் கிளையிலும் குறைந்தது ஒரு பட்டியலிடப்பட்ட சாதி (SC) அல்லது பட்டியலிடப்பட்ட பழங்குடியினர் (ST) கடன் பெறுநருக்கும், குறைந்தது ஒரு பெண் கடன் பெறுநருக்கும் Rs 10 lakh முதல் Rs 1 crore வரையிலான வங்கிக் கடன்களை எளிதாக்குதல்.",
    "SC/ST or woman entrepreneur, above 18 years of age, setting up a greenfield (newly established) enterprise. For non-individual enterprises, at least 51% shareholding and controlling stake must be held by an SC/ST or woman entrepreneur.":
        "SC/ST அல்லது பெண் தொழில்முனைவோர், 18 வயதிற்கு மேற்பட்டவர், கிரீன்ஃபீல்ட் (புதிதாக நிறுவப்பட்ட) நிறுவனத்தைத் தொடங்குபவர். தனிநபர் அல்லாத நிறுவனங்களுக்கு, குறைந்தது 51% பங்குடைமையும் கட்டுப்பாட்டு பங்கும் SC/ST அல்லது பெண் தொழில்முனைவோரிடம் இருக்க வேண்டும்.",
    "Composite loan Rs 10 lakh-Rs 1 crore. Margin money: 15% (borrower contribution). Collateral: security cover under the Credit Guarantee Fund Scheme for Stand-Up India Loans (CGFSIL) -- not a specific percentage/amount stated on the fetched page.":
        "கூட்டுக் கடன் Rs 10 lakh-Rs 1 crore. மார்ஜின் மணி: 15% (கடன் பெறுநர் பங்களிப்பு). அடமானம்: ஸ்டாண்ட்-அப் இந்தியா கடன்களுக்கான கடன் உத்தரவாத நிதி திட்டத்தின் (CGFSIL) கீழான பாதுகாப்பு -- குறிப்பிட்ட சதவீதம்/தொகை பெறப்பட்ட பக்கத்தில் குறிப்பிடப்படவில்லை.",
    "PM Formalisation of Micro Food Processing Enterprises (PMFME)":
        "பிரதமர் குறு உணவுப் பதப்படுத்தல் நிறுவனங்கள் முறைப்படுத்தல் திட்டம் (PMFME)",
    "Centrally-sponsored scheme (launched 29 June 2020, Rs 10,000 crore 5-year outlay) supporting micro food processing units, FPOs/SHGs/producer cooperatives, common infrastructure, branding/marketing, and capacity building, structured around 7 named components: One District One Product, individual unit upgradation, FPO/SHG/cooperative support, SHG seed capital, common infrastructure, branding & marketing, and capacity building.":
        "குறு உணவுப் பதப்படுத்தல் அலகுகள், FPO/SHG/உற்பத்தியாளர் கூட்டுறவு சங்கங்கள், பொது உள்கட்டமைப்பு, பிராண்டிங்/சந்தைப்படுத்தல், மற்றும் திறன் மேம்பாட்டிற்கு ஆதரவளிக்கும் மத்திய அரசு நிதியுதவி திட்டம் (29 ஜூன் 2020 அன்று தொடங்கப்பட்டது, Rs 10,000 crore 5-ஆண்டு ஒதுக்கீடு), 7 பெயரிடப்பட்ட கூறுகளைக் கொண்டு அமைக்கப்பட்டுள்ளது: ஒரு மாவட்டம் ஒரு தயாரிப்பு, தனிப்பட்ட அலகு மேம்பாடு, FPO/SHG/கூட்டுறவு ஆதரவு, SHG விதை மூலதனம், பொது உள்கட்டமைப்பு, பிராண்டிங் & சந்தைப்படுத்தல், மற்றும் திறன் மேம்பாடு.",
    "To formalise existing unorganised micro food processing enterprises, upgrade their technology, and link them to organised markets via the One District One Product (ODOP) approach.":
        "ஏற்கனவே உள்ள ஒழுங்கமைக்கப்படாத குறு உணவுப் பதப்படுத்தல் நிறுவனங்களை முறைப்படுத்துதல், அவற்றின் தொழில்நுட்பத்தை மேம்படுத்துதல், மற்றும் ஒரு மாவட்டம் ஒரு தயாரிப்பு (ODOP) அணுகுமுறை மூலம் அவற்றை ஒழுங்கமைக்கப்பட்ட சந்தைகளுடன் இணைத்தல்.",
    "Individual entrepreneurs, proprietorships, partnerships, and private limited companies operating existing unorganised micro food processing units; also Farmer Producer Organisations (FPOs), Self-Help Groups (SHGs), and cooperatives across the food processing value chain.":
        "ஏற்கனவே உள்ள ஒழுங்கமைக்கப்படாத குறு உணவுப் பதப்படுத்தல் அலகுகளை இயக்கும் தனிநபர் தொழில்முனைவோர், தனியுரிம நிறுவனங்கள், கூட்டாண்மைகள், மற்றும் தனியார் வரையறுக்கப்பட்ட நிறுவனங்கள்; மேலும், உணவுப் பதப்படுத்தல் மதிப்புச் சங்கிலி முழுவதும் உள்ள விவசாயிகள் உற்பத்தியாளர் அமைப்புகள் (FPOs), தன்னுதவிக் குழுக்கள் (SHGs), மற்றும் கூட்டுறவு சங்கங்கள்.",
    "Credit-linked subsidy (percentage and per-unit ceiling corroborated by secondary sources at MEDIUM confidence, not read verbatim from the primary PDF this session -- see verification.notes).":
        "கடன்-இணைந்த மானியம் (சதவீதம் மற்றும் அலகு-வாரியான வரம்பு, இரண்டாம் நிலை ஆதாரங்களால் நடுத்தர நம்பகத்தன்மையில் உறுதிப்படுத்தப்பட்டது; இந்த அமர்வில் முதன்மை PDF-லிருந்து அப்படியே படிக்கப்படவில்லை -- verification.notes பார்க்கவும்).",
}

# ---- Task 3: the 5 zero-coverage catalogs (name + summary per record) ----
CLUSTER_ASSISTANCE = {
    "MSME Cluster Development Programme": "MSME கொத்து மேம்பாட்டுத் திட்டம்",
    "Application and support channel for Common Facility Centres (CFC) and Infrastructure Development (ID) for MSME clusters nationally.":
        "நாடு முழுவதும் உள்ள MSME கொத்துகளுக்கான பொது வசதி மையங்கள் (CFC) மற்றும் உள்கட்டமைப்பு மேம்பாட்டிற்கான (ID) விண்ணப்ப மற்றும் ஆதரவு வழி.",
    "SIPCOT Industrial Parks (Tamil Nadu)": "SIPCOT தொழில்துறை பூங்காக்கள் (தமிழ்நாடு)",
    "50 industrial parks including 8 SEZs across Tamil Nadu; plot allotment and grievance redressal for tenant enterprises. Established 1971. Major tenants referenced on-site include Bosch, Apollo Tyres, Reliance Retail.":
        "தமிழ்நாடு முழுவதும் 8 சிறப்பு பொருளாதார மண்டலங்கள் (SEZs) உட்பட 50 தொழில்துறை பூங்காக்கள்; குத்தகைதாரர் நிறுவனங்களுக்கான மனை ஒதுக்கீடு மற்றும் குறை தீர்வு. 1971-ல் நிறுவப்பட்டது. Bosch, Apollo Tyres, Reliance Retail ஆகியவை தளத்தில் குறிப்பிடப்பட்ட முக்கிய குத்தகைதாரர்கள்.",
    "Cut & Sew Scheme (Tamil Nadu Textiles)": "கட் & சூ திட்டம் (தமிழ்நாடு ஜவுளித்துறை)",
    "50% capital subsidy for brand new computerized cutting machines with CAD/CAM software in Garmenting, Home Textiles and Technical Textile sectors; maximum ceiling Rs 50 lakh per machine; released in 60/20/20 instalments. Verbatim from tntextilesschemes.tn.gov.in/cut_sew_landing.":
        "ஆடை உற்பத்தி, வீட்டு ஜவுளி மற்றும் தொழில்நுட்ப ஜவுளித் துறைகளில் CAD/CAM மென்பொருளுடன் கூடிய புத்தம்புதிய கணினிமயமாக்கப்பட்ட வெட்டும் இயந்திரங்களுக்கு 50% மூலதன மானியம்; இயந்திரம் ஒன்றுக்கு அதிகபட்சம் Rs 50 lakh வரம்பு; 60/20/20 தவணைகளில் வழங்கப்படும். tntextilesschemes.tn.gov.in/cut_sew_landing இலிருந்து அப்படியே.",
    "Non-Conventional Fibre/Yarn Manufacturing Capital Investment Subsidy (Tamil Nadu Textiles)":
        "மரபுசாரா இழை/நூல் உற்பத்தி மூலதன முதலீட்டு மானியம் (தமிழ்நாடு ஜவுளித்துறை)",
    "25% capital investment subsidy on eligible plant and machinery cost for new non-conventional fibre/yarn manufacturing factories and spinning mills; maximum ceiling Rs 1.00 crore per unit; disbursed 60% on commencement, 40% after one year. Verbatim from tntextilesschemes.tn.gov.in/fibre.":
        "புதிய மரபுசாரா இழை/நூல் உற்பத்தி தொழிற்சாலைகள் மற்றும் நூற்பு ஆலைகளுக்கு, தகுதியான ஆலை மற்றும் இயந்திரச் செலவின் மீது 25% மூலதன முதலீட்டு மானியம்; அலகு ஒன்றுக்கு அதிகபட்சம் Rs 1.00 crore வரம்பு; தொடக்கத்தில் 60%, ஒரு வருடம் கழித்து 40% வழங்கப்படும். tntextilesschemes.tn.gov.in/fibre இலிருந்து அப்படியே.",
    "Printing Cluster CFC — Sivakasi": "அச்சிடும் கொத்து பொது வசதி மையம் — சிவகாசி",
    "Common Facility Centre (CFC) under the MSE Cluster Development Programme (MSE-CDP), completed: 5-colour offset printing, cutting and plate-making facility. THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the cluster, not a per-enterprise benefit amount: GoI Rs 767.80 lakh + GoTN Rs 90.66 lakh = Rs 858.46 lakh total government grant (SPV/cluster-unit own contribution separate, not counted as assistance).":
        "MSE கொத்து மேம்பாட்டுத் திட்டத்தின் (MSE-CDP) கீழான பொது வசதி மையம் (CFC), முடிக்கப்பட்டது: 5-நிற ஆஃப்செட் அச்சிடுதல், வெட்டுதல் மற்றும் தகடு தயாரிப்பு வசதி. இது கொத்திற்கான ஒரு பகிரப்பட்ட வசதியை உருவாக்குவதற்கான மொத்தத் திட்ட மானியம், நிறுவனம் ஒன்றுக்கான பலன் தொகை அல்ல: GoI Rs 767.80 lakh + GoTN Rs 90.66 lakh = மொத்தம் Rs 858.46 lakh அரசு மானியம் (SPV/கொத்து-அலகின் சொந்தப் பங்களிப்பு தனி, உதவியாகக் கணக்கிடப்படவில்லை).",
    "Printing Cluster CFC — Krishnagiri": "அச்சிடும் கொத்து பொது வசதி மையம் — கிருஷ்ணகிரி",
    "Common Facility Centre (CFC) under the MSE Cluster Development Programme (MSE-CDP), completed: Computer-to-plate, graphic designing and 4-colour offset facility. THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the cluster, not a per-enterprise benefit amount: GoI Rs 936.81 lakh + GoTN Rs 90.00 lakh = Rs 1026.81 lakh total government grant (SPV/cluster-unit own contribution separate, not counted as assistance).":
        "MSE கொத்து மேம்பாட்டுத் திட்டத்தின் (MSE-CDP) கீழான பொது வசதி மையம் (CFC), முடிக்கப்பட்டது: கணினி-முதல்-தகடு, வடிவமைப்பு மற்றும் 4-நிற ஆஃப்செட் வசதி. இது கொத்திற்கான ஒரு பகிரப்பட்ட வசதியை உருவாக்குவதற்கான மொத்தத் திட்ட மானியம், நிறுவனம் ஒன்றுக்கான பலன் தொகை அல்ல: GoI Rs 936.81 lakh + GoTN Rs 90.00 lakh = மொத்தம் Rs 1026.81 lakh அரசு மானியம் (SPV/கொத்து-அலகின் சொந்தப் பங்களிப்பு தனி, உதவியாகக் கணக்கிடப்படவில்லை).",
    "Engineering Cluster CFC — Hosur": "பொறியியல் கொத்து பொது வசதி மையம் — ஓசூர்",
    "Common Facility Centre (CFC) under the MSE Cluster Development Programme (MSE-CDP), completed: Common metal processing (de-coiling) facility. THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the cluster, not a per-enterprise benefit amount: GoI Rs 439.89 lakh + GoTN Rs 70.75 lakh = Rs 510.64 lakh total government grant (SPV/cluster-unit own contribution separate, not counted as assistance).":
        "MSE கொத்து மேம்பாட்டுத் திட்டத்தின் (MSE-CDP) கீழான பொது வசதி மையம் (CFC), முடிக்கப்பட்டது: பொது உலோக செயலாக்க (டி-காயிலிங்) வசதி. இது கொத்திற்கான ஒரு பகிரப்பட்ட வசதியை உருவாக்குவதற்கான மொத்தத் திட்ட மானியம், நிறுவனம் ஒன்றுக்கான பலன் தொகை அல்ல: GoI Rs 439.89 lakh + GoTN Rs 70.75 lakh = மொத்தம் Rs 510.64 lakh அரசு மானியம் (SPV/கொத்து-அலகின் சொந்தப் பங்களிப்பு தனி, உதவியாகக் கணக்கிடப்படவில்லை).",
    "Engineering Cluster CFC — Ranipet": "பொறியியல் கொத்து பொது வசதி மையம் — இராணிப்பேட்டை",
    "Common Facility Centre (CFC) under the MSE Cluster Development Programme (MSE-CDP), completed: Facility complementing firm-level engineering processes. THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the cluster, not a per-enterprise benefit amount: GoI Rs 616.39 lakh + GoTN Rs 97.21 lakh = Rs 713.60 lakh total government grant (SPV/cluster-unit own contribution separate, not counted as assistance).":
        "MSE கொத்து மேம்பாட்டுத் திட்டத்தின் (MSE-CDP) கீழான பொது வசதி மையம் (CFC), முடிக்கப்பட்டது: நிறுவன அளவிலான பொறியியல் செயல்முறைகளை நிறைவு செய்யும் வசதி. இது கொத்திற்கான ஒரு பகிரப்பட்ட வசதியை உருவாக்குவதற்கான மொத்தத் திட்ட மானியம், நிறுவனம் ஒன்றுக்கான பலன் தொகை அல்ல: GoI Rs 616.39 lakh + GoTN Rs 97.21 lakh = மொத்தம் Rs 713.60 lakh அரசு மானியம் (SPV/கொத்து-அலகின் சொந்தப் பங்களிப்பு தனி, உதவியாகக் கணக்கிடப்படவில்லை).",
    "Leather Cluster CFC — Pallavaram": "தோல் கொத்து பொது வசதி மையம் — பல்லாவரம்",
    "Common Facility Centre (CFC) under the MSE Cluster Development Programme (MSE-CDP), ongoing: Designing, pattern making and cutting facility. THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the cluster, not a per-enterprise benefit amount: GoI Rs 197.93 lakh + GoTN Rs 29.69 lakh = Rs 227.62 lakh total government grant (SPV/cluster-unit own contribution separate, not counted as assistance).":
        "MSE கொத்து மேம்பாட்டுத் திட்டத்தின் (MSE-CDP) கீழான பொது வசதி மையம் (CFC), நடைபெற்று வருகிறது: வடிவமைப்பு, மாதிரி தயாரிப்பு மற்றும் வெட்டும் வசதி. இது கொத்திற்கான ஒரு பகிரப்பட்ட வசதியை உருவாக்குவதற்கான மொத்தத் திட்ட மானியம், நிறுவனம் ஒன்றுக்கான பலன் தொகை அல்ல: GoI Rs 197.93 lakh + GoTN Rs 29.69 lakh = மொத்தம் Rs 227.62 lakh அரசு மானியம் (SPV/கொத்து-அலகின் சொந்தப் பங்களிப்பு தனி, உதவியாகக் கணக்கிடப்படவில்லை).",
    "Rice Mill Cluster CFC — Alangulam": "அரிசி ஆலை கொத்து பொது வசதி மையம் — ஆலங்குளம்",
    "Common Facility Centre (CFC) under the MSE Cluster Development Programme (MSE-CDP), completed: Colour sorter and mechanized paddy pre-cleaning facility. THIS IS AN AGGREGATE PROJECT GRANT to build one shared facility for the cluster, not a per-enterprise benefit amount: GoI Rs 550.25 lakh + GoTN Rs 78.91 lakh = Rs 629.16 lakh total government grant (SPV/cluster-unit own contribution separate, not counted as assistance).":
        "MSE கொத்து மேம்பாட்டுத் திட்டத்தின் (MSE-CDP) கீழான பொது வசதி மையம் (CFC), முடிக்கப்பட்டது: நிற பிரிப்பான் மற்றும் இயந்திரமயமாக்கப்பட்ட நெல் முன்-சுத்திகரிப்பு வசதி. இது கொத்திற்கான ஒரு பகிரப்பட்ட வசதியை உருவாக்குவதற்கான மொத்தத் திட்ட மானியம், நிறுவனம் ஒன்றுக்கான பலன் தொகை அல்ல: GoI Rs 550.25 lakh + GoTN Rs 78.91 lakh = மொத்தம் Rs 629.16 lakh அரசு மானியம் (SPV/கொத்து-அலகின் சொந்தப் பங்களிப்பு தனி, உதவியாகக் கணக்கிடப்படவில்லை).",
}

CSR = {
    "Section 135, Companies Act 2013": "பிரிவு 135, நிறுவனங்கள் சட்டம் 2013",
    "Companies meeting prescribed thresholds must spend at least 2% of average net profits on CSR; activities are strictly limited to Schedule VII, executed per CSR Rules 2014 (as amended through 2022/2024 MCA notifications).":
        "நிர்ணயிக்கப்பட்ட வரம்புகளை பூர்த்தி செய்யும் நிறுவனங்கள் தங்கள் சராசரி நிகர லாபத்தில் குறைந்தது 2%-ஐ CSR-க்காக செலவிட வேண்டும்; நடவடிக்கைகள் அட்டவணை VII-க்கு மட்டுமே கண்டிப்பாக வரம்பிடப்பட்டு, CSR விதிகள் 2014-ன் (2022/2024 MCA அறிவிப்புகள் வரை திருத்தப்பட்டவாறு) படி செயல்படுத்தப்படும்.",
    "Schedule VII clause (i) — eradicating poverty and livelihood enhancement":
        "அட்டவணை VII பிரிவு (i) — வறுமை ஒழிப்பு மற்றும் வாழ்வாதார மேம்பாடு",
    "Relevant Schedule VII clause for MSME-aligned interventions: eradicating poverty and livelihood enhancement.":
        "MSME-சார்ந்த தலையீடுகளுக்கான தொடர்புடைய அட்டவணை VII பிரிவு: வறுமை ஒழிப்பு மற்றும் வாழ்வாதார மேம்பாடு.",
    "Schedule VII clause (ii) — promoting education, employability and vocational skills":
        "அட்டவணை VII பிரிவு (ii) — கல்வி, வேலைவாய்ப்புத் திறன் மற்றும் தொழிற்கல்வித் திறன்களை மேம்படுத்துதல்",
    "Relevant Schedule VII clause for MSME-aligned interventions: promoting education, employability, and vocational skills.":
        "MSME-சார்ந்த தலையீடுகளுக்கான தொடர்புடைய அட்டவணை VII பிரிவு: கல்வி, வேலைவாய்ப்புத் திறன் மற்றும் தொழிற்கல்வித் திறன்களை மேம்படுத்துதல்.",
    "Schedule VII clause (iv) — environmental sustainability and technology upgradation":
        "அட்டவணை VII பிரிவு (iv) — சுற்றுச்சூழல் நிலைத்தன்மை மற்றும் தொழில்நுட்ப மேம்பாடு",
    "Relevant Schedule VII clause for MSME-aligned interventions: environmental sustainability and technology upgradation.":
        "MSME-சார்ந்த தலையீடுகளுக்கான தொடர்புடைய அட்டவணை VII பிரிவு: சுற்றுச்சூழல் நிலைத்தன்மை மற்றும் தொழில்நுட்ப மேம்பாடு.",
    "Schedule VII clause (ix) — contributions to technology incubators and R&D":
        "அட்டவணை VII பிரிவு (ix) — தொழில்நுட்ப அடைவூட்டிகள் மற்றும் R&D-க்கான பங்களிப்புகள்",
    "Relevant Schedule VII clause for MSME-aligned interventions: contributions to technology incubators, R&D projects, and incubators funded by Central/State Government or PSUs.":
        "MSME-சார்ந்த தலையீடுகளுக்கான தொடர்புடைய அட்டவணை VII பிரிவு: தொழில்நுட்ப அடைவூட்டிகள், R&D திட்டங்கள், மற்றும் மத்திய/மாநில அரசு அல்லது PSU-களால் நிதியளிக்கப்படும் அடைவூட்டிகளுக்கான பங்களிப்புகள்.",
    "Prohibition on commercial support to for-profit MSMEs": "இலாப நோக்கிலான MSME-களுக்கு வணிக ஆதரவு வழங்குவதற்கான தடை",
    "Direct commercial lending, equity investment, or profit-linked support to for-profit MSMEs is not a permissible CSR activity under the Companies Act 2013.":
        "இலாப நோக்கிலான MSME-களுக்கு நேரடி வணிகக் கடன், பங்கு முதலீடு, அல்லது லாபம் தொடர்பான ஆதரவு வழங்குவது நிறுவனங்கள் சட்டம் 2013-ன் கீழ் அனுமதிக்கப்பட்ட CSR நடவடிக்கை அல்ல.",
    "Grants via registered implementing agencies": "பதிவு செய்யப்பட்ட செயல்படுத்தும் முகமைகள் வழியாக மானியங்கள்",
    "Channel funds through Section 8 companies, registered societies, or public trusts holding CSR-1 registration with the MCA and (where required) a 3-year track record. Suitable for skill, livelihood, and technology grants benefiting MSMEs.":
        "பிரிவு 8 நிறுவனங்கள், பதிவு செய்யப்பட்ட சங்கங்கள், அல்லது MCA-வுடன் CSR-1 பதிவு மற்றும் (தேவைப்படும் இடங்களில்) 3-ஆண்டு செயல்பாட்டு வரலாறு கொண்ட பொது அறக்கட்டளைகள் வழியாக நிதியைச் செலுத்துங்கள். MSME-களுக்குப் பயனளிக்கும் திறன், வாழ்வாதாரம் மற்றும் தொழில்நுட்ப மானியங்களுக்கு ஏற்றது.",
    "Contributions to approved incubators": "அங்கீகரிக்கப்பட்ட அடைவூட்டிகளுக்கான பங்களிப்புகள்",
    "Direct contributions to Atal Incubation Centres, DST-recognised incubators, or Government/PSU-funded technology business incubators supporting MSMEs and start-ups (Schedule VII clause ix).":
        "அடல் அடைவூட்டு மையங்கள், DST-அங்கீகரிக்கப்பட்ட அடைவூட்டிகள், அல்லது MSME-கள் மற்றும் தொடக்க நிறுவனங்களை ஆதரிக்கும் அரசு/PSU-நிதியளிக்கும் தொழில்நுட்ப வணிக அடைவூட்டிகளுக்கு நேரடி பங்களிப்புகள் (அட்டவணை VII பிரிவு ix).",
    "Livelihood enhancement and cluster development": "வாழ்வாதார மேம்பாடு மற்றும் கொத்து மேம்பாடு",
    "Programs combining skill training, market linkage, and non-commercial working-capital grants for artisan, weaver, and micro-enterprise clusters—anchored in Schedule VII clauses (i) and (ii).":
        "கைவினைஞர், நெசவாளர் மற்றும் குறு நிறுவனக் கொத்துகளுக்கான திறன் பயிற்சி, சந்தை இணைப்பு, மற்றும் வணிகம் அல்லாத செயல்பாட்டு மூலதன மானியங்களை இணைக்கும் திட்டங்கள்—அட்டவணை VII பிரிவுகள் (i) மற்றும் (ii) அடிப்படையில்.",
    "Blended finance and venture philanthropy via not-for-profits": "இலாப நோக்கற்ற நிறுவனங்கள் வழியாக கலப்பு நிதி மற்றும் நிறுவன தொண்டு முதலீடு",
    "Impact-first or recoverable grants routed through eligible Section 8 vehicles, where any recovered amounts are ploughed back into the same CSR project (consistent with MCA's stance that CSR funds may not generate commercial return for the donor company).":
        "தகுதியான பிரிவு 8 நிறுவனங்கள் வழியாக செலுத்தப்படும் தாக்க-முதன்மை அல்லது மீட்கக்கூடிய மானியங்கள், மீட்கப்படும் தொகைகள் அதே CSR திட்டத்திற்குள் மீண்டும் செலுத்தப்படும் (CSR நிதிகள் நன்கொடையாளர் நிறுவனத்திற்கு வணிக வருமானத்தை உருவாக்கக்கூடாது என்ற MCA-வின் நிலைப்பாட்டிற்கு இணங்க).",
    "Partnerships with SIDBI, NSIC or state MSME corporations": "SIDBI, NSIC அல்லது மாநில MSME கழகங்களுடன் கூட்டாண்மைகள்",
    "Co-funded capacity-building, technology-upgradation, and financial-literacy projects, leveraging the public-institution route under Schedule VII.":
        "அட்டவணை VII-ன் கீழ் பொது நிறுவன வழியைப் பயன்படுத்தி இணை-நிதியளிக்கப்படும் திறன் மேம்பாடு, தொழில்நுட்ப மேம்பாடு மற்றும் நிதி அறிவுத் திட்டங்கள்.",
    "Company-specific CSR Foundation or Trust": "நிறுவனத்திற்கே உரிய CSR அறக்கட்டளை அல்லது டிரஸ்ட்",
    "A dedicated Section 8 company or trust (CSR-1 registered) that designs and delivers Schedule VII-compliant programmes for MSMEs—offering governance control while retaining strict non-commercial character.":
        "MSME-களுக்கான அட்டவணை VII-இணக்கமான திட்டங்களை வடிவமைத்து வழங்கும், அர்ப்பணிக்கப்பட்ட பிரிவு 8 நிறுவனம் அல்லது டிரஸ்ட் (CSR-1 பதிவு செய்யப்பட்டது)—நிர்வாகக் கட்டுப்பாட்டை வழங்கும் அதேவேளையில் கண்டிப்பான வணிகமற்ற தன்மையை தக்கவைத்துக்கொள்கிறது.",
    "CSR-1 registration of implementing agencies": "செயல்படுத்தும் முகமைகளின் CSR-1 பதிவு",
    "CSR Committee recommendation and Board approval of the Annual Action Plan; verify CSR-1 status of all implementing agencies.":
        "ஆண்டு செயல் திட்டத்திற்கான CSR குழுவின் பரிந்துரை மற்றும் இயக்குநர் குழுவின் ஒப்புதல்; அனைத்து செயல்படுத்தும் முகமைகளின் CSR-1 நிலையை சரிபார்க்கவும்.",
    "Third-party impact assessment": "மூன்றாம் தரப்பு தாக்க மதிப்பீடு",
    "Mandatory third-party impact assessment for projects ≥ ₹1 crore (per CSR Rules); define MSME-level KPIs—jobs, incomes, formalisation.":
        "₹1 crore-க்கும் அதிகமான திட்டங்களுக்கு கட்டாய மூன்றாம் தரப்பு தாக்க மதிப்பீடு (CSR விதிகளின்படி); MSME-அளவிலான KPI-களை வரையறுக்கவும்—வேலைவாய்ப்புகள், வருமானங்கள், முறைப்படுத்தல்.",
    "Form CSR-2 reporting and unspent funds transfer": "படிவம் CSR-2 அறிக்கையிடல் மற்றும் செலவிடப்படாத நிதி பரிமாற்றம்",
    "Disclose in Form CSR-2 with the Registrar and the Board's Report; transfer unspent earmarked funds to the prescribed Unspent CSR Account within 30 days.":
        "பதிவாளரிடமும் இயக்குநர் குழு அறிக்கையிலும் படிவம் CSR-2-ல் வெளிப்படுத்தவும்; செலவிடப்படாத ஒதுக்கப்பட்ட நிதிகளை நிர்ணயிக்கப்பட்ட செலவிடப்படாத CSR கணக்கிற்கு 30 நாட்களுக்குள் மாற்றவும்.",
    "Monitoring and audit trail": "கண்காணிப்பு மற்றும் தணிக்கை பாதை",
    "Quarterly review by the CSR Committee; independent audit trail for all disbursements.":
        "CSR குழுவால் காலாண்டு மறுஆய்வு; அனைத்து செலுத்துதல்களுக்கும் சுயாதீன தணிக்கை பாதை.",
}

TREDS = {
    "Receivables Exchange of India Limited": "Receivables Exchange of India Limited",
    "Receivables Exchange of India Limited is one of the three RBI-regulated TReDS platforms.":
        "Receivables Exchange of India Limited, RBI-ஒழுங்குமுறைப்படுத்தும் மூன்று TReDS தளங்களில் ஒன்றாகும்.",
    "M1xchange": "M1xchange",
    "M1xchange is one of the three RBI-regulated TReDS platforms.":
        "M1xchange, RBI-ஒழுங்குமுறைப்படுத்தும் மூன்று TReDS தளங்களில் ஒன்றாகும்.",
    "Invoicemart": "Invoicemart",
    "Invoicemart is one of the three RBI-regulated TReDS platforms.":
        "Invoicemart, RBI-ஒழுங்குமுறைப்படுத்தும் மூன்று TReDS தளங்களில் ஒன்றாகும்.",
    "Trade Receivables Discounting System": "வர்த்தக பெறத்தக்கவை தள்ளுபடி முறைமை (TReDS)",
    "TReDS is an RBI-regulated electronic platform that enables MSMEs to discount invoices raised on large buyers, securing rapid working-capital liquidity through competitive financier bidding. Operating since 2017 across three platforms—RXIL, M1xchange, and Invoicemart.":
        "TReDS என்பது, பெரிய வாங்குபவர்கள் மீது எழுப்பப்படும் விலைப்பட்டியல்களை MSME-கள் தள்ளுபடி செய்ய உதவும் RBI-ஒழுங்குமுறைப்படுத்தும் மின்னணு தளமாகும்; போட்டி நிதியளிப்பாளர் ஏலம் மூலம் விரைவான செயல்பாட்டு மூலதன பணப்புழக்கத்தை உறுதி செய்கிறது. 2017 முதல் RXIL, M1xchange, மற்றும் Invoicemart ஆகிய மூன்று தளங்களில் செயல்பட்டு வருகிறது.",
    "TReDS adoption and throughput": "TReDS ஏற்றுக்கொள்ளல் மற்றும் செயல்திறன்",
    "Of 7.3+ crore Udyam-registered MSMEs, fewer than 1% are active TReDS sellers as of 2025–26. Cumulative TReDS throughput crossed ₹6.5 lakh crore, yet annual volumes (~₹2.5 lakh crore) remain a fraction of the estimated ₹10–12 lakh crore receivables-financing potential.":
        "7.3+ கோடி Udyam-பதிவு செய்யப்பட்ட MSME-களில், 2025-26 நிலவரப்படி 1%-க்கும் குறைவானவையே செயலில் உள்ள TReDS விற்பனையாளர்கள். ஒட்டுமொத்த TReDS செயல்திறன் ₹6.5 lakh crore-ஐ கடந்துவிட்டது, எனினும் ஆண்டு அளவுகள் (~₹2.5 lakh crore) மதிப்பிடப்பட்ட ₹10-12 lakh crore பெறத்தக்கவை-நிதியளிப்பு திறனில் ஒரு பகுதியாகவே உள்ளது.",
    "Structural barriers to small-MSME participation": "சிறு-MSME பங்கேற்புக்கான கட்டமைப்பு தடைகள்",
    "Credit-rating and KYC requirements, financier risk aversion toward unrated micro units, slow buyer-side invoice acceptance, fragmentation across platforms, weak digital literacy, and high relative transaction costs on small-ticket invoices.":
        "கடன்-தரவரிசை மற்றும் KYC தேவைகள், தரவரிசையிடப்படாத குறு அலகுகள் மீதான நிதியளிப்பாளர் அபாய தவிர்ப்பு, வாங்குபவர் பக்க விலைப்பட்டியல் ஏற்றுக்கொள்ளலின் மெதுவான வேகம், தளங்கள் முழுவதும் துண்டாடல், பலவீனமான டிஜிட்டல் அறிவு, மற்றும் சிறிய-தொகை விலைப்பட்டியல்களுக்கான உயர்ந்த ஒப்பீட்டு பரிவர்த்தனை செலவுகள்.",
    "Buyer reluctance and mandate under-compliance": "வாங்குபவர் தயக்கம் மற்றும் கட்டாய விதி குறை-இணக்கம்",
    "Despite the mandate for companies above ₹250 crore turnover and CPSEs, active large-buyer participation lags, delaying invoice acceptance beyond viable discounting windows.":
        "₹250 crore-க்கும் அதிகமான வருவாய் கொண்ட நிறுவனங்கள் மற்றும் CPSE-களுக்கான கட்டாய விதி இருந்தபோதிலும், செயலில் உள்ள பெரிய-வாங்குபவர் பங்கேற்பு பின்தங்கியுள்ளது, இது சாத்தியமான தள்ளுபடி காலப்பகுதியை மீறி விலைப்பட்டியல் ஏற்றுக்கொள்ளலை தாமதப்படுத்துகிறது.",
    "RBI interoperability framework": "RBI இயக்கூடுநிலைக் கட்டமைப்பு",
    "RBI's interoperability framework allows an invoice uploaded on one TReDS platform to be visible to financiers on all platforms, breaking platform-level lock-in. For small MSMEs this means wider financier access, sharper price discovery, lower discount rates through real competition, and reduced dependency on a single platform's financier base.":
        "RBI-யின் இயக்கூடுநிலைக் கட்டமைப்பு, ஒரு TReDS தளத்தில் பதிவேற்றப்பட்ட விலைப்பட்டியல் அனைத்து தளங்களிலும் உள்ள நிதியளிப்பாளர்களுக்குத் தெரியும்படி அனுமதிக்கிறது, இது தள-அளவிலான பூட்டு-இணைப்பை உடைக்கிறது. சிறு MSME-களுக்கு இது பரந்த நிதியளிப்பாளர் அணுகல், கூர்மையான விலை கண்டறிதல், உண்மையான போட்டி மூலம் குறைந்த தள்ளுபடி விகிதங்கள், மற்றும் ஒரே தளத்தின் நிதியளிப்பாளர் தளத்தை சார்ந்திருப்பதைக் குறைத்தல் ஆகியவற்றைக் குறிக்கிறது.",
    "Simplify onboarding": "இணைப்பு செயல்முறையை எளிமையாக்குதல்",
    "Auto-onboard via Udyam-GST linkage; waive external credit ratings for micro enterprises with invoices below ₹50 lakh.":
        "Udyam-GST இணைப்பு மூலம் தானாக இணைத்தல்; ₹50 lakh-க்குக் குறைவான விலைப்பட்டியல்கள் கொண்ட குறு நிறுவனங்களுக்கு வெளிப்புற கடன் தரவரிசைகளை தள்ளுபடி செய்தல்.",
    "Operationalise interoperability fully": "இயக்கூடுநிலையை முழுமையாக செயல்படுத்துதல்",
    "Mandate cross-platform bidding within a defined timeline and publish unified MIS dashboards.":
        "வரையறுக்கப்பட்ட காலக்கெடுவிற்குள் தள-குறுக்கு ஏலத்தை கட்டாயமாக்கி, ஒருங்கிணைந்த MIS டாஷ்போர்டுகளை வெளியிடவும்.",
    "Deep system integration": "ஆழமான அமைப்பு ஒருங்கிணைப்பு",
    "Connect TReDS with Udyam, GSTN, GeM, PFMS, and Account Aggregator stacks for one-click invoice flow and verification.":
        "ஒரு-கிளிக் விலைப்பட்டியல் ஓட்டம் மற்றும் சரிபார்ப்புக்காக TReDS-ஐ Udyam, GSTN, GeM, PFMS, மற்றும் கணக்கு திரட்டி அமைப்புகளுடன் இணைக்கவும்.",
    "Incentivise buyers and financiers": "வாங்குபவர்கள் மற்றும் நிதியளிப்பாளர்களை ஊக்குவித்தல்",
    "Expand the MSMED Act/CPSE mandate to all firms above ₹100 crore turnover; offer priority-sector benefits and refinance support to TReDS financiers focused on micro units.":
        "MSMED சட்டம்/CPSE கட்டாய விதியை ₹100 crore-க்கும் அதிகமான வருவாய் கொண்ட அனைத்து நிறுவனங்களுக்கும் விரிவுபடுத்தவும்; குறு அலகுகளில் கவனம் செலுத்தும் TReDS நிதியளிப்பாளர்களுக்கு முன்னுரிமைத் துறை பலன்கள் மற்றும் மறு-நிதியளிப்பு ஆதரவை வழங்கவும்.",
    "Technology upgrades": "தொழில்நுட்ப மேம்பாடுகள்",
    "API-first architecture, vernacular mobile apps, and AI/ML-based risk scoring leveraging GST and bank-statement data.":
        "API-முதன்மைக் கட்டமைப்பு, தாய்மொழி மொபைல் செயலிகள், மற்றும் GST மற்றும் வங்கிக் கணக்கு தரவுகளைப் பயன்படுத்தும் AI/ML-அடிப்படையிலான அபாய மதிப்பீடு.",
    "Awareness, hand-holding and fee relief": "விழிப்புணர்வு, வழிகாட்டுதல் மற்றும் கட்டண நிவாரணம்",
    "Cluster-level outreach with MSME-DFOs and DICs; cap or waive platform fees on invoices below ₹10 lakh.":
        "MSME-DFO-க்கள் மற்றும் DIC-களுடன் கொத்து-அளவிலான தொடர்பு; ₹10 lakh-க்குக் குறைவான விலைப்பட்டியல்கள் மீதான தள கட்டணங்களை வரம்பிடுதல் அல்லது தள்ளுபடி செய்தல்.",
    "Credit guarantees and co-lending": "கடன் உத்தரவாதங்கள் மற்றும் இணை-கடன் வழங்கல்",
    "Extend CGTMSE-style cover to TReDS factoring units and enable bank–NBFC–fintech co-lending for first-time micro sellers.":
        "TReDS ஃபேக்டரிங் அலகுகளுக்கு CGTMSE-பாணி காப்பீட்டை விரிவுபடுத்தி, முதல்முறை குறு விற்பனையாளர்களுக்கு வங்கி–NBFC–ஃபின்டெக் இணை-கடன் வழங்கலை செயல்படுத்தவும்.",
    "Strengthen buyer accountability": "வாங்குபவர் பொறுப்புக்கூறலை வலுப்படுத்துதல்",
    "Penalise delayed invoice acceptance beyond 7 days and link CPSE compliance to Budget 2026 procurement-linked incentives.":
        "7 நாட்களுக்கு மேல் தாமதமான விலைப்பட்டியல் ஏற்றுக்கொள்ளலுக்கு அபராதம் விதித்து, CPSE இணக்கத்தை பட்ஜெட் 2026 கொள்முதல்-தொடர்பான ஊக்கத்தொகைகளுடன் இணைக்கவும்.",
}

MSME_PRIVILEGE = {
    "Delayed Payment Protection (MSME Samadhaan)": "தாமத கட்டண பாதுகாப்பு (MSME சமாதான்)",
    "Buyers must pay MSE suppliers within 45 days of acceptance of goods/services; failing which compound interest applies at three times the RBI-notified bank rate, with monthly rests. Sections 20-21 authorise State Governments to establish Micro and Small Enterprise Facilitation Councils for dispute settlement.":
        "வாங்குபவர்கள், பொருட்கள்/சேவைகள் ஏற்றுக்கொள்ளப்பட்ட 45 நாட்களுக்குள் MSE வழங்குநர்களுக்குப் பணம் செலுத்த வேண்டும்; இல்லையெனில் RBI-அறிவித்த வங்கி விகிதத்தின் மூன்று மடங்கு கூட்டு வட்டி, மாதாந்திர இடைவெளிகளுடன் பொருந்தும். பிரிவுகள் 20-21, தகராறு தீர்வுக்காக குறு மற்றும் சிறு நிறுவன வசதியளிப்பு மன்றங்களை நிறுவ மாநில அரசுகளுக்கு அதிகாரம் அளிக்கின்றன.",
}

BUSINESS_ENABLEMENT = {
    "Udyam Registration (MSME Self-Registration)": "Udyam பதிவு (MSME சுய-பதிவு)",
    "Free, paperless, self-declaration-based MSME registration. Aadhaar number required initially; PAN and GSTIN retrieved automatically from government databases (mandatory since 1 April 2021). No fee is charged at any stage.":
        "இலவச, காகிதமற்ற, சுய-பிரகடன அடிப்படையிலான MSME பதிவு. ஆரம்பத்தில் ஆதார் எண் தேவை; PAN மற்றும் GSTIN அரசு தரவுத்தளங்களிலிருந்து தானாகப் பெறப்படும் (1 ஏப்ரல் 2021 முதல் கட்டாயம்). எந்த நிலையிலும் கட்டணம் வசூலிக்கப்படாது.",
    "MSME Cluster Development Programme -- duplicate label, business_enablement": None,  # placeholder removed below
    "CHAMPIONS Portal": "CHAMPIONS போர்ட்டல்",
    "\"Our Small Hands to make you LARGE\" -- platform for resolution, redressal and remedies for MSMEs, plus guidance and scheme information dissemination. Control rooms across states, nodal officer directories.":
        "\"Our Small Hands to make you LARGE\" -- MSME-களுக்கான தீர்வு, குறை தீர்த்தல் மற்றும் பரிகாரங்களுக்கான தளம், மேலும் வழிகாட்டுதல் மற்றும் திட்ட தகவல் பரப்புதல். மாநிலங்கள் முழுவதும் கட்டுப்பாட்டு அறைகள், நோடல் அதிகாரி அடைவுகள்.",
    "Startup India / DPIIT Recognition": "Startup India / DPIIT அங்கீகாரம்",
    "DPIIT recognition, BHASKAR startup registry, Seed Fund Scheme, National Startup Awards, and mentorship (MAARG) for the startup ecosystem.":
        "தொடக்க நிறுவன சூழலமைப்பிற்கான DPIIT அங்கீகாரம், BHASKAR தொடக்க நிறுவன பதிவேடு, Seed Fund திட்டம், தேசிய தொடக்க நிறுவன விருதுகள், மற்றும் வழிகாட்டுதல் (MAARG).",
}
del BUSINESS_ENABLEMENT["MSME Cluster Development Programme -- duplicate label, business_enablement"]
BUSINESS_ENABLEMENT["Application and support channel for Common Facility Centres and Infrastructure Development initiatives under the Cluster Development Programme framework."] = \
    "கொத்து மேம்பாட்டுத் திட்டக் கட்டமைப்பின் கீழ் பொது வசதி மையங்கள் மற்றும் உள்கட்டமைப்பு மேம்பாடு முன்முயற்சிகளுக்கான விண்ணப்ப மற்றும் ஆதரவு வழி."
# ENAB000002 reuses the exact same "name" string as CLUS000001
# ("MSME Cluster Development Programme") -- the CLUSTER_ASSISTANCE entry
# above already covers it via the shared OVR lookup table.

# ---- merge ------------------------------------------------------------
o["scheme"].update(SCHEME_NEW)
o["cluster_assistance"] = CLUSTER_ASSISTANCE
o["csr"] = CSR
o["treds"] = TREDS
o["msme_privilege"] = MSME_PRIVILEGE
o["business_enablement"] = BUSINESS_ENABLEMENT
o["_meta"]["batch"] = o["_meta"].get("batch", 0) + 1
o["_meta"]["note"] += " Batch " + str(o["_meta"]["batch"]) + " (2026-08-15, Tamil Localization Completion Phase): SCH000218/SCH000219 + 5 previously zero-coverage catalogs."

json.dump(o, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("ta_overrides.json updated. New section sizes:")
for k in ("scheme", "cluster_assistance", "csr", "treds", "msme_privilege", "business_enablement"):
    print(f"   {k:20} {len(o[k])}")
