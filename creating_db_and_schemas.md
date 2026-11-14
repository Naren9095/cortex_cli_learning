# Session: creating DB and schemas

Session ID: `443c83df-2b60-4b9b-8fca-bd318559b7a4`
Date: 2026-11-14
Connection: `coco_cli_user`, role `ACCOUNTADMIN`, warehouse `COMPUTE_WH`

## 1. Git branches
- Created `dev` and `qa` from `main` (all at commit `cf97dd7`).
- `dev` is the working branch locally.
- Local branches: `main`, `dev`, `qa`. Remote (`origin`) has only `main`.
- Still to do: `git push -u origin dev qa`, then make `dev` the GitHub default branch.

## 2. Design rules followed (from `__architectural_notes/`)
- `SALES_DEV` and `SALES_QA` are **transient**, so they incur no Fail-safe cost. `SALES_PROD` is permanent.
- Each sales database has `BRONZE`, `SILVER`, `GOLD` and `COMMON` schemas. `COMMON` holds file formats, sequences, UDFs and procedures.
- All tags and policies live in the `GOVERNANCE` database.
- Every object has a short comment.
- Everything is created with `IF NOT EXISTS`.
- Objects are tagged for chargeback.

## 3. Objects created

| Database | Type | Schemas |
| --- | --- | --- |
| GOVERNANCE | Permanent | TAGS, POLICIES (empty) |
| SALES_DEV | Transient | BRONZE, SILVER, GOLD, COMMON |
| SALES_QA | Transient | BRONZE, SILVER, GOLD, COMMON |
| SALES_PROD | Permanent | BRONZE, SILVER, GOLD, COMMON |

Snowflake also created the default `PUBLIC` schema in each database. It isn't tagged.

## 4. Tags (`GOVERNANCE.TAGS`)

| Tag | Allowed values |
| --- | --- |
| ENVIRONMENT | DEV, QA, PROD, SHARED |
| DATA_LAYER | BRONZE, SILVER, GOLD, COMMON, GOVERNANCE |
| COST_CENTER | SALES_ANALYTICS, DATA_GOVERNANCE |
| DATA_OWNER | free text |
| DATA_CLASSIFICATION | PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED (not applied yet; for tables and columns) |

**Assignments**
- Sales databases: `ENVIRONMENT` (DEV/QA/PROD), `COST_CENTER=SALES_ANALYTICS`, `DATA_OWNER=DATA_ENGINEERING`.
- `GOVERNANCE` database: `ENVIRONMENT=SHARED`, `COST_CENTER=DATA_GOVERNANCE`, `DATA_OWNER=DATA_ENGINEERING`.
- Every schema has its own `DATA_LAYER` value. Schemas also inherit the database tags.

## 5. Scripts (not yet committed)
- `setup/01_governance.sql`: governance database, schemas, tags and tag assignments
- `setup/02_sales_databases.sql`: the 3 sales databases, their schemas and tag assignments

Run them in that order. Both are safe to re-run.

## 6. Verification
- `SHOW TAGS IN SCHEMA GOVERNANCE.TAGS` lists all 5 tags.
- `INFORMATION_SCHEMA.TAG_REFERENCES` shows the expected tags on the databases and schemas, including inherited ones. Checked on `SALES_DEV.BRONZE`, `SALES_PROD.GOLD` and `GOVERNANCE`.
- `SHOW SCHEMAS` / `SHOW DATABASES` report dev/QA as `TRANSIENT`.

## 7. "Tags not visible" in Snowsight
The tags exist and are applied; this was checked directly. Likely reasons they don't show:
- `ACCOUNT_USAGE.TAG_REFERENCES` can lag by up to about 2 hours, and it still returned 0 rows at the time of checking.
- Snowsight may be using a role other than `ACCOUNTADMIN`, which owns all these objects.

To check immediately:
```sql
SHOW TAGS IN SCHEMA GOVERNANCE.TAGS;
SELECT * FROM TABLE(SALES_DEV.INFORMATION_SCHEMA.TAG_REFERENCES('SALES_DEV.BRONZE','SCHEMA'));
```

## 8. Open items
- Push `dev`/`qa` and set `dev` as the GitHub default branch.
- Commit the `setup/` scripts to `dev`.
- Decide whether to drop or tag the `PUBLIC` schemas.
- Add grants for non-ACCOUNTADMIN roles if needed.
- Next build step: `COMMON` objects, such as the CSV file format and sequences.

## 9. Initial load: source CSVs to stage
Stage `SALES_DEV.BRONZE.INITIAL_LOAD_STAGE` is internal, with a directory table enabled. It mirrors the folder structure of `__initial_load/`.

| Stage folder | Files | Scope |
| --- | --- | --- |
| `customer-master/2019/<country>/` | 35 | 2019 only, one folder per country |
| `sales-transaction/2019/` | 2 | 2019 only (header + item) |
| `country-master/` | 4 | all files |
| `product-master/` | 5 | all files |
| `store-master/` | 1 | all files |

**How the load was made fast**
- 39 PUT commands (one per target folder), run 8 at a time from the shell via `xargs -P 8`.
- Each PUT used `PARALLEL = 99` (max upload threads) and `AUTO_COMPRESS = TRUE`, so files are stored as `.csv.gz`.
- `OVERWRITE = TRUE` makes re-runs replace files instead of duplicating them.
- The directory table doesn't refresh on PUT; run `ALTER STAGE SALES_DEV.BRONZE.INITIAL_LOAD_STAGE REFRESH` before querying `DIRECTORY(...)`.

**Script:** `setup/03_initial_load_stage.sql` contains the stage DDL, all 39 PUTs, the refresh and a verification query. Run it with `snow sql -c coco_cli_user -f setup/03_initial_load_stage.sql`. This runs the PUTs one after another rather than concurrently. The PUT paths are absolute local paths, so edit them if the repo moves.

**Verification:** after the refresh, `DIRECTORY(@SALES_DEV.BRONZE.INITIAL_LOAD_STAGE)` showed all 47 files in the 5 folders.

**Open items**
- Commit `setup/03_initial_load_stage.sql`.
- Create CSV file formats in `SALES_DEV.COMMON` and `COPY INTO` bronze tables.
- Load remaining years (2020-2025) for customer-master and sales-transaction when needed.
