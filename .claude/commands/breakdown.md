Think hard before decomposing — decomposition quality determines everything downstream; a bad shard wastes an entire agent cycle.

Decompose spec/SPEC.md into work items.

Steps:
1. Read spec/SPEC.md fully. List every discrete requirement with a section reference.
2. Group into work items sized ≤ 1 day each, independently testable. Each item is a TRACER-BULLET VERTICAL SLICE — a thin cut through the whole stack (endpoint → logic → DB → test), never a horizontal layer ("all the models", "all the endpoints"). Write every item assuming the build agent has ZERO context for this codebase and questionable taste: exact files, exact spec values, how to test — nothing left to inference. Minimize file-surface overlap; where overlap is unavoidable, add `depends-on` so they serialize.
2b. Declare each item's SEAMS UNDER TEST — the public interfaces (HTTP contracts, exported service methods) where locked acceptance tests will live. Tests never go against internals; agreeing seams up front is how test effort lands on critical paths.
2c. MAINTAIN THE DOMAIN MODEL: keep a `CONTEXT.md` glossary at repo root. Every term the spec uses (risk, finding, SLA state, role names) gets one canonical definition; item text, seam names, and test names use ONLY glossary terms. When the spec uses a term two ways, resolve it with the human and record the ruling. Flag any schema change with `db-migration: true`. Assign a risk-tier per item (trivial/lite/full per CLAUDE.md heuristics); anything touching auth, crypto, secrets, RBAC, sessions, or migrations is ALWAYS full.
3. For each item, create work-items/backlog/WI-NNN.md from work-items/TEMPLATE.md with ALL sections filled: objective, in/out of scope, file surface, acceptance criteria (each citing a spec §), concrete test plan steps, security requirements.
4. THREAT MODEL every full-tier item before it enters backlog: walk STRIDE (spoofing, tampering, repudiation, info disclosure, DoS, privilege escalation) against the item's endpoints/data flows; record concrete attack paths and the mitigation each one requires in the item's Threat Model table. Mitigations become acceptance criteria. Mark API-facing items `dast: true`.
5. FOGGY SPEC RULE: if a spec area is too ambiguous to shard into build items, do NOT guess — file DECISION ISSUES instead (gh issue create --label "decision"): questions whose resolution is a human decision, not a slice to build. Build items in that area wait on the decision issue.
6. Output a dispatch plan: which items can run in parallel (wave 1, wave 2, ...) based on depends-on and file-surface collisions.
7. GITHUB: for each item create an Issue mirroring it:
   gh issue create --title "WI-NNN: <title>" --body-file work-items/backlog/WI-NNN.md --label "work-item,tier:<risk-tier>,wave:<n>"
   (add label "db-migration" where flagged). Record the issue number in the item frontmatter. The board of record for status is GitHub; work-items/ folders remain the machine queue.
8. Confirm total traceability: every SPEC requirement appears in exactly one item. List any spec ambiguities as questions for the human before dispatching.
