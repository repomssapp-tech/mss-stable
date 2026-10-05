# Search Rank Stability Comparison: `origin/main` vs `HEAD`

**Fixture File:** `frontend/test/fixtures/scheme_search_rank_stability_expected.json`  
**Total Queries Evaluated:** 234  
**Maintained Previous #1 in Top-5:** 154  
**Flagged (Previous #1 Dropped from Top-5):** 80  

---

## 1. Summary of Flagged Queries

Under **Decision D4**, 131 `DRAFT` schemes (including 44 Tamil Nadu state schemes) were excluded from the offline client bundle. Queries whose previous #1 was a draft scheme, or where a newly introduced/enriched active scheme ranked higher, are flagged below:

| # | Query | Previous #1 (`origin/main`) | New #1 (`HEAD`) | Status |
|:---|:---|:---|:---|:---:|
| 1 | I am a woman and need a loan | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Stand-Up India (`TN168`) | **FLAGGED** |
| 7 | I am a woman and need a tax benefit | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | **FLAGGED** |
| 14 | I am a farmer and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 35 | I am a young entrepreneur and need a certificate | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 36 | I am a young entrepreneur and need a insurance | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 37 | I am a young entrepreneur and need a tax benefit | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Startup India Initiative (`TN169`) | **FLAGGED** |
| 38 | I am a young entrepreneur and need a registration | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 39 | I am a young entrepreneur and need a scholarship | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 40 | I am a young entrepreneur and need a pension | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 52 | I am a shopkeeper and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 53 | I am a shopkeeper and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 54 | I am a shopkeeper and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 55 | I am a shopkeeper and need a certificate | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) | **FLAGGED** |
| 60 | I am a shopkeeper and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 62 | I am a dairy owner and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) | **FLAGGED** |
| 63 | I am a dairy owner and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) | **FLAGGED** |
| 64 | I am a dairy owner and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 72 | I am a fisherman and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) | **FLAGGED** |
| 73 | I am a fisherman and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) | **FLAGGED** |
| 74 | I am a fisherman and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 75 | I am a fisherman and need a certificate | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) | **FLAGGED** |
| 80 | I am a fisherman and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) | **FLAGGED** |
| 102 | I am a mechanic and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 103 | I am a mechanic and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 104 | I am a mechanic and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 105 | I am a mechanic and need a certificate | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) | **FLAGGED** |
| 110 | I am a mechanic and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 112 | I am a trader and need a subsidy | Financial Assistance for participation in International Trade Fair (`TN058`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 113 | I am a trader and need a grant | Financial Assistance for participation in International Trade Fair (`TN058`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 114 | I am a trader and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 115 | I am a trader and need a certificate | Financial Assistance for participation in International Trade Fair (`TN058`) | Deemed Exports (`TN040`) | **FLAGGED** |
| 116 | I am a trader and need a insurance | Financial Assistance for participation in International Trade Fair (`TN058`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | **FLAGGED** |
| 118 | I am a trader and need a registration | Financial Assistance for participation in International Trade Fair (`TN058`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) | **FLAGGED** |
| 120 | I am a trader and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | **FLAGGED** |
| 121 | I am a widow and need a loan | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Stand-Up India (`TN168`) | **FLAGGED** |
| 127 | I am a widow and need a tax benefit | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | **FLAGGED** |
| 140 | I am a disabled person and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | **FLAGGED** |
| 142 | I am a senior citizen and need a subsidy | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 143 | I am a senior citizen and need a grant | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 144 | I am a senior citizen and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 145 | I am a senior citizen and need a certificate | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) | **FLAGGED** |
| 146 | I am a senior citizen and need a insurance | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Shakti Sadan (`TN156`) | **FLAGGED** |
| 147 | I am a senior citizen and need a tax benefit | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Deemed Exports (`TN040`) | **FLAGGED** |
| 148 | I am a senior citizen and need a registration | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) | **FLAGGED** |
| 150 | I am a senior citizen and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | NONE (`NONE`) | **FLAGGED** |
| 162 | I am a migrant worker and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 163 | I am a migrant worker and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 164 | I am a migrant worker and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 165 | I am a migrant worker and need a certificate | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) | **FLAGGED** |
| 170 | I am a migrant worker and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | National Action for Mechanised Sanitation Ecosystem (NAMASTE) (`SCH000295`) | **FLAGGED** |
| 175 | I am a startup founder and need a certificate | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 176 | I am a startup founder and need a insurance | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 177 | I am a startup founder and need a tax benefit | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Startup India Initiative (`TN169`) | **FLAGGED** |
| 178 | I am a startup founder and need a registration | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 179 | I am a startup founder and need a scholarship | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 180 | I am a startup founder and need a pension | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 182 | I am an exporter and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 183 | I am an exporter and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 184 | I am an exporter and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 185 | I am an exporter and need a certificate | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) | **FLAGGED** |
| 186 | I am an exporter and need a insurance | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) | **FLAGGED** |
| 187 | I am an exporter and need a tax benefit | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) | **FLAGGED** |
| 188 | I am an exporter and need a registration | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) | **FLAGGED** |
| 190 | I am an exporter and need a pension | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) | **FLAGGED** |
| 192 | I am a manufacturer and need a subsidy | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 193 | I am a manufacturer and need a grant | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 194 | I am a manufacturer and need a training | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) | **FLAGGED** |
| 195 | I am a manufacturer and need a certificate | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) | **FLAGGED** |
| 200 | I am a manufacturer and need a pension | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Deemed Exports (`TN040`) | **FLAGGED** |
| 201 | women entrepreneur loan subsidy scheme in Tamil Nadu | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Stand-Up India (`TN168`) | **FLAGGED** |
| 207 | pension scheme for senior citizens with disability | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | **FLAGGED** |
| 208 | credit guarantee scheme for women led startup | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | Women Entrepreneurship Platform (WEP) (`TN212`) | **FLAGGED** |
| 209 | buisness loan for wome entreprenur | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Entrepreneurship Platform (WEP) (`TN212`) | **FLAGGED** |
| 212 | msme regstration certifcate | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 213 | pention scheme for seniors | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | NONE (`NONE`) | **FLAGGED** |
| 214 | exoprt incentive for manufactuer | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |
| 218 | பெண் தொழில் முனைவோருக்கு கடன் திட்டம் | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Stand-Up India (`TN168`) | **FLAGGED** |
| 220 | மூத்த குடிமக்களுக்கு ஓய்வூதியம் | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | NONE (`NONE`) | **FLAGGED** |
| 221 | குறு தொழில் பதிவு சான்றிதழ் | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | **FLAGGED** |
| 223 | இயந்திரம் வாங்க மானியம் | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) | **FLAGGED** |

---

## 2. Complete Side-by-Side Top-5 Results for All 234 Queries

### Query 1: `I am a woman and need a loan` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Stand-Up India (`TN168`) |
| #2 | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | Dena Shakti Scheme (`TN044`) |
| #3 | Nagaland Startup Fund - 25% Reservation for Women-led Ventures (`TN108`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #4 | Stand-Up India (`TN168`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #5 | Dena Shakti Scheme (`TN044`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |

### Query 2: `I am a woman and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Maharashtra Women-led Startup GST/Utility/Participation Reimbursement Support (`TN081`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #4 | Mahila Coir Yojana (MCY) (`TN082`) | Women Helpline (WHL 181) (`TN213`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Mission Shakti (`TN097`) |

### Query 3: `I am a woman and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Maharashtra Women-led Startup GST/Utility/Participation Reimbursement Support (`TN081`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #4 | Mahila Coir Yojana (MCY) (`TN082`) | Women Helpline (WHL 181) (`TN213`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Mission Shakti (`TN097`) |

### Query 4: `I am a woman and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #3 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #4 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #5 | Support to Training and Employment Programme for Women (STEP) (`TN179`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |

### Query 5: `I am a woman and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #5 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Women Entrepreneurship Platform (WEP) (`TN212`) |

### Query 6: `I am a woman and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |

### Query 7: `I am a woman and need a tax benefit` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |
| #4 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |

### Query 8: `I am a woman and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |

### Query 9: `I am a woman and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #3 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #4 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |

### Query 10: `I am a woman and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Mission Shakti (`TN097`) |

### Query 11: `I am a farmer and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | Bank Credit Facilitation Scheme (`TN018`) |
| #4 | General Purpose Term Loan (`TN061`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |

### Query 12: `I am a farmer and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #4 | Capital Subsidy (`TN028`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |
| #5 | Generator Subsidy (`TN062`) | Formation and Promotion of 10,000 Farmer Producer Organisations (FPOs) (`SCH000301`) |

### Query 13: `I am a farmer and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #4 | Capital Subsidy (`TN028`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |
| #5 | Generator Subsidy (`TN062`) | Formation and Promotion of 10,000 Farmer Producer Organisations (FPOs) (`SCH000301`) |

### Query 14: `I am a farmer and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #3 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #4 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #5 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |

### Query 15: `I am a farmer and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Namo Drone Didi (`TN049`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | Stand-Up India Scheme (`TN218`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #4 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | National Mission on Natural Farming (NMNF) (`SCH000285`) |
| #5 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |

### Query 16: `I am a farmer and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Namo Drone Didi (`TN049`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | Stand-Up India Scheme (`TN218`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #4 | Priority Sector Lending (`TN131`) | National Mission on Natural Farming (NMNF) (`SCH000285`) |
| #5 | Shakti Sadan (`TN156`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |

### Query 17: `I am a farmer and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Namo Drone Didi (`TN049`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | Stand-Up India Scheme (`TN218`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #4 | Deemed Exports (`TN040`) | National Mission on Natural Farming (NMNF) (`SCH000285`) |
| #5 | Startup India Initiative (`TN169`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |

### Query 18: `I am a farmer and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Udyam Registration (`TN197`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | Namo Drone Didi (`TN049`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #4 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | National Mission on Natural Farming (NMNF) (`SCH000285`) |
| #5 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |

### Query 19: `I am a farmer and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #4 | Atal Tinkering Labs (ATLs) (`TN016`) | Tamil Puthalvan Scheme (`TN185`) |
| #5 | Naan Mudhalvan (`TN107`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |

### Query 20: `I am a farmer and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | Namo Drone Didi (`TN049`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #4 | Stand-Up India Scheme (`TN218`) | National Mission on Natural Farming (NMNF) (`SCH000285`) |
| #5 | Priority Sector Lending (`TN131`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |

### Query 21: `I am a student and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #3 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #4 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 22: `I am a student and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #5 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |

### Query 23: `I am a student and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #5 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |

### Query 24: `I am a student and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #3 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri National Apprenticeship Promotion Scheme (PM-NAPS) (`SCH000281`) |
| #4 | Tool Rooms and Technical Institutions (`TN193`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #5 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Skill India Programme (restructured: PMKVY 4.0, PM-NAPS, JSS) (`SCH000280`) |

### Query 25: `I am a student and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 26: `I am a student and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |

### Query 27: `I am a student and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | Deemed Exports (`TN040`) |

### Query 28: `I am a student and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |

### Query 29: `I am a student and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 30: `I am a student and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Naan Mudhalvan (`TN107`) |
| #5 | Naan Mudhalvan (`TN107`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 31: `I am a young entrepreneur and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | Secured Business Loans for MSMEs (`TN152`) | Secured Business Loans for MSMEs (`TN152`) |
| #4 | General Purpose Term Loan (`TN061`) | Stand-Up India (`TN168`) |
| #5 | Stand-Up India (`TN168`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 32: `I am a young entrepreneur and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #2 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Capital Subsidy (`TN028`) |
| #4 | Incentives to entrepreneurs for shifting of existing units outside Urban areas (`TN067`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #5 | Capital Subsidy (`TN028`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 33: `I am a young entrepreneur and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #2 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Capital Subsidy (`TN028`) |
| #4 | Incentives to entrepreneurs for shifting of existing units outside Urban areas (`TN067`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #5 | Capital Subsidy (`TN028`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 34: `I am a young entrepreneur and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #4 | Assistance to Training Institutions (ATI) Scheme (`TN013`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Skill training and Employment Scheme (`TN163`) | Assistance to Training Institutions (ATI) Scheme (`TN013`) |

### Query 35: `I am a young entrepreneur and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Startup India Initiative (`TN169`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 36: `I am a young entrepreneur and need a insurance` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Startup India Initiative (`TN169`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 37: `I am a young entrepreneur and need a tax benefit` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Startup India Initiative (`TN169`) |
| #2 | Startup India Initiative (`TN169`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #5 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 38: `I am a young entrepreneur and need a registration` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Udyam Registration (`TN197`) |
| #5 | Udyam Registration (`TN197`) | Startup India Initiative (`TN169`) |

### Query 39: `I am a young entrepreneur and need a scholarship` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #3 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #4 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 40: `I am a young entrepreneur and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Startup India Initiative (`TN169`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 41: `I am a weaver and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #4 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 42: `I am a weaver and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Capital Subsidy (`TN028`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |

### Query 43: `I am a weaver and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Capital Subsidy (`TN028`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |

### Query 44: `I am a weaver and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #4 | Skill training and Employment Scheme (`TN163`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |

### Query 45: `I am a weaver and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Pottery Activity- Gramodyog Vikas Yojana (GVY) (`TN125`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 46: `I am a weaver and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Pottery Activity- Gramodyog Vikas Yojana (GVY) (`TN125`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 47: `I am a weaver and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Khadi Vikas Yojana (`TN076`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 48: `I am a weaver and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Udyam Registration (`TN197`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #5 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |

### Query 49: `I am a weaver and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Atal Tinkering Labs (ATLs) (`TN016`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #5 | Naan Mudhalvan (`TN107`) | Atal Tinkering Labs (ATLs) (`TN016`) |

### Query 50: `I am a weaver and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 51: `I am a shopkeeper and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 52: `I am a shopkeeper and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 53: `I am a shopkeeper and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 54: `I am a shopkeeper and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 55: `I am a shopkeeper and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #2 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | International Cooperation (`TN071`) |
| #3 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | Udyam Registration (`TN197`) |
| #4 | Status Holder Certificate (`TN172`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #5 | International Cooperation (`TN071`) | - |

### Query 56: `I am a shopkeeper and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Shakti Sadan (`TN156`) | Shakti Sadan (`TN156`) |
| #2 | International Cooperation (`TN071`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #3 | Special Capital Subsidy for Thrust Sector Enterprises (`TN166`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #4 | One Stop Centres (OSCs / Sakhi Centres) (`TN118`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #5 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Dharti Aaba Janjatiya Gram Utkarsh Abhiyan (DAJGUA) (`SCH000291`) |

### Query 57: `I am a shopkeeper and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #2 | Startup India Initiative (`TN169`) | Startup India Initiative (`TN169`) |
| #3 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |
| #4 | Beti Bachao Beti Padhao (BBBP) (`TN020`) | Beti Bachao Beti Padhao (BBBP) (`TN020`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |

### Query 58: `I am a shopkeeper and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Udyam Registration (`TN197`) |
| #3 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Udyam Assist Platform (`TN196`) |
| #4 | Subsidy for Asset Creation for Intellectual Property (`TN174`) | MSME Innovative Scheme (Intellectual Property Rights - IPR) (`TN104`) |
| #5 | Udyam Assist Platform (`TN196`) | International Cooperation (`TN071`) |

### Query 59: `I am a shopkeeper and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 60: `I am a shopkeeper and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 61: `I am a dairy owner and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Cent Kalyani (`TN029`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 62: `I am a dairy owner and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | Capital Subsidy (`TN028`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #5 | Generator Subsidy (`TN062`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |

### Query 63: `I am a dairy owner and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | Capital Subsidy (`TN028`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #5 | Generator Subsidy (`TN062`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |

### Query 64: `I am a dairy owner and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |

### Query 65: `I am a dairy owner and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #5 | Status Holder Certificate (`TN172`) | National SC-ST Hub Scheme (`TN113`) |

### Query 66: `I am a dairy owner and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Shakti Sadan (`TN156`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Nannilam Women Landownership Scheme (`TN110`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | National SC-ST Hub Scheme (`TN113`) | Shakti Sadan (`TN156`) |
| #5 | Cent Kalyani (`TN029`) | National SC-ST Hub Scheme (`TN113`) |

### Query 67: `I am a dairy owner and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Deemed Exports (`TN040`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Startup India Initiative (`TN169`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | National SC-ST Hub Scheme (`TN113`) | Deemed Exports (`TN040`) |
| #5 | Nannilam Women Landownership Scheme (`TN110`) | Startup India Initiative (`TN169`) |

### Query 68: `I am a dairy owner and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Udyam Registration (`TN197`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #4 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Udyam Registration (`TN197`) |
| #5 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |

### Query 69: `I am a dairy owner and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #5 | Naan Mudhalvan (`TN107`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |

### Query 70: `I am a dairy owner and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #2 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Nannilam Women Landownership Scheme (`TN110`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #5 | Cent Kalyani (`TN029`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |

### Query 71: `I am a fisherman and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 72: `I am a fisherman and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | Capital Subsidy (`TN028`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Generator Subsidy (`TN062`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Back-ended Interest Subsidy (`TN017`) |

### Query 73: `I am a fisherman and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | Capital Subsidy (`TN028`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Generator Subsidy (`TN062`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Back-ended Interest Subsidy (`TN017`) |

### Query 74: `I am a fisherman and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 75: `I am a fisherman and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #4 | Status Holder Certificate (`TN172`) | International Cooperation (`TN071`) |
| #5 | International Cooperation (`TN071`) | Udyam Registration (`TN197`) |

### Query 76: `I am a fisherman and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Shakti Sadan (`TN156`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | International Cooperation (`TN071`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | Special Capital Subsidy for Thrust Sector Enterprises (`TN166`) | Shakti Sadan (`TN156`) |
| #4 | One Stop Centres (OSCs / Sakhi Centres) (`TN118`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #5 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |

### Query 77: `I am a fisherman and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Deemed Exports (`TN040`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | Startup India Initiative (`TN169`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Deemed Exports (`TN040`) |
| #4 | Beti Bachao Beti Padhao (BBBP) (`TN020`) | Startup India Initiative (`TN169`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |

### Query 78: `I am a fisherman and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #3 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Udyam Registration (`TN197`) |
| #4 | Subsidy for Asset Creation for Intellectual Property (`TN174`) | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #5 | Udyam Assist Platform (`TN196`) | Udyam Assist Platform (`TN196`) |

### Query 79: `I am a fisherman and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #4 | Naan Mudhalvan (`TN107`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #5 | Sponsorship of students (`TN167`) | Naan Mudhalvan (`TN107`) |

### Query 80: `I am a fisherman and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Pradhan Mantri Matsya Kisan Samridhi Sah-Yojana (PM-MKSSY) (`SCH000286`) |
| #2 | - | National Livestock Mission – Entrepreneurship Development Programme (NLM-EDP) (`SCH000299`) |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 81: `I am an artisan and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #4 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 82: `I am an artisan and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Capital Subsidy (`TN028`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |

### Query 83: `I am an artisan and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Capital Subsidy (`TN028`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |

### Query 84: `I am an artisan and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #4 | Skill training and Employment Scheme (`TN163`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |

### Query 85: `I am an artisan and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Pottery Activity- Gramodyog Vikas Yojana (GVY) (`TN125`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 86: `I am an artisan and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Pottery Activity- Gramodyog Vikas Yojana (GVY) (`TN125`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 87: `I am an artisan and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Khadi Vikas Yojana (`TN076`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 88: `I am an artisan and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Udyam Registration (`TN197`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #5 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |

### Query 89: `I am an artisan and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Atal Tinkering Labs (ATLs) (`TN016`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #5 | Naan Mudhalvan (`TN107`) | Atal Tinkering Labs (ATLs) (`TN016`) |

### Query 90: `I am an artisan and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 91: `I am a tailor and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #4 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 92: `I am a tailor and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Capital Subsidy (`TN028`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |

### Query 93: `I am a tailor and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Capital Subsidy (`TN028`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |

### Query 94: `I am a tailor and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #4 | Skill training and Employment Scheme (`TN163`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |

### Query 95: `I am a tailor and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Pottery Activity- Gramodyog Vikas Yojana (GVY) (`TN125`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 96: `I am a tailor and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Pottery Activity- Gramodyog Vikas Yojana (GVY) (`TN125`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 97: `I am a tailor and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Khadi Vikas Yojana (`TN076`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 98: `I am a tailor and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Udyam Registration (`TN197`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #5 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |

### Query 99: `I am a tailor and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Atal Tinkering Labs (ATLs) (`TN016`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #5 | Naan Mudhalvan (`TN107`) | Atal Tinkering Labs (ATLs) (`TN016`) |

### Query 100: `I am a tailor and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Waste Wood / Turn Wood Craft Programme – Gramodyog Vikas Yojana (`SCH000249`) |
| #3 | Mahila Coir Yojana (MCY) (`TN082`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Market Promotion and Development Assistance (MPDA) (`TN089`) | Hand Made Paper & Fibre Activities – Gramodyog Vikas Yojana (`SCH000250`) |
| #5 | Revamped Scheme of Fund for Regeneration of Traditional Industries (SFURTI) (`TN144`) | Gramodyog Vikas Yojana (GVY) (`SCH000247`) |

### Query 101: `I am a mechanic and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 102: `I am a mechanic and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 103: `I am a mechanic and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 104: `I am a mechanic and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 105: `I am a mechanic and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #2 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | International Cooperation (`TN071`) |
| #3 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | Udyam Registration (`TN197`) |
| #4 | Status Holder Certificate (`TN172`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #5 | International Cooperation (`TN071`) | - |

### Query 106: `I am a mechanic and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Shakti Sadan (`TN156`) | Shakti Sadan (`TN156`) |
| #2 | International Cooperation (`TN071`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #3 | Special Capital Subsidy for Thrust Sector Enterprises (`TN166`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #4 | One Stop Centres (OSCs / Sakhi Centres) (`TN118`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #5 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Dharti Aaba Janjatiya Gram Utkarsh Abhiyan (DAJGUA) (`SCH000291`) |

### Query 107: `I am a mechanic and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #2 | Startup India Initiative (`TN169`) | Startup India Initiative (`TN169`) |
| #3 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |
| #4 | Beti Bachao Beti Padhao (BBBP) (`TN020`) | Beti Bachao Beti Padhao (BBBP) (`TN020`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |

### Query 108: `I am a mechanic and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Udyam Registration (`TN197`) |
| #3 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Udyam Assist Platform (`TN196`) |
| #4 | Subsidy for Asset Creation for Intellectual Property (`TN174`) | MSME Innovative Scheme (Intellectual Property Rights - IPR) (`TN104`) |
| #5 | Udyam Assist Platform (`TN196`) | International Cooperation (`TN071`) |

### Query 109: `I am a mechanic and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 110: `I am a mechanic and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 111: `I am a trader and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) |
| #4 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 112: `I am a trader and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Financial Assistance for participation in International Trade Fair (`TN058`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Capital Subsidy (`TN028`) | Capital Subsidy (`TN028`) |
| #5 | Generator Subsidy (`TN062`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 113: `I am a trader and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Financial Assistance for participation in International Trade Fair (`TN058`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Capital Subsidy (`TN028`) | Capital Subsidy (`TN028`) |
| #5 | Generator Subsidy (`TN062`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 114: `I am a trader and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 115: `I am a trader and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Financial Assistance for participation in International Trade Fair (`TN058`) | Deemed Exports (`TN040`) |
| #2 | Deemed Exports (`TN040`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) |
| #3 | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | Trade Receivables Discounting System (TReDS) (`SCH000274`) |
| #4 | Status Holder Certificate (`TN172`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #5 | Trade and Industry Related Functional Support (`TN194`) | TRACE – Trade Regulations, Accreditation & Compliance Support (EPM – Niryat Disha) (`SCH000264`) |

### Query 116: `I am a trader and need a insurance` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Financial Assistance for participation in International Trade Fair (`TN058`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) |
| #2 | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | Trade Receivables Discounting System (TReDS) (`SCH000274`) |
| #3 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #4 | Trade and Industry Related Functional Support (`TN194`) | TRACE – Trade Regulations, Accreditation & Compliance Support (EPM – Niryat Disha) (`SCH000264`) |
| #5 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |

### Query 117: `I am a trader and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #2 | Financial Assistance for participation in International Trade Fair (`TN058`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) |
| #3 | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | Trade Receivables Discounting System (TReDS) (`SCH000274`) |
| #4 | Trade and Industry Related Functional Support (`TN194`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #5 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Startup India Initiative (`TN169`) |

### Query 118: `I am a trader and need a registration` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Financial Assistance for participation in International Trade Fair (`TN058`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Udyam Registration (`TN197`) | Udyam Registration (`TN197`) |
| #3 | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | Trade Receivables Discounting System (TReDS) (`SCH000274`) |
| #4 | Deemed Exports (`TN040`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) |
| #5 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Deemed Exports (`TN040`) |

### Query 119: `I am a trader and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Financial Assistance for participation in International Trade Fair (`TN058`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) |

### Query 120: `I am a trader and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) |
| #2 | Financial Assistance for participation in International Trade Fair (`TN058`) | Trade Receivables Discounting System (TReDS) (`SCH000274`) |
| #3 | Domestic events: participating and visiting business explorations / exhibitions (`TN045`) | Deemed Exports (`TN040`) |
| #4 | Deemed Exports (`TN040`) | TRACE – Trade Regulations, Accreditation & Compliance Support (EPM – Niryat Disha) (`SCH000264`) |
| #5 | Trade and Industry Related Functional Support (`TN194`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |

### Query 121: `I am a widow and need a loan` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Stand-Up India (`TN168`) |
| #2 | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | Dena Shakti Scheme (`TN044`) |
| #3 | Nagaland Startup Fund - 25% Reservation for Women-led Ventures (`TN108`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #4 | Stand-Up India (`TN168`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #5 | Dena Shakti Scheme (`TN044`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |

### Query 122: `I am a widow and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Maharashtra Women-led Startup GST/Utility/Participation Reimbursement Support (`TN081`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #4 | Mahila Coir Yojana (MCY) (`TN082`) | Women Helpline (WHL 181) (`TN213`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Mission Shakti (`TN097`) |

### Query 123: `I am a widow and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #3 | Maharashtra Women-led Startup GST/Utility/Participation Reimbursement Support (`TN081`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #4 | Mahila Coir Yojana (MCY) (`TN082`) | Women Helpline (WHL 181) (`TN213`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Mission Shakti (`TN097`) |

### Query 124: `I am a widow and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #2 | Mahila Coir Yojana (MCY) (`TN082`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #3 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #4 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #5 | Support to Training and Employment Programme for Women (STEP) (`TN179`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |

### Query 125: `I am a widow and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #5 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Women Entrepreneurship Platform (WEP) (`TN212`) |

### Query 126: `I am a widow and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |

### Query 127: `I am a widow and need a tax benefit` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |
| #4 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |

### Query 128: `I am a widow and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |

### Query 129: `I am a widow and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #3 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #4 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #5 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |

### Query 130: `I am a widow and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Helpline (WHL 181) (`TN213`) |
| #3 | Women Helpline (WHL 181) (`TN213`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |
| #4 | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Mission Shakti (`TN097`) |

### Query 131: `I am a disabled person and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 132: `I am a disabled person and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Back-ended Interest Subsidy (`TN017`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 133: `I am a disabled person and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #4 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Back-ended Interest Subsidy (`TN017`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 134: `I am a disabled person and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #2 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #3 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Entrepreneurship Awareness Programme (EAP) (`SCH000221`) |

### Query 135: `I am a disabled person and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #2 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #3 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #4 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #5 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |

### Query 136: `I am a disabled person and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #2 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #3 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #4 | Shakti Sadan (`TN156`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #5 | International Cooperation (`TN071`) | Shakti Sadan (`TN156`) |

### Query 137: `I am a disabled person and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #2 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #3 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #4 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #5 | Startup India Initiative (`TN169`) | Startup India Initiative (`TN169`) |

### Query 138: `I am a disabled person and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Udyam Registration (`TN197`) |
| #2 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #3 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #4 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #5 | Reimbursement of Stamp duty and Registration charges (`TN142`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 139: `I am a disabled person and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #5 | Naan Mudhalvan (`TN107`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |

### Query 140: `I am a disabled person and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #2 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #3 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #4 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #5 | Procurement and Marketing Support (PMS) Scheme (`TN132`) | Entrepreneurship Awareness Programme (EAP) (`SCH000221`) |

### Query 141: `I am a senior citizen and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 142: `I am a senior citizen and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Capital Subsidy (`TN028`) | Capital Subsidy (`TN028`) |
| #5 | Generator Subsidy (`TN062`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 143: `I am a senior citizen and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Capital Subsidy (`TN028`) | Capital Subsidy (`TN028`) |
| #5 | Generator Subsidy (`TN062`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 144: `I am a senior citizen and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 145: `I am a senior citizen and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | International Cooperation (`TN071`) |
| #3 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Udyam Registration (`TN197`) |
| #4 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | - |
| #5 | Status Holder Certificate (`TN172`) | - |

### Query 146: `I am a senior citizen and need a insurance` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Shakti Sadan (`TN156`) |
| #2 | Shakti Sadan (`TN156`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #3 | International Cooperation (`TN071`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #4 | Special Capital Subsidy for Thrust Sector Enterprises (`TN166`) | Dharti Aaba Janjatiya Gram Utkarsh Abhiyan (DAJGUA) (`SCH000291`) |
| #5 | One Stop Centres (OSCs / Sakhi Centres) (`TN118`) | International Cooperation (`TN071`) |

### Query 147: `I am a senior citizen and need a tax benefit` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Deemed Exports (`TN040`) |
| #2 | Deemed Exports (`TN040`) | Startup India Initiative (`TN169`) |
| #3 | Startup India Initiative (`TN169`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |
| #4 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Beti Bachao Beti Padhao (BBBP) (`TN020`) |
| #5 | Beti Bachao Beti Padhao (BBBP) (`TN020`) | SANKALP: Hub for Empowerment of Women (HEW) (`TN146`) |

### Query 148: `I am a senior citizen and need a registration` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Udyam Registration (`TN197`) | Udyam Registration (`TN197`) |
| #3 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Udyam Assist Platform (`TN196`) |
| #4 | Reimbursement of Stamp duty and Registration charges (`TN142`) | MSME Innovative Scheme (Intellectual Property Rights - IPR) (`TN104`) |
| #5 | Subsidy for Asset Creation for Intellectual Property (`TN174`) | International Cooperation (`TN071`) |

### Query 149: `I am a senior citizen and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Naan Mudhalvan (`TN107`) |
| #5 | Naan Mudhalvan (`TN107`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 150: `I am a senior citizen and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 151: `I am a tribal community member and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Stand-Up India (`TN168`) | Stand-Up India (`TN168`) |
| #2 | Stand-Up India Scheme (`TN218`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |
| #3 | Bank Credit Facilitation Scheme (`TN018`) | Stand-Up India Scheme (`TN218`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Bank Credit Facilitation Scheme (`TN018`) |
| #5 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) |

### Query 152: `I am a tribal community member and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #2 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | National SC-ST Hub Scheme (`TN113`) |
| #3 | Annal Ambedkar Business Champions Scheme (`TN008`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #4 | Stand-Up India (`TN168`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #5 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 153: `I am a tribal community member and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #2 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | National SC-ST Hub Scheme (`TN113`) |
| #3 | Annal Ambedkar Business Champions Scheme (`TN008`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #4 | Stand-Up India (`TN168`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #5 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 154: `I am a tribal community member and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #2 | National SC-ST Hub Scheme (`TN113`) | Jan Shikshan Sansthan (JSS) Scheme (`SCH000282`) |
| #3 | Skill training and Employment Scheme (`TN163`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #4 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Reimbursement of Management Training Programme Fee (NSSH) (`SCH000241`) |
| #5 | Nai Roshni (`TN109`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |

### Query 155: `I am a tribal community member and need a certificate` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #2 | Stand-Up India (`TN168`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #3 | Stand-Up India Scheme (`TN218`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #4 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Stand-Up India (`TN168`) |
| #5 | Annal Ambedkar Business Champions Scheme (`TN008`) | Stand-Up India Scheme (`TN218`) |

### Query 156: `I am a tribal community member and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #2 | Stand-Up India (`TN168`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #3 | Stand-Up India Scheme (`TN218`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #4 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Stand-Up India (`TN168`) |
| #5 | Annal Ambedkar Business Champions Scheme (`TN008`) | Stand-Up India Scheme (`TN218`) |

### Query 157: `I am a tribal community member and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #2 | Stand-Up India (`TN168`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #3 | Stand-Up India Scheme (`TN218`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #4 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Stand-Up India (`TN168`) |
| #5 | Annal Ambedkar Business Champions Scheme (`TN008`) | Stand-Up India Scheme (`TN218`) |

### Query 158: `I am a tribal community member and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Stand-Up India (`TN168`) | National SC-ST Hub Scheme (`TN113`) |
| #3 | Stand-Up India Scheme (`TN218`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #4 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #5 | Annal Ambedkar Business Champions Scheme (`TN008`) | Stand-Up India (`TN168`) |

### Query 159: `I am a tribal community member and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #3 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #4 | Annal Ambedkar Business Champions Scheme (`TN008`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #5 | Stand-Up India (`TN168`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 160: `I am a tribal community member and need a pension` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #2 | Stand-Up India (`TN168`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #3 | Stand-Up India Scheme (`TN218`) | Reimbursement of Government e-Commerce Portals Membership Fee (NSSH) (`SCH000240`) |
| #4 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Stand-Up India (`TN168`) |
| #5 | Annal Ambedkar Business Champions Scheme (`TN008`) | Stand-Up India Scheme (`TN218`) |

### Query 161: `I am a migrant worker and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 162: `I am a migrant worker and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Generator Subsidy (`TN062`) | Back-ended Interest Subsidy (`TN017`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Capital Subsidy (`TN028`) |

### Query 163: `I am a migrant worker and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Generator Subsidy (`TN062`) | Back-ended Interest Subsidy (`TN017`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Capital Subsidy (`TN028`) |

### Query 164: `I am a migrant worker and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 165: `I am a migrant worker and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #2 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | National Action for Mechanised Sanitation Ecosystem (NAMASTE) (`SCH000295`) |
| #3 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | Status Holder Certificate (`TN172`) | Prime Minister's Internship Scheme (PMIS) (`SCH000279`) |
| #5 | Coir Vikas Yojana (`TN033`) | Coir Vikas Yojana (`TN033`) |

### Query 166: `I am a migrant worker and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Shakti Sadan (`TN156`) | National Action for Mechanised Sanitation Ecosystem (NAMASTE) (`SCH000295`) |
| #2 | Coir Vikas Yojana (`TN033`) | Prime Minister's Internship Scheme (PMIS) (`SCH000279`) |
| #3 | Science and Technology Scheme (`TN151`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #4 | International Cooperation (`TN071`) | Shakti Sadan (`TN156`) |
| #5 | Special Capital Subsidy for Thrust Sector Enterprises (`TN166`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |

### Query 167: `I am a migrant worker and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #2 | Startup India Initiative (`TN169`) | Startup India Initiative (`TN169`) |
| #3 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | National Action for Mechanised Sanitation Ecosystem (NAMASTE) (`SCH000295`) |
| #4 | Beti Bachao Beti Padhao (BBBP) (`TN020`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #5 | Coir Vikas Yojana (`TN033`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |

### Query 168: `I am a migrant worker and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Udyam Registration (`TN197`) |
| #3 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Udyam Assist Platform (`TN196`) |
| #4 | Subsidy for Asset Creation for Intellectual Property (`TN174`) | National Action for Mechanised Sanitation Ecosystem (NAMASTE) (`SCH000295`) |
| #5 | Udyam Assist Platform (`TN196`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |

### Query 169: `I am a migrant worker and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | Prime Minister's Internship Scheme (PMIS) (`SCH000279`) |

### Query 170: `I am a migrant worker and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | National Action for Mechanised Sanitation Ecosystem (NAMASTE) (`SCH000295`) |
| #2 | Coir Vikas Yojana (`TN033`) | Work-shed Scheme for Khadi Artisans (`SCH000244`) |
| #3 | Science and Technology Scheme (`TN151`) | Coir Vikas Yojana (`TN033`) |
| #4 | Tool Rooms and Technical Institutions (`TN193`) | Science and Technology Scheme (`TN151`) |
| #5 | Payroll Subsidy (`TN122`) | Prime Minister's Internship Scheme (PMIS) (`SCH000279`) |

### Query 171: `I am a startup founder and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | Secured Business Loans for MSMEs (`TN152`) | Secured Business Loans for MSMEs (`TN152`) |
| #4 | General Purpose Term Loan (`TN061`) | Stand-Up India (`TN168`) |
| #5 | Stand-Up India (`TN168`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |

### Query 172: `I am a startup founder and need a subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #2 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Capital Subsidy (`TN028`) |
| #4 | Incentives to entrepreneurs for shifting of existing units outside Urban areas (`TN067`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #5 | Capital Subsidy (`TN028`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 173: `I am a startup founder and need a grant` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #2 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Capital Subsidy (`TN028`) |
| #4 | Incentives to entrepreneurs for shifting of existing units outside Urban areas (`TN067`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #5 | Capital Subsidy (`TN028`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 174: `I am a startup founder and need a training` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #4 | Assistance to Training Institutions (ATI) Scheme (`TN013`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Skill training and Employment Scheme (`TN163`) | Assistance to Training Institutions (ATI) Scheme (`TN013`) |

### Query 175: `I am a startup founder and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Startup India Initiative (`TN169`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 176: `I am a startup founder and need a insurance` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Startup India Initiative (`TN169`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 177: `I am a startup founder and need a tax benefit` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Startup India Initiative (`TN169`) |
| #2 | Startup India Initiative (`TN169`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #3 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #5 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 178: `I am a startup founder and need a registration` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Udyam Registration (`TN197`) |
| #5 | Udyam Registration (`TN197`) | Startup India Initiative (`TN169`) |

### Query 179: `I am a startup founder and need a scholarship` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #3 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #4 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 180: `I am a startup founder and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Startup India Initiative (`TN169`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 181: `I am an exporter and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | Interest Equalisation Scheme (`TN070`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #4 | General Purpose Term Loan (`TN061`) | E-Commerce Export Credit Facility (EPM – Niryat Protsahan) (`SCH000261`) |
| #5 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Interest Equalisation Scheme (`TN070`) |

### Query 182: `I am an exporter and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Financial Assistance for participation in International Trade Fair (`TN058`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Capital Subsidy (`TN028`) |
| #5 | Capital Subsidy (`TN028`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |

### Query 183: `I am an exporter and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Financial Assistance for participation in International Trade Fair (`TN058`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Back-ended Interest Subsidy (`TN017`) | Capital Subsidy (`TN028`) |
| #5 | Capital Subsidy (`TN028`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |

### Query 184: `I am an exporter and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 185: `I am an exporter and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #2 | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #3 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Export Promotion Mission (EPM) (`SCH000256`) |
| #4 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Interest Equalisation Scheme (`TN070`) |
| #5 | Interest Equalisation Scheme (`TN070`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |

### Query 186: `I am an exporter and need a insurance` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #2 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #3 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Export Promotion Mission (EPM) (`SCH000256`) |
| #4 | Interest Equalisation Scheme (`TN070`) | Interest Equalisation Scheme (`TN070`) |
| #5 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | Collateral Support for Export Credit (EPM – Niryat Protsahan) (`SCH000259`) |

### Query 187: `I am an exporter and need a tax benefit` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #2 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #3 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Export Promotion Mission (EPM) (`SCH000256`) |
| #4 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |
| #5 | Interest Equalisation Scheme (`TN070`) | Interest Equalisation Scheme (`TN070`) |

### Query 188: `I am an exporter and need a registration` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #2 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Export Promotion Mission (EPM) (`SCH000256`) |
| #3 | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #4 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Interest Equalisation Scheme (`TN070`) |
| #5 | Interest Equalisation Scheme (`TN070`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |

### Query 189: `I am an exporter and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Atal Tinkering Labs (ATLs) (`TN016`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #5 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |

### Query 190: `I am an exporter and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Product Research and Development (for registered exporters/ institutions) (`TN133`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #2 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #3 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Export Promotion Mission (EPM) (`SCH000256`) |
| #4 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Interest Equalisation Scheme (`TN070`) |
| #5 | Interest Equalisation Scheme (`TN070`) | Collateral Support for Export Credit (EPM – Niryat Protsahan) (`SCH000259`) |

### Query 191: `I am a manufacturer and need a loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #2 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #3 | General Purpose Term Loan (`TN061`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |
| #4 | Credit Guarantee Scheme for Startups (CGSS) (`TN039`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #5 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |

### Query 192: `I am a manufacturer and need a subsidy` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 193: `I am a manufacturer and need a grant` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 194: `I am a manufacturer and need a training` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Skill training and Employment Scheme (`TN163`) | Entrepreneurship cum Skill Development Programme (E-SDP) (`SCH000222`) |
| #2 | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) | Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi (PM-DAKSH) Yojana (`SCH000292`) |
| #3 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Coir Vikas Yojana - Skill Upgradation and Mahila Coir Yojana (`TN035`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #5 | Deen Dayal Upadhyaya Grameen Kaushalya Yojana (DDU-GKY) (`TN041`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |

### Query 195: `I am a manufacturer and need a certificate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Mahila Samman Savings Certificate (MSSC) (`TN085`) |
| #2 | Mahila Samman Savings Certificate (MSSC) (`TN085`) | Deemed Exports (`TN040`) |
| #3 | Scheme for acquiring Quality Certification (Q-Cert) (`TN148`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |
| #4 | Status Holder Certificate (`TN172`) | Science and Technology Scheme (`TN151`) |
| #5 | Deemed Exports (`TN040`) | International Cooperation (`TN071`) |

### Query 196: `I am a manufacturer and need a insurance` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Shakti Sadan (`TN156`) | Shakti Sadan (`TN156`) |
| #2 | Deemed Exports (`TN040`) | Support for Marginalized Individuals for Livelihood and Enterprise (SMILE) (`SCH000294`) |
| #3 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | Deemed Exports (`TN040`) |
| #4 | Science and Technology Scheme (`TN151`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |
| #5 | International Cooperation (`TN071`) | Science and Technology Scheme (`TN151`) |

### Query 197: `I am a manufacturer and need a tax benefit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Deemed Exports (`TN040`) | Deemed Exports (`TN040`) |
| #2 | Startup India Initiative (`TN169`) | Startup India Initiative (`TN169`) |
| #3 | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) | Pradhan Mantri Matru Vandana Yojana (PMMVY) (`TN127`) |
| #4 | Beti Bachao Beti Padhao (BBBP) (`TN020`) | Beti Bachao Beti Padhao (BBBP) (`TN020`) |
| #5 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |

### Query 198: `I am a manufacturer and need a registration` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Single Point Registration Scheme (SPRS) under NSSH (`SCH000235`) |
| #2 | Reimbursement of fees for Certificate of Registration as Exporter of Spices (CRES) (`TN141`) | Udyam Registration (`TN197`) |
| #3 | Reimbursement of Stamp duty and Registration charges (`TN142`) | Udyam Assist Platform (`TN196`) |
| #4 | Subsidy for Asset Creation for Intellectual Property (`TN174`) | MSME Innovative Scheme (Intellectual Property Rights - IPR) (`TN104`) |
| #5 | Udyam Assist Platform (`TN196`) | Deemed Exports (`TN040`) |

### Query 199: `I am a manufacturer and need a scholarship` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #4 | Naan Mudhalvan (`TN107`) | Naan Mudhalvan (`TN107`) |
| #5 | Sponsorship of students (`TN167`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 200: `I am a manufacturer and need a pension` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Deemed Exports (`TN040`) |
| #2 | Deemed Exports (`TN040`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |
| #3 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | Science and Technology Scheme (`TN151`) |
| #4 | Science and Technology Scheme (`TN151`) | Interest Equalisation Scheme (`TN070`) |
| #5 | Interest Equalisation Scheme (`TN070`) | - |

### Query 201: `women entrepreneur loan subsidy scheme in Tamil Nadu` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Stand-Up India (`TN168`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #3 | Stand-Up India (`TN168`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #4 | Women Entrepreneurship Platform (WEP) (`TN212`) | Dena Shakti Scheme (`TN044`) |
| #5 | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |

### Query 202: `MSME registration and GST benefits for small business` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Udyam Registration (`TN197`) | Udyam Registration (`TN197`) |
| #2 | Micro & Small Enterprises Facilitation Councils (MSEFC) / MSME SAMADHAAN (`TN093`) | Micro & Small Enterprises Facilitation Councils (MSEFC) / MSME SAMADHAAN (`TN093`) |
| #3 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #4 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #5 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Startup India Initiative (`TN169`) |

### Query 203: `export promotion scheme with insurance and subsidy` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Coir Vikas Yojana - Export Market Promotion (`TN034`) | Coir Vikas Yojana - Export Market Promotion (`TN034`) |
| #2 | Promotion of Indian Spice Brands Abroad (`TN135`) | Capacity Building of First Time MSE Exporters (CBFTE) (`SCH000231`) |
| #3 | Financial Assistance for participation in International Trade Fair (`TN058`) | Export Promotion Mission (EPM) (`SCH000256`) |
| #4 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | Reimbursement of Export Promotion Council Membership Fee (NSSH) (`SCH000239`) |
| #5 | Assistance to Exporters for Rapid Food Testing Devices and Kits (`TN010`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |

### Query 204: `startup funding grant for manufacturing unit` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | Stand-Up India (`TN168`) | Stand-Up India (`TN168`) |
| #4 | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |
| #5 | Secured Business Loans for MSMEs (`TN152`) | Secured Business Loans for MSMEs (`TN152`) |

### Query 205: `agriculture loan with interest subvention for farmers` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #3 | Interest Equalisation Scheme (`TN070`) | Interest Subvention on Pre- and Post-Shipment Export Credit (EPM – Niryat Protsahan) (`SCH000258`) |
| #4 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | Bank Credit Facilitation Scheme (`TN018`) |
| #5 | General Purpose Term Loan (`TN061`) | Interest Equalisation Scheme (`TN070`) |

### Query 206: `scholarship and hostel facility for scheduled caste student` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | National SC-ST Hub Scheme (`TN113`) | National SC-ST Hub Scheme (`TN113`) |
| #3 | Stand-Up India (`TN168`) | Stand-Up India (`TN168`) |
| #4 | Stand-Up India Scheme (`TN218`) | Stand-Up India Scheme (`TN218`) |
| #5 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |

### Query 207: `pension scheme for senior citizens with disability` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #2 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |
| #3 | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) |
| #4 | Unemployed Youth Employment Generation Programme (UYEGP) (`TN200`) | Entrepreneurship Awareness Programme (EAP) (`SCH000221`) |
| #5 | Procurement and Marketing Support (PMS) Scheme (`TN132`) | Procurement and Marketing Support (PMS) Scheme (`TN132`) |

### Query 208: `credit guarantee scheme for women led startup` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #2 | Nagaland Startup Fund - 25% Reservation for Women-led Ventures (`TN108`) | Stand-Up India (`TN168`) |
| #3 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Mutual Credit Guarantee Scheme for MSMEs (MCGS-MSME) (`SCH000255`) |
| #4 | Bhamashah Techno Fund - Women-led Startup Fund (`TN021`) | Dena Shakti Scheme (`TN044`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |

### Query 209: `buisness loan for wome entreprenur` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #2 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Stand-Up India (`TN168`) |
| #3 | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | Dena Shakti Scheme (`TN044`) |
| #4 | Nagaland Startup Fund - 25% Reservation for Women-led Ventures (`TN108`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #5 | Women Entrepreneurship Platform (WEP) (`TN212`) | Government e-Marketplace (GeM) Women-owned MSME Procurement Support (`TN063`) |

### Query 210: `scholership for colege studnts` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #3 | Sponsorship of students (`TN167`) | Naan Mudhalvan (`TN107`) |
| #4 | Naan Mudhalvan (`TN107`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #5 | Atal Tinkering Labs (ATLs) (`TN016`) | MSME Innovative Scheme (Design) (`TN102`) |

### Query 211: `farmr subsdy for irrigaton` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #3 | Capital Subsidy (`TN028`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |
| #4 | Generator Subsidy (`TN062`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |

### Query 212: `msme regstration certifcate` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Udyam Registration (`TN197`) |
| #3 | Udyam Registration (`TN197`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #4 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Startup India Initiative (`TN169`) |

### Query 213: `pention scheme for seniors` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 214: `exoprt incentive for manufactuer` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Incentives to entrepreneurs for shifting of existing units outside Urban areas (`TN067`) | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) |
| #3 | Maharashtra Women-led Startup GST/Utility/Participation Reimbursement Support (`TN081`) | Interest Equalisation Scheme (`TN070`) |
| #4 | Export Promotion Capital Goods (EPCG) Scheme (`TN057`) | International Cooperation (`TN071`) |
| #5 | Generator Subsidy (`TN062`) | National Mission on Natural Farming (NMNF) (`SCH000285`) |

### Query 215: `disabilty pension schem` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | MSME Champions Scheme (`TN099`) | MSME Champions Scheme (`TN099`) |
| #2 | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) | New Entrepreneur cum Enterprise Development Scheme (NEEDS) (`TN115`) |
| #3 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Dr. Dharmambal Ammaiyar Ninaivu Widow Remarriage Assistance Scheme (`TN047`) |
| #4 | Chief Minister's Girl Child Protection Scheme (`TN031`) | Dr. Muthulakshmi Reddy Ninaivu Inter-Caste Marriage Assistance Scheme (`TN048`) |
| #5 | Dr. Dharmambal Ammaiyar Ninaivu Widow Remarriage Assistance Scheme (`TN047`) | MSME Competitive (LEAN) Scheme (`TN100`) |

### Query 216: `tax benfit for small bussiness` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Micro & Small Enterprises Facilitation Councils (MSEFC) / MSME SAMADHAAN (`TN093`) | Micro & Small Enterprises Facilitation Councils (MSEFC) / MSME SAMADHAAN (`TN093`) |
| #2 | International event : For visiting business exploration/ exhibitions/ buyer-seller meets (`TN073`) | Secured Business Loans for MSMEs (`TN152`) |
| #3 | Secured Business Loans for MSMEs (`TN152`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #4 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #5 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Credit Guarantee Scheme for Micro and Small Enterprises (CGTMSE) (`TN038`) |

### Query 217: `எனக்கு விவசாய மானியம் வேணும்` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) | Agriculture Infrastructure Fund (AIF) (`SCH000287`) |
| #2 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Prime Minister Dhan-Dhaanya Krishi Yojana (PMDDKY) (`SCH000283`) |
| #3 | Back-ended Interest Subsidy (`TN017`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |
| #4 | Capital Subsidy (`TN028`) | Pradhan Mantri Kisan Urja Suraksha evam Utthaan Mahabhiyan (PM-KUSUM) (`SCH000288`) |
| #5 | Generator Subsidy (`TN062`) | Formation and Promotion of 10,000 Farmer Producer Organisations (FPOs) (`SCH000301`) |

### Query 218: `பெண் தொழில் முனைவோருக்கு கடன் திட்டம்` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Stand-Up India (`TN168`) |
| #2 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Women Entrepreneurship Platform (WEP) (`TN212`) |
| #3 | Punjab Startup Fund - 25% Reservation for Women-led Ventures (`TN137`) | Dena Shakti Scheme (`TN044`) |
| #4 | Nagaland Startup Fund - 25% Reservation for Women-led Ventures (`TN108`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #5 | Stand-Up India (`TN168`) | Trade Related Entrepreneurship Assistance and Development (TREAD) (`TN195`) |

### Query 219: `மாணவர்களுக்கு கல்வி உதவித்தொகை` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #2 | Atal Tinkering Labs (ATLs) (`TN016`) | Atal Tinkering Labs (ATLs) (`TN016`) |
| #3 | Tamil Puthalvan Scheme (`TN185`) | Tamil Puthalvan Scheme (`TN185`) |
| #4 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #5 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |

### Query 220: `மூத்த குடிமக்களுக்கு ஓய்வூதியம்` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 221: `குறு தொழில் பதிவு சான்றிதழ்` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Economic Empowerment of Women Enterprises and Start-Ups by Women (`TN052`) | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) |
| #2 | Ministry of MSME Entrepreneurship and Skill Development Programme (ESDP) (`TN095`) | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) |
| #3 | Tamil Nadu Startup and Innovation Mission (StartupTN / TANSIM) (`TN181`) | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) |
| #4 | Entrepreneurship Skill Development Programme (ESDP) (`TN055`) | Startup India Initiative (`TN169`) |
| #5 | Uttarakhand Startup Policy - Women Entrepreneur Allowance & Marketing Support (`TN201`) | Additional Capital Subsidy for select category of entrepreneurs (`TN004`) |

### Query 222: `ஏற்றுமதி ஊக்குவிப்பு திட்டம்` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 223: `இயந்திரம் வாங்க மானியம்` ⚠️ **[FLAGGED: PREV #1 DROPPED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | Incentives for setting up new clusters units on the outskirts of Towns and Cities (`TN066`) | Pradhan Mantri Viksit Bharat Rozgar Yojana (PM-VBRY) – Employment Linked Incentive Scheme (`SCH000278`) |
| #2 | Back-ended Interest Subsidy (`TN017`) | Special Credit Linked Capital Subsidy Scheme (SCLCSS) (`SCH000233`) |
| #3 | Capital Subsidy (`TN028`) | Back-ended Interest Subsidy (`TN017`) |
| #4 | Generator Subsidy (`TN062`) | Capital Subsidy (`TN028`) |
| #5 | Low Tension Power Tariff (LTPT) Subsidy (`TN079`) | Additional Capital Subsidy for Micro Manufacturing Enterprises (`TN001`) |

### Query 224: `நெசவாளர்களுக்கு கடன் உதவி` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) | PM Vishwakarma- Enabling Artisans & Craftspeople to scale-up their Enterprises (`TN124`) |
| #2 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #3 | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) | Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme (Pudhumai Penn Thittam) (`TN098`) |
| #4 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #5 | Credit Linked Capital Subsidy Scheme (CLCSS) (`TN032`) | Back-ended Interest Subsidy (`TN017`) |

### Query 225: `` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 226: ` ` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 227: `a` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 228: `1` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 229: `??` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 230: `loan` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) | SIDBI Make In India Soft Loan Fund For MSMEs (SMILE) (`TN159`) |
| #2 | General Purpose Term Loan (`TN061`) | Reimbursement of Bank Loan Processing Fee (NSSH) (`SCH000236`) |
| #3 | Secured Business Loans for MSMEs (`TN152`) | Secured Business Loans for MSMEs (`TN152`) |
| #4 | Bank Credit Facilitation Scheme (`TN018`) | Bank Credit Facilitation Scheme (`TN018`) |
| #5 | Loan for Purchase of Equipment for Enterprise's Development (SPEED) (`TN078`) | Credit Assessment Model (CAM) for MSMEs based on Digital Footprints (`SCH000273`) |

### Query 231: `scheme` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 232: `help` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 233: `the` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

### Query 234: `and` ✅ **[MAINTAINED]**

| Rank | `origin/main` Top 5 | `HEAD` Top 5 |
|:---:|:---|:---|
| #1 | - | - |
| #2 | - | - |
| #3 | - | - |
| #4 | - | - |
| #5 | - | - |

