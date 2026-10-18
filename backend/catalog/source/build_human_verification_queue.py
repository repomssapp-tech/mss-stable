#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Builds HUMAN_VERIFICATION_QUEUE_E5.xlsx from the user's priority list,
cross-referenced against the ACTUAL current state of scheme_catalog.json
and cluster_assistance_catalog.json -- not a blind copy of the input
list, since many entries are already verified or already have a
documented block reason from this session's batch reports.
READ ONLY on catalogs -- writes only the .xlsx queue file.
"""
import json, os
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

CAT = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(CAT)

sch = json.load(open(os.path.join(CAT, "scheme_catalog.json"), encoding="utf-8"))["data"]
clus = json.load(open(os.path.join(CAT, "cluster_assistance_catalog.json"), encoding="utf-8"))["data"]
sch_by_id = {r["identity"]["id"]: r for r in sch}

# Known blockers discovered this session (from SCHEME_VERIFICATION_BATCH_REPORT_14/15)
TLS_FAIL = {
    "coirboard.gov.in": "TLS: certificate could not be verified",
    "kmut.tn.gov.in": "TLS: certificate expired",
    "clcss.dcmsme.gov.in": "TLS: hostname not in certificate's altnames",
    "dashboard.msme.gov.in": "TLS: certificate could not be verified",
}
JS_SPA = {
    "lean.msme.gov.in": "JS-rendered SPA -- static fetch sees no eligibility/benefit content",
    "seedfund.startupindia.gov.in": "JS-rendered SPA -- static fetch returns no substantive content",
    "pmfme.mofpi.gov.in": "JS-rendered SPA -- static fetch returns no substantive content",
}


def find_scheme(*name_fragments):
    """Return (id, name, status, url, dept) for the first scheme whose name
    contains ANY of the given fragments (case-insensitive), or None."""
    for frag in name_fragments:
        for r in sch:
            if frag.lower() in r["identity"]["name"].lower():
                url = None
                for s in r["content"].get("sources", []):
                    u = s.get("url") or ""
                    if u and u != "https://www.msmeonline.tn.gov.in/":
                        url = u
                        break
                dept = r["content"]["classification"]["government"].get("departmentText")
                return {
                    "id": r["identity"]["id"], "name": r["identity"]["name"],
                    "status": r["verification"]["status"], "url": url, "dept": dept,
                }
    return None


def find_cluster(*name_fragments):
    for frag in name_fragments:
        for r in clus:
            if frag.lower() in r["identity"]["name"].lower():
                return {"id": r["identity"]["id"], "name": r["identity"]["name"],
                        "status": r["verification"]["status"]}
    return None


def blocker_for(url):
    if not url:
        return None
    for dom, reason in {**TLS_FAIL, **JS_SPA}.items():
        if dom in url:
            return reason
    return None


# ---------------------------------------------------------------------
# (priority, category, user-listed name, name fragments to match, note-if-no-match)
QUEUE_SPEC = [
    # Priority 1 -- Startup / Innovation
    (1, "Startup/Innovation", "Startup India Seed Fund Scheme (SISFS)", ["Startup India Seed Fund"], None),
    (1, "Startup/Innovation", "Startup India Recognition", ["Startup India Initiative"], None),
    (1, "Startup/Innovation", "Fund of Funds for Startups", ["Fund of Funds for Startups"], None),
    (1, "Startup/Innovation", "BIRAC BIG Grant", ["Biotechnology Ignition Grant"], None),
    (1, "Startup/Innovation", "BIRAC LEAP Fund", ["BIRAC LEAP Fund"], None),
    (1, "Startup/Innovation", "BIRAC SEED Fund", ["BIRAC SEED Fund"], None),
    (1, "Startup/Innovation", "NIDHI PRAYAS", ["NIDHI PRAYAS", "PRAYAS"], "NOT IN CATALOG -- no scheme record exists; would need to be newly added, not just verified"),
    (1, "Startup/Innovation", "NIDHI EIR", ["NIDHI EIR", "Entrepreneur In Residence"], "NOT IN CATALOG -- no scheme record exists; would need to be newly added, not just verified"),

    # Priority 2 -- Major Central MSME Schemes
    (2, "Central MSME", "PMEGP", ["Prime Minister’s Employment Generation", "Prime Minister's Employment Generation"], None),
    (2, "Central MSME", "PM Mudra Yojana", ["Pradhan Mantri Mudra Yojana"], None),
    (2, "Central MSME", "CGTMSE", ["Credit Guarantee Scheme for Micro and Small Enterprises"], None),
    (2, "Central MSME", "PM Vishwakarma", ["PM Vishwakarma"], None),
    (2, "Central MSME", "SFURTI", ["Regeneration of Traditional Industries"], None),
    (2, "Central MSME", "MSE-CDP", ["Cluster Development Programme (MSE-CDP)"], None),
    (2, "Central MSME", "ZED Certification Scheme", ["Sustainable (ZED)"], None),
    (2, "Central MSME", "Lean MSME Scheme", ["MSME Competitive (LEAN)"], None),
    (2, "Central MSME", "Procurement & Marketing Support Scheme", ["Procurement and Marketing Support"], None),
    (2, "Central MSME", "International Cooperation Scheme", ["International Cooperation"], None),

    # Priority 3 -- Tamil Nadu MSME Schemes
    (3, "TN MSME", "NEEDS", ["New Entrepreneur cum Enterprise Development"], None),
    (3, "TN MSME", "UYEGP", ["Unemployed Youth Employment Generation"], None),
    (3, "TN MSME", "Annal Ambedkar Business Champions Scheme", ["Annal Ambedkar"], None),
    (3, "TN MSME", "Kalaignar Kaivinai Thittam", ["Kalaignar Kaivinai"], "NOT IN CATALOG -- launched Dec 2024, after this catalog's source baseline; flagged in a prior conversation turn as a genuine future-addition candidate, not yet a scheme record"),
    (3, "TN MSME", "Capital Subsidy Scheme", ["Capital Subsidy"], "MULTIPLE MATCHES -- see note; family of ~6 related records, list below"),
    (3, "TN MSME", "Interest Subsidy Scheme", ["Back-ended Interest Subsidy", "Interest Subvention"], None),
    (3, "TN MSME", "Back-ended Capital Subsidy", ["Back-ended Interest Subsidy"], None),
    (3, "TN MSME", "Entrepreneur Development Programs", ["Entrepreneurship Skill Development", "Entrepreneurship and Skill Development"], None),
    (3, "TN MSME", "Tamil Nadu Startup Mission schemes", ["MentorTN", "Innovation Voucher"], "Multiple TANSIM-adjacent records exist separately (MentorTN, Innovation Voucher, TANSEED) -- no single umbrella record"),
    (3, "TN MSME", "TANSEED", ["Tamil Nadu Startup Seed Grant Fund"], None),
    (3, "TN MSME", "MSME Idea Challenge", ["Idea Challenge"], "NOT IN CATALOG -- no scheme record found"),

    # Priority 4 -- Manufacturing / Sector Schemes (mostly live in
    # cluster_assistance_catalog.json, not scheme_catalog.json)
    (4, "Sector: Textile", "Textile Technology Development Scheme", ["Textile Technology Development"], "NOT IN CATALOG (scheme_catalog) -- not in cluster_assistance_catalog either"),
    (4, "Sector: Textile", "Integrated Textile Parks", ["Integrated Textile Parks"], "NOT IN CATALOG"),
    (4, "Sector: Textile", "Textile Cluster Support", ["Cut & Sew", "Non-Conventional Fibre"], "See cluster_assistance_catalog.json instead of scheme_catalog -- 2 verified TN textile CFC records already exist there (CLUS000003, CLUS000004, Phase D2/E.1)"),
    (4, "Sector: Textile", "Processing Cluster Assistance", ["Processing Cluster"], "NOT IN CATALOG as a named scheme; general processing/CFC records exist in cluster_assistance_catalog"),
    (4, "Sector: Leather", "Indian Leather Development Programme", ["Leather Development Programme"], "NOT IN CATALOG"),
    (4, "Sector: Leather", "Leather Cluster Development", ["Leather Cluster"], "See cluster_assistance_catalog.json -- 1 verified TN leather CFC record already exists (CLUS000009, Pallavaram, Phase E.1)"),
    (4, "Sector: Auto/Engg", "Automotive Mission Plan support", ["Automotive Mission"], "NOT IN CATALOG"),
    (4, "Sector: Auto/Engg", "Industry 4.0 support", ["Industry 4.0"], "NOT IN CATALOG as a standalone scheme (mentioned only as one of 24 thrust sectors in the general TN capital subsidy circular, CLUSTER_COVERAGE_REPORT.md)"),
    (4, "Sector: Auto/Engg", "Technology Upgradation support", ["Technology Upgradation"], "No single scheme by this exact name; CLCSS (SCH000032) IS the technology-upgradation subsidy scheme -- see Priority 5"),
    (4, "Sector: Food Processing", "PMFME", ["PMFME", "Formalisation of Micro Food Processing"], "Added Phase F Task 2 as SCH000219 (medium confidence -- primary pmfme.mofpi.gov.in portal is JS-rendered, see TECHNICAL_SOURCE_BLOCKS_QUEUE.md)"),
    (4, "Sector: Food Processing", "Food Processing Cluster Support", ["Food Processing Cluster"], "See cluster_assistance_catalog.json -- 1 verified TN rice-mill CFC record exists (CLUS000010, Alangulam, Phase E.1), but no broader food-processing cluster scheme"),
    (4, "Sector: Food Processing", "Cold Chain Scheme", ["Cold Chain"], "NOT IN CATALOG"),

    # Priority 5 -- Finance / Loan Schemes
    (5, "Finance/Loan", "Stand Up India", ["Stand Up India", "Stand-Up India"], "Added Phase F Task 2 as SCH000218 (high confidence, standupmitra.in live-verified)"),
    (5, "Finance/Loan", "SIDBI loans", ["Secured Business Loans", "General Purpose Term Loan", "SMILE"], "Multiple SIDBI loan-product scheme records already exist and are largely verified -- see Priority 2/already-verified list"),
    (5, "Finance/Loan", "TIIC schemes", ["TIIC", "Tamil Nadu Industrial Investment"], "NOT IN CATALOG as a scheme -- TIIC is tracked only as an institution_catalog.json entity (a lender), not as a specific loan-product scheme record"),
    (5, "Finance/Loan", "CGTMSE-backed loans", ["Credit Guarantee Scheme for Micro and Small Enterprises"], "Same record as Priority 2's CGTMSE"),
    (5, "Finance/Loan", "Credit Linked Capital Subsidy Scheme", ["Credit Linked Capital Subsidy"], None),
    (5, "Finance/Loan", "MSME Credit Guarantee Scheme", ["Credit Guarantee Scheme for Micro and Small Enterprises"], "Same record as Priority 2's CGTMSE"),
    (5, "Finance/Loan", "Working Capital Assistance", ["Working Capital (Cash Credit)", "Timely Working Capital Assistance"], None),
]

rows = []
seen_ids = set()
for priority, category, user_name, fragments, forced_note in QUEUE_SPEC:
    match = find_scheme(*fragments)
    cluster_match = None if match else find_cluster(*fragments)
    if match:
        sid = match["id"]
        if sid in seen_ids:
            continue  # avoid duplicate rows for schemes matched twice under different priority labels
        r = sch_by_id[sid]
        missing = []
        elig = r["content"]["eligibility"]["narrative"]["criteria"]
        ben = r["content"]["benefits"]["summary"]
        app_mode = r["content"]["applicationProcess"]["mode"]
        if not elig or "not entered" in (elig or "").lower() or "not asserted" in (elig or "").lower():
            missing.append("eligibility")
        if not ben or "not entered" in (ben or "").lower() or "not asserted" in (ben or "").lower():
            missing.append("benefits")
        if not app_mode:
            missing.append("application process")
        blocker = blocker_for(match["url"])
        if sid == "SCH000038":
            req_verification = ("RESOLVED Phase F Task 1: maxCoverInr = Rs 10 crore CONFIRMED "
                                 "(live cgtmse.in fetch, 2026, cites Circular No. 250, 2024-25, "
                                 "raising the ceiling from Rs 5cr to Rs 10cr). See "
                                 "CONFLICT_RESOLUTION_REPORT.md sec 2. Confidence: HIGH.")
            status_col = "DONE"
        elif sid == "SCH000128":
            req_verification = ("RESOLVED Phase F Task 1: maxInr = Rs 20 lakh CONFIRMED -- reflects "
                                 "the 'Tarun Plus' tier (Rs 10-20 lakh, effective 24 Oct 2024, per "
                                 "PIB PRID 2069170). Primary PIB document itself could not be read "
                                 "directly this session (403 / non-extractable scanned PDF); corroborated "
                                 "via multiple independent secondary sources instead. See "
                                 "CONFLICT_RESOLUTION_REPORT.md sec 3. Confidence: MEDIUM -- a human "
                                 "re-check of the primary PIB release in-browser would raise this to HIGH.")
            status_col = "DONE (confidence: medium)"
        elif sid == "SCH000152":
            req_verification = ("RESOLVED Phase F Task 1: maxInr = Rs 25 lakh / tenure = 36mo "
                                 "CONFIRMED (live sidbi.in/en/business-loan fetch matches catalog "
                                 "exactly). The competing 2022 TN booklet figure (Rs 10 crore/120mo) "
                                 "was determined to describe a different/superseded SIDBI product, "
                                 "not the current Secured Business Loan -- rejected, not averaged or "
                                 "guessed. See CONFLICT_RESOLUTION_REPORT.md sec 1. Confidence: HIGH.")
            status_col = "DONE"
        elif sid == "SCH000032":
            req_verification = ("CLCSS: 3 fetch attempts this session, all technically failed -- "
                                 "msme.gov.in/clcss (403), clcss.dcmsme.gov.in (TLS cert hostname "
                                 "mismatch), my.msme.gov.in/.../0_2_1.html (TLS cert chain error). "
                                 "Search-derived figures (15%/Rs15L standard, 25%/Rs25L SC-ST SCLCSS "
                                 "variant) found but NOT applied -- no approved-domain page confirmed "
                                 "them directly. Human: open clcss.dcmsme.gov.in in a real browser.")
            status_col = "BLOCKED (needs human browser)"
        elif match["status"] == "verified":
            req_verification = "None -- already meets the minimum bar (name+eligibility+benefits+application process, sourced)"
            status_col = "DONE"
        elif blocker:
            req_verification = f"Blocked this session: {blocker}. Human: open {match['url']} in a real browser and copy eligibility/benefit/application-process text."
            status_col = "BLOCKED (needs human browser)"
        elif missing:
            req_verification = f"Missing/thin: {', '.join(missing)}. Human: confirm against {match['url'] or '(no URL on file)'}"
            status_col = "NEEDS VERIFICATION"
        else:
            req_verification = "Fields present but status not yet raised -- spot-check then confirm"
            status_col = "NEEDS SPOT-CHECK"
        rows.append([
            sid, match["name"], match["dept"] or "", match["url"] or "",
            ", ".join(missing) if missing else "(none obviously missing)",
            req_verification, priority, status_col, "", "", forced_note or "",
        ])
        seen_ids.add(sid)
    elif cluster_match:
        rows.append([
            cluster_match["id"], f"{user_name} -> {cluster_match['name']} (cluster_assistance_catalog, not scheme_catalog)",
            "", "", "", "Already handled in cluster_assistance_catalog.json -- see note", priority,
            "DONE (different catalog)" if cluster_match["status"] == "verified" else "NEEDS VERIFICATION (cluster catalog)",
            "", "", forced_note or "",
        ])
    else:
        rows.append([
            "", user_name, "", "", "ALL (no record exists)",
            forced_note or "No matching scheme record found in scheme_catalog.json or cluster_assistance_catalog.json.",
            priority, "NOT IN CATALOG", "", "", forced_note or "",
        ])

# Add the explicit "special handling" domains as their own rows too
for dom, reason in {**TLS_FAIL, **JS_SPA}.items():
    rows.append(["", f"(domain-level flag) {dom}", "", f"https://{dom}/", "", reason, 0,
                 "BLOCKED (needs human browser)", "", "", "Affects multiple schemes above -- see Status column on individual rows."])

# ---------------------------------------------------------------------
wb = Workbook()
ws = wb.active
ws.title = "E5 Verification Queue"
headers = ["Scheme ID", "Scheme Name", "Department", "Official URL", "Missing Fields",
           "Required Verification", "Priority", "Status", "Verified Value", "Source", "Notes"]
ws.append(headers)
for cell in ws[1]:
    cell.font = Font(bold=True, color="FFFFFF")
    cell.fill = PatternFill("solid", fgColor="2F5597")
    cell.alignment = Alignment(wrap_text=True, vertical="top")

rows.sort(key=lambda r: (r[6] if r[6] else 0, 0 if r[7] == "DONE" else 1))
for row in rows:
    ws.append(row)

widths = [12, 42, 22, 40, 22, 55, 9, 24, 18, 18, 45]
for i, w in enumerate(widths, start=1):
    ws.column_dimensions[get_column_letter(i)].width = w
for row in ws.iter_rows(min_row=2):
    for cell in row:
        cell.alignment = Alignment(wrap_text=True, vertical="top")

status_colors = {"DONE": "C6E0B4", "NEEDS VERIFICATION": "FFE699",
                  "BLOCKED (needs human browser)": "F8CBAD", "NOT IN CATALOG": "D9D9D9",
                  "NEEDS SPOT-CHECK": "FFF2CC"}
status_col_idx = headers.index("Status") + 1
for row in ws.iter_rows(min_row=2):
    status_val = row[status_col_idx - 1].value or ""
    for key, color in status_colors.items():
        if status_val.startswith(key):
            for cell in row:
                cell.fill = PatternFill("solid", fgColor=color)
            break

ws.freeze_panes = "A2"

out_path = os.path.join(ROOT, "HUMAN_VERIFICATION_QUEUE_E5.xlsx")
wb.save(out_path)
print(f"Wrote {out_path} -- {len(rows)} rows")
from collections import Counter
print(Counter(r[7] for r in rows))
