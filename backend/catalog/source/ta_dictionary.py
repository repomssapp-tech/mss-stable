# -*- coding: utf-8 -*-
"""Formal Tamil government terminology for MSS. Hand-authored, reusable across catalogs."""

# Acronyms preserved verbatim in Tamil text (never transliterated, never translated).
ACRONYMS = [
    "MSME", "MSMEs", "PMEGP", "PMMY", "PMKVY", "PMMVY", "PMUY", "PMSVANidhi", "CGTMSE",
    "SIDBI", "NSIC", "KVIC", "GST", "PAN", "TAN", "UDYAM", "Udyam", "DGFT", "DIC", "DICs",
    "IEC", "QRMP", "DPIIT", "NABARD", "RBI", "AIM", "ATL", "AIC", "BIRAC", "NITI", "GVY",
    "SPRS", "ZED", "LEAN", "MSEFC", "SAMADHAAN", "TReDS", "CSR", "SHG", "SHGs", "NGO",
    "EDII", "TIIC", "SIPCOT", "TANGEDCO", "MUDRA", "NCGTC", "DDU-GKY", "DAY-NRLM",
    "DAY-NULM", "EPCG", "SION", "FTP", "AIF", "AIFs", "SEBI", "LLP", "R&D", "IPR", "GeM",
    "MSE", "MSEs", "ARISE", "SAFE", "SPEED", "NEEDS", "UYEGP", "AABCS", "ESDP", "ATI",
    "CLCSS", "MSE-CDP", "MCDP", "BBBP", "MPDA", "SC", "ST", "OBC", "IT", "FSSAI", "CIN",
    # Added Tamil Localization Completion Phase (2026-08-15), Task 1 --
    # PMFME's own scheme-family acronyms, missed by the original list.
    "PMFME", "CGFSIL", "ODOP", "FPO", "FPOs", "MOFPI",
]

# --------------------------------------------------------------------- core terms
TERMS = {
    # governance
    "Government": "அரசு",
    "Government of India": "இந்திய அரசு",
    "Union Government": "மத்திய அரசு",
    "Government of Tamil Nadu": "தமிழ்நாடு அரசு",
    "Central Government": "மத்திய அரசு",
    "State Government": "மாநில அரசு",
    "Ministry": "அமைச்சகம்",
    "Department": "துறை",
    "Directorate": "இயக்குநரகம்",
    "Commissionerate": "ஆணையரகம்",
    "Statutory Board": "சட்டப்பூர்வ வாரியம்",
    "Board": "வாரியம்",
    "Commission": "ஆணையம்",
    "Government Corporation": "அரசு கழகம்",
    "Corporation": "கழகம்",
    "Council": "மன்றம்",
    "Authority": "அதிகாரசபை",
    "Agency": "முகமை",
    "Mission": "இயக்கம்",
    "Bureau": "பணியகம்",
    "Office": "அலுவலகம்",
    "Institute": "நிறுவனம்",
    "Centre": "மையம்",
    "District Industries Centre": "மாவட்டத் தொழில் மையம்",
    "District Industries Centres": "மாவட்டத் தொழில் மையங்கள்",
    "Facilitation Council": "வசதியளிப்பு மன்றம்",
    "Regulator": "ஒழுங்குமுறை ஆணையம்",
    "Development Commissioner": "வளர்ச்சி ஆணையர்",
    "Public Sector Undertaking": "பொதுத்துறை நிறுவனம்",
    "Development Finance Institution": "வளர்ச்சி நிதி நிறுவனம்",
    "Bank": "வங்கி",
    "Incubator": "தொழில் வளர்ப்பகம்",
    "Training Institute": "பயிற்சி நிறுவனம்",
    "Industry Association": "தொழில் சங்கம்",
    "Statutory Body": "சட்டப்பூர்வ அமைப்பு",

    # enterprise
    "Micro Enterprise": "குறு நிறுவனம்",
    "Small Enterprise": "சிறு நிறுவனம்",
    "Medium Enterprise": "நடுத்தர நிறுவனம்",
    "Enterprise": "நிறுவனம்",
    "Enterprises": "நிறுவனங்கள்",
    "Micro": "குறு",
    "Small": "சிறு",
    "Medium": "நடுத்தர",
    "Startup": "தொடக்க நிறுவனம்",
    "Self-Help Group": "சுய உதவிக் குழு",
    "Cooperative Society": "கூட்டுறவுச் சங்கம்",
    "Proprietorship": "தனியுரிமை நிறுவனம்",
    "Partnership Firm": "கூட்டாண்மை நிறுவனம்",
    "Limited Liability Partnership": "வரையறுக்கப்பட்ட பொறுப்புக் கூட்டாண்மை",
    "Company": "கம்பெனி",
    "Trust": "அறக்கட்டளை",
    "Society": "சங்கம்",
    "Section 8 Company": "பிரிவு 8 கம்பெனி",
    "Manufacturing": "உற்பத்தி",
    "Services": "சேவைகள்",
    "Service": "சேவை",
    "Trading": "வணிகம்",

    # stages
    "Idea Stage": "கருத்து நிலை",
    "New / Greenfield": "புதிய நிறுவனம்",
    "Existing / Operating": "இயங்கும் நிறுவனம்",
    "Expansion": "விரிவாக்கம்",
    "Diversification": "பன்முகப்படுத்தல்",
    "Modernisation": "நவீனமயமாக்கல்",
    "Revival / Rehabilitation": "மறுசீரமைப்பு",

    # beneficiaries
    "Women": "மகளிர்",
    "Scheduled Caste": "பட்டியலின மக்கள்",
    "Scheduled Tribe": "பட்டியல் பழங்குடியினர்",
    "Other Backward Classes": "பிற பிற்படுத்தப்பட்ட வகுப்பினர்",
    "Minority": "சிறுபான்மையினர்",
    "Differently Abled": "மாற்றுத்திறனாளிகள்",
    "Transgender": "திருநர்",
    "Ex-Servicemen": "முன்னாள் படைவீரர்கள்",
    "Youth": "இளைஞர்கள்",
    "Artisan": "கைவினைஞர்",
    "Farmer": "விவசாயி",
    "Student": "மாணவர்",
    "First-Generation Entrepreneur": "முதல் தலைமுறைத் தொழில்முனைவோர்",
    "Rural": "கிராமப்புற",
    "Urban": "நகர்ப்புற",
    "Below Poverty Line": "வறுமைக் கோட்டிற்குக் கீழ்",
    "Orphan": "அனாதை",
    "Widow": "விதவை",
    "Entrepreneur": "தொழில்முனைவோர்",
    "Beneficiary": "பயனாளி",
    "Applicant": "விண்ணப்பதாரர்",

    # benefits / finance
    "Capital Subsidy": "மூலதன மானியம்",
    "Subsidy": "மானியம்",
    "Interest Subvention": "வட்டி மானியம்",
    "Interest Subsidy": "வட்டி மானியம்",
    "Margin Money": "விளிம்பு நிதி",
    "Grant": "நிதியுதவி",
    "Grant-in-Aid": "நிதியுதவி",
    "Loan": "கடன்",
    "Term Loan": "கால கடன்",
    "Working Capital Loan": "சுழல் மூலதனக் கடன்",
    "Working Capital": "சுழல் மூலதனம்",
    "Equipment Loan": "உபகரணக் கடன்",
    "Collateral-Free Loan": "அடைமானமில்லாக் கடன்",
    "Bill Discounting": "மாற்றுச்சீட்டு தள்ளுபடி",
    "Composite Loan": "கூட்டுக் கடன்",
    "Soft Loan": "தளர்வான கடன்",
    "Refinance": "மறுநிதியளிப்பு",
    "Tax Benefit": "வரிச் சலுகை",
    "Reimbursement": "திருப்பிச் செலுத்துதல்",
    "Equity Support": "பங்கு முதலீட்டு உதவி",
    "Credit Guarantee": "கடன் உத்தரவாதம்",
    "Guarantee": "உத்தரவாதம்",
    "Insurance": "காப்பீடு",
    "Training Support": "பயிற்சி உதவி",
    "Market Support": "சந்தை உதவி",
    "Technology Support": "தொழில்நுட்ப உதவி",
    "Financial Assistance": "நிதி உதவி",
    "Credit": "கடன்",
    "Finance": "நிதி",
    "Investment": "முதலீடு",
    "Capital": "மூலதனம்",
    "Interest": "வட்டி",
    "Collateral": "அடைமானம்",

    # tax
    "Goods and Services Tax": "சரக்கு மற்றும் சேவை வரி",
    "Income Tax": "வருமான வரி",
    "Corporate Tax": "நிறுவன வரி",
    "Composition Scheme": "தொகுப்புத் திட்டம்",
    "Customs Duty": "சுங்க வரி",
    "Stamp Duty": "முத்திரைத் தீர்வை",
    "Electricity Tax": "மின் வரி",
    "Tax": "வரி",

    # registration / compliance
    "Udyam Registration": "Udyam பதிவு",
    "Entrepreneur Memorandum Part II": "தொழில்முனைவோர் குறிப்பாணை பகுதி II",
    "DPIIT Startup Recognition": "DPIIT தொடக்க நிறுவன அங்கீகாரம்",
    "Importer-Exporter Code": "இறக்குமதி-ஏற்றுமதி குறியீடு",
    "GST Registration": "GST பதிவு",
    "NSIC Single Point Registration": "NSIC ஒற்றைப் புள்ளிப் பதிவு",
    "Shops and Establishments Registration": "கடைகள் மற்றும் நிறுவனங்கள் பதிவு",
    "Factory Licence": "தொழிற்சாலை உரிமம்",
    "FSSAI Licence": "FSSAI உரிமம்",
    "Corporate Identity Number": "நிறுவன அடையாள எண்",
    "Registration": "பதிவு",
    "GST Return Filing": "GST வரி தாக்கல்",
    "Income Tax Return": "வருமான வரி தாக்கல்",
    "Annual Return": "ஆண்டு தாக்கல்",
    "Udyam Annual Update": "Udyam ஆண்டு புதுப்பிப்பு",
    "Pollution Control Consent": "மாசுக் கட்டுப்பாட்டு ஒப்புதல்",
    "Labour Return": "தொழிலாளர் தாக்கல்",

    # documents
    "Enterprise Registration Proof": "நிறுவனப் பதிவுச் சான்று",
    "Identity Proof": "அடையாளச் சான்று",
    "Address Proof": "முகவரிச் சான்று",
    "Constitution Document": "அமைப்பு ஆவணம்",
    "Land / Property Document": "நிலம் / சொத்து ஆவணம்",
    "Financial Statement": "நிதி அறிக்கை",
    "Bank Document": "வங்கி ஆவணம்",
    "Project Report": "திட்ட அறிக்கை",
    "Invoice / Purchase Proof": "விலைப்பட்டியல் / கொள்முதல் சான்று",
    "Certificate": "சான்றிதழ்",
    "Category / Community Proof": "வகை / சமுதாயச் சான்று",
    "Application Form": "விண்ணப்பப் படிவம்",
    "Other Supporting Document": "பிற ஆதரவு ஆவணம்",
    "Document": "ஆவணம்",

    # scheme types
    "Credit-Linked Subsidy": "கடன் இணைந்த மானியம்",
    "Loan / Term Finance": "கடன் / கால நிதி",
    "Grant / Grant-in-Aid": "நிதியுதவி",
    "Equity / Venture Funding": "பங்கு / துணிகர நிதியளிப்பு",
    "Training / Skill Development": "பயிற்சி / திறன் மேம்பாடு",
    "Market / Export Promotion": "சந்தை / ஏற்றுமதி ஊக்குவிப்பு",
    "Technology / Innovation Support": "தொழில்நுட்ப / புத்தாக்க உதவி",
    "Infrastructure Support": "உள்கட்டமைப்பு உதவி",
    "Social / Welfare Assistance": "சமூக / நல உதவி",
    "Startup Support": "தொடக்க நிறுவன உதவி",
    "Event / Exhibition Support": "நிகழ்வு / கண்காட்சி உதவி",
    "Public Procurement Access": "பொதுக் கொள்முதல் அணுகல்",
    "Energy / Utility Support": "எரிசக்தி / பயன்பாட்டு உதவி",
    "Operating / Location Incentive": "இயக்க / இட ஊக்கத்தொகை",
    "Certification / Quality Support": "சான்றளிப்பு / தர உதவி",
    "Facilitation / Handholding": "வசதியளிப்பு / கைகொடுத்தல்",

    # general
    "Scheme": "திட்டம்",
    "Schemes": "திட்டங்கள்",
    "Policy": "கொள்கை",
    "Guidelines": "வழிகாட்டு நெறிமுறைகள்",
    "Act": "சட்டம்",
    "Notification": "அறிவிக்கை",
    "Circular": "சுற்றறிக்கை",
    "Government Order": "அரசாணை",
    "Eligibility": "தகுதி",
    "Application": "விண்ணப்பம்",
    "Online": "இணையவழி",
    "Offline": "நேரடி",
    "Website": "இணையதளம்",
    "Contact": "தொடர்பு",
    "Helpline": "உதவி எண்",
    "Skill Development": "திறன் மேம்பாடு",
    "Innovation": "புத்தாக்கம்",
    "Technology": "தொழில்நுட்பம்",
    "Infrastructure": "உள்கட்டமைப்பு",
    "Cluster": "கொத்து",
    "Export": "ஏற்றுமதி",
    "Import": "இறக்குமதி",
    "Market": "சந்தை",
    "Marketing": "சந்தைப்படுத்தல்",
    "Employment": "வேலைவாய்ப்பு",
    "Livelihood": "வாழ்வாதாரம்",
    "Welfare": "நலன்",
    "Education": "கல்வி",
    "Health": "சுகாதாரம்",
    "Agriculture": "வேளாண்மை",
    "Food Processing": "உணவுப் பதப்படுத்துதல்",
    "Textile": "ஜவுளி",
    "Handicraft": "கைவினைப் பொருள்",
    "Coir": "தென்னைநார்",
    "Khadi": "காதி",
    "Village Industries": "கிராமத் தொழில்கள்",
    "Rural Development": "ஊரக வளர்ச்சி",
    "Women and Child Development": "மகளிர் மற்றும் குழந்தைகள் மேம்பாடு",
    "Commerce and Industry": "வணிகம் மற்றும் தொழில்",
    "Science and Technology": "அறிவியல் மற்றும் தொழில்நுட்பம்",
    "Biotechnology": "உயிரித் தொழில்நுட்பம்",
    "Social Justice and Empowerment": "சமூக நீதி மற்றும் அதிகாரமளித்தல்",
    "Housing and Urban Affairs": "வீட்டுவசதி மற்றும் நகர்ப்புற விவகாரங்கள்",
    "Minority Affairs": "சிறுபான்மையினர் நலன்",
    "Home Affairs": "உள்துறை",
    "Tourism": "சுற்றுலா",
    "Petroleum and Natural Gas": "பெட்ரோலியம் மற்றும் இயற்கை எரிவாயு",
    "Skill Development and Entrepreneurship": "திறன் மேம்பாடு மற்றும் தொழில்முனைவு",
    "Foreign Trade": "வெளிநாட்டு வர்த்தகம்",
    "Financial Services": "நிதிச் சேவைகள்",
    "Social Welfare and Women Empowerment": "சமூக நலன் மற்றும் மகளிர் அதிகாரமளித்தல்",

    # named institutions (acronyms preserved separately by the masker)
    "Small Industries Development Bank of India": "இந்திய சிறுதொழில் வளர்ச்சி வங்கி",
    "National Small Industries Corporation": "தேசிய சிறுதொழில் கழகம்",
    "Khadi and Village Industries Commission": "காதி மற்றும் கிராமத் தொழில்கள் ஆணையம்",
    "Coir Board": "தென்னைநார் வாரியம்",
    "Spices Board": "வாசனைப் பொருள் வாரியம்",
    "Spices Board India": "இந்திய வாசனைப் பொருள் வாரியம்",
    "Directorate General of Foreign Trade": "வெளிநாட்டு வர்த்தக இயக்குநரகம்",
    "Department for Promotion of Industry and Internal Trade":
        "தொழில் மற்றும் உள்நாட்டு வர்த்தக ஊக்குவிப்புத் துறை",
    "National Bank for Agriculture and Rural Development":
        "தேசிய வேளாண்மை மற்றும் ஊரக வளர்ச்சி வங்கி",
    "Reserve Bank of India": "இந்திய ரிசர்வ் வங்கி",
    "Atal Innovation Mission": "அடல் புத்தாக்க இயக்கம்",
    "Biotechnology Industry Research Assistance Council":
        "உயிரித் தொழில்நுட்பத் தொழில் ஆராய்ச்சி உதவி மன்றம்",
    "Credit Guarantee Fund Trust for Micro and Small Enterprises":
        "குறு மற்றும் சிறு நிறுவனங்களுக்கான கடன் உத்தரவாத நிதி அறக்கட்டளை",
    "Tamil Nadu Industrial Investment Corporation":
        "தமிழ்நாடு தொழில் முதலீட்டுக் கழகம்",
    "Tamil Nadu Generation and Distribution Corporation":
        "தமிழ்நாடு மின் உற்பத்தி மற்றும் பகிர்மானக் கழகம்",
    "Entrepreneurship Development and Innovation Institute":
        "தொழில்முனைவு மேம்பாடு மற்றும் புத்தாக்க நிறுவனம்",
    "Office of Development Commissioner": "வளர்ச்சி ஆணையர் அலுவலகம்",
    "Micro, Small and Medium Enterprises": "குறு, சிறு மற்றும் நடுத்தர நிறுவனங்கள்",
    "Micro and Small Enterprises": "குறு மற்றும் சிறு நிறுவனங்கள்",
    "Micro, Small and Medium Enterprises Department":
        "குறு, சிறு மற்றும் நடுத்தர நிறுவனங்கள் துறை",
    "Tamil Nadu Micro, Small and Medium Enterprises Department":
        "தமிழ்நாடு குறு, சிறு மற்றும் நடுத்தர நிறுவனங்கள் துறை",
    "Ministry of Micro, Small and Medium Enterprises":
        "குறு, சிறு மற்றும் நடுத்தர நிறுவனங்கள் அமைச்சகம்",
    "Development Commissioner (MSME)": "வளர்ச்சி ஆணையர் (MSME)",
    "National SC-ST Hub": "தேசிய SC-ST மையம்",
    "Startup India": "Startup India",
    "Make in India": "Make in India",
    "Rural Development": "ஊரக வளர்ச்சி",
    "Finance": "நிதி",
}

# --------------------------------------------------------------------- geography
STATES_TA = {
    "Tamil Nadu": "தமிழ்நாடு", "Kerala": "கேரளா", "Karnataka": "கர்நாடகா",
    "Andhra Pradesh": "ஆந்திரப் பிரதேசம்", "Telangana": "தெலங்கானா",
    "Maharashtra": "மகாராஷ்டிரா", "Gujarat": "குஜராத்", "Rajasthan": "ராஜஸ்தான்",
    "Delhi": "டெல்லி", "Punjab": "பஞ்சாப்", "Haryana": "ஹரியானா", "Bihar": "பீகார்",
    "West Bengal": "மேற்கு வங்கம்", "Odisha": "ஒடிசா", "Assam": "அசாம்", "Goa": "கோவா",
    "Jharkhand": "ஜார்க்கண்ட்", "Chhattisgarh": "சத்தீஸ்கர்",
    "Madhya Pradesh": "மத்தியப் பிரதேசம்", "Uttar Pradesh": "உத்தரப் பிரதேசம்",
    "Uttarakhand": "உத்தராகண்ட்", "Himachal Pradesh": "இமாசலப் பிரதேசம்",
    "Jammu and Kashmir": "ஜம்மு காஷ்மீர்", "Ladakh": "லடாக்",
    "Arunachal Pradesh": "அருணாசலப் பிரதேசம்", "Assam ": "அசாம்",
    "Manipur": "மணிப்பூர்", "Meghalaya": "மேகாலயா", "Mizoram": "மிசோரம்",
    "Nagaland": "நாகாலாந்து", "Sikkim": "சிக்கிம்", "Tripura": "திரிபுரா",
    "Puducherry": "புதுச்சேரி", "Chandigarh": "சண்டிகர்", "Lakshadweep": "லட்சத்தீவு",
    "Andaman and Nicobar Islands": "அந்தமான் நிக்கோபார் தீவுகள்",
    "Dadra and Nagar Haveli and Daman and Diu": "தாத்ரா நகர் ஹவேலி மற்றும் டாமன் தியூ",
}

DISTRICTS_TA = {
    "Ariyalur": "அரியலூர", "Chengalpattu": "செங்கல்பட்டு", "Chennai": "சென்னை",
    "Coimbatore": "கோயம்புத்தூர்", "Cuddalore": "கடலூர்", "Dharmapuri": "தருமபுரி",
    "Dindigul": "திண்டுக்கல்", "Erode": "ஈரோடு", "Kallakurichi": "கள்ளக்குறிச்சி",
    "Kancheepuram": "காஞ்சிபுரம்", "Kanniyakumari": "கன்னியாகுமரி", "Karur": "கரூர்",
    "Krishnagiri": "கிருஷ்ணகிரி", "Madurai": "மதுரை", "Mayiladuthurai": "மயிலாடுதுறை",
    "Nagapattinam": "நாகப்பட்டினம்", "Namakkal": "நாமக்கல்", "Nilgiris": "நீலகிரி",
    "Perambalur": "பெரம்பலூர்", "Pudukkottai": "புதுக்கோட்டை",
    "Ramanathapuram": "ராமநாதபுரம்", "Ranipet": "இராணிப்பேட்டை", "Salem": "சேலம்",
    "Sivaganga": "சிவகங்கை", "Tenkasi": "தென்காசி", "Thanjavur": "தஞ்சாவூர்",
    "Theni": "தேனி", "Thoothukudi": "தூத்துக்குடி",
    "Tiruchirappalli": "திருச்சிராப்பள்ளி", "Tirunelveli": "திருநெல்வேலி",
    "Tirupathur": "திருப்பத்தூர்", "Tiruppur": "திருப்பூர்", "Tiruvallur": "திருவள்ளூர்",
    "Tiruvannamalai": "திருவண்ணாமலை", "Tiruvarur": "திருவாரூர்", "Vellore": "வேலூர்",
    "Viluppuram": "விழுப்புரம்", "Virudhunagar": "விருதுநகர்",
}

# single-word search keywords
KEYWORDS_TA = {
    "loan": "கடன்", "subsidy": "மானியம்", "grant": "நிதியுதவி", "training": "பயிற்சி",
    "women": "மகளிர்", "export": "ஏற்றுமதி", "market": "சந்தை", "credit": "கடன்",
    "capital": "மூலதனம்", "interest": "வட்டி", "guarantee": "உத்தரவாதம்",
    "technology": "தொழில்நுட்பம்", "innovation": "புத்தாக்கம்", "startup": "தொடக்கநிறுவனம்",
    "manufacturing": "உற்பத்தி", "service": "சேவை", "services": "சேவைகள்",
    "rural": "கிராமப்புற", "urban": "நகர்ப்புற", "employment": "வேலைவாய்ப்பு",
    "development": "வளர்ச்சி", "assistance": "உதவி", "support": "உதவி",
    "scheme": "திட்டம்", "programme": "திட்டம்", "fund": "நிதி", "finance": "நிதி",
    "investment": "முதலீடு", "insurance": "காப்பீடு", "welfare": "நலன்",
    "education": "கல்வி", "skill": "திறன்", "artisan": "கைவினைஞர்",
    "agriculture": "வேளாண்மை", "food": "உணவு", "textile": "ஜவுளி", "coir": "தென்னைநார்",
    "khadi": "காதி", "village": "கிராமம்", "incubation": "வளர்ப்பகம்",
    "cluster": "கொத்து", "infrastructure": "உள்கட்டமைப்பு", "certification": "சான்றளிப்பு",
    "quality": "தரம்", "design": "வடிவமைப்பு", "research": "ஆராய்ச்சி",
    "entrepreneur": "தொழில்முனைவோர்", "entrepreneurship": "தொழில்முனைவு",
    "enterprise": "நிறுவனம்", "enterprises": "நிறுவனங்கள்", "industry": "தொழில்",
    "industries": "தொழில்கள்", "business": "வணிகம்", "girl": "பெண்குழந்தை",
    "child": "குழந்தை", "marriage": "திருமணம்", "housing": "வீட்டுவசதி",
    "energy": "எரிசக்தி", "power": "மின்சாரம்", "equipment": "உபகரணம்",
    "machinery": "இயந்திரம்", "portal": "வலைவாயில்", "registration": "பதிவு",
    "tax": "வரி", "duty": "தீர்வை", "import": "இறக்குமதி", "exhibition": "கண்காட்சி",
    "procurement": "கொள்முதல்", "tender": "ஒப்பந்தப்புள்ளி", "reimbursement": "திருப்பிச்செலுத்தல்",
    "equity": "பங்கு", "venture": "துணிகரம்", "seed": "விதைநிதி", "mission": "இயக்கம்",
    "council": "மன்றம்", "board": "வாரியம்", "corporation": "கழகம்",
    "commission": "ஆணையம்", "ministry": "அமைச்சகம்", "department": "துறை",
    "authority": "அதிகாரசபை", "agency": "முகமை", "institute": "நிறுவனம்",
    "centre": "மையம்", "national": "தேசிய", "state": "மாநில", "central": "மத்திய",
    "district": "மாவட்டம்", "bank": "வங்கி", "beneficiary": "பயனாளி",
    # Added Tamil Localization Completion Phase (2026-08-15), Task 1 --
    # search-keyword gaps found while localizing SCH000218/SCH000219.
    "india": "இந்தியா", "greenfield": "கிரீன்ஃபீல்ட்", "composite": "கூட்டு",
    "margin": "மார்ஜின்", "processing": "பதப்படுத்தல்", "micro": "குறு",
    "product": "தயாரிப்பு", "one": "ஒரு",
}

# ---------------------------------------------------------------------
# Added Tamil Localization Completion Phase (2026-08-15), Task 3 -- reusable
# cross-catalog terminology extracted while covering cluster_assistance,
# csr, treds, msme_privilege and business_enablement. Kept in TERMS (the
# same reusable, compositional dictionary tier as every other entry above)
# rather than as one-off overrides, per "add terminology through the
# dictionary first, do not create one-off translations." Each entry also
# gets a metadata record below (domain/confidence/source) purely for the
# translation_dictionary.json artifact -- it does not change how translate()
# looks the term up.
DOMAIN_TERMS = {
    "Common Facility Centre": "பொது வசதி மையம்",
    "Common Facility Centres": "பொது வசதி மையங்கள்",
    "Cluster Development Programme": "கொத்து மேம்பாட்டுத் திட்டம்",
    "Infrastructure Development": "உள்கட்டமைப்பு மேம்பாடு",
    "Corporate Social Responsibility": "பெருநிறுவன சமூகப் பொறுப்பு",
    "Companies Act 2013": "நிறுவனங்கள் சட்டம் 2013",
    "Implementing Agency": "செயல்படுத்தும் முகமை",
    "Trade Receivables Discounting System": "வர்த்தக பெறத்தக்கவை தள்ளுபடி முறைமை",
    "Receivables Exchange": "பெறத்தக்கவை பரிவர்த்தனை மையம்",
    "working capital": "செயல்பாட்டு மூலதனம்",
    "self-declaration": "சுய-பிரகடனம்",
    "credit rating": "கடன் தரவரிசை",
    "invoice": "விலைப்பட்டியல்",
    "discounting": "தள்ளுபடி",
    "financier": "நிதியளிப்பாளர்",
    "onboarding": "இணைப்பு செயல்முறை",
    "buyer": "வாங்குபவர்",
    "seller": "விற்பனையாளர்",
    "platform": "தளம்",
    "Schedule VII": "அட்டவணை VII",
    "interest rate": "வட்டி விகிதம்",
    "bank rate": "வங்கி விகிதம்",
    "paperless": "காகிதமற்ற",
    "dispute settlement": "தகராறு தீர்வு",
}
TERMS.update(DOMAIN_TERMS)

# ---------------------------------------------------------------------
# Final Localization Release Gate (2026-08-15), Part 4/5 -- the required
# technical-terms table (translation_terminology_dictionary.json) plus
# the Category A (transliterate) protected terms. Added to TERMS/
# KEYWORDS_TA -- the same two reusable, compositional dictionaries every
# other entry in this file already lives in -- not a separate mechanism.
CATEGORY_A_TRANSLITERATIONS = {
    "MSME": "எம் எஸ் எம் ஈ",
    "GST": "ஜி எஸ் டி",
    "EMI": "இ எம் ஐ",
}
CATEGORY_B_GLOSSED = {
    # Category B: preserve the official abbreviation verbatim; the
    # parenthetical is a plain-language gloss, not a translation of the
    # abbreviation itself. IDs/references are never touched by any of this.
    "PMEGP": "PMEGP (பிரதம மந்திரி வேலை வாய்ப்பு உருவாக்கத் திட்டம்)",
    "PMMY": "PMMY (பிரதான் மந்திரி முத்ரா யோஜனா)",
    "CGTMSE": "CGTMSE (கடன் உத்தரவாத திட்டம்)",
    "SIDBI": "SIDBI (சிறு தொழில் வளர்ச்சி வங்கி)",
    "TReDS": "TReDS (வர்த்தக பெறத்தக்கவை தள்ளுபடி முறைமை)",
    "DPIIT": "DPIIT (தொழில் மற்றும் உள்நாட்டு வர்த்தக மேம்பாட்டுத் துறை)",
    "PMFME": "PMFME (குறு உணவுப் பதப்படுத்தல் முறைப்படுத்தல் திட்டம்)",
    "ODOP": "ODOP (ஒரு மாவட்டம் ஒரு தயாரிப்பு)",
}
TECHNICAL_TERMS_TABLE = {
    "Startup": "தொடக்க நிறுவனம்",
    "Subsidy": "மானியம்",
    "Capital Subsidy": "மூலதன மானியம்",
    "Loan": "கடன்",
    "Interest Subsidy": "வட்டி மானியம்",
    "Working Capital": "செயல்பாட்டு மூலதனம்",
    "Collateral": "பிணையம்",
    "Eligibility": "தகுதி",
    "Benefits": "நன்மைகள்",
    "Application Process": "விண்ணப்ப செயல்முறை",
    "Documents Required": "தேவையான ஆவணங்கள்",
}
TERMS.update(TECHNICAL_TERMS_TABLE)
# Category B stays OUT of TERMS -- these must not silently substitute for
# the bare abbreviation wherever it appears in prose (that would break the
# "preserve unchanged" rule for IDs/references that happen to share the
# abbreviation's text). They are offered separately for a client that
# explicitly wants the glossed display form.

KEYWORDS_TA.update({
    "msme": CATEGORY_A_TRANSLITERATIONS["MSME"],
    "gst": CATEGORY_A_TRANSLITERATIONS["GST"],
    "emi": CATEGORY_A_TRANSLITERATIONS["EMI"],
    "collateral": TECHNICAL_TERMS_TABLE["Collateral"],
    "eligibility": TECHNICAL_TERMS_TABLE["Eligibility"],
    "benefit": TECHNICAL_TERMS_TABLE["Benefits"],
    "benefits": TECHNICAL_TERMS_TABLE["Benefits"],
})

DOMAIN_TERMS_META = {
    en: {"domain": dom, "confidence": "medium", "source": "llm_contextual_translation"}
    for en, dom in {
        "Common Facility Centre": "cluster_assistance", "Common Facility Centres": "cluster_assistance",
        "Cluster Development Programme": "cluster_assistance", "Infrastructure Development": "cluster_assistance",
        "Corporate Social Responsibility": "csr", "Companies Act 2013": "csr",
        "Implementing Agency": "csr", "dispute settlement": "msme_privilege",
        "Trade Receivables Discounting System": "treds", "Receivables Exchange": "treds",
        "working capital": "treds", "credit rating": "treds", "invoice": "treds",
        "discounting": "treds", "financier": "treds", "onboarding": "treds",
        "buyer": "treds", "seller": "treds", "platform": "treds",
        "Schedule VII": "csr", "interest rate": "msme_privilege", "bank rate": "msme_privilege",
        "paperless": "business_enablement", "self-declaration": "business_enablement",
    }.items()
}

def all_pairs():
    """Every English -> Tamil pair for the dictionary artifact."""
    out = {}
    for src, d in (("term", TERMS), ("state", STATES_TA),
                   ("district", DISTRICTS_TA), ("keyword", KEYWORDS_TA)):
        for en, ta in d.items():
            entry = {"ta": ta, "category": src}
            if en in DOMAIN_TERMS_META:
                entry.update(DOMAIN_TERMS_META[en])
            out.setdefault(en, entry)
    return out
