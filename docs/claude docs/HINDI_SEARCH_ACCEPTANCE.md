# Hindi search acceptance set (P5), version 2

Created by Claude on the owner's instruction ("create the queries, find them from government sites"). Machine-readable copy: `hindi_search_queries.json` (the test must be generated from that file). **Version 2 removes archived schemes (SCH000064, SCH000055) from the expected ids** after the reconciliation showed they are closed duplicates.

## Where the wording comes from (read this first)

Government sources found and used: a PIB Hindi release (PMEGP), Lok Sabha Hindi replies on `eparlib` (PMFME, SFURTI), the Vikaspedia Hindi portal (PMEGP, NSSH), and myScheme (ZED, English). The rest are mainstream Hindi explainers and a bank page that quote the official names (Drishti IAS, Vision IAS, Chronicle India, Amar Ujala, Aaj Tak, SBI). **I did not open the Hindi pages on msme.gov.in, mudra.org.in or pmvishwakarma.gov.in directly.** Lower confidence: A7 (ESDP: only a commercial Hindi page) and C5 (exact phrase from explainers).

Expected ids come from your v3.1 changelog and the earlier test output. Preconditions below check them against the published pack and their status.

## The 20 queries

| id | query | expected id(s) | must rank within | spelling variants (blocking) | alternative wording (info only) |
|---|---|---|---|---|---|
| A1 | प्रधानमंत्री रोजगार सृजन कार्यक्रम | SCH000130 | 1 | प्रधानमंत्री रोज़गार सृजन कार्यक्रम | पीएमईजीपी योजना |
| A2 | प्रधानमंत्री मुद्रा योजना | SCH000128 | 1 | - | मुद्रा योजना; पीएम मुद्रा योजना |
| A3 | पीएम विश्वकर्मा योजना | SCH000124 | 1 | - | प्रधानमंत्री विश्वकर्मा योजना; प्रधानमंत्री विश्वकर्मा कौशल सम्मान योजना |
| A4 | सूक्ष्म और लघु उद्यमों के लिए क्रेडिट गारंटी योजना | SCH000038 | 1 | - | सूक्ष्म एवं लघु उद्यमों के लिए क्रेडिट गारंटी फंड ट्रस्ट |
| A5 | पारंपरिक उद्योगों के उन्नयन एवं पुनर्निर्माण के लिए कोष की योजना | SCH000144 | 1 | पारम्परिक उद्योगों के उन्नयन एवं पुनर्निर्माण के लिए कोष की योजना | पारंपरिक उद्योगों के पुनर्जनन के लिए कोष की योजना; परंपरागत उद्योगों के पुनरुद्धार के लिए स्फूर्ति योजना |
| A6 | एमएसएमई सस्टेनेबल (जेडईडी) प्रमाणन योजना | SCH000106 | 1 | - | एमएसएमई सतत (जेडईडी) प्रमाणन योजना; शून्य दोष शून्य प्रभाव प्रमाणन |
| A7 | उद्यमिता कौशल विकास कार्यक्रम | SCH000095 | 1 | - | - |
| A8 | राष्ट्रीय अनुसूचित जाति-अनुसूचित जनजाति हब | SCH000113 | 1 | - | राष्ट्रीय एससी-एसटी हब योजना |
| A9 | प्रधानमंत्री सूक्ष्म खाद्य प्रसंस्करण उद्यम उन्नयन योजना | SCH000219 | 1 | - | प्रधानमंत्री सूक्ष्म खाद्य प्रसंस्करण उद्यमों का औपचारिकीकरण योजना |
| B1 | पीएमईजीपी | SCH000130 | 1 | पीएमइजीपी | - |
| B2 | सीजीटीएमएसई | SCH000038 | 1 | - | - |
| B3 | स्फूर्ति | SCH000144 | 1 | - | - |
| B4 | जेडईडी | SCH000106 | 1 | - | - |
| B5 | पीएमएफएमई | SCH000219 | 1 | पीएम-एफएमई | - |
| C1 | बिना गारंटी का ऋण | SCH000038, SCH000128, SCH000124 | 5 | - | - |
| C2 | व्यापार शुरू करने के लिए लोन | SCH000128, SCH000130 | 5 | - | - |
| C3 | कारीगर और शिल्पकार | SCH000124 | 3 | - | - |
| C4 | परंपरागत उद्योगों का पुनरुद्धार | SCH000144 | 5 | - | पारंपरिक उद्योग क्लस्टर |
| C5 | अनुसूचित जाति जनजाति उद्यमियों के लिए सार्वजनिक खरीद | SCH000113 | 3 | - | - |
| C6 | खाद्य प्रसंस्करण इकाई पर 35% सब्सिडी | SCH000219 | 3 | - | - |

Groups: **A** official full names (rank 1), **B** acronyms typed in Devanagari (rank 1), **C** need-based phrases (rank 3 or 5, see table).

## Controls (not part of the 20)

- **N1** `क्रिकेट विश्वकप टिकट बुकिंग` must return 0 results and must not throw. Unrelated topic must return nothing.
- **N2** `ख्ख्घ्झ्` must return 0 results and must not throw. Gibberish in Devanagari must return nothing and must not throw.
- **R1** `पीएम विश्वकर्मा`: top result must be SCH000124 and at most 3 results. Earlier, 84 schemes carried this alias and the query returned about 84 results. It must return at most 3.

## Pass mark (owner may change it before the run, never after)

- **Group A:** every testable query passes.
- **Group B:** at least 4 of 5.
- **Group C:** at least 5 of 6.
- **Controls:** N1, N2 and R1 pass.
- Equivalent to at least 18 of 20 overall, and the rank-1 name lookups cannot be the ones that fail.
- **Spelling variants** must also rank an expected id in the top 3 or the query fails. Alternative wordings are reported, never blocking.
- **Preconditions:** each expected id must be in the published hi pack with a Devanagari name and have status active. Otherwise the query is `DATA_GAP`, excluded and listed; more than 2 `DATA_GAP` queries blocks acceptance.

## Rules for the executor

- The executor must not change any query, expected id, rank, variant or pass rule in this file. Only the owner changes them.
- The executor must not change search code, taxonomy, synonyms or data after seeing a failure without the owner's written approval.
- Every failure gets one diagnosis: DATA_GAP (expected scheme or its Hindi text missing), TOKENIZATION (the query is not split or normalised as the text is), SYNONYM (same meaning, different word), or RANKING (found but ranked too low). Propose a fix; do not apply it.
- Report for every query: the query text, the ids and names of the top 5 results with ranks, the expected ids and their rank (or NOT FOUND), pass/fail and diagnosis.
- Search code and taxonomy changes are kept in their own commit or branch, separate from the release gate and publish tooling.
- English and Tamil behaviour: run the existing English/Tamil search suites unchanged and paste the results.
- For exact-name queries (groups A and B), also report whether an archived scheme outranks the expected active scheme; the earlier run returned the archived SCH000064 first for a credit-guarantee query.
- A result that only matches through hand-added taxonomy synonyms and has no Hindi text in the pack (for example SCH000017 for the query ऋण in the earlier run) must be flagged as such in the report.

## Sources per query

**A1** प्रधानमंत्री रोजगार सृजन कार्यक्रम  
Why: Official Hindi name of PMEGP as used in a PIB release and the Vikaspedia government portal; some sources spell रोज़गार with a nukta.  
- [government] https://static.pib.gov.in/WriteReadData/specificdocs/documents/2025/jun/doc2025619573101.pdf
- [government] https://hi.vikaspedia.in/viewcontent/agriculture/policies-and-schemes/91594393793f-93094b91c91793e930-935-92a94d93093693f91594d937923/rural-employment?lgn=hi
- [public-sector bank] https://sbi.bank.in/hi/web/get-business-product-information/prime-ministers-employment-generation-program-pmegp-

**A2** प्रधानमंत्री मुद्रा योजना  
Why: Official name of PMMY; mudra.org.in is the portal named in these pages.  
- [news / explainer] https://www.drishtiias.com/hindi/pdf/1775452711.pdf
- [news / explainer] https://www.chronicleindia.in/hindi/current-affairs/13810-pradhan-mantri-mudra-yojana-pmmy-10-glorious-years

**A3** पीएम विश्वकर्मा योजना  
Why: Name as written on the scheme's Hindi coverage; also expanded as प्रधानमंत्री. Regression for the alias bug.  
- [news / explainer] https://drishtiias.com/hindi/pdf/1741808360.pdf
- [news / explainer] https://currentaffairs.khanglobalstudies.com/?p=23618

**A4** सूक्ष्म और लघु उद्यमों के लिए क्रेडिट गारंटी योजना  
Why: Hindi name of the credit guarantee scheme (CGTMSE). SCH000064 ('Guarantee Schemes for MSEs') is ARCHIVED and is not an accepted answer.  
- [news / explainer] https://visionias.in/current-affairs/hi/schemes/ministry-of-micro-small-and-medium-enterprises/sakashhama-oura-lgha-uthayama-ka-le-karadata-garata-yajana-cgmse
- [news / explainer] https://www.amarujala.com/business/business-diary/govt-promotes-credit-guarantee-scheme-for-msmes-to-empower-entrepreneurs-with-collateral-free-loans-2025-07-21

**A5** पारंपरिक उद्योगों के उन्नयन एवं पुनर्निर्माण के लिए कोष की योजना  
Why: SFURTI. A Lok Sabha document spells it पारम्परिक (conjunct म) and uses पुनरुद्धार; both are real official spellings.  
- [news / explainer] https://drishtiias.com/hindi/pdf/1736323185.pdf
- [government] https://eparlib.nic.in/bitstream/123456789/729837/1/7514.pdf

**A6** एमएसएमई सस्टेनेबल (जेडईडी) प्रमाणन योजना  
Why: ZED certification scheme. PIB-derived text also uses सतत instead of सस्टेनेबल.  
- [news / explainer] https://www.drishtiias.com/hindi/prelims-facts/msme-sustainable-certification-scheme
- [news / explainer] https://www.chronicleindia.in/hindi/current-affairs/7611-msme-sustainable-zed-certification-scheme
- [government] https://myscheme.gov.in/schemes/mszcs

**A7** उद्यमिता कौशल विकास कार्यक्रम  
Why: ESDP. LOWER CONFIDENCE: only a commercial Hindi page was found, no government Hindi page. SCH000055 is the ARCHIVED duplicate and is not an accepted answer.  
- [commercial] https://www.bajajfinserv.in/hindi/entrepreneurship-skill-development-program

**A8** राष्ट्रीय अनुसूचित जाति-अनुसूचित जनजाति हब  
Why: NSSH, exact name from the Vikaspedia government portal.  
- [government] https://hi.vikaspedia.in/viewcontent/social-welfare/अनुसूचित-जनजाति-कल्याण/राष्ट्रीय-अनुसूचित-जाति-अनुसूचित-जनजाति-हब?lgn=hi

**A9** प्रधानमंत्री सूक्ष्म खाद्य प्रसंस्करण उद्यम उन्नयन योजना  
Why: PMFME, wording from a Lok Sabha Hindi reply; other documents write औपचारिकीकरण instead of उन्नयन.  
- [government] https://eparlib.sansad.in/bitstream/123456789/3016409/2/AU823_BAYtqe_hindi.pdf
- [news / explainer] https://www.drishtiias.com/hindi/pdf/1701835616.pdf

**B1** पीएमईजीपी  
Why: Acronym as written in Hindi; SBI's Hindi page uses the short-vowel spelling.  
- [public-sector bank] https://sbi.bank.in/hi/web/get-business-product-information/prime-ministers-employment-generation-program-pmegp-
- [government] https://hi.vikaspedia.in/viewcontent/agriculture/policies-and-schemes/91594393793f-93094b91c91793e930-935-92a94d93093693f91594d937923/rural-employment?lgn=hi

**B2** सीजीटीएमएसई  
Why: CGTMSE acronym in Devanagari as printed in a Hindi newspaper report of the ministry statement.  
- [news / explainer] https://www.amarujala.com/business/business-diary/govt-promotes-credit-guarantee-scheme-for-msmes-to-empower-entrepreneurs-with-collateral-free-loans-2025-07-21

**B3** स्फूर्ति  
Why: Common short name of SFURTI.  
- [news / explainer] https://drishtiias.com/hindi/pdf/1736323185.pdf
- [government] https://eparlib.nic.in/bitstream/123456789/729837/1/7514.pdf

**B4** जेडईडी  
Why: ZED acronym in Devanagari.  
- [news / explainer] https://www.drishtiias.com/hindi/prelims-facts/msme-sustainable-certification-scheme
- [news / explainer] https://www.chronicleindia.in/hindi/current-affairs/7611-msme-sustainable-zed-certification-scheme

**B5** पीएमएफएमई  
Why: PMFME acronym as in the Lok Sabha Hindi reply; another document writes पीएम-एफएमई.  
- [government] https://eparlib.sansad.in/bitstream/123456789/3016409/2/AU823_BAYtqe_hindi.pdf

**C1** बिना गारंटी का ऋण  
Why: Collateral-free credit is described this way for the credit guarantee scheme and for PM Vishwakarma loans; Mudra is described as collateral-free too.  
- [news / explainer] https://visionias.in/current-affairs/hi/schemes/ministry-of-micro-small-and-medium-enterprises/sakashhama-oura-lgha-uthayama-ka-le-karadata-garata-yajana-cgmse
- [news / explainer] https://drishtiias.com/hindi/pdf/1741808360.pdf

**C2** व्यापार शुरू करने के लिए लोन  
Why: Everyday phrasing with the loanword लोन instead of ऋण (a synonym test).  
- [news / explainer] https://www.aajtak.in/business/utility/photo/pm-mudra-loan-yojana-how-to-apply-for-20-lakhs-rupees-debt-tutd-2575417-2026-06-16

**C3** कारीगर और शिल्पकार  
Why: How official coverage addresses the beneficiaries. KNOWN WEAK: the earlier run returned ATI first for कारीगर.  
- [news / explainer] https://drishtiias.com/hindi/pdf/1724745544.pdf
- [news / explainer] https://currentaffairs.khanglobalstudies.com/?p=23618

**C4** परंपरागत उद्योगों का पुनरुद्धार  
Why: Lok Sabha wording; differs from the catalog-style पारंपरिक/पुनर्निर्माण (a synonym and spelling test).  
- [government] https://eparlib.nic.in/bitstream/123456789/729837/1/7514.pdf

**C5** अनुसूचित जाति जनजाति उद्यमियों के लिए सार्वजनिक खरीद  
Why: Public procurement is the central feature of NSSH. LOWER CONFIDENCE for the exact phrase: the government page was not opened for it.  
- [government] https://hi.vikaspedia.in/viewcontent/social-welfare/अनुसूचित-जनजाति-कल्याण/राष्ट्रीय-अनुसूचित-जाति-अनुसूचित-जनजाति-हब?lgn=hi
- [news / explainer] https://www.usthadian.com/hi/national-sc-st-entrepreneurship-hub-initiative-hi/

**C6** खाद्य प्रसंस्करण इकाई पर 35% सब्सिडी  
Why: Benefit phrase with a digit and a percent sign, as in the scheme coverage.  
- [news / explainer] https://www.drishtiias.com/hindi/pdf/1701835616.pdf
- [news / explainer] https://www.drishtiias.com/hindi/daily-updates/daily-news-analysis/pm-formalization-of-micro-food-processing-enterprises-scheme-1
