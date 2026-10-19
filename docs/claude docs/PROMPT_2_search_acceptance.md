# Prompt 2: Hindi search acceptance run (start only when the owner says so)

Read first: `docs/claude docs/README.md`, `docs/claude docs/HINDI_SEARCH_ACCEPTANCE.md`, `docs/claude docs/hindi_search_queries.json`.
Those files are read-only for you. Do not retype the queries and do not edit the JSON.

Build the Hindi search acceptance test from `hindi_search_queries.json`. Use the published hi pack and core bundle of the
current release (what the app ships).
1. **Preconditions first.** For each expectedId: is it in the hi pack with a Devanagari name, and is its status active in the bundle?
   Paste the table. Queries with no qualifying expected id are DATA_GAP.
2. **Run** all 20 queries, their spellingVariants, the 2 negative controls and R1. Paste per query: the query, the top 5 results
   (id, name, rank, status), the rank of each expected id (or NOT FOUND), PASS/FAIL, and one diagnosis for each failure
   (DATA_GAP, TOKENIZATION, SYNONYM, RANKING). Also flag any archived scheme that outranks the expected active scheme, and any result
   that matches only through taxonomy synonyms with no Hindi text in the pack.
3. **Report** pass counts per group against the pass rule in the JSON.
4. **Do NOT change** the test file, search code, taxonomy, synonyms or data. Propose fixes only.
5. Run the existing English/Tamil search suites unchanged and paste the results.

STOP and report.
