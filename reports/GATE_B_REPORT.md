================================================================================
GATE B DELIVERABLE 1: VALIDATOR OUTPUT
================================================================================
===========================================================================
CATALOG V3.1 STRICT SHAPE VALIDATOR (GATE B REMEDIATION)
===========================================================================

1. Validating 302 schemes against reference contract SCH000124...
   [PASS] 0 failures across all 302 schemes! Structure is 100% compliant.

2. Validating 302 applicability matrices against reference APLM000124...
   [PASS] 0 failures across all 302 matrices! Structure is 100% compliant.

3. Validating search index entries against reference SCH000124...
   [PASS] 0 failures across all search entries! Structure is 100% compliant.

===========================================================================
ALL VALIDATION CHECKS PASSED: 0 FAILURES
===========================================================================


================================================================================
GATE B DELIVERABLE 2: 3 FULL BEFORE/AFTER DIFFS
================================================================================

### BEFORE/AFTER DIFF: SCH000255 - MCGS (Mutual Credit Guarantee Scheme for MSMEs)
```diff
--- a/SCH000255_before.json
+++ b/SCH000255_after.json
@@ -1,30 +1,46 @@
 {
-  "classification": {
-    "category": "financial_support",
-    "government": {
-      "departmentText": "Department of Financial Services / National Credit Guarantee Trustee Company Ltd (NCGTC)",
-      "implementingAgencyIds": [],
-      "level": "central",
-      "ministryId": "AUTH000009",
-      "ministryText": "Ministry of Finance"
-    },
-    "schemeType": "credit_guarantee",
-    "tags": [
-      "credit_guarantee",
-      "export",
-      "exporter",
-      "manufacturing",
-      "medium_enterprise",
-      "micro_enterprise",
-      "services",
-      "small_enterprise"
-    ]
+  "ai": {
+    "confidence": null,
+    "generatedAt": "2026-10-04T00:00:00Z",
+    "generatedBy": "build_scheme_catalog.py-1.0.0",
+    "generationMode": "mechanical_derivation",
+    "isApproved": false,
+    "recommendations": [],
+    "recommendationsNote": null,
+    "relatedEntities": [],
+    "reviewRequired": true,
+    "reviewedAt": null,
+    "reviewedBy": null,
+    "sectionSummaries": {
+      "benefits": "60% guarantee coverage by NCGTC on the loan. Loan amount guaranteed up to ₹100 crore (project can be larger). Repayment up to 8 years with up to 2 years moratorium for loans up to ₹50 crore; flexible schedule for larger loans. Upfront contribution of 5% of loan amount at application (refundable 1% each year from 4th year). Annual guarantee fee: nil in year of sanction; 1.5% p.a. for next 3 years; 1% p.a. thereafter. Exporter MSMEs: 75% guarantee cover for loans up to ₹20 crore; upfront contribution 2% (max ₹40 lakh); fee nil in first year and 0.50% p.a. thereafter.",
+      "documents": "Udyam Registration Certificate",
+      "eligibility": "MSME with valid Udyam Registration Number. Service-sector MSMEs are also included (March 2026 modification). Cost of equipment/machinery must be at least 60% of project cost (reduced from 75%). Exporter window: profitable units exporting at least 25% of sales in the previous 3 financial years."
+    },
+    "semanticTags": [],
+    "similarityMethod": null,
+    "sourceFieldsUsed": [
+      "content.overview.summary",
+      "content.benefits.summary",
+      "content.eligibility.narrative.criteria",
+      "content.requiredDocuments[].name"
+    ],
+    "summary": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery."
+  },
+  "analytics": {
+    "actionCount": null,
+    "lastAggregatedAt": null,
+    "popularity": null,
+    "saveCount": null,
+    "viewCount": null
   },
   "content": {
     "applicationProcess": {
+      "applicationFeeInr": null,
+      "applicationFeeText": null,
       "mode": "offline",
       "modeText": "Application via offline channel",
-      "onlineUrl": null,
+      "offlineDetails": null,
+      "onlineUrl": "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2243388",
       "services": [],
       "steps": [
         {
@@ -34,7 +50,7 @@
           ],
           "mode": "offline",
           "step": 1,
-          "title": "Step 1",
+          "title": "Apply at participating bank",
           "url": "https://www.ncgtc.in"
         },
         {
@@ -42,12 +58,23 @@
           "documents": [],
           "mode": "offline",
           "step": 2,
-          "title": "Step 2",
+          "title": "Deposit borrower contribution",
           "url": null
         }
       ]
     },
+    "applicationTimeline": {
+      "closesOn": null,
+      "cycles": [],
+      "isRollingIntake": null,
+      "opensOn": null,
+      "processingDurationDays": null,
+      "text": null
+    },
     "benefits": {
+      "benefitTypes": [
+        "guarantee"
+      ],
       "capitalSubsidy": {
         "amountInr": null,
         "amountText": null,
@@ -72,16 +99,33 @@
         "modeText": null,
         "text": null
       },
+      "equitySupport": {
+        "amountInr": null,
+        "amountText": null,
+        "applicable": null,
+        "basis": null,
+        "conditions": [],
+        "description": null,
+        "durationMonths": null,
+        "maxAmountInr": null,
+        "maxAmountText": null,
+        "minAmountInr": null,
+        "minAmountText": null,
+        "percentage": null,
+        "percentageText": null,
+        "varies": false,
+        "variesBy": null
+      },
       "grant": {
-        "amountInr": null,
-        "amountText": null,
-        "applicable": null,
-        "basis": null,
-        "conditions": [],
-        "description": null,
-        "durationMonths": null,
-        "maxAmountInr": null,
-        "maxAmountText": null,
+        "amountInr": 15000,
+        "amountText": "₹15,000",
+        "applicable": null,
+        "basis": null,
+        "conditions": [],
+        "description": "A toolkit incentive of up to Rs. 15,000 through e-vouchers",
+        "durationMonths": null,
+        "maxAmountInr": 15000,
+        "maxAmountText": "₹15,000",
         "minAmountInr": null,
         "minAmountText": null,
         "percentage": null,
@@ -98,7 +142,7 @@
           "general MSMEs, equipment/machinery loans",
           "exporter MSMEs (≥25% export sales)"
         ],
-        "coveragePercent": 60.0,
+        "coveragePercent": 60,
         "description": "60% guarantee coverage by National Credit Guarantee Trustee Company Limited (NCGTC)",
         "durationMonths": null,
         "feePercent": null,
@@ -109,7 +153,7 @@
         "maxCoverInr": 1000000000,
         "minAmountInr": null,
         "minAmountText": null,
-        "percentage": 60.0,
+        "percentage": 60,
         "percentageText": "60%",
         "varies": false,
         "variesBy": null
@@ -137,14 +181,14 @@
         "applicable": null,
         "basis": null,
         "conditions": [],
-        "description": null,
+        "description": "at a concessional rate of interest fixed at 5%, with Government of India subvention to the extent of 8%",
         "durationMonths": null,
         "maxAmountInr": null,
         "maxAmountText": null,
         "minAmountInr": null,
         "minAmountText": null,
-        "percentage": null,
-        "percentageText": null,
+        "percentage": 8,
+        "percentageText": "8%",
         "varies": false,
         "variesBy": null
       },
@@ -155,21 +199,21 @@
         "basis": null,
         "collateralRequired": false,
         "conditions": [],
-        "description": null,
+        "description": "Scheme includes recognition, skill training, toolkit support, concessional collateral-free enterprise-development credit, digital incentives and marketing support. Exact current component values should follow official guidelines.",
         "durationMonths": null,
         "interestRatePercent": null,
         "interestRateText": null,
         "maxAmountInr": null,
-        "maxAmountText": null,
+        "maxAmountText": "Guideline-specific",
         "minAmountInr": null,
         "minAmountText": null,
         "moratoriumMonths": null,
         "percentage": null,
-        "percentageText": null,
+        "percentageText": "Component-specific",
         "repaymentText": null,
         "tenureMonths": null,
         "varies": false,
-        "variesBy": null
+        "variesBy": "Component-specific"
       },
       "marginMoney": {
         "amountInr": null,
@@ -251,35 +295,72 @@
         "providerText": null
       }
     },
+    "classification": {
+      "categories": [],
+      "government": {
+        "country": "IN",
+        "departmentId": null,
+        "departmentText": "Department of Financial Services / National Credit Guarantee Trustee Company Ltd (NCGTC)",
+        "districts": [],
+        "districtsText": null,
+        "implementingAgencyIds": [],
+        "implementingAgencyText": null,
+        "level": "central",
+        "levelText": "Central",
+        "ministryId": "AUTH000009",
+        "ministryText": "Ministry of Finance",
+        "states": [],
+        "statesText": null
+      },
+      "schemeType": "credit_guarantee",
+      "schemeTypeText": "Credit Guarantee",
+      "sectors": [],
+      "sectorsText": null,
+      "tags": [
+        "credit_guarantee",
+        "export",
+        "exporter",
+        "manufacturing",
+        "medium_enterprise",
+        "micro_enterprise",
+        "services",
+        "small_enterprise"
+      ]
+    },
     "contacts": {
+      "district": [],
       "helplines": [],
-      "national": [
-        {
-          "title": "NCGTC",
-          "url": "https://www.ncgtc.in"
-        }
-      ]
+      "national": [],
+      "state": []
     },
     "eligibility": {
       "narrative": {
-        "criteria": [
-          "MSME with valid Udyam Registration Number.",
-          "Service-sector MSMEs are also included (March 2026 modification).",
-          "Cost of equipment/machinery must be at least 60% of project cost (reduced from 75%).",
-          "Exporter window: profitable units exporting at least 25% of sales in the previous 3 financial years."
-        ],
-        "exclusions": []
+        "criteria": "MSME with valid Udyam Registration Number. Service-sector MSMEs are also included (March 2026 modification). Cost of equipment/machinery must be at least 60% of project cost (reduced from 75%). Exporter window: profitable units exporting at least 25% of sales in the previous 3 financial years.",
+        "exclusions": [],
+        "relaxations": null,
+        "verifiedCriteria": null
       },
       "structured": {
         "age": {
-          "max": null,
-          "min": null
+          "applies": null,
+          "maxYears": null,
+          "minYears": null,
+          "text": null
+        },
+        "businessStage": {
+          "applies": null,
+          "text": null,
+          "values": []
         },
         "community": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "enterprise": {
+          "applies": true,
+          "constitution": [],
+          "text": "micro, small, medium",
           "types": [
             "micro",
             "small",
@@ -287,62 +368,87 @@
           ]
         },
         "existingRegistration": {
-          "applicable": true,
-          "requiredTypes": [
+          "applies": true,
+          "required": [
             "Udyam Registration"
-          ]
+          ],
+          "text": "Udyam Registration"
         },
         "gender": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "investment": {
-          "applicable": false,
-          "maxAmountInr": null
-        },
-        "landHolding": {
-          "applicable": false
+          "applies": null,
+          "maxInr": null,
+          "minInr": null,
+          "text": null
         },
         "location": {
-          "areaTypes": [
-            "rural",
-            "urban"
-          ],
-          "states": []
-        },
+          "applies": null,
+          "areaTypes": [],
+          "country": null,
+          "districts": [],
+          "states": [],
+          "text": null
+        },
+        "otherConditions": [],
         "sector": {
-          "applicable": true,
+          "applies": true,
           "excluded": [],
           "included": [
             "manufacturing",
             "services",
             "export"
-          ]
+          ],
+          "text": "manufacturing, services, export"
         },
         "specialCategory": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "turnover": {
-          "applicable": false,
-          "maxAmountInr": null
+          "applies": null,
+          "maxInr": null,
+          "minInr": null,
+          "text": null
         }
       }
     },
+    "faqs": [],
+    "objectives": [
+      "Guarantee is provided by NCGTC to Member Lending Institutions (banks, NBFCs, financial institutions).",
+      "Modified in March 2026 to include service-sector MSMEs and a special window for exporter MSMEs."
+    ],
     "overview": {
+      "background": null,
       "description": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery. Guarantee is provided by NCGTC to Member Lending Institutions (banks, NBFCs, financial institutions). Modified in March 2026 to include service-sector MSMEs and a special window for exporter MSMEs.",
-      "keyPointers": [],
-      "objectives": [
-        "Guarantee is provided by NCGTC to Member Lending Institutions (banks, NBFCs, financial institutions).",
-        "Modified in March 2026 to include service-sector MSMEs and a special window for exporter MSMEs."
-      ],
-      "summary": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery."
+      "lastUpdated": null,
+      "lastUpdatedText": "Current",
+      "legalBasis": [],
+      "objective": "Guarantee is provided by NCGTC to Member Lending Institutions (banks, NBFCs, financial institutions).",
+      "summary": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery.",
+      "validity": {
+        "from": null,
+        "isOpenEnded": true,
+        "text": null,
+        "to": null
+      },
+      "version": "Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME)"
     },
     "requiredDocuments": [
       {
+        "description": "Udyam Registration Certificate",
         "documentTypeId": "CMN000163",
-        "mandatory": true,
-        "name": "Udyam Registration Certificate"
+        "documentTypeText": "Udyam Registration Certificate",
+        "isMandatory": true,
+        "issuingAuthority": null,
+        "name": "Udyam Registration Certificate",
+        "originalRequired": null,
+        "stage": "application",
+        "validityPeriod": null
       }
     ],
     "schemeUrl": "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2243388",
@@ -371,12 +477,30 @@
         "type": "official_portal",
         "url": "https://www.pib.gov.in/PressReleaseIframePage.aspx?PRID=2104140"
       }
-    ]
+    ],
+    "targetBeneficiaries": {
+      "beneficiaryTypes": [
+        "micro_enterprise",
+        "small_enterprise",
+        "medium_enterprise",
+        "exporter"
+      ],
+      "businessStages": [],
+      "description": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery.",
+      "enterpriseTypes": [
+        "micro",
+        "small",
+        "medium"
+      ],
+      "specialCategories": []
+    }
   },
   "identity": {
+    "acronym": null,
     "code": "SCH000255",
-    "fullName": "Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME)",
+    "entityType": "scheme",
     "id": "SCH000255",
+    "language": "en",
     "legacyCodes": [
       {
         "code": "NEW2026-001",
@@ -390,7 +514,7 @@
   },
   "localization": {
     "en": {
-      "applicationText": "Apply for a term loan for equipment/machinery at a participating bank/NBFC (Member Lending Institution); the lender seeks the guarantee from NCGTC. Deposit the upfront contribution (5% of loan; 2% for exporter window) at the time of application.",
+      "applicationText": "Application via offline channel",
       "benefitsText": "60% guarantee coverage by NCGTC on the loan. Loan amount guaranteed up to ₹100 crore (project can be larger). Repayment up to 8 years with up to 2 years moratorium for loans up to ₹50 crore; flexible schedule for larger loans. Upfront contribution of 5% of loan amount at application (refundable 1% each year from 4th year). Annual guarantee fee: nil in year of sanction; 1.5% p.a. for next 3 years; 1% p.a. thereafter. Exporter MSMEs: 75% guarantee cover for loans up to ₹20 crore; upfront contribution 2% (max ₹40 lakh); fee nil in first year and 0.50% p.a. thereafter.",
       "description": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery. Guarantee is provided by NCGTC to Member Lending Institutions (banks, NBFCs, financial institutions). Modified in March 2026 to include service-sector MSMEs and a special window for exporter MSMEs.",
       "eligibilityText": "MSME with valid Udyam Registration Number. Service-sector MSMEs are also included (March 2026 modification). Cost of equipment/machinery must be at least 60% of project cost (reduced from 75%). Exporter window: profitable units exporting at least 25% of sales in the previous 3 financial years.",
@@ -400,14 +524,14 @@
       "summary": "Credit guarantee scheme (announced in Union Budget 2024-25) for collateral-free term loans to MSMEs for purchase of equipment/machinery."
     },
     "hi": {
-      "applicationText": "किसी भागीदार बैंक/NBFC (सदस्य ऋणदाता संस्था) में उपकरण/मशीनरी हेतु सावधि ऋण के लिए आवेदन करें; ऋणदाता NCGTC से गारंटी प्राप्त करता है। आवेदन के समय अग्रिम अंशदान (ऋण का 5%; निर्यातक सुविधा में 2%) जमा करें।",
-      "benefitsText": "ऋण पर NCGTC द्वारा 60% गारंटी कवरेज। ₹100 करोड़ तक की ऋण राशि पर गारंटी (परियोजना इससे बड़ी हो सकती है)। ₹50 करोड़ तक के ऋण पर 8 वर्ष तक पुनर्भुगतान अवधि तथा 2 वर्ष तक मोरेटोरियम; बड़े ऋणों के लिए लचीला कार्यक्रम। आवेदन के समय ऋण राशि का 5% अग्रिम अंशदान (चौथे वर्ष से प्रतिवर्ष 1% वापसी योग्य)। वार्षिक गारंटी शुल्क: स्वीकृति वर्ष में शून्य; अगले 3 वर्ष 1.5% प्रति वर्ष; उसके बाद 1% प्रति वर्ष। निर्यातक एमएसएमई: ₹20 करोड़ तक के ऋण पर 75% गारंटी; अग्रिम अंशदान 2% (अधिकतम ₹40 लाख); पहले वर्ष शुल्क शून्य, उसके बाद 0.50% प्रति वर्ष।",
-      "description": "उपकरण/मशीनरी की खरीद हेतु एमएसएमई को बिना संपार्श्विक सावधि ऋण के लिए ऋण गारंटी योजना (केंद्रीय बजट 2024-25 में घोषित)। गारंटी NCGTC द्वारा सदस्य ऋणदाता संस्थाओं (बैंक, NBFC, वित्तीय संस्थाएँ) को दी जाती है। मार्च 2026 में संशोधन कर सेवा क्षेत्र के एमएसएमई तथा निर्यातक एमएसएमई के लिए विशेष सुविधा जोड़ी गई।",
-      "eligibilityText": "वैध उद्यम पंजीकरण संख्या वाला एमएसएमई। सेवा क्षेत्र के एमएसएमई भी शामिल (मार्च 2026 संशोधन)। उपकरण/मशीनरी की लागत परियोजना लागत का कम से कम 60% होनी चाहिए (पहले 75%)। निर्यातक सुविधा: पिछले 3 वित्त वर्षों में बिक्री का कम से कम 25% निर्यात करने वाली लाभकारी इकाइयाँ।",
+      "applicationText": null,
+      "benefitsText": null,
+      "description": null,
+      "eligibilityText": null,
       "name": "एमएसएमई के लिए पारस्परिक ऋण गारंटी योजना (MCGS-MSME)",
-      "objective": "उपकरण/मशीनरी की खरीद हेतु एमएसएमई को बिना संपार्श्विक सावधि ऋण के लिए ऋण गारंटी योजना (केंद्रीय बजट 2024-25 में घोषित)।",
+      "objective": null,
       "shortName": null,
-      "summary": "उपकरण/मशीनरी की खरीद हेतु एमएसएमई को बिना संपार्श्विक सावधि ऋण के लिए ऋण गारंटी योजना (केंद्रीय बजट 2024-25 में घोषित)।"
+      "summary": null
     },
     "ta": {
       "applicationText": null,
@@ -421,30 +545,32 @@
     }
   },
   "metadata": {
-    "catalogVersion": "1.35.0-alpha",
+    "catalogVersion": "1.35.1-alpha",
     "createdAt": "2026-10-04T13:50:15Z",
+    "recordStatus": "published",
     "revision": 1,
     "schemaVersion": "1.0.0",
-    "updatedAt": "2026-10-04T13:50:15Z"
+    "updatedAt": "2026-10-04T19:30:32Z"
   },
   "provenance": {
-    "pipelineVersion": "catalog-v3-1-migration",
+    "contributingSourceIds": [
+      "SCH000255-SRC001"
+    ],
+    "defaultSourceTier": 2,
+    "extractedAt": "2026-10-04T00:00:00Z",
+    "extractionMethod": "automated",
+    "fieldSources": [],
+    "pipelineVersion": "catalog-v3.1-migration-1.35.1",
+    "primarySourceId": "SCH000255-SRC001",
     "transformationNotes": [
-      "Migrated from mss_scheme_data_v3_1 (ID: NEW2026-001)",
-      "Action: ADD_NEW"
+      "Rebuilt to reference catalog shape in v3.1 migration"
     ],
     "translations": {
       "hi": {
-        "generatedAt": "2026-10-04T00:00:00Z",
+        "generatedAt": "2026-10-04T13:45:56Z",
         "reviewRequired": true,
         "source": "booklet_2025_26_machine_hi",
         "status": "machine"
-      },
-      "ta": {
-        "engine": "none",
-        "note": "Tamil translation pending",
-        "reviewRequired": true,
-        "status": "none"
       }
     }
   },
@@ -464,10 +590,12 @@
         "MCGS-MSME"
       ],
       "hi": [
-        "एमएसएमई के लिए पारस्परिक ऋण गारंटी योजना (MCGS-MSME)"
+        "पीएम विश्वकर्मा"
       ],
       "ta": []
     },
+    "boostTerms": [],
+    "crossReferences": [],
     "keywords": {
       "en": [
         "mutual",
@@ -478,36 +606,46 @@
         "mcgs",
         "msme"
       ],
-      "hi": [],
       "ta": []
     },
+    "searchRank": null,
     "synonyms": []
   },
   "verification": {
     "confidence": "high",
     "disputedFields": [
       {
-        "field": "content.benefits",
-        "reason": "guarantee max=200000000 pct=75 :: 75% for eligible exporters"
-      }
-    ],
-    "missingFields": [],
-    "notes": "Approved Jan 2025 (Budget 2024-25), launched Feb 2025; valid for loans sanctioned within 4 years of operational guidelines or until ₹7 lakh crore cumulative guarantees; modified 21 Mar 2026 to add service MSMEs and exporter window.; Exporter-window figures from PIB 21 Mar 2026 via fetch summary; '75% for eligible exporters' paraphrased — quote not verified verbatim.; Equipment/machinery threshold changed 75%→60% in Mar 2026; original Jan 2025 guidelines said 75%.; Not in the MSME booklet 2025-26 (Ministry of Finance / NCGTC scheme); duplicate MSME2526-004 dropped in favour of this record.; [agent_flag] Exporter-window figures from PIB 21 Mar 2026 via fetch summary; '75% for eligible exporters' paraphrased — quote not verified verbatim.; [agent_flag] Equipment/machinery threshold changed 75%→60% in Mar 2026; original Jan 2025 guidelines said 75%.; [agent_flag] Not in the MSME booklet 2025-26 (Ministry of Finance / NCGTC scheme); duplicate MSME2526-004 dropped in favour of this record.",
+        "field": "content.benefits.guarantee",
+        "reason": "quote_verified=false in v3.1 source: '75% for eligible exporters'",
+        "resolvedBy": null,
+        "values": []
+      }
+    ],
+    "isVerified": false,
+    "missingFields": [
+      {
+        "field": "content.applicationTimeline",
+        "reason": "Not available in available sources"
+      },
+      {
+        "field": "content.faqs",
+        "reason": "Not available in available sources"
+      },
+      {
+        "field": "localization.ta",
+        "reason": "Tamil translation pending (D5=English-only)"
+      }
+    ],
+    "notes": "Exporter-window figures from PIB 21 Mar 2026 via fetch summary; '75% for eligible exporters' paraphrased — quote not verified verbatim. | Equipment/machinery threshold changed 75%→60% in Mar 2026; original Jan 2025 guidelines said 75%. | Not in the MSME booklet 2025-26 (Ministry of Finance / NCGTC scheme); duplicate MSME2526-004 dropped in favour of this record.",
+    "researchStatus": "Researched",
+    "reviewDueOn": null,
     "status": "verified",
+    "statusText": null,
     "verifiedAgainst": [
       "SCH000255-SRC001"
     ],
     "verifiedAt": "2026-10-04",
-    "verifiedFields": [
-      {
-        "field": "content.schemeUrl",
-        "note": "Official scheme portal",
-        "outcome": "confirmed",
-        "retrievedAt": "2026-10-04",
-        "sourceTier": 5,
-        "url": "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2243388",
-        "value": "https://www.pib.gov.in/PressReleasePage.aspx?PRID=2243388"
-      }
-    ]
+    "verifiedBy": null,
+    "verifiedFields": []
   }
 }
```

### BEFORE/AFTER DIFF: SCH000289 - PM Surya Ghar: Muft Bijli Yojana
```diff
--- a/SCH000289_before.json
+++ b/SCH000289_after.json
@@ -1,26 +1,45 @@
 {
-  "classification": {
-    "category": "financial_support",
-    "government": {
-      "departmentText": "MNRE / DISCOMs (National Portal)",
-      "implementingAgencyIds": [],
-      "level": "central",
-      "ministryId": null,
-      "ministryText": "Ministry of New and Renewable Energy"
-    },
-    "schemeType": "capital_subsidy",
-    "tags": [
-      "capital_subsidy",
-      "energy",
-      "individual",
-      "micro_enterprise",
-      "small_enterprise"
-    ]
+  "ai": {
+    "confidence": null,
+    "generatedAt": "2026-10-04T00:00:00Z",
+    "generatedBy": "build_scheme_catalog.py-1.0.0",
+    "generationMode": "mechanical_derivation",
+    "isApproved": false,
+    "recommendations": [],
+    "recommendationsNote": null,
+    "relatedEntities": [],
+    "reviewRequired": true,
+    "reviewedAt": null,
+    "reviewedBy": null,
+    "sectionSummaries": {
+      "benefits": "Central Financial Assistance: ₹30,000 for 1 kW, ₹60,000 for 2 kW, ₹78,000 for 3 kW or higher. Collateral-free low-interest loans of around 7%. Subsidy credited to bank account within about 30 days after commissioning.",
+      "documents": "Electricity bill / consumer number; Cancelled cheque; Bank details",
+      "eligibility": "Indian household owning a house with a roof suitable for solar panels. Valid electricity connection; not availed any other subsidy for solar panels."
+    },
+    "semanticTags": [],
+    "similarityMethod": null,
+    "sourceFieldsUsed": [
+      "content.overview.summary",
+      "content.benefits.summary",
+      "content.eligibility.narrative.criteria",
+      "content.requiredDocuments[].name"
+    ],
+    "summary": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27."
+  },
+  "analytics": {
+    "actionCount": null,
+    "lastAggregatedAt": null,
+    "popularity": null,
+    "saveCount": null,
+    "viewCount": null
   },
   "content": {
     "applicationProcess": {
+      "applicationFeeInr": null,
+      "applicationFeeText": null,
       "mode": "online",
       "modeText": "Application via online channel",
+      "offlineDetails": null,
       "onlineUrl": "https://www.pib.gov.in/PressReleaseIframePage.aspx?PRID=2010133&reg=48&lang=2",
       "services": [],
       "steps": [
@@ -31,7 +50,7 @@
           ],
           "mode": "online",
           "step": 1,
-          "title": "Step 1",
+          "title": "Register on online portal",
           "url": "https://pmsuryaghar.gov.in"
         },
         {
@@ -39,7 +58,7 @@
           "documents": [],
           "mode": "online",
           "step": 2,
-          "title": "Step 2",
+          "title": "Install system via vendor",
           "url": null
         },
         {
@@ -47,7 +66,7 @@
           "documents": [],
           "mode": "online",
           "step": 3,
-          "title": "Step 3",
+          "title": "Obtain commissioning inspection",
           "url": null
         },
         {
@@ -58,12 +77,24 @@
           ],
           "mode": "online",
           "step": 4,
-          "title": "Step 4",
+          "title": "Submit bank details for subsidy",
           "url": null
         }
       ]
     },
+    "applicationTimeline": {
+      "closesOn": null,
+      "cycles": [],
+      "isRollingIntake": null,
+      "opensOn": null,
+      "processingDurationDays": null,
+      "text": null
+    },
     "benefits": {
+      "benefitTypes": [
+        "capitalSubsidy",
+        "loan"
+      ],
       "capitalSubsidy": {
         "amountInr": null,
         "amountText": null,
@@ -92,16 +123,33 @@
         "modeText": null,
         "text": null
       },
+      "equitySupport": {
+        "amountInr": null,
+        "amountText": null,
+        "applicable": null,
+        "basis": null,
+        "conditions": [],
+        "description": null,
+        "durationMonths": null,
+        "maxAmountInr": null,
+        "maxAmountText": null,
+        "minAmountInr": null,
+        "minAmountText": null,
+        "percentage": null,
+        "percentageText": null,
+        "varies": false,
+        "variesBy": null
+      },
       "grant": {
-        "amountInr": null,
-        "amountText": null,
-        "applicable": null,
-        "basis": null,
-        "conditions": [],
-        "description": null,
-        "durationMonths": null,
-        "maxAmountInr": null,
-        "maxAmountText": null,
+        "amountInr": 15000,
+        "amountText": "₹15,000",
+        "applicable": null,
+        "basis": null,
+        "conditions": [],
+        "description": "A toolkit incentive of up to Rs. 15,000 through e-vouchers",
+        "durationMonths": null,
+        "maxAmountInr": 15000,
+        "maxAmountText": "₹15,000",
         "minAmountInr": null,
         "minAmountText": null,
         "percentage": null,
@@ -154,14 +202,14 @@
         "applicable": null,
         "basis": null,
         "conditions": [],
-        "description": null,
+        "description": "at a concessional rate of interest fixed at 5%, with Government of India subvention to the extent of 8%",
         "durationMonths": null,
         "maxAmountInr": null,
         "maxAmountText": null,
         "minAmountInr": null,
         "minAmountText": null,
-        "percentage": null,
-        "percentageText": null,
+        "percentage": 8,
+        "percentageText": "8%",
         "varies": false,
         "variesBy": null
       },
@@ -177,16 +225,16 @@
         "interestRatePercent": null,
         "interestRateText": null,
         "maxAmountInr": null,
-        "maxAmountText": null,
+        "maxAmountText": "Guideline-specific",
         "minAmountInr": null,
         "minAmountText": null,
         "moratoriumMonths": null,
         "percentage": null,
-        "percentageText": null,
+        "percentageText": "Component-specific",
         "repaymentText": null,
         "tenureMonths": null,
         "varies": false,
-        "variesBy": null
+        "variesBy": "Component-specific"
       },
       "marginMoney": {
         "amountInr": null,
@@ -268,103 +316,171 @@
         "providerText": null
       }
     },
+    "classification": {
+      "categories": [],
+      "government": {
+        "country": "IN",
+        "departmentId": null,
+        "departmentText": "MNRE / DISCOMs (National Portal)",
+        "districts": [],
+        "districtsText": null,
+        "implementingAgencyIds": [],
+        "implementingAgencyText": null,
+        "level": "central",
+        "levelText": "Central",
+        "ministryId": "AUTH000129",
+        "ministryText": "Ministry of New and Renewable Energy",
+        "states": [],
+        "statesText": null
+      },
+      "schemeType": "capital_subsidy",
+      "schemeTypeText": "Capital Subsidy",
+      "sectors": [],
+      "sectorsText": null,
+      "tags": [
+        "capital_subsidy",
+        "energy",
+        "individual",
+        "micro_enterprise",
+        "small_enterprise"
+      ]
+    },
     "contacts": {
+      "district": [],
       "helplines": [],
-      "national": [
-        {
-          "title": "National Portal",
-          "url": "https://pmsuryaghar.gov.in"
-        }
-      ]
+      "national": [],
+      "state": []
     },
     "eligibility": {
       "narrative": {
-        "criteria": [
-          "Indian household owning a house with a roof suitable for solar panels.",
-          "Valid electricity connection; not availed any other subsidy for solar panels."
-        ],
-        "exclusions": []
+        "criteria": "Indian household owning a house with a roof suitable for solar panels. Valid electricity connection; not availed any other subsidy for solar panels.",
+        "exclusions": [],
+        "relaxations": null,
+        "verifiedCriteria": null
       },
       "structured": {
         "age": {
-          "max": null,
-          "min": null
+          "applies": null,
+          "maxYears": null,
+          "minYears": null,
+          "text": null
+        },
+        "businessStage": {
+          "applies": null,
+          "text": null,
+          "values": []
         },
         "community": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "enterprise": {
-          "types": [
-            "micro",
-            "small"
-          ]
+          "applies": null,
+          "constitution": [],
+          "text": null,
+          "types": []
         },
         "existingRegistration": {
-          "applicable": true,
-          "requiredTypes": [
-            "Udyam Registration"
-          ]
+          "applies": null,
+          "required": [],
+          "text": null
         },
         "gender": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "investment": {
-          "applicable": false,
-          "maxAmountInr": null
-        },
-        "landHolding": {
-          "applicable": false
+          "applies": null,
+          "maxInr": null,
+          "minInr": null,
+          "text": null
         },
         "location": {
-          "areaTypes": [
-            "rural",
-            "urban"
-          ],
-          "states": []
-        },
+          "applies": null,
+          "areaTypes": [],
+          "country": null,
+          "districts": [],
+          "states": [],
+          "text": null
+        },
+        "otherConditions": [],
         "sector": {
-          "applicable": true,
+          "applies": true,
           "excluded": [],
           "included": [
             "energy"
-          ]
+          ],
+          "text": "energy"
         },
         "specialCategory": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "turnover": {
-          "applicable": false,
-          "maxAmountInr": null
+          "applies": null,
+          "maxInr": null,
+          "minInr": null,
+          "text": null
         }
       }
     },
+    "faqs": [],
+    "objectives": [
+      "A Model Solar Village in each district (₹1 crore per selected village).",
+      "Expected to create about 17 lakh direct jobs in manufacturing, logistics, sales, installation and O&M — opportunity for local vendors/MSMEs."
+    ],
     "overview": {
+      "background": null,
       "description": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27. A Model Solar Village in each district (₹1 crore per selected village). Expected to create about 17 lakh direct jobs in manufacturing, logistics, sales, installation and O&M — opportunity for local vendors/MSMEs.",
-      "keyPointers": [],
-      "objectives": [
-        "A Model Solar Village in each district (₹1 crore per selected village).",
-        "Expected to create about 17 lakh direct jobs in manufacturing, logistics, sales, installation and O&M — opportunity for local vendors/MSMEs."
-      ],
-      "summary": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27."
+      "lastUpdated": null,
+      "lastUpdatedText": "Current",
+      "legalBasis": [],
+      "objective": "A Model Solar Village in each district (₹1 crore per selected village).",
+      "summary": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27.",
+      "validity": {
+        "from": null,
+        "isOpenEnded": true,
+        "text": null,
+        "to": null
+      },
+      "version": "PM Surya Ghar: Muft Bijli Yojana"
     },
     "requiredDocuments": [
       {
+        "description": "Electricity bill / consumer number",
         "documentTypeId": "CMN000001",
-        "mandatory": true,
-        "name": "Electricity bill / consumer number"
-      },
-      {
+        "documentTypeText": "Electricity bill / consumer number",
+        "isMandatory": true,
+        "issuingAuthority": null,
+        "name": "Electricity bill / consumer number",
+        "originalRequired": null,
+        "stage": "application",
+        "validityPeriod": null
+      },
+      {
+        "description": "Cancelled cheque",
         "documentTypeId": "CMN000001",
-        "mandatory": true,
-        "name": "Cancelled cheque"
-      },
-      {
+        "documentTypeText": "Cancelled cheque",
+        "isMandatory": true,
+        "issuingAuthority": null,
+        "name": "Cancelled cheque",
+        "originalRequired": null,
+        "stage": "application",
+        "validityPeriod": null
+      },
+      {
+        "description": "Bank details",
         "documentTypeId": "CMN000001",
-        "mandatory": true,
-        "name": "Bank details"
+        "documentTypeText": "Bank details",
+        "isMandatory": true,
+        "issuingAuthority": null,
+        "name": "Bank details",
+        "originalRequired": null,
+        "stage": "application",
+        "validityPeriod": null
       }
     ],
     "schemeUrl": "https://www.pib.gov.in/PressReleaseIframePage.aspx?PRID=2010133&reg=48&lang=2",
@@ -385,12 +501,28 @@
         "type": "official_portal",
         "url": "https://static.pib.gov.in/WriteReadData/specificdocs/documents/2025/mar/doc2025313520001.pdf"
       }
-    ]
+    ],
+    "targetBeneficiaries": {
+      "beneficiaryTypes": [
+        "individual",
+        "micro_enterprise",
+        "small_enterprise"
+      ],
+      "businessStages": [],
+      "description": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27.",
+      "enterpriseTypes": [
+        "micro",
+        "small"
+      ],
+      "specialCategories": []
+    }
   },
   "identity": {
+    "acronym": null,
     "code": "SCH000289",
-    "fullName": "PM Surya Ghar: Muft Bijli Yojana",
+    "entityType": "scheme",
     "id": "SCH000289",
+    "language": "en",
     "legacyCodes": [
       {
         "code": "NEW2026-061",
@@ -404,7 +536,7 @@
   },
   "localization": {
     "en": {
-      "applicationText": "Register on the national portal with State, DISCOM, consumer number and mobile number. Apply for rooftop solar; after DISCOM feasibility approval, install through a registered vendor. Submit plant details and apply for net meter; after inspection obtain commissioning certificate. Submit bank details and cancelled cheque on the portal; subsidy credited within 30 days.",
+      "applicationText": "Application via online channel",
       "benefitsText": "Central Financial Assistance: ₹30,000 for 1 kW, ₹60,000 for 2 kW, ₹78,000 for 3 kW or higher. Collateral-free low-interest loans of around 7%. Subsidy credited to bank account within about 30 days after commissioning.",
       "description": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27. A Model Solar Village in each district (₹1 crore per selected village). Expected to create about 17 lakh direct jobs in manufacturing, logistics, sales, installation and O&M — opportunity for local vendors/MSMEs.",
       "eligibilityText": "Indian household owning a house with a roof suitable for solar panels. Valid electricity connection; not availed any other subsidy for solar panels.",
@@ -414,14 +546,14 @@
       "summary": "Rooftop solar for one crore households with ₹75,021 crore outlay; target by 2026-27."
     },
     "hi": {
-      "applicationText": "राज्य, डिस्कॉम, उपभोक्ता संख्या और मोबाइल नंबर से राष्ट्रीय पोर्टल पर पंजीकरण करें। रूफटॉप सोलर हेतु आवेदन करें; डिस्कॉम की व्यवहार्यता स्वीकृति के बाद पंजीकृत विक्रेता से स्थापित कराएं। संयंत्र विवरण जमा कर नेट मीटर हेतु आवेदन करें; निरीक्षण के बाद कमीशनिंग प्रमाणपत्र प्राप्त करें। पोर्टल पर बैंक विवरण और रद्द चेक जमा करें; 30 दिनों में सब्सिडी।",
-      "benefitsText": "केंद्रीय वित्तीय सहायता: 1 किलोवाट पर ₹30,000, 2 किलोवाट पर ₹60,000, 3 किलोवाट या अधिक पर ₹78,000। लगभग 7% ब्याज पर बिना गारंटी के ऋण। कमीशनिंग के बाद लगभग 30 दिनों में सब्सिडी बैंक खाते में।",
-      "description": "₹75,021 करोड़ परिव्यय से एक करोड़ घरों पर रूफटॉप सोलर; लक्ष्य 2026-27 तक। प्रत्येक जिले में एक मॉडल सौर गांव (प्रति चयनित गांव ₹1 करोड़)। विनिर्माण, लॉजिस्टिक्स, बिक्री, स्थापना और रखरखाव में लगभग 17 लाख प्रत्यक्ष रोजगार — स्थानीय विक्रेताओं/एमएसएमई के लिए अवसर।",
-      "eligibilityText": "सौर पैनल हेतु उपयुक्त छत वाले घर का स्वामी भारतीय परिवार। वैध बिजली कनेक्शन; सौर पैनल हेतु कोई अन्य सब्सिडी न ली हो।",
+      "applicationText": null,
+      "benefitsText": null,
+      "description": null,
+      "eligibilityText": null,
       "name": "पीएम सूर्य घर: मुफ्त बिजली योजना",
-      "objective": "₹75,021 करोड़ परिव्यय से एक करोड़ घरों पर रूफटॉप सोलर; लक्ष्य 2026-27 तक।",
+      "objective": null,
       "shortName": null,
-      "summary": "₹75,021 करोड़ परिव्यय से एक करोड़ घरों पर रूफटॉप सोलर; लक्ष्य 2026-27 तक।"
+      "summary": null
     },
     "ta": {
       "applicationText": null,
@@ -435,30 +567,32 @@
     }
   },
   "metadata": {
-    "catalogVersion": "1.35.0-alpha",
+    "catalogVersion": "1.35.1-alpha",
     "createdAt": "2026-10-04T13:50:15Z",
+    "recordStatus": "published",
     "revision": 1,
     "schemaVersion": "1.0.0",
-    "updatedAt": "2026-10-04T13:50:15Z"
+    "updatedAt": "2026-10-04T19:30:32Z"
   },
   "provenance": {
-    "pipelineVersion": "catalog-v3-1-migration",
+    "contributingSourceIds": [
+      "SCH000289-SRC001"
+    ],
+    "defaultSourceTier": 2,
+    "extractedAt": "2026-10-04T00:00:00Z",
+    "extractionMethod": "automated",
+    "fieldSources": [],
+    "pipelineVersion": "catalog-v3.1-migration-1.35.1",
+    "primarySourceId": "SCH000289-SRC001",
     "transformationNotes": [
-      "Migrated from mss_scheme_data_v3_1 (ID: NEW2026-061)",
-      "Action: ADD_NEW"
+      "Rebuilt to reference catalog shape in v3.1 migration"
     ],
     "translations": {
       "hi": {
-        "generatedAt": "2026-10-04T00:00:00Z",
+        "generatedAt": "2026-10-04T13:45:56Z",
         "reviewRequired": true,
         "source": "booklet_2025_26_machine_hi",
         "status": "machine"
-      },
-      "ta": {
-        "engine": "none",
-        "note": "Tamil translation pending",
-        "reviewRequired": true,
-        "status": "none"
       }
     }
   },
@@ -471,10 +605,12 @@
         "PM Surya Ghar: Muft Bijli Yojana"
       ],
       "hi": [
-        "पीएम सूर्य घर: मुफ्त बिजली योजना"
+        "पीएम विश्वकर्मा"
       ],
       "ta": []
     },
+    "boostTerms": [],
+    "crossReferences": [],
     "keywords": {
       "en": [
         "surya",
@@ -483,31 +619,39 @@
         "bijli",
         "yojana"
       ],
-      "hi": [],
       "ta": []
     },
+    "searchRank": null,
     "synonyms": []
   },
   "verification": {
     "confidence": "high",
     "disputedFields": [],
-    "missingFields": [],
-    "notes": "Running; 23.96 lakh households covered as per PIB (late 2025).; Vendor/MSME registration process on the portal not detailed on source; vendor angle noted in description only.; Step 1 field list (State, DISCOM) partially inferred; source says login with consumer number and mobile.; [agent_flag] Vendor/MSME registration process on the portal not detailed on source; vendor angle noted in description only.; [agent_flag] Step 1 field list (State, DISCOM) partially inferred; source says login with consumer number and mobile.",
+    "isVerified": false,
+    "missingFields": [
+      {
+        "field": "content.applicationTimeline",
+        "reason": "Not available in available sources"
+      },
+      {
+        "field": "content.faqs",
+        "reason": "Not available in available sources"
+      },
+      {
+        "field": "localization.ta",
+        "reason": "Tamil translation pending (D5=English-only)"
+      }
+    ],
+    "notes": "Vendor/MSME registration process on the portal not detailed on source; vendor angle noted in description only. | Step 1 field list (State, DISCOM) partially inferred; source says login with consumer number and mobile.",
+    "researchStatus": "Researched",
+    "reviewDueOn": null,
     "status": "verified",
+    "statusText": null,
     "verifiedAgainst": [
       "SCH000289-SRC001"
     ],
     "verifiedAt": "2026-10-04",
-    "verifiedFields": [
-      {
-        "field": "content.schemeUrl",
-        "note": "Official scheme portal",
-        "outcome": "confirmed",
-        "retrievedAt": "2026-10-04",
-        "sourceTier": 5,
-        "url": "https://www.pib.gov.in/PressReleaseIframePage.aspx?PRID=2010133&reg=48&lang=2",
-        "value": "https://www.pib.gov.in/PressReleaseIframePage.aspx?PRID=2010133&reg=48&lang=2"
-      }
-    ]
+    "verifiedBy": null,
+    "verifiedFields": []
   }
 }
```

### BEFORE/AFTER DIFF: SCH000220 - PMEGP 2nd Loan for Upgradation
```diff
--- a/SCH000220_before.json
+++ b/SCH000220_after.json
@@ -1,27 +1,45 @@
 {
-  "classification": {
-    "category": "financial_support",
-    "government": {
-      "departmentText": "Khadi and Village Industries Commission (KVIC)",
-      "implementingAgencyIds": [],
-      "level": "central",
-      "ministryId": "AUTH000003",
-      "ministryText": "Ministry of Micro, Small and Medium Enterprises"
-    },
-    "schemeType": "capital_subsidy",
-    "tags": [
-      "capital_subsidy",
-      "khadi_village",
-      "manufacturing",
-      "micro_enterprise",
-      "services",
-      "small_enterprise"
-    ]
+  "ai": {
+    "confidence": null,
+    "generatedAt": "2026-10-04T00:00:00Z",
+    "generatedBy": "build_scheme_catalog.py-1.0.0",
+    "generationMode": "mechanical_derivation",
+    "isApproved": false,
+    "recommendations": [],
+    "recommendationsNote": null,
+    "relatedEntities": [],
+    "reviewRequired": true,
+    "reviewedAt": null,
+    "reviewedBy": null,
+    "sectionSummaries": {
+      "benefits": "Maximum project cost for upgradation: Rs. 1.00 crore (manufacturing) and Rs. 25.00 lakh (service/trading). Subsidy: 15% of project cost (maximum Rs. 15 lakh); 20% for NER and Hill States (maximum Rs. 20 lakh). Balance of project cost is provided by banks as term loan.",
+      "documents": "Udyam Registration",
+      "eligibility": "Existing well-performing PMEGP/REGP/MUDRA units. Margin money claim adjusted and first loan repaid in stipulated time. Unit should have been making profit for the last three years. The 2nd loan should lead to additional employment generation. UAM/Udyam Registration is mandatory. May apply to the same or any other financing bank, and choose any implementing agency."
+    },
+    "semanticTags": [],
+    "similarityMethod": null,
+    "sourceFieldsUsed": [
+      "content.overview.summary",
+      "content.benefits.summary",
+      "content.eligibility.narrative.criteria",
+      "content.requiredDocuments[].name"
+    ],
+    "summary": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation."
+  },
+  "analytics": {
+    "actionCount": null,
+    "lastAggregatedAt": null,
+    "popularity": null,
+    "saveCount": null,
+    "viewCount": null
   },
   "content": {
     "applicationProcess": {
+      "applicationFeeInr": null,
+      "applicationFeeText": null,
       "mode": "both",
       "modeText": "Application via both channel",
+      "offlineDetails": null,
       "onlineUrl": "https://www.kviconline.gov.in/pmegpeportal/pmegphome",
       "services": [],
       "steps": [
@@ -32,7 +50,7 @@
           ],
           "mode": "online",
           "step": 1,
-          "title": "Step 1",
+          "title": "Submit online application",
           "url": "https://www.kviconline.gov.in/pmegpeportal/pmegphome"
         },
         {
@@ -40,12 +58,24 @@
           "documents": [],
           "mode": "both",
           "step": 2,
-          "title": "Step 2",
+          "title": "Apply at participating bank",
           "url": null
         }
       ]
     },
+    "applicationTimeline": {
+      "closesOn": null,
+      "cycles": [],
+      "isRollingIntake": null,
+      "opensOn": null,
+      "processingDurationDays": null,
+      "text": null
+    },
     "benefits": {
+      "benefitTypes": [
+        "capitalSubsidy",
+        "loan"
+      ],
       "capitalSubsidy": {
         "amountInr": null,
         "amountText": null,
@@ -61,7 +91,7 @@
         "maxAmountText": "₹15 lakh",
         "minAmountInr": null,
         "minAmountText": null,
-        "percentage": 15.0,
+        "percentage": 15,
         "percentageText": "15%",
         "varies": false,
         "variesBy": null
@@ -73,7 +103,7 @@
         "modeText": null,
         "text": null
       },
-      "grant": {
+      "equitySupport": {
         "amountInr": null,
         "amountText": null,
         "applicable": null,
@@ -83,6 +113,23 @@
         "durationMonths": null,
         "maxAmountInr": null,
         "maxAmountText": null,
+        "minAmountInr": null,
+        "minAmountText": null,
+        "percentage": null,
+        "percentageText": null,
+        "varies": false,
+        "variesBy": null
+      },
+      "grant": {
+        "amountInr": 15000,
+        "amountText": "₹15,000",
+        "applicable": null,
+        "basis": null,
+        "conditions": [],
+        "description": "A toolkit incentive of up to Rs. 15,000 through e-vouchers",
+        "durationMonths": null,
+        "maxAmountInr": 15000,
+        "maxAmountText": "₹15,000",
         "minAmountInr": null,
         "minAmountText": null,
         "percentage": null,
@@ -135,14 +182,14 @@
         "applicable": null,
         "basis": null,
         "conditions": [],
-        "description": null,
+        "description": "at a concessional rate of interest fixed at 5%, with Government of India subvention to the extent of 8%",
         "durationMonths": null,
         "maxAmountInr": null,
         "maxAmountText": null,
         "minAmountInr": null,
         "minAmountText": null,
-        "percentage": null,
-        "percentageText": null,
+        "percentage": 8,
+        "percentageText": "8%",
         "varies": false,
         "variesBy": null
       },
@@ -166,11 +213,11 @@
         "minAmountText": null,
         "moratoriumMonths": null,
         "percentage": null,
-        "percentageText": null,
+        "percentageText": "Component-specific",
         "repaymentText": null,
         "tenureMonths": null,
         "varies": false,
-        "variesBy": null
+        "variesBy": "Component-specific"
       },
       "marginMoney": {
         "amountInr": null,
@@ -252,63 +299,100 @@
         "providerText": null
       }
     },
+    "classification": {
+      "categories": [],
+      "government": {
+        "country": "IN",
+        "departmentId": null,
+        "departmentText": "Khadi and Village Industries Commission (KVIC)",
+        "districts": [],
+        "districtsText": null,
+        "implementingAgencyIds": [],
+        "implementingAgencyText": null,
+        "level": "central",
+        "levelText": "Central",
+        "ministryId": "AUTH000003",
+        "ministryText": "Ministry of Micro, Small and Medium Enterprises",
+        "states": [],
+        "statesText": null
+      },
+      "schemeType": "capital_subsidy",
+      "schemeTypeText": "Capital Subsidy",
+      "sectors": [],
+      "sectorsText": null,
+      "tags": [
+        "capital_subsidy",
+        "khadi_village",
+        "manufacturing",
+        "micro_enterprise",
+        "services",
+        "small_enterprise"
+      ]
+    },
     "contacts": {
+      "district": [],
       "helplines": [],
-      "national": [
-        {
-          "title": "PMEGP e-portal",
-          "url": "https://www.kviconline.gov.in/pmegpeportal/pmegphome"
-        }
-      ]
+      "national": [],
+      "state": []
     },
     "eligibility": {
       "narrative": {
-        "criteria": [
-          "Existing well-performing PMEGP/REGP/MUDRA units.",
-          "Margin money claim adjusted and first loan repaid in stipulated time.",
-          "Unit should have been making profit for the last three years.",
-          "The 2nd loan should lead to additional employment generation.",
-          "UAM/Udyam Registration is mandatory.",
-          "May apply to the same or any other financing bank, and choose any implementing agency."
-        ],
-        "exclusions": []
+        "criteria": "Existing well-performing PMEGP/REGP/MUDRA units. Margin money claim adjusted and first loan repaid in stipulated time. Unit should have been making profit for the last three years. The 2nd loan should lead to additional employment generation. UAM/Udyam Registration is mandatory. May apply to the same or any other financing bank, and choose any implementing agency.",
+        "exclusions": [],
+        "relaxations": null,
+        "verifiedCriteria": null
       },
       "structured": {
         "age": {
-          "max": null,
-          "min": null
+          "applies": null,
+          "maxYears": null,
+          "minYears": null,
+          "text": null
+        },
+        "businessStage": {
+          "applies": null,
+          "text": null,
+          "values": []
         },
         "community": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "enterprise": {
+          "applies": true,
+          "constitution": [],
+          "text": "micro, small",
           "types": [
             "micro",
             "small"
           ]
         },
         "existingRegistration": {
-          "applicable": true,
-          "requiredTypes": [
+          "applies": true,
+          "required": [
             "Udyam Registration"
-          ]
+          ],
+          "text": "Udyam Registration"
         },
         "gender": {
-          "applicable": false,
+          "applies": null,
+          "text": null,
           "values": []
         },
         "investment": {
-          "applicable": false,
-          "maxAmountInr": null
-        },
-        "landHolding": {
-          "applicable": false
+          "applies": null,
+          "maxInr": null,
+          "minInr": null,
+          "text": null
         },
         "location": {
+          "applies": true,
           "areaTypes": [
             "rural"
           ],
+          "country": "IN",
+          "districts": [],
           "states": [
             "Assam",
             "Arunachal Pradesh",
@@ -318,41 +402,67 @@
             "Nagaland",
             "Sikkim",
             "Tripura"
-          ]
-        },
+          ],
+          "text": "States: Assam, Arunachal Pradesh, Manipur, Meghalaya, Mizoram, Nagaland, Sikkim, Tripura; Areas: rural"
+        },
+        "otherConditions": [],
         "sector": {
-          "applicable": true,
+          "applies": true,
           "excluded": [],
           "included": [
             "manufacturing",
             "services",
             "khadi_village"
+          ],
+          "text": "manufacturing, services, khadi_village"
+        },
+        "specialCategory": {
+          "applies": true,
+          "text": "ner",
+          "values": [
+            "ner"
           ]
         },
-        "specialCategory": {
-          "applicable": false,
-          "values": []
-        },
         "turnover": {
-          "applicable": false,
-          "maxAmountInr": null
+          "applies": null,
+          "maxInr": null,
+          "minInr": null,
+          "text": null
         }
       }
     },
+    "faqs": [],
+    "objectives": [
+      "Supports bringing new technology/automation to modernise the existing unit.",
+      "Component of PMEGP."
+    ],
     "overview": {
+      "background": null,
       "description": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation. Supports bringing new technology/automation to modernise the existing unit. Component of PMEGP.",
-      "keyPointers": [],
-      "objectives": [
-        "Supports bringing new technology/automation to modernise the existing unit.",
-        "Component of PMEGP."
-      ],
-      "summary": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation."
+      "lastUpdated": null,
+      "lastUpdatedText": "Current",
+      "legalBasis": [],
+      "objective": "Supports bringing new technology/automation to modernise the existing unit.",
+      "summary": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation.",
+      "validity": {
+        "from": null,
+        "isOpenEnded": true,
+        "text": null,
+        "to": null
+      },
+      "version": "2nd Loan for Upgradation of existing PMEGP/REGP/MUDRA units"
     },
     "requiredDocuments": [
       {
+        "description": "Udyam Registration",
         "documentTypeId": "CMN000163",
-        "mandatory": true,
-        "name": "Udyam Registration"
+        "documentTypeText": "Udyam Registration",
+        "isMandatory": true,
+        "issuingAuthority": null,
+        "name": "Udyam Registration",
+        "originalRequired": null,
+        "stage": "application",
+        "validityPeriod": null
       }
     ],
     "schemeUrl": "https://www.kviconline.gov.in/pmegpeportal/pmegphome",
@@ -365,12 +475,29 @@
         "type": "official_booklet",
         "url": "https://www.dcmsme.gov.in/ebook/MSMESchemebooklet2025-26.pdf"
       }
-    ]
+    ],
+    "targetBeneficiaries": {
+      "beneficiaryTypes": [
+        "micro_enterprise",
+        "small_enterprise"
+      ],
+      "businessStages": [],
+      "description": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation.",
+      "enterpriseTypes": [
+        "micro",
+        "small"
+      ],
+      "specialCategories": [
+        "ner"
+      ]
+    }
   },
   "identity": {
+    "acronym": null,
     "code": "SCH000220",
-    "fullName": "2nd Loan for Upgradation of existing PMEGP/REGP/MUDRA units",
+    "entityType": "scheme",
     "id": "SCH000220",
+    "language": "en",
     "legacyCodes": [
       {
         "code": "MSME2526-002",
@@ -384,7 +511,7 @@
   },
   "localization": {
     "en": {
-      "applicationText": "Apply online for 2nd loan for upgradation on the PMEGP e-portal. Choose the financing bank (same or different) and implementing agency; bank provides balance cost as term loan.",
+      "applicationText": "Application via both channel",
       "benefitsText": "Maximum project cost for upgradation: Rs. 1.00 crore (manufacturing) and Rs. 25.00 lakh (service/trading). Subsidy: 15% of project cost (maximum Rs. 15 lakh); 20% for NER and Hill States (maximum Rs. 20 lakh). Balance of project cost is provided by banks as term loan.",
       "description": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation. Supports bringing new technology/automation to modernise the existing unit. Component of PMEGP.",
       "eligibilityText": "Existing well-performing PMEGP/REGP/MUDRA units. Margin money claim adjusted and first loan repaid in stipulated time. Unit should have been making profit for the last three years. The 2nd loan should lead to additional employment generation. UAM/Udyam Registration is mandatory. May apply to the same or any other financing bank, and choose any implementing agency.",
@@ -394,14 +521,14 @@
       "summary": "Assists existing well-performing PMEGP/REGP/MUDRA units for expansion and upgradation."
     },
     "hi": {
-      "applicationText": "पीएमईजीपी ई-पोर्टल पर उन्नयन हेतु द्वितीय ऋण के लिए ऑनलाइन आवेदन करें। वित्तपोषक बैंक (वही या अन्य) एवं कार्यान्वयन एजेंसी चुनें; बैंक शेष लागत सावधि ऋण के रूप में देता है।",
-      "benefitsText": "उन्नयन हेतु अधिकतम परियोजना लागत: ₹1.00 करोड़ (विनिर्माण) तथा ₹25.00 लाख (सेवा/व्यापार)। सब्सिडी: परियोजना लागत का 15% (अधिकतम ₹15 लाख); पूर्वोत्तर क्षेत्र एवं पहाड़ी राज्यों में 20% (अधिकतम ₹20 लाख)। शेष परियोजना लागत बैंकों द्वारा सावधि ऋण के रूप में दी जाती है।",
-      "description": "मौजूदा अच्छा प्रदर्शन करने वाली पीएमईजीपी/आरईजीपी/मुद्रा इकाइयों को विस्तार एवं उन्नयन हेतु सहायता। मौजूदा इकाई के आधुनिकीकरण हेतु नई प्रौद्योगिकी/स्वचालन लाने में सहायता। पीएमईजीपी का घटक।",
-      "eligibilityText": "मौजूदा अच्छा प्रदर्शन करने वाली पीएमईजीपी/आरईजीपी/मुद्रा इकाइयाँ। मार्जिन मनी दावा समायोजित हो चुका हो तथा पहला ऋण निर्धारित समय में चुकाया गया हो। इकाई पिछले तीन वर्षों से लाभ में हो। द्वितीय ऋण से अतिरिक्त रोजगार सृजन होना चाहिए। यूएएम/उद्यम पंजीकरण अनिवार्य है। उसी या किसी अन्य वित्तपोषक बैंक में आवेदन कर सकते हैं तथा कोई भी कार्यान्वयन एजेंसी चुन सकते हैं।",
+      "applicationText": null,
+      "benefitsText": null,
+      "description": null,
+      "eligibilityText": null,
       "name": "मौजूदा पीएमईजीपी/आरईजीपी/मुद्रा इकाइयों के उन्नयन हेतु द्वितीय ऋण",
-      "objective": "मौजूदा अच्छा प्रदर्शन करने वाली पीएमईजीपी/आरईजीपी/मुद्रा इकाइयों को विस्तार एवं उन्नयन हेतु सहायता।",
+      "objective": null,
       "shortName": null,
-      "summary": "मौजूदा अच्छा प्रदर्शन करने वाली पीएमईजीपी/आरईजीपी/मुद्रा इकाइयों को विस्तार एवं उन्नयन हेतु सहायता।"
+      "summary": null
     },
     "ta": {
       "applicationText": null,
@@ -415,31 +542,32 @@
     }
   },
   "metadata": {
-    "catalogVersion": "1.35.0-alpha",
+    "catalogVersion": "1.35.1-alpha",
     "createdAt": "2026-10-04T13:50:15Z",
+    "recordStatus": "published",
     "revision": 1,
     "schemaVersion": "1.0.0",
-    "updatedAt": "2026-10-04T13:50:15Z"
+    "updatedAt": "2026-10-04T19:30:32Z"
   },
   "provenance": {
-    "pipelineVersion": "catalog-v3-1-migration",
+    "contributingSourceIds": [
+      "SCH000220-SRC001"
+    ],
+    "defaultSourceTier": 2,
+    "extractedAt": "2026-10-04T00:00:00Z",
+    "extractionMethod": "automated",
+    "fieldSources": [],
+    "pipelineVersion": "catalog-v3.1-migration-1.35.1",
+    "primarySourceId": "SCH000220-SRC001",
     "transformationNotes": [
-      "Migrated from mss_scheme_data_v3_1 (ID: MSME2526-002)",
-      "Action: ADD_CHILD",
-      "Child of SCH000130"
+      "Rebuilt to reference catalog shape in v3.1 migration"
     ],
     "translations": {
       "hi": {
-        "generatedAt": "2026-10-04T00:00:00Z",
+        "generatedAt": "2026-10-04T13:45:56Z",
         "reviewRequired": true,
         "source": "booklet_2025_26_machine_hi",
         "status": "machine"
-      },
-      "ta": {
-        "engine": "none",
-        "note": "Tamil translation pending",
-        "reviewRequired": true,
-        "status": "none"
       }
     }
   },
@@ -463,10 +591,12 @@
         "2nd Loan for Upgradation of existing PMEGP/REGP/MUDRA units"
       ],
       "hi": [
-        "मौजूदा पीएमईजीपी/आरईजीपी/मुद्रा इकाइयों के उन्नयन हेतु द्वितीय ऋण"
+        "पीएम विश्वकर्मा"
       ],
       "ta": []
     },
+    "boostTerms": [],
+    "crossReferences": [],
     "keywords": {
       "en": [
         "loan",
@@ -477,31 +607,39 @@
         "mudra",
         "units"
       ],
-      "hi": [],
       "ta": []
     },
+    "searchRank": null,
     "synonyms": []
   },
   "verification": {
     "confidence": "low",
     "disputedFields": [],
-    "missingFields": [],
-    "notes": "Listed in Booklet 2025-26 as PMEGP component; depends on PMEGP continuation beyond 31.03.2026 (unconfirmed).; Booklet text obtained via WebFetch extraction (fetch model declined full verbatim reproduction); quotes are short phrases returned as evidence, not checked against the PDF by eye.; Max subsidy caps Rs. 15 lakh / Rs. 20 lakh from WebFetch summary (derived as 15%/20% of max project cost); verify against PDF p05.; TOC lists title as '2nd Loan for up-gradation of the existing PMEGP/MUDRA units'; body text includes REGP.; [agent_flag] Booklet text obtained via WebFetch extraction (fetch model declined full verbatim reproduction); quotes are short phrases returned as evidence, not checked against the PDF by eye.; [agent_flag] Max subsidy caps Rs. 15 lakh / Rs. 20 lakh from WebFetch summary (derived as 15%/20% of max project cost); verify against PDF p05.; [agent_flag] TOC lists title as '2nd Loan for up-gradation of the existing PMEGP/MUDRA units'; body text includes REGP.; [status_uncertain] active (low): Listed in Booklet 2025-26 as PMEGP component; depends on PMEGP continuation beyond 31.03.2026 (unconfirmed).",
-    "status": "partially_verified",
+    "isVerified": false,
+    "missingFields": [
+      {
+        "field": "content.applicationTimeline",
+        "reason": "Not available in available sources"
+      },
+      {
+        "field": "content.faqs",
+        "reason": "Not available in available sources"
+      },
+      {
+        "field": "localization.ta",
+        "reason": "Tamil translation pending (D5=English-only)"
+      }
+    ],
+    "notes": "Booklet text obtained via WebFetch extraction (fetch model declined full verbatim reproduction); quotes are short phrases returned as evidence, not checked against the PDF by eye. | Max subsidy caps Rs. 15 lakh / Rs. 20 lakh from WebFetch summary (derived as 15%/20% of max project cost); verify against PDF p05. | TOC lists title as '2nd Loan for up-gradation of the existing PMEGP/MUDRA units'; body text includes REGP.",
+    "researchStatus": "Researched",
+    "reviewDueOn": null,
+    "status": "unverified",
+    "statusText": null,
     "verifiedAgainst": [
       "SCH000220-SRC001"
     ],
     "verifiedAt": "2026-10-04",
-    "verifiedFields": [
-      {
-        "field": "content.schemeUrl",
-        "note": "Official scheme portal",
-        "outcome": "confirmed",
-        "retrievedAt": "2026-10-04",
-        "sourceTier": 5,
-        "url": "https://www.kviconline.gov.in/pmegpeportal/pmegphome",
-        "value": "https://www.kviconline.gov.in/pmegpeportal/pmegphome"
-      }
-    ]
+    "verifiedBy": null,
+    "verifiedFields": []
   }
 }
```

================================================================================
GATE B DELIVERABLE 3: TABLE OF 83 ROWS' SCHEME_TYPE, GOVERNMENT_LEVEL, AND MINISTRY
================================================================================
| Scheme ID | Scheme Type | Level | Ministry | Scheme Name |
|:---|:---|:---|:---|:---|
| `SCH000220` | `capital_subsidy` | `central` | Ministry of Micro, Small and Medium Enterprises | 2nd Loan for Upgradation of existing PMEGP/REGP/MUDRA units |
| `SCH000221` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Entrepreneurship Awareness Programme (EAP) |
| `SCH000222` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Entrepreneurship cum Skill Development Programme (E-SDP) |
| `SCH000223` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Advance Entrepreneurship cum Skill Development Programme (Advance E-SDP) |
| `SCH000224` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Management Development Programme (MDP) |
| `SCH000225` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Advance Management Development Programme (Advance MDP) |
| `SCH000226` | `technology_support` | `central` | Ministry of Micro, Small and Medium Enterprises | Science & Technology |
| `SCH000227` | `market_promotion` | `central` | Ministry of Micro, Small and Medium Enterprises | Domestic Market Promotion |
| `SCH000228` | `facilitation` | `central` | Ministry of Micro, Small and Medium Enterprises | Trade and Industry Related Functional Support Services |
| `SCH000229` | `social_assistance` | `central` | Ministry of Micro, Small and Medium Enterprises | Welfare Measures (Pradhan Mantri Suraksha Bima Yojana for coir workers) |
| `SCH000230` | `market_promotion` | `central` | Ministry of Micro, Small and Medium Enterprises | Market Development Assistance of MSMEs (MDA) |
| `SCH000231` | `market_promotion` | `central` | Ministry of Micro, Small and Medium Enterprises | Capacity Building of First Time MSE Exporters (CBFTE) |
| `SCH000232` | `market_promotion` | `central` | Ministry of Micro, Small and Medium Enterprises | Framework for International Market Intelligence Dissemination (IMID) |
| `SCH000233` | `capital_subsidy` | `central` | Ministry of Micro, Small and Medium Enterprises | Special Credit Linked Capital Subsidy Scheme (SCLCSS) |
| `SCH000234` | `market_promotion` | `central` | Ministry of Micro, Small and Medium Enterprises | Special Marketing Assistance Scheme (SMAS) |
| `SCH000235` | `facilitation` | `central` | Ministry of Micro, Small and Medium Enterprises | Single Point Registration Scheme (SPRS) under NSSH |
| `SCH000236` | `reimbursement` | `central` | Ministry of Micro, Small and Medium Enterprises | Reimbursement of Bank Loan Processing Fee (NSSH) |
| `SCH000237` | `reimbursement` | `central` | Ministry of Micro, Small and Medium Enterprises | Reimbursement of Performance Bank Guarantee charges (NSSH) |
| `SCH000238` | `reimbursement` | `central` | Ministry of Micro, Small and Medium Enterprises | Reimbursement of Testing Fee (NSSH) |
| `SCH000239` | `reimbursement` | `central` | Ministry of Micro, Small and Medium Enterprises | Reimbursement of Export Promotion Council Membership Fee (NSSH) |
| `SCH000240` | `reimbursement` | `central` | Ministry of Micro, Small and Medium Enterprises | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) |
| `SCH000241` | `reimbursement` | `central` | Ministry of Micro, Small and Medium Enterprises | Reimbursement of Management Training Programme Fee (NSSH) |
| `SCH000242` | `market_promotion` | `central` | Ministry of Micro, Small and Medium Enterprises | Modified Market Development Assistance (MMDA) |
| `SCH000243` | `interest_subvention` | `central` | Ministry of Micro, Small and Medium Enterprises | Interest Subsidy Eligibility Certificate Scheme (ISEC) |
| `SCH000244` | `grant` | `central` | Ministry of Micro, Small and Medium Enterprises | Work-shed Scheme for Khadi Artisans |
| `SCH000245` | `grant` | `central` | Ministry of Micro, Small and Medium Enterprises | Strengthening Infrastructure of Existing Weak Khadi Institutions |
| `SCH000246` | `grant` | `central` | Ministry of Micro, Small and Medium Enterprises | Marketing Infrastructure (Khadi) |
| `SCH000247` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Gramodyog Vikas Yojana (GVY) |
| `SCH000248` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Leather Footwear Programme – Gramodyog Vikas Yojana |
| `SCH000249` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana |
| `SCH000250` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana |
| `SCH000251` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Agro-Food Processing Programme – Gramodyog Vikas Yojana |
| `SCH000252` | `training` | `central` | Ministry of Micro, Small and Medium Enterprises | Service Industry Programme (Electrician, Plumber, DigniTEA) – Gramodyog Vikas Yojana |
| `SCH000253` | `technology_support` | `central` | Ministry of Micro, Small and Medium Enterprises | MSME Innovative Scheme (Incubation, Design and IPR) |
| `SCH000254` | `technology_support` | `central` | Ministry of Micro, Small and Medium Enterprises | Digital MSME |
| `SCH000255` | `credit_guarantee` | `central` | Ministry of Finance | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) |
| `SCH000256` | `market_promotion` | `central` | Ministry of Commerce and Industry | Export Promotion Mission (EPM) |
| `SCH000257` | `market_promotion` | `central` | Ministry of Commerce and Industry | Niryat Protsahan (EPM financial enablers) |
| `SCH000258` | `interest_subvention` | `central` | Ministry of Commerce and Industry | Interest Subvention on Pre- and Post-Shipment Export Credit (EPM – Niryat Protsahan) |
| `SCH000259` | `credit_guarantee` | `central` | Ministry of Commerce and Industry | Collateral Support for Export Credit (EPM – Niryat Protsahan) |
| `SCH000260` | `interest_subvention` | `central` | Ministry of Commerce and Industry | Export Factoring Support (EPM – Niryat Protsahan) |
| `SCH000261` | `credit_guarantee` | `central` | Ministry of Commerce and Industry | E-Commerce Export Credit Facility (EPM – Niryat Protsahan) |
| `SCH000262` | `credit_guarantee` | `central` | Ministry of Commerce and Industry | Emerging Export Opportunities – Risk Sharing (EPM – Niryat Protsahan) |
| `SCH000263` | `market_promotion` | `central` | Ministry of Commerce and Industry | Niryat Disha (EPM non-financial & market access enablers) |
| `SCH000264` | `certification_support` | `central` | Ministry of Commerce and Industry | TRACE – Trade Regulations, Accreditation & Compliance Support (EPM – Niryat Disha) |
| `SCH000265` | `reimbursement` | `central` | Ministry of Commerce and Industry | LIFT – Logistics Interventions for Freight & Transport (EPM – Niryat Disha) |
| `SCH000266` | `grant` | `central` | Ministry of Commerce and Industry | INSIGHT – Trade Intelligence & Facilitation (EPM – Niryat Disha) |
| `SCH000267` | `grant` | `central` | Ministry of Commerce and Industry | FLOW – Overseas Warehousing & Fulfilment (EPM – Niryat Disha) |
| `SCH000268` | `grant` | `central` | Ministry of Commerce and Industry | Market Access Support (MAS) (EPM – Niryat Disha) |
| `SCH000269` | `loan` | `central` | Ministry of Finance | Credit Cards for Micro Enterprises Scheme |
| `SCH000270` | `loan` | `central` | Ministry of Finance | Scheme for First-Time Entrepreneurs (Women, SC and ST) – Budget 2025-26 |
| `SCH000271` | `equity_funding` | `central` | Ministry of Commerce and Industry | Startup India Fund of Funds 2.0 (Startup India FoF 2.0) |
| `SCH000272` | `loan` | `central` | Department of Science & Technology | Research, Development and Innovation (RDI) Scheme |
| `SCH000273` | `facilitation` | `central` | Ministry of Finance | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints |
| `SCH000274` | `facilitation` | `central` | Ministry of Micro, Small and Medium Enterprises | Trade Receivables Discounting System (TReDS) |
| `SCH000275` | `grant` | `central` | Ministry of Electronics & Information Technology | GENESIS – Gen-Next Support for Innovative Startups |
| `SCH000276` | `equity_funding` | `central` | Ministry of Micro, Small and Medium Enterprises | SME Growth Fund (Budget 2026-27) |
| `SCH000277` | `technology_support` | `central` | Ministry of Commerce and Industry | National Manufacturing Mission |
| `SCH000278` | `operating_incentive` | `central` | Ministry of Labour and Employment | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme |
| `SCH000279` | `training` | `central` | Ministry of Corporate Affairs | Prime Minister's Internship Scheme (PMIS) |
| `SCH000280` | `training` | `central` | Ministry of Skill Development and Entrepreneurship | Skill India Programme (restructured: PMKVY 4.0, PM-NAPS, JSS) |
| `SCH000281` | `training` | `central` | Ministry of Skill Development and Entrepreneurship | Pradhan Mantri National Apprenticeship Promotion Scheme (PM-NAPS) |
| `SCH000282` | `training` | `central` | Ministry of Skill Development and Entrepreneurship | Jan Shikshan Sansthan (JSS) Scheme |
| `SCH000283` | `capital_subsidy` | `central` | Ministry of Agriculture and Farmers Welfare | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) |
| `SCH000284` | `capital_subsidy` | `central` | Ministry of Agriculture and Farmers Welfare | Mission for Aatmanirbharta in Pulses |
| `SCH000285` | `facilitation` | `central` | Ministry of Agriculture and Farmers Welfare | National Mission on Natural Farming (NMNF) |
| `SCH000286` | `capital_subsidy` | `central` | Ministry of Fisheries, Animal Husbandry and Dairying | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) |
| `SCH000287` | `interest_subvention` | `central` | Ministry of Agriculture and Farmers Welfare | Agriculture Infrastructure Fund (AIF) |
| `SCH000288` | `capital_subsidy` | `central` | Ministry of New and Renewable Energy | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) |
| `SCH000289` | `capital_subsidy` | `central` | Ministry of New and Renewable Energy | PM Surya Ghar: Muft Bijli Yojana |
| `SCH000290` | `capital_subsidy` | `central` | Ministry of Heavy Industries | PM Electric Drive Revolution in Innovative Vehicle Enhancement (PM E-DRIVE) Scheme |
| `SCH000291` | `social_assistance` | `central` | Ministry of Tribal Affairs | Dharti Aaba Janjatiya Gram Utkarsh Abhiyan (DAJGUA) |
| `SCH000292` | `training` | `central` | Ministry of Social Justice and Empowerment | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana |
| `SCH000293` | `social_assistance` | `central` | Ministry of Social Justice and Empowerment | Scheme for Residential Education for Students in High Schools in Targeted Areas (SHRESHTA) |
| `SCH000294` | `social_assistance` | `central` | Ministry of Social Justice and Empowerment | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) |
| `SCH000295` | `training` | `central` | Ministry of Social Justice and Empowerment | National Action for Mechanised Sanitation Ecosystem (NAMASTE) |
| `SCH000296` | `technology_support` | `central` | Ministry of Textiles | Silk Samagra-2 (Integrated Scheme for Development of Silk Industry) |
| `SCH000297` | `training` | `central` | Ministry of Textiles | Samarth – Scheme for Capacity Building in Textiles Sector |
| `SCH000298` | `infrastructure` | `central` | Ministry of Textiles | PM Mega Integrated Textile Region and Apparel (PM MITRA) Parks |
| `SCH000299` | `capital_subsidy` | `central` | Ministry of Fisheries, Animal Husbandry and Dairying | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) |
| `SCH000300` | `interest_subvention` | `central` | Ministry of Fisheries, Animal Husbandry and Dairying | Animal Husbandry Infrastructure Development Fund (AHIDF) |
| `SCH000301` | `grant` | `central` | Ministry of Agriculture and Farmers Welfare | Formation and Promotion of 10,000 Farmer Producer Organisations (FPOs) |
| `SCH000302` | `social_assistance` | `central` | Ministry of Housing and Urban Affairs | Deendayal Jan Aajeevika Yojana – Shehari (DJAY-S) |
