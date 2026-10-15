# Customer Genome: dbt Core POC (identity resolution)

Shows, in dbt on BigQuery: **fuzzy matching**, an **identity graph**, a **golden record with survivorship rules**,
an **audit trail**, **audience growth reporting**, and a **prospecting audience** for Activations to sync.
Everything is built on pretend data in `seeds/`. Nothing here touches production.

---------------------------------------------------------------------
## Setup, step by step (plain English)

You need: a Google Cloud project with BigQuery, permission in it to create tables
(roles: *BigQuery Data Editor* and *BigQuery Job User*), and a computer with a terminal.

**1. Check Python.** dbt is a Python program. In a terminal run `python3 --version`.
You want 3.10, 3.11 or 3.12. If it's missing or older, install it from python.org.

**2. Install the Google Cloud CLI and sign in.** This is how your computer proves to
BigQuery that it's you (no passwords or key files to manage). Install from
cloud.google.com/sdk, then run:

    gcloud auth application-default login
    gcloud config set project YOUR-GCP-PROJECT-ID

A browser opens; pick your Google account.

**3. Unzip this project and open a terminal inside the `customer_genome` folder.**

**4. Create a private Python "bubble" and install dbt into it.** The bubble keeps dbt from
interfering with anything else on your machine.

    python3 -m venv .venv
    source .venv/bin/activate          # Windows: .venv\Scripts\activate
    pip install dbt-bigquery

Your prompt now starts with `(.venv)`. **Every time you open a new terminal for this demo,
re-run the `source .venv/bin/activate` line.**

**5. Tell dbt where your BigQuery lives.** Copy `profiles.yml.example` to dbt's settings folder
and put your project ID in it:

    mkdir -p ~/.dbt
    cp profiles.yml.example ~/.dbt/profiles.yml
    # now open ~/.dbt/profiles.yml and replace YOUR-GCP-PROJECT-ID

(Windows: the folder is `%USERPROFILE%\.dbt`.) `location: US` must match where your BigQuery
data region is. If unsure, leave US; dbt creates the `customer_genome` dataset for you.

**6. Health check.**

    dbt debug

Look for "All checks passed!" at the bottom. If not, see Troubleshooting below.

**7. Load the pretend data.** This uploads the CSVs in `seeds/` as tables.

    dbt seed

**8. Build everything and run the tests.**

    dbt build

This creates all the views/tables and runs 20-ish automated checks (for example: "no shared phone
was ever used to merge two people", "nobody suppressed leaked into the audience").
Everything should be green. A deprecation warning about test arguments is harmless.

**9. Look at the results.** Open console.cloud.google.com/bigquery, find the `customer_genome`
dataset, and run the queries in "Demo walkthrough" below.

**10. Point Activations at it** (the non-dbt part of the demo): sync `customer_genome`
(golden record) and `aud_prospecting` (Use Case 2) as your sources.

To start over from scratch: `dbt seed --full-refresh && dbt build`.

---------------------------------------------------------------------
## What got built

| Model | What it is |
|---|---|
| `stg_*` (6) | Cleans each source: lowercase email, phone to +1XXXXXXXXXX, tidy names |
| `int_source_records` | All sources stacked into one shape; derives the hashed `user_id` from email |
| `int_identifiers` / `int_nodes` | Every email, phone, device, reservation, user_id = a "node" |
| `int_shared_identifiers` | **Guard 1:** phones/devices tied to more than 1 email are "shared" |
| `int_record_pairs` | Identifiers seen together in one record = a link |
| `int_email_entities` -> `int_candidate_pairs` | **Fuzzy matching**: blocking, scoring, rules |
| `int_identity_edges` | Links we trust (deterministic + auto-merged fuzzy) |
| `int_identity_graph` | **Identity graph**: connected components via label propagation -> `genome_id` |
| `int_genome_components` | Profile sizes. **Guard 2:** oversized profiles are quarantined |
| `int_field_candidates` | Every value seen per field, ranked by `seeds/survivorship_rules.csv` |
| **`customer_genome`** | **Golden record**, one row per person/device |
| **`customer_genome_audit_log`** | **Audit trail**: merge / blocked / queued_for_review / quarantined, with rule + score |
| `customer_genome_journey` | Event-by-event stage for one profile (the Use Case 3 story) |
| `rpt_customer_genome_growth` | **Audience growth** by day |
| **`aud_prospecting`** + `aud_prospecting_suppression_log` | **Use Case 2** audience and why people were removed |

### How the fuzzy matching works
1. **Blocking**: only compare emails that share SOUNDEX(last name)+first initial, or the same text before the `@`. (Avoids comparing everyone to everyone.)
2. **Scoring**: BigQuery's built-in `EDIT_DISTANCE` (count of letter changes), turned into a 0-1 similarity. Short forms count (Jon ~ Jonathan = 0.9).
3. **Rules**: a name alone is **never** enough to merge.
   - `email_domain_typo` (gmial.com vs gmail.com) -> high, auto-merge
   - `name_and_email_variant` (similar name + similar email + same domain) -> high, auto-merge
   - `name_only` -> medium, goes to the review queue, **not merged**

### How the identity graph works
Each identifier is a dot; each link is a line. Every dot starts with its own name as a label, then
for 8 rounds adopts the smallest label among its neighbours. Dots that are connected end up
sharing one label, and that label becomes the `genome_id`. A test fails loudly if 8 rounds
isn't enough for your data.

---------------------------------------------------------------------
## Demo walkthrough (pre-built, nothing live)

Replace nothing: dataset is `customer_genome`. (Add your project in front if needed.)

**1. Use Case 3 story: anonymous -> known (Maria)**

    select event_ts, source_system, page_path, anonymous_id, stage_at_this_event
    from customer_genome.customer_genome_journey
    where genome_id = (select genome_id from customer_genome.customer_genome
                       where primary_email = 'maria.alvarez@gmail.com')
    order by event_ts;

Shows: anonymous_new -> anonymous_returning -> identified (identify event) -> known_returning
(new device, recognized by hashed userId), then the booking.

**2. Golden record + survivorship**

    select * from customer_genome.customer_genome
    where primary_email in ('maria.alvarez@gmail.com', 'jonathan.smith@yahoo.com', 'priya.nair@gmail.com');

Point at `first_name_source` / `primary_email_source`: Jon's first name became "Jonathan" because
`web_booking` outranks `metarouter_identify` in `seeds/survivorship_rules.csv`.

**3. Fuzzy matching and the review queue**

    select action, rule, confidence, match_score, node_a, node_b, detail
    from customer_genome.customer_genome_audit_log
    where edge_type = 'fuzzy' or action = 'queued_for_review'
    order by action, rule;

**4. Guardrails (shared phone, travel agent device)**

    select action, rule, node_a, node_b, detail
    from customer_genome.customer_genome_audit_log
    where action = 'blocked'
    limit 20;

**5. Audience growth**

    select * from customer_genome.rpt_customer_genome_growth order by report_date;

**6. Use Case 2: audience and suppression**

    select * from customer_genome.aud_prospecting;
    select * from customer_genome.aud_prospecting_suppression_log;

### Expected results (so you know it worked)
- 22 profiles in `customer_genome`.
- Fuzzy auto-merges (2): Jon/Jonathan Smith; priya.nair@gmail.com / @gmial.com.
- Review queue (1): samlee@gmail.com vs s.lee.travel@outlook.com (Sam/Samuel Lee), **not merged**.
- Shared identifiers (3): the Garcia family phone, the travel agency phone, the agency's device. Rosa and Luis Garcia stay separate people.
- `aud_prospecting` has 7 rows: Rosa, Luis, Priya, Sam Lee, Hannah, and two anonymous visitors (anon_n2, anon_n3).
- `aud_prospecting_suppression_log` has 7 rows: Maria, Jon/Jonathan, Owen (recent_booking), Kim and Sam Ortiz (employee), Pat Chen (competitor), the agency's shared device (shared_device).

---------------------------------------------------------------------
## Knobs (dbt_project.yml -> vars)
`as_of_date` (pinned to 2026-10-15 so the demo never drifts), `max_emails_per_identifier`,
`max_component_size`, `graph_iterations`, `fuzzy_name_threshold`, `fuzzy_email_local_threshold`,
`review_name_threshold`, `prospect_lookback_days` (60), `recent_booker_days` (30).
Config seeds you can edit: `survivorship_rules.csv`, `suppression_domains.csv`.
To regenerate the pretend data: `python scripts/generate_seeds.py` then `dbt seed`.

## Be upfront on the call
- dbt is the **batch** identity layer. Real-time recognition would be a separate path.
- `genome_id` is derived from the smallest identifier in each profile, so it can change when two profiles merge. A production build would persist IDs in an incremental table.
- Recency is day-level here ("booked in the last 30 days"), not minute-level.
- The graph uses fixed-pass label propagation rather than a recursive query: predictable, easy to explain, and has a convergence test.

## Troubleshooting
- `dbt: command not found` -> the bubble isn't active. Run `source .venv/bin/activate`.
- `Access Denied` / `Permission denied` -> your Google account needs *BigQuery Data Editor* and *BigQuery Job User* on the project.
- `Failed to authenticate` -> re-run `gcloud auth application-default login`.
- `Dataset ... was not found in location` -> `location:` in profiles.yml doesn't match your region.
- `assert_graph_converged` fails -> raise `graph_iterations` in dbt_project.yml.
