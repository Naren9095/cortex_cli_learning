-- =====================================================================
-- Data quality validation queries - __initial_load datasets
-- Generated 2026-11-13. Rule IDs match Data_Quality_Assessment.pdf
-- =====================================================================
-- ASSUMPTIONS
--  * Each CSV is loaded into a table with the same name as the file:
--      region_master, country_master, tax_master, currency_master,
--      product_category_master, product_family_master, product_model_master,
--      product_sku_master, product_country_availability, store_master.
--  * Year-split files are unioned into one table named after the file stem:
--      sales_header_<yyyy>.csv  -> sales_header
--      sales_item_<yyyy>.csv    -> sales_item
--      customer_master_<yyyy>_<cc>.csv -> customer_master, PLUS a column
--      snapshot_year NUMBER(4) taken from the folder (METADATA$FILENAME).
--  * Empty CSV fields are loaded as NULL (EMPTY_FIELD_AS_NULL = TRUE).
--  * Dates/timestamps/numbers are typed (DATE, TIMESTAMP_NTZ, NUMBER);
--    Y/N flags stay VARCHAR. customer_master.is_active may be BOOLEAN or
--    the string 'True'/'False' (handled via LOWER(TO_VARCHAR(..))).
--  * Run in the database/schema holding the tables: USE SCHEMA <db>.<schema>;
--  * Each query returns rule_id, description, baseline (count observed in
--    initial-load profiling), expected and failed_count.
-- =====================================================================


-- ---------------------------------------------------------------------
-- COUNTRY & REFERENCE
-- ---------------------------------------------------------------------

-- DQ-001 | region_master | Uniqueness | High
-- region_code is unique
SELECT 'DQ-001' AS rule_id, 'region_code is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT region_code FROM region_master GROUP BY region_code HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-002 | country_master | Uniqueness | High
-- country_code is unique
SELECT 'DQ-002' AS rule_id, 'country_code is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT country_code FROM country_master GROUP BY country_code HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-003 | tax_master | Uniqueness | High
-- tax_code is unique
SELECT 'DQ-003' AS rule_id, 'tax_code is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT tax_code FROM tax_master GROUP BY tax_code HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-004 | currency_master | Uniqueness | High
-- currency_code is unique
SELECT 'DQ-004' AS rule_id, 'currency_code is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT currency_code FROM currency_master GROUP BY currency_code HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-005 | country_master | Integrity | High
-- region_code exists in region_master
SELECT 'DQ-005' AS rule_id, 'region_code exists in region_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM country_master c LEFT JOIN region_master p ON c.region_code = p.region_code WHERE c.region_code IS NOT NULL AND p.region_code IS NULL) AS failed_count;

-- DQ-006 | country_master | Integrity | High
-- currency_code exists in currency_master
SELECT 'DQ-006' AS rule_id, 'currency_code exists in currency_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM country_master c LEFT JOIN currency_master p ON c.currency_code = p.currency_code WHERE c.currency_code IS NOT NULL AND p.currency_code IS NULL) AS failed_count;

-- DQ-007 | country_master | Integrity | High
-- tax_code exists in tax_master
SELECT 'DQ-007' AS rule_id, 'tax_code exists in tax_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM country_master c LEFT JOIN tax_master p ON c.tax_code = p.tax_code WHERE c.tax_code IS NOT NULL AND p.tax_code IS NULL) AS failed_count;

-- DQ-008 | country_master | Uniqueness | Medium
-- iso_alpha3 and country_name are unique
SELECT 'DQ-008' AS rule_id, 'iso_alpha3 and country_name are unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM (SELECT iso_alpha3 FROM country_master GROUP BY 1 HAVING COUNT(*)>1)) + (SELECT COUNT(*) FROM (SELECT country_name FROM country_master GROUP BY 1 HAVING COUNT(*)>1))) AS failed_count;

-- DQ-009 | country_master | Validity | Medium
-- country_code is ISO 3166-1 alpha-2 ('UK' should be 'GB')
SELECT 'DQ-009' AS rule_id, 'country_code is ISO 3166-1 alpha-2 (''UK'' should be ''GB'')' AS description, 1 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM country_master WHERE country_code = 'UK') AS failed_count;

-- DQ-010 | reference masters | Validity | High
-- effective_start_date <= effective_end_date
SELECT 'DQ-010' AS rule_id, 'effective_start_date <= effective_end_date' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM region_master WHERE effective_start_date > effective_end_date) + (SELECT COUNT(*) FROM country_master WHERE effective_start_date > effective_end_date) + (SELECT COUNT(*) FROM tax_master WHERE effective_start_date > effective_end_date) + (SELECT COUNT(*) FROM currency_master WHERE effective_start_date > effective_end_date)) AS failed_count;

-- DQ-011 | tax_master | Validity | High
-- tax_rate between 0 and 1 (stored as fraction)
SELECT 'DQ-011' AS rule_id, 'tax_rate between 0 and 1 (stored as fraction)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM tax_master WHERE tax_rate < 0 OR tax_rate >= 1 OR tax_rate IS NULL) AS failed_count;

-- DQ-012 | tax_master | Timeliness | High
-- Tax validity covers the earliest sale date
SELECT 'DQ-012' AS rule_id, 'Tax validity covers the earliest sale date' AS description, 35 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM tax_master WHERE effective_start_date > (SELECT MIN(transaction_timestamp)::DATE FROM sales_header)) AS failed_count;

-- DQ-013 | currency_master | Validity | Medium
-- minor_unit in (0,2,3)
SELECT 'DQ-013' AS rule_id, 'minor_unit in (0,2,3)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM currency_master WHERE minor_unit NOT IN (0,2,3) OR minor_unit IS NULL) AS failed_count;

-- DQ-014 | country_master | Validity | Medium
-- Y/N flags contain only 'Y' or 'N'
SELECT 'DQ-014' AS rule_id, 'Y/N flags contain only ''Y'' or ''N''' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM country_master WHERE ecommerce_supported NOT IN ('Y','N') OR retail_store_supported NOT IN ('Y','N') OR gdpr_applicable NOT IN ('Y','N') OR is_active NOT IN ('Y','N')) AS failed_count;

-- DQ-015 | country_master | Consistency | Low
-- apple_fiscal_segment is 1:1 with region_code
SELECT 'DQ-015' AS rule_id, 'apple_fiscal_segment is 1:1 with region_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT region_code FROM country_master GROUP BY 1 HAVING COUNT(DISTINCT apple_fiscal_segment) > 1)) AS failed_count;

-- DQ-016 | country_master | Consistency | Medium
-- AE/SA mapped to EMEA (business review)
SELECT 'DQ-016' AS rule_id, 'AE/SA mapped to EMEA (business review)' AS description, 2 AS baseline, '= 0 after review' AS expected,
       (SELECT COUNT(*) FROM country_master WHERE country_code IN ('AE','SA') AND region_code <> 'EMEA') AS failed_count;


-- ---------------------------------------------------------------------
-- PRODUCT
-- ---------------------------------------------------------------------

-- DQ-020 | product masters | Uniqueness | High
-- PKs unique: category_code, family_code, model_code, sku_code
SELECT 'DQ-020' AS rule_id, 'PKs unique: category_code, family_code, model_code, sku_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM (SELECT category_code FROM product_category_master GROUP BY category_code HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT family_code FROM product_family_master GROUP BY family_code HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT model_code FROM product_model_master GROUP BY model_code HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT sku_code FROM product_sku_master GROUP BY sku_code HAVING COUNT(*) > 1))) AS failed_count;

-- DQ-021 | product_country_availability | Uniqueness | High
-- (sku_code, country_code) is unique
SELECT 'DQ-021' AS rule_id, '(sku_code, country_code) is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT sku_code, country_code FROM product_country_availability GROUP BY sku_code, country_code HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-022 | product_family_master | Integrity | High
-- category_code exists in product_category_master
SELECT 'DQ-022' AS rule_id, 'category_code exists in product_category_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_family_master c LEFT JOIN product_category_master p ON c.category_code = p.category_code WHERE c.category_code IS NOT NULL AND p.category_code IS NULL) AS failed_count;

-- DQ-023 | product_model_master | Integrity | High
-- family_code exists in product_family_master
SELECT 'DQ-023' AS rule_id, 'family_code exists in product_family_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_model_master c LEFT JOIN product_family_master p ON c.family_code = p.family_code WHERE c.family_code IS NOT NULL AND p.family_code IS NULL) AS failed_count;

-- DQ-024 | product_sku_master | Integrity | High
-- model_code exists in product_model_master
SELECT 'DQ-024' AS rule_id, 'model_code exists in product_model_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_sku_master c LEFT JOIN product_model_master p ON c.model_code = p.model_code WHERE c.model_code IS NOT NULL AND p.model_code IS NULL) AS failed_count;

-- DQ-025 | product_country_availability | Integrity | High
-- sku_code exists in product_sku_master
SELECT 'DQ-025' AS rule_id, 'sku_code exists in product_sku_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_country_availability c LEFT JOIN product_sku_master p ON c.sku_code = p.sku_code WHERE c.sku_code IS NOT NULL AND p.sku_code IS NULL) AS failed_count;

-- DQ-026 | product_country_availability | Integrity | High
-- country_code exists in country_master
SELECT 'DQ-026' AS rule_id, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_country_availability c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count;

-- DQ-027 | product_family_master | Consistency | Medium
-- family_code = category_code || launch_year
SELECT 'DQ-027' AS rule_id, 'family_code = category_code || launch_year' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_family_master WHERE family_code <> category_code || TO_VARCHAR(launch_year)) AS failed_count;

-- DQ-028 | product_model_master | Consistency | Medium
-- model_code starts with family_code
SELECT 'DQ-028' AS rule_id, 'model_code starts with family_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_model_master WHERE NOT STARTSWITH(model_code, family_code)) AS failed_count;

-- DQ-029 | product_model_master | Consistency | Medium
-- YEAR(launch_date) = family launch_year
SELECT 'DQ-029' AS rule_id, 'YEAR(launch_date) = family launch_year' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_model_master m JOIN product_family_master f ON m.family_code = f.family_code WHERE YEAR(m.launch_date) <> f.launch_year) AS failed_count;

-- DQ-030 | product_sku_master | Consistency | Medium
-- global_launch_date = model launch_date
SELECT 'DQ-030' AS rule_id, 'global_launch_date = model launch_date' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_sku_master s JOIN product_model_master m ON s.model_code = m.model_code WHERE s.global_launch_date <> m.launch_date) AS failed_count;

-- DQ-031 | product_country_availability | Consistency | Medium
-- local_launch_date >= SKU global_launch_date
SELECT 'DQ-031' AS rule_id, 'local_launch_date >= SKU global_launch_date' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_country_availability a JOIN product_sku_master s ON a.sku_code = s.sku_code WHERE a.local_launch_date < s.global_launch_date) AS failed_count;

-- DQ-032 | model / availability | Validity | Medium
-- discontinue date not before launch date
SELECT 'DQ-032' AS rule_id, 'discontinue date not before launch date' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM product_model_master WHERE discontinue_date < launch_date) + (SELECT COUNT(*) FROM product_country_availability WHERE local_discontinue_date < local_launch_date)) AS failed_count;

-- DQ-033 | product_model_master | Uniqueness | Medium
-- model_name is unique
SELECT 'DQ-033' AS rule_id, 'model_name is unique' AS description, 1 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT model_name FROM product_model_master GROUP BY 1 HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-034 | product_model_master | Completeness | High
-- Lifecycle populated: models with a discontinue_date (gap if 0)
SELECT 'DQ-034' AS rule_id, 'Lifecycle populated: models with a discontinue_date (gap if 0)' AS description, 0 AS baseline, '> 0 expected (review)' AS expected,
       (SELECT COUNT(*) FROM product_model_master WHERE discontinue_date IS NOT NULL) AS failed_count;

-- DQ-035 | product_country_availability | Consistency | High
-- Missing SKU x country pairs (0 = full cross join, gap)
SELECT 'DQ-035' AS rule_id, 'Missing SKU x country pairs (0 = full cross join, gap)' AS description, 0 AS baseline, '> 0 expected (review)' AS expected,
       (SELECT (SELECT COUNT(*) FROM product_sku_master) * (SELECT COUNT(*) FROM country_master) - (SELECT COUNT(*) FROM product_country_availability)) AS failed_count;

-- DQ-036 | product_country_availability | Uniqueness | Medium
-- local_part_number unique within a country
SELECT 'DQ-036' AS rule_id, 'local_part_number unique within a country' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT country_code, local_part_number FROM product_country_availability GROUP BY 1,2 HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-037 | product_sku_master | Validity | Low
-- price_tier in (Standard, Premium, Ultra)
SELECT 'DQ-037' AS rule_id, 'price_tier in (Standard, Premium, Ultra)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_sku_master WHERE price_tier NOT IN ('Standard','Premium','Ultra') OR price_tier IS NULL) AS failed_count;

-- DQ-038 | product_sku_master | Validity | Low
-- sku_code matches M + 6 alnum + LL/A
SELECT 'DQ-038' AS rule_id, 'sku_code matches M + 6 alnum + LL/A' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM product_sku_master WHERE NOT RLIKE(sku_code, 'M[A-Z0-9]{6}LL/A')) AS failed_count;


-- ---------------------------------------------------------------------
-- STORE
-- ---------------------------------------------------------------------

-- DQ-040 | store_master | Uniqueness | High
-- store_code is unique
SELECT 'DQ-040' AS rule_id, 'store_code is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT store_code FROM store_master GROUP BY store_code HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-041 | store_master | Integrity | High
-- country_code exists in country_master
SELECT 'DQ-041' AS rule_id, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count;

-- DQ-042 | store_master | Integrity | High
-- region_code exists in region_master
SELECT 'DQ-042' AS rule_id, 'region_code exists in region_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master c LEFT JOIN region_master p ON c.region_code = p.region_code WHERE c.region_code IS NOT NULL AND p.region_code IS NULL) AS failed_count;

-- DQ-043 | store_master | Consistency | Medium
-- store region_code = country region_code
SELECT 'DQ-043' AS rule_id, 'store region_code = country region_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master s JOIN country_master c ON s.country_code = c.country_code WHERE s.region_code <> c.region_code) AS failed_count;

-- DQ-044 | store_master | Consistency | Low
-- store_code prefix = country_code
SELECT 'DQ-044' AS rule_id, 'store_code prefix = country_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE NOT STARTSWITH(store_code, country_code || '_')) AS failed_count;

-- DQ-045 | store_master | Integrity | High
-- tax_jurisdiction_code exists in tax_master
SELECT 'DQ-045' AS rule_id, 'tax_jurisdiction_code exists in tax_master' AS description, 121 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master c LEFT JOIN tax_master p ON c.tax_jurisdiction_code = p.tax_code WHERE c.tax_jurisdiction_code IS NOT NULL AND p.tax_code IS NULL) AS failed_count;

-- DQ-046 | store_master | Consistency | Medium
-- No stores in countries with retail_store_supported = 'N'
SELECT 'DQ-046' AS rule_id, 'No stores in countries with retail_store_supported = ''N''' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master s JOIN country_master c ON s.country_code = c.country_code WHERE c.retail_store_supported = 'N') AS failed_count;

-- DQ-047 | store_master | Validity | Medium
-- store_close_date >= store_open_date
SELECT 'DQ-047' AS rule_id, 'store_close_date >= store_open_date' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE store_close_date < store_open_date) AS failed_count;

-- DQ-048 | sales_header | Timeliness | High
-- POS transactions on/after store_open_date
SELECT 'DQ-048' AS rule_id, 'POS transactions on/after store_open_date' AS description, 152808 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN store_master s ON h.store_id = s.store_code WHERE h.transaction_timestamp::DATE < s.store_open_date) AS failed_count;

-- DQ-049 | store_master | Timeliness | Medium
-- SCD effective_start_date <= store_open_date
SELECT 'DQ-049' AS rule_id, 'SCD effective_start_date <= store_open_date' AS description, 121 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE effective_start_date > store_open_date) AS failed_count;

-- DQ-050 | store_master | Validity | Medium
-- latitude in [-90,90], longitude in [-180,180]
SELECT 'DQ-050' AS rule_id, 'latitude in [-90,90], longitude in [-180,180]' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE latitude NOT BETWEEN -90 AND 90 OR longitude NOT BETWEEN -180 AND 180 OR latitude IS NULL OR longitude IS NULL) AS failed_count;

-- DQ-051 | store_master | Validity | Medium
-- Plausible rent: annual_rent_usd / floor_area_sqft <= 1,000
SELECT 'DQ-051' AS rule_id, 'Plausible rent: annual_rent_usd / floor_area_sqft <= 1,000' AS description, 29 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE annual_rent_usd / NULLIF(floor_area_sqft,0) > 1000) AS failed_count;

-- DQ-052 | store_master | Validity | Low
-- format_code in (FLG, MALL, MINI)
SELECT 'DQ-052' AS rule_id, 'format_code in (FLG, MALL, MINI)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE format_code NOT IN ('FLG','MALL','MINI') OR format_code IS NULL) AS failed_count;

-- DQ-053 | store_master | Validity | Low
-- address_line1 without embedded newline
SELECT 'DQ-053' AS rule_id, 'address_line1 without embedded newline' AS description, 5 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE CONTAINS(address_line1, CHR(10)) OR CONTAINS(address_line1, CHR(13))) AS failed_count;

-- DQ-054 | store_master | Consistency | Low
-- US tax_jurisdiction_code = 'US_' || state_code || '_STD'
SELECT 'DQ-054' AS rule_id, 'US tax_jurisdiction_code = ''US_'' || state_code || ''_STD''' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM store_master WHERE country_code = 'US' AND tax_jurisdiction_code <> 'US_' || state_code || '_STD') AS failed_count;


-- ---------------------------------------------------------------------
-- CUSTOMER
-- ---------------------------------------------------------------------

-- DQ-060 | customer_master | Uniqueness | High
-- (customer_id, snapshot_year) is unique
SELECT 'DQ-060' AS rule_id, '(customer_id, snapshot_year) is unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT customer_id, snapshot_year FROM customer_master GROUP BY customer_id, snapshot_year HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-061 | customer_master | Consistency | High
-- customer_id <-> customer_number is 1:1
SELECT 'DQ-061' AS rule_id, 'customer_id <-> customer_number is 1:1' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT customer_number) > 1)) + (SELECT COUNT(*) FROM (SELECT customer_number FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT customer_id) > 1))) AS failed_count;

-- DQ-062 | customer_master | Integrity | High
-- country_code exists in country_master
SELECT 'DQ-062' AS rule_id, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count;

-- DQ-063 | customer_master | Consistency | Low
-- region / country_name / preferred_language match country_master
SELECT 'DQ-063' AS rule_id, 'region / country_name / preferred_language match country_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master cu JOIN country_master c ON cu.country_code = c.country_code WHERE cu.region <> c.region_code OR cu.country_name <> c.country_name OR cu.preferred_language <> c.primary_language) AS failed_count;

-- DQ-064 | customer_master | Validity | Medium
-- customer_number format CUST-<acq_year>-<CC>-<6 digits>, consistent with acquisition_year and country_code
SELECT 'DQ-064' AS rule_id, 'customer_number format CUST-<acq_year>-<CC>-<6 digits>, consistent with acquisition_year and country_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE NOT RLIKE(customer_number, 'CUST-[0-9]{4}-[A-Z]{2}-[0-9]{6}') OR SUBSTR(customer_number, 6, 4) <> TO_VARCHAR(acquisition_year) OR SUBSTR(customer_number, 11, 2) <> country_code) AS failed_count;

-- DQ-065 | customer_master | Consistency | Medium
-- acquisition_year = YEAR(registration_date)
SELECT 'DQ-065' AS rule_id, 'acquisition_year = YEAR(registration_date)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE acquisition_year <> YEAR(registration_date)) AS failed_count;

-- DQ-066 | customer_master | Consistency | Low
-- full_name = first_name || ' ' || last_name
SELECT 'DQ-066' AS rule_id, 'full_name = first_name || '' '' || last_name' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE full_name <> first_name || ' ' || last_name) AS failed_count;

-- DQ-067 | customer_master | Validity | Medium
-- email has a valid format
SELECT 'DQ-067' AS rule_id, 'email has a valid format' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE email IS NULL OR NOT RLIKE(email, '[^@ ]+@[^@ ]+\\.[a-z]{2,}')) AS failed_count;

-- DQ-068 | customer_master | Uniqueness | Medium
-- email not shared by different customers (count of shared emails)
SELECT 'DQ-068' AS rule_id, 'email not shared by different customers (count of shared emails)' AS description, 6067 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT email FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT customer_id) > 1)) AS failed_count;

-- DQ-069 | customer_master | Validity | Medium
-- Age at registration >= 13 (rows)
SELECT 'DQ-069' AS rule_id, 'Age at registration >= 13 (rows)' AS description, 3652 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE FLOOR(DATEDIFF('day', date_of_birth, registration_date) / 365) < 13) AS failed_count;

-- DQ-070 | customer_master | Validity | Low
-- street_address has no leading/trailing whitespace
SELECT 'DQ-070' AS rule_id, 'street_address has no leading/trailing whitespace' AS description, 2850 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE street_address <> TRIM(street_address)) AS failed_count;

-- DQ-071 | customer_master | Validity | Low
-- city has no leading/trailing whitespace
SELECT 'DQ-071' AS rule_id, 'city has no leading/trailing whitespace' AS description, 16 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE city <> TRIM(city)) AS failed_count;

-- DQ-072 | customer_master | Consistency | Medium
-- customer_type = NEW exactly in the acquisition snapshot
SELECT 'DQ-072' AS rule_id, 'customer_type = NEW exactly in the acquisition snapshot' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE (customer_type = 'NEW') <> (snapshot_year = acquisition_year)) AS failed_count;

-- DQ-073 | customer_master | Completeness | Medium
-- No gaps in yearly snapshot presence (customers)
SELECT 'DQ-073' AS rule_id, 'No gaps in yearly snapshot presence (customers)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY 1 HAVING MAX(snapshot_year) - MIN(snapshot_year) + 1 <> COUNT(DISTINCT snapshot_year))) AS failed_count;

-- DQ-074 | customer_master | Consistency | Medium
-- Immutable attributes unchanged across snapshots (name, DOB, email, segment, country)
SELECT 'DQ-074' AS rule_id, 'Immutable attributes unchanged across snapshots (name, DOB, email, segment, country)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT first_name) > 1 OR COUNT(DISTINCT last_name) > 1 OR COUNT(DISTINCT date_of_birth) > 1 OR COUNT(DISTINCT email) > 1 OR COUNT(DISTINCT customer_segment) > 1 OR COUNT(DISTINCT country_code) > 1)) AS failed_count;

-- DQ-075 | customer_master | Consistency | Low
-- No loyalty_tier downgrades between consecutive snapshots
SELECT 'DQ-075' AS rule_id, 'No loyalty_tier downgrades between consecutive snapshots' AS description, 0 AS baseline, '= 0 (info)' AS expected,
       (SELECT COUNT(*) FROM (SELECT DECODE(loyalty_tier,'None',0,'Silver',1,'Gold',2,'Platinum',3) AS t, LAG(DECODE(loyalty_tier,'None',0,'Silver',1,'Gold',2,'Platinum',3)) OVER (PARTITION BY customer_id ORDER BY snapshot_year) AS prev_t FROM customer_master) WHERE t < prev_t) AS failed_count;

-- DQ-076 | customer_master | Validity | Low
-- Domain values: gender, customer_segment, loyalty_tier, customer_type
SELECT 'DQ-076' AS rule_id, 'Domain values: gender, customer_segment, loyalty_tier, customer_type' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM customer_master WHERE gender NOT IN ('Female','Male') OR customer_segment NOT IN ('Consumer','Business','Education') OR loyalty_tier NOT IN ('None','Silver','Gold','Platinum') OR customer_type NOT IN ('NEW','RETURNING')) AS failed_count;


-- ---------------------------------------------------------------------
-- SALES
-- ---------------------------------------------------------------------

-- DQ-080 | sales_header | Uniqueness | High
-- transaction_sk and transaction_id are unique
SELECT 'DQ-080' AS rule_id, 'transaction_sk and transaction_id are unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM (SELECT transaction_sk FROM sales_header GROUP BY transaction_sk HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT transaction_id FROM sales_header GROUP BY transaction_id HAVING COUNT(*) > 1))) AS failed_count;

-- DQ-081 | sales_item | Uniqueness | High
-- transaction_line_id and (transaction_sk, line_number) are unique
SELECT 'DQ-081' AS rule_id, 'transaction_line_id and (transaction_sk, line_number) are unique' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM (SELECT transaction_line_id FROM sales_item GROUP BY transaction_line_id HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT transaction_sk, line_number FROM sales_item GROUP BY transaction_sk, line_number HAVING COUNT(*) > 1))) AS failed_count;

-- DQ-082 | sales_item | Integrity | High
-- Every item has a header
SELECT 'DQ-082' AS rule_id, 'Every item has a header' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item c LEFT JOIN sales_header p ON c.transaction_sk = p.transaction_sk WHERE c.transaction_sk IS NOT NULL AND p.transaction_sk IS NULL) AS failed_count;

-- DQ-083 | sales_header | Completeness | High
-- Every header has at least one item
SELECT 'DQ-083' AS rule_id, 'Every header has at least one item' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h WHERE NOT EXISTS (SELECT 1 FROM sales_item i WHERE i.transaction_sk = h.transaction_sk)) AS failed_count;

-- DQ-084 | sales_item | Completeness | Low
-- Transactions with more than one line (0 = single-line baskets, gap)
SELECT 'DQ-084' AS rule_id, 'Transactions with more than one line (0 = single-line baskets, gap)' AS description, 0 AS baseline, '> 0 expected (info)' AS expected,
       (SELECT COUNT(*) FROM (SELECT transaction_sk FROM sales_item GROUP BY 1 HAVING COUNT(*) > 1)) AS failed_count;

-- DQ-085 | sales_header | Integrity | High
-- customer_id exists in customer_master
SELECT 'DQ-085' AS rule_id, 'customer_id exists in customer_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h WHERE h.customer_id IS NULL OR NOT EXISTS (SELECT 1 FROM customer_master c WHERE c.customer_id = h.customer_id)) AS failed_count;

-- DQ-086 | sales_header | Integrity | High
-- store_id exists in store_master
SELECT 'DQ-086' AS rule_id, 'store_id exists in store_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header c LEFT JOIN store_master p ON c.store_id = p.store_code WHERE c.store_id IS NOT NULL AND p.store_code IS NULL) AS failed_count;

-- DQ-087 | sales_header | Integrity | High
-- country_code exists in country_master
SELECT 'DQ-087' AS rule_id, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count;

-- DQ-088 | sales_header | Integrity | High
-- currency exists in currency_master
SELECT 'DQ-088' AS rule_id, 'currency exists in currency_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header c LEFT JOIN currency_master p ON c.currency = p.currency_code WHERE c.currency IS NOT NULL AND p.currency_code IS NULL) AS failed_count;

-- DQ-089 | sales_item | Integrity | High
-- sku_code exists in product_sku_master
SELECT 'DQ-089' AS rule_id, 'sku_code exists in product_sku_master' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item c LEFT JOIN product_sku_master p ON c.sku_code = p.sku_code WHERE c.sku_code IS NOT NULL AND p.sku_code IS NULL) AS failed_count;

-- DQ-090 | sales_header | Consistency | High
-- POS requires store_id; ONLINE must have no store_id
SELECT 'DQ-090' AS rule_id, 'POS requires store_id; ONLINE must have no store_id' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header WHERE channel_id NOT IN ('POS','ONLINE') OR (channel_id = 'POS' AND store_id IS NULL) OR (channel_id = 'ONLINE' AND store_id IS NOT NULL)) AS failed_count;

-- DQ-091 | sales_header | Consistency | High
-- POS country_code = store country_code
SELECT 'DQ-091' AS rule_id, 'POS country_code = store country_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN store_master s ON h.store_id = s.store_code WHERE h.country_code <> s.country_code) AS failed_count;

-- DQ-092 | sales_header | Consistency | High
-- currency = country currency_code
SELECT 'DQ-092' AS rule_id, 'currency = country currency_code' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN country_master c ON h.country_code = c.country_code WHERE h.currency <> c.currency_code) AS failed_count;

-- DQ-093 | sales_header | Consistency | Medium
-- Sale country = customer country
SELECT 'DQ-093' AS rule_id, 'Sale country = customer country' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN (SELECT DISTINCT customer_id, country_code FROM customer_master) c ON h.customer_id = c.customer_id WHERE h.country_code <> c.country_code) AS failed_count;

-- DQ-094 | sales_item | Consistency | Medium
-- category_code matches SKU hierarchy
SELECT 'DQ-094' AS rule_id, 'category_code matches SKU hierarchy' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item i JOIN (SELECT s.sku_code, f.category_code FROM product_sku_master s JOIN product_model_master m ON s.model_code = m.model_code JOIN product_family_master f ON m.family_code = f.family_code) x ON i.sku_code = x.sku_code WHERE i.category_code <> x.category_code) AS failed_count;

-- DQ-095 | sales_item | Accuracy | High
-- line_total = quantity*unit_price - discount_amount + tax_amount (+/-0.01)
SELECT 'DQ-095' AS rule_id, 'line_total = quantity*unit_price - discount_amount + tax_amount (+/-0.01)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item WHERE ABS(quantity * unit_price - discount_amount + tax_amount - line_total) > 0.01) AS failed_count;

-- DQ-096 | sales_header | Accuracy | High
-- Header gross/discount/tax/net = sum of item lines (+/-0.01)
SELECT 'DQ-096' AS rule_id, 'Header gross/discount/tax/net = sum of item lines (+/-0.01)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN (SELECT transaction_sk, SUM(quantity * unit_price) g, SUM(discount_amount) d, SUM(tax_amount) t, SUM(line_total) n FROM sales_item GROUP BY 1) i ON h.transaction_sk = i.transaction_sk WHERE ABS(h.gross_amount - i.g) > 0.01 OR ABS(h.total_discount - i.d) > 0.01 OR ABS(h.total_tax - i.t) > 0.01 OR ABS(h.net_total - i.n) > 0.01) AS failed_count;

-- DQ-097 | sales_header | Accuracy | High
-- net_total = gross_amount - total_discount + total_tax (+/-0.01)
SELECT 'DQ-097' AS rule_id, 'net_total = gross_amount - total_discount + total_tax (+/-0.01)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header WHERE ABS(gross_amount - total_discount + total_tax - net_total) > 0.01) AS failed_count;

-- DQ-098 | sales_header / sales_item | Validity | High
-- No negative/zero amounts; discount <= gross; quantity > 0
SELECT 'DQ-098' AS rule_id, 'No negative/zero amounts; discount <= gross; quantity > 0' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT (SELECT COUNT(*) FROM sales_header WHERE gross_amount <= 0 OR net_total <= 0 OR total_discount < 0 OR total_tax < 0 OR total_discount > gross_amount) + (SELECT COUNT(*) FROM sales_item WHERE quantity <= 0 OR unit_price <= 0 OR discount_amount > quantity * unit_price)) AS failed_count;

-- DQ-099 | sales_header | Accuracy | High
-- Effective tax rate = tax_master rate for the country (+/-0.002)
SELECT 'DQ-099' AS rule_id, 'Effective tax rate = tax_master rate for the country (+/-0.002)' AS description, 45671 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN country_master c ON h.country_code = c.country_code JOIN tax_master t ON c.tax_code = t.tax_code WHERE (h.gross_amount - h.total_discount) > 0 AND ABS(h.total_tax / (h.gross_amount - h.total_discount) - t.tax_rate) > 0.002) AS failed_count;

-- DQ-100 | sales_item | Timeliness | High
-- Sale on/after SKU global_launch_date
SELECT 'DQ-100' AS rule_id, 'Sale on/after SKU global_launch_date' AS description, 6737 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk JOIN product_sku_master s ON i.sku_code = s.sku_code WHERE h.transaction_timestamp::DATE < s.global_launch_date) AS failed_count;

-- DQ-101 | sales_item | Timeliness | High
-- Sale on/after local_launch_date in that country
SELECT 'DQ-101' AS rule_id, 'Sale on/after local_launch_date in that country' AS description, 6739 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk JOIN product_country_availability a ON a.sku_code = i.sku_code AND a.country_code = h.country_code WHERE h.transaction_timestamp::DATE < a.local_launch_date) AS failed_count;

-- DQ-102 | sales_item | Integrity | High
-- SKU is available in the sale country
SELECT 'DQ-102' AS rule_id, 'SKU is available in the sale country' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk LEFT JOIN product_country_availability a ON a.sku_code = i.sku_code AND a.country_code = h.country_code WHERE a.sku_code IS NULL) AS failed_count;

-- DQ-103 | sales_header | Timeliness | High
-- Sale on/after customer registration_date
SELECT 'DQ-103' AS rule_id, 'Sale on/after customer registration_date' AS description, 111385 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN (SELECT customer_id, MIN(registration_date) AS reg FROM customer_master GROUP BY 1) c ON h.customer_id = c.customer_id WHERE h.transaction_timestamp::DATE < c.reg) AS failed_count;

-- DQ-104 | sales_header | Consistency | Medium
-- No sales by customers inactive in that year's snapshot
SELECT 'DQ-104' AS rule_id, 'No sales by customers inactive in that year''s snapshot' AS description, 40311 AS baseline, '= 0 (review)' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN customer_master c ON c.customer_id = h.customer_id AND c.snapshot_year = YEAR(h.transaction_timestamp) WHERE LOWER(TO_VARCHAR(c.is_active)) = 'false') AS failed_count;

-- DQ-105 | sales_header | Consistency | Low
-- Customer present in the snapshot of the sale year
SELECT 'DQ-105' AS rule_id, 'Customer present in the snapshot of the sale year' AS description, 54 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h WHERE NOT EXISTS (SELECT 1 FROM customer_master c WHERE c.customer_id = h.customer_id AND c.snapshot_year = YEAR(h.transaction_timestamp))) AS failed_count;

-- DQ-106 | sales_header | Validity | High
-- No fractional amounts in zero-decimal currencies (JPY, KRW)
SELECT 'DQ-106' AS rule_id, 'No fractional amounts in zero-decimal currencies (JPY, KRW)' AS description, 66607 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN currency_master c ON h.currency = c.currency_code WHERE c.minor_unit = 0 AND h.gross_amount <> ROUND(h.gross_amount, 0)) AS failed_count;

-- DQ-107 | sales_header | Consistency | High
-- Tax-inclusive countries must not add tax on top of gross
SELECT 'DQ-107' AS rule_id, 'Tax-inclusive countries must not add tax on top of gross' AS description, 451922 AS baseline, '= 0 (decision needed)' AS expected,
       (SELECT COUNT(*) FROM sales_header h JOIN country_master c ON h.country_code = c.country_code JOIN tax_master t ON c.tax_code = t.tax_code WHERE t.tax_inclusive_flag = 'Y' AND h.total_tax > 0 AND ABS(h.net_total - (h.gross_amount - h.total_discount + h.total_tax)) <= 0.01) AS failed_count;

-- DQ-108 | sales_header | Validity | Medium
-- ONLINE orders not paid in Cash
SELECT 'DQ-108' AS rule_id, 'ONLINE orders not paid in Cash' AS description, 23488 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header WHERE channel_id = 'ONLINE' AND payment_method = 'Cash') AS failed_count;

-- DQ-109 | sales_item | Consistency | Medium
-- SKU+currency price spread (max/min) <= 2x (count of pairs)
SELECT 'DQ-109' AS rule_id, 'SKU+currency price spread (max/min) <= 2x (count of pairs)' AS description, 7419 AS baseline, '= 0 (review)' AS expected,
       (SELECT COUNT(*) FROM (SELECT i.sku_code, h.currency FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk GROUP BY 1,2 HAVING MAX(i.unit_price) / NULLIF(MIN(i.unit_price),0) > 2)) AS failed_count;

-- DQ-110 | sales_header | Validity | Low
-- POS transactions outside 06:00-23:59 store hours
SELECT 'DQ-110' AS rule_id, 'POS transactions outside 06:00-23:59 store hours' AS description, 82824 AS baseline, '= 0 (review)' AS expected,
       (SELECT COUNT(*) FROM sales_header WHERE channel_id = 'POS' AND HOUR(transaction_timestamp) < 6) AS failed_count;

-- DQ-111 | sales_header | Timeliness | Medium
-- No future-dated transactions
SELECT 'DQ-111' AS rule_id, 'No future-dated transactions' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_header WHERE transaction_timestamp > CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS failed_count;

-- DQ-112 | sales_item | Validity | Low
-- quantity in expected range (1-10)
SELECT 'DQ-112' AS rule_id, 'quantity in expected range (1-10)' AS description, 0 AS baseline, '= 0' AS expected,
       (SELECT COUNT(*) FROM sales_item WHERE quantity NOT BETWEEN 1 AND 10) AS failed_count;


-- =====================================================================
-- SCORECARD: all rules in one result set
-- =====================================================================
WITH results AS (
  SELECT 'DQ-001' AS rule_id, 'region_master' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'region_code is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT region_code FROM region_master GROUP BY region_code HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-002' AS rule_id, 'country_master' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'country_code is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT country_code FROM country_master GROUP BY country_code HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-003' AS rule_id, 'tax_master' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'tax_code is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT tax_code FROM tax_master GROUP BY tax_code HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-004' AS rule_id, 'currency_master' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'currency_code is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT currency_code FROM currency_master GROUP BY currency_code HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-005' AS rule_id, 'country_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'region_code exists in region_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM country_master c LEFT JOIN region_master p ON c.region_code = p.region_code WHERE c.region_code IS NOT NULL AND p.region_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-006' AS rule_id, 'country_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'currency_code exists in currency_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM country_master c LEFT JOIN currency_master p ON c.currency_code = p.currency_code WHERE c.currency_code IS NOT NULL AND p.currency_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-007' AS rule_id, 'country_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'tax_code exists in tax_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM country_master c LEFT JOIN tax_master p ON c.tax_code = p.tax_code WHERE c.tax_code IS NOT NULL AND p.tax_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-008' AS rule_id, 'country_master' AS table_name, 'Uniqueness' AS dimension, 'Medium' AS severity, 'iso_alpha3 and country_name are unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM (SELECT iso_alpha3 FROM country_master GROUP BY 1 HAVING COUNT(*)>1)) + (SELECT COUNT(*) FROM (SELECT country_name FROM country_master GROUP BY 1 HAVING COUNT(*)>1))) AS failed_count
  UNION ALL SELECT 'DQ-009' AS rule_id, 'country_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'country_code is ISO 3166-1 alpha-2 (''UK'' should be ''GB'')' AS description, 1 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM country_master WHERE country_code = 'UK') AS failed_count
  UNION ALL SELECT 'DQ-010' AS rule_id, 'reference masters' AS table_name, 'Validity' AS dimension, 'High' AS severity, 'effective_start_date <= effective_end_date' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM region_master WHERE effective_start_date > effective_end_date) + (SELECT COUNT(*) FROM country_master WHERE effective_start_date > effective_end_date) + (SELECT COUNT(*) FROM tax_master WHERE effective_start_date > effective_end_date) + (SELECT COUNT(*) FROM currency_master WHERE effective_start_date > effective_end_date)) AS failed_count
  UNION ALL SELECT 'DQ-011' AS rule_id, 'tax_master' AS table_name, 'Validity' AS dimension, 'High' AS severity, 'tax_rate between 0 and 1 (stored as fraction)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM tax_master WHERE tax_rate < 0 OR tax_rate >= 1 OR tax_rate IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-012' AS rule_id, 'tax_master' AS table_name, 'Timeliness' AS dimension, 'High' AS severity, 'Tax validity covers the earliest sale date' AS description, 35 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM tax_master WHERE effective_start_date > (SELECT MIN(transaction_timestamp)::DATE FROM sales_header)) AS failed_count
  UNION ALL SELECT 'DQ-013' AS rule_id, 'currency_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'minor_unit in (0,2,3)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM currency_master WHERE minor_unit NOT IN (0,2,3) OR minor_unit IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-014' AS rule_id, 'country_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'Y/N flags contain only ''Y'' or ''N''' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM country_master WHERE ecommerce_supported NOT IN ('Y','N') OR retail_store_supported NOT IN ('Y','N') OR gdpr_applicable NOT IN ('Y','N') OR is_active NOT IN ('Y','N')) AS failed_count
  UNION ALL SELECT 'DQ-015' AS rule_id, 'country_master' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'apple_fiscal_segment is 1:1 with region_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT region_code FROM country_master GROUP BY 1 HAVING COUNT(DISTINCT apple_fiscal_segment) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-016' AS rule_id, 'country_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'AE/SA mapped to EMEA (business review)' AS description, 2 AS baseline, '= 0 after review' AS expected, (SELECT COUNT(*) FROM country_master WHERE country_code IN ('AE','SA') AND region_code <> 'EMEA') AS failed_count
  UNION ALL SELECT 'DQ-020' AS rule_id, 'product masters' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'PKs unique: category_code, family_code, model_code, sku_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM (SELECT category_code FROM product_category_master GROUP BY category_code HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT family_code FROM product_family_master GROUP BY family_code HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT model_code FROM product_model_master GROUP BY model_code HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT sku_code FROM product_sku_master GROUP BY sku_code HAVING COUNT(*) > 1))) AS failed_count
  UNION ALL SELECT 'DQ-021' AS rule_id, 'product_country_availability' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, '(sku_code, country_code) is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT sku_code, country_code FROM product_country_availability GROUP BY sku_code, country_code HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-022' AS rule_id, 'product_family_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'category_code exists in product_category_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_family_master c LEFT JOIN product_category_master p ON c.category_code = p.category_code WHERE c.category_code IS NOT NULL AND p.category_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-023' AS rule_id, 'product_model_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'family_code exists in product_family_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_model_master c LEFT JOIN product_family_master p ON c.family_code = p.family_code WHERE c.family_code IS NOT NULL AND p.family_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-024' AS rule_id, 'product_sku_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'model_code exists in product_model_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_sku_master c LEFT JOIN product_model_master p ON c.model_code = p.model_code WHERE c.model_code IS NOT NULL AND p.model_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-025' AS rule_id, 'product_country_availability' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'sku_code exists in product_sku_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_country_availability c LEFT JOIN product_sku_master p ON c.sku_code = p.sku_code WHERE c.sku_code IS NOT NULL AND p.sku_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-026' AS rule_id, 'product_country_availability' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_country_availability c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-027' AS rule_id, 'product_family_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'family_code = category_code || launch_year' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_family_master WHERE family_code <> category_code || TO_VARCHAR(launch_year)) AS failed_count
  UNION ALL SELECT 'DQ-028' AS rule_id, 'product_model_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'model_code starts with family_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_model_master WHERE NOT STARTSWITH(model_code, family_code)) AS failed_count
  UNION ALL SELECT 'DQ-029' AS rule_id, 'product_model_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'YEAR(launch_date) = family launch_year' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_model_master m JOIN product_family_master f ON m.family_code = f.family_code WHERE YEAR(m.launch_date) <> f.launch_year) AS failed_count
  UNION ALL SELECT 'DQ-030' AS rule_id, 'product_sku_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'global_launch_date = model launch_date' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_sku_master s JOIN product_model_master m ON s.model_code = m.model_code WHERE s.global_launch_date <> m.launch_date) AS failed_count
  UNION ALL SELECT 'DQ-031' AS rule_id, 'product_country_availability' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'local_launch_date >= SKU global_launch_date' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_country_availability a JOIN product_sku_master s ON a.sku_code = s.sku_code WHERE a.local_launch_date < s.global_launch_date) AS failed_count
  UNION ALL SELECT 'DQ-032' AS rule_id, 'model / availability' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'discontinue date not before launch date' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM product_model_master WHERE discontinue_date < launch_date) + (SELECT COUNT(*) FROM product_country_availability WHERE local_discontinue_date < local_launch_date)) AS failed_count
  UNION ALL SELECT 'DQ-033' AS rule_id, 'product_model_master' AS table_name, 'Uniqueness' AS dimension, 'Medium' AS severity, 'model_name is unique' AS description, 1 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT model_name FROM product_model_master GROUP BY 1 HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-034' AS rule_id, 'product_model_master' AS table_name, 'Completeness' AS dimension, 'High' AS severity, 'Lifecycle populated: models with a discontinue_date (gap if 0)' AS description, 0 AS baseline, '> 0 expected (review)' AS expected, (SELECT COUNT(*) FROM product_model_master WHERE discontinue_date IS NOT NULL) AS failed_count
  UNION ALL SELECT 'DQ-035' AS rule_id, 'product_country_availability' AS table_name, 'Consistency' AS dimension, 'High' AS severity, 'Missing SKU x country pairs (0 = full cross join, gap)' AS description, 0 AS baseline, '> 0 expected (review)' AS expected, (SELECT (SELECT COUNT(*) FROM product_sku_master) * (SELECT COUNT(*) FROM country_master) - (SELECT COUNT(*) FROM product_country_availability)) AS failed_count
  UNION ALL SELECT 'DQ-036' AS rule_id, 'product_country_availability' AS table_name, 'Uniqueness' AS dimension, 'Medium' AS severity, 'local_part_number unique within a country' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT country_code, local_part_number FROM product_country_availability GROUP BY 1,2 HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-037' AS rule_id, 'product_sku_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'price_tier in (Standard, Premium, Ultra)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_sku_master WHERE price_tier NOT IN ('Standard','Premium','Ultra') OR price_tier IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-038' AS rule_id, 'product_sku_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'sku_code matches M + 6 alnum + LL/A' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM product_sku_master WHERE NOT RLIKE(sku_code, 'M[A-Z0-9]{6}LL/A')) AS failed_count
  UNION ALL SELECT 'DQ-040' AS rule_id, 'store_master' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'store_code is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT store_code FROM store_master GROUP BY store_code HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-041' AS rule_id, 'store_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-042' AS rule_id, 'store_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'region_code exists in region_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master c LEFT JOIN region_master p ON c.region_code = p.region_code WHERE c.region_code IS NOT NULL AND p.region_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-043' AS rule_id, 'store_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'store region_code = country region_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master s JOIN country_master c ON s.country_code = c.country_code WHERE s.region_code <> c.region_code) AS failed_count
  UNION ALL SELECT 'DQ-044' AS rule_id, 'store_master' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'store_code prefix = country_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE NOT STARTSWITH(store_code, country_code || '_')) AS failed_count
  UNION ALL SELECT 'DQ-045' AS rule_id, 'store_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'tax_jurisdiction_code exists in tax_master' AS description, 121 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master c LEFT JOIN tax_master p ON c.tax_jurisdiction_code = p.tax_code WHERE c.tax_jurisdiction_code IS NOT NULL AND p.tax_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-046' AS rule_id, 'store_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'No stores in countries with retail_store_supported = ''N''' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master s JOIN country_master c ON s.country_code = c.country_code WHERE c.retail_store_supported = 'N') AS failed_count
  UNION ALL SELECT 'DQ-047' AS rule_id, 'store_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'store_close_date >= store_open_date' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE store_close_date < store_open_date) AS failed_count
  UNION ALL SELECT 'DQ-048' AS rule_id, 'sales_header' AS table_name, 'Timeliness' AS dimension, 'High' AS severity, 'POS transactions on/after store_open_date' AS description, 152808 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN store_master s ON h.store_id = s.store_code WHERE h.transaction_timestamp::DATE < s.store_open_date) AS failed_count
  UNION ALL SELECT 'DQ-049' AS rule_id, 'store_master' AS table_name, 'Timeliness' AS dimension, 'Medium' AS severity, 'SCD effective_start_date <= store_open_date' AS description, 121 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE effective_start_date > store_open_date) AS failed_count
  UNION ALL SELECT 'DQ-050' AS rule_id, 'store_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'latitude in [-90,90], longitude in [-180,180]' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE latitude NOT BETWEEN -90 AND 90 OR longitude NOT BETWEEN -180 AND 180 OR latitude IS NULL OR longitude IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-051' AS rule_id, 'store_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'Plausible rent: annual_rent_usd / floor_area_sqft <= 1,000' AS description, 29 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE annual_rent_usd / NULLIF(floor_area_sqft,0) > 1000) AS failed_count
  UNION ALL SELECT 'DQ-052' AS rule_id, 'store_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'format_code in (FLG, MALL, MINI)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE format_code NOT IN ('FLG','MALL','MINI') OR format_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-053' AS rule_id, 'store_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'address_line1 without embedded newline' AS description, 5 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE CONTAINS(address_line1, CHR(10)) OR CONTAINS(address_line1, CHR(13))) AS failed_count
  UNION ALL SELECT 'DQ-054' AS rule_id, 'store_master' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'US tax_jurisdiction_code = ''US_'' || state_code || ''_STD''' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM store_master WHERE country_code = 'US' AND tax_jurisdiction_code <> 'US_' || state_code || '_STD') AS failed_count
  UNION ALL SELECT 'DQ-060' AS rule_id, 'customer_master' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, '(customer_id, snapshot_year) is unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT customer_id, snapshot_year FROM customer_master GROUP BY customer_id, snapshot_year HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-061' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'High' AS severity, 'customer_id <-> customer_number is 1:1' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT customer_number) > 1)) + (SELECT COUNT(*) FROM (SELECT customer_number FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT customer_id) > 1))) AS failed_count
  UNION ALL SELECT 'DQ-062' AS rule_id, 'customer_master' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-063' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'region / country_name / preferred_language match country_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master cu JOIN country_master c ON cu.country_code = c.country_code WHERE cu.region <> c.region_code OR cu.country_name <> c.country_name OR cu.preferred_language <> c.primary_language) AS failed_count
  UNION ALL SELECT 'DQ-064' AS rule_id, 'customer_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'customer_number format CUST-<acq_year>-<CC>-<6 digits>, consistent with acquisition_year and country_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE NOT RLIKE(customer_number, 'CUST-[0-9]{4}-[A-Z]{2}-[0-9]{6}') OR SUBSTR(customer_number, 6, 4) <> TO_VARCHAR(acquisition_year) OR SUBSTR(customer_number, 11, 2) <> country_code) AS failed_count
  UNION ALL SELECT 'DQ-065' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'acquisition_year = YEAR(registration_date)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE acquisition_year <> YEAR(registration_date)) AS failed_count
  UNION ALL SELECT 'DQ-066' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'full_name = first_name || '' '' || last_name' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE full_name <> first_name || ' ' || last_name) AS failed_count
  UNION ALL SELECT 'DQ-067' AS rule_id, 'customer_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'email has a valid format' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE email IS NULL OR NOT RLIKE(email, '[^@ ]+@[^@ ]+\\.[a-z]{2,}')) AS failed_count
  UNION ALL SELECT 'DQ-068' AS rule_id, 'customer_master' AS table_name, 'Uniqueness' AS dimension, 'Medium' AS severity, 'email not shared by different customers (count of shared emails)' AS description, 6067 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT email FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT customer_id) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-069' AS rule_id, 'customer_master' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'Age at registration >= 13 (rows)' AS description, 3652 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE FLOOR(DATEDIFF('day', date_of_birth, registration_date) / 365) < 13) AS failed_count
  UNION ALL SELECT 'DQ-070' AS rule_id, 'customer_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'street_address has no leading/trailing whitespace' AS description, 2850 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE street_address <> TRIM(street_address)) AS failed_count
  UNION ALL SELECT 'DQ-071' AS rule_id, 'customer_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'city has no leading/trailing whitespace' AS description, 16 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE city <> TRIM(city)) AS failed_count
  UNION ALL SELECT 'DQ-072' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'customer_type = NEW exactly in the acquisition snapshot' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE (customer_type = 'NEW') <> (snapshot_year = acquisition_year)) AS failed_count
  UNION ALL SELECT 'DQ-073' AS rule_id, 'customer_master' AS table_name, 'Completeness' AS dimension, 'Medium' AS severity, 'No gaps in yearly snapshot presence (customers)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY 1 HAVING MAX(snapshot_year) - MIN(snapshot_year) + 1 <> COUNT(DISTINCT snapshot_year))) AS failed_count
  UNION ALL SELECT 'DQ-074' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'Immutable attributes unchanged across snapshots (name, DOB, email, segment, country)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM (SELECT customer_id FROM customer_master GROUP BY 1 HAVING COUNT(DISTINCT first_name) > 1 OR COUNT(DISTINCT last_name) > 1 OR COUNT(DISTINCT date_of_birth) > 1 OR COUNT(DISTINCT email) > 1 OR COUNT(DISTINCT customer_segment) > 1 OR COUNT(DISTINCT country_code) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-075' AS rule_id, 'customer_master' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'No loyalty_tier downgrades between consecutive snapshots' AS description, 0 AS baseline, '= 0 (info)' AS expected, (SELECT COUNT(*) FROM (SELECT DECODE(loyalty_tier,'None',0,'Silver',1,'Gold',2,'Platinum',3) AS t, LAG(DECODE(loyalty_tier,'None',0,'Silver',1,'Gold',2,'Platinum',3)) OVER (PARTITION BY customer_id ORDER BY snapshot_year) AS prev_t FROM customer_master) WHERE t < prev_t) AS failed_count
  UNION ALL SELECT 'DQ-076' AS rule_id, 'customer_master' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'Domain values: gender, customer_segment, loyalty_tier, customer_type' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM customer_master WHERE gender NOT IN ('Female','Male') OR customer_segment NOT IN ('Consumer','Business','Education') OR loyalty_tier NOT IN ('None','Silver','Gold','Platinum') OR customer_type NOT IN ('NEW','RETURNING')) AS failed_count
  UNION ALL SELECT 'DQ-080' AS rule_id, 'sales_header' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'transaction_sk and transaction_id are unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM (SELECT transaction_sk FROM sales_header GROUP BY transaction_sk HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT transaction_id FROM sales_header GROUP BY transaction_id HAVING COUNT(*) > 1))) AS failed_count
  UNION ALL SELECT 'DQ-081' AS rule_id, 'sales_item' AS table_name, 'Uniqueness' AS dimension, 'High' AS severity, 'transaction_line_id and (transaction_sk, line_number) are unique' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM (SELECT transaction_line_id FROM sales_item GROUP BY transaction_line_id HAVING COUNT(*) > 1)) + (SELECT COUNT(*) FROM (SELECT transaction_sk, line_number FROM sales_item GROUP BY transaction_sk, line_number HAVING COUNT(*) > 1))) AS failed_count
  UNION ALL SELECT 'DQ-082' AS rule_id, 'sales_item' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'Every item has a header' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item c LEFT JOIN sales_header p ON c.transaction_sk = p.transaction_sk WHERE c.transaction_sk IS NOT NULL AND p.transaction_sk IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-083' AS rule_id, 'sales_header' AS table_name, 'Completeness' AS dimension, 'High' AS severity, 'Every header has at least one item' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h WHERE NOT EXISTS (SELECT 1 FROM sales_item i WHERE i.transaction_sk = h.transaction_sk)) AS failed_count
  UNION ALL SELECT 'DQ-084' AS rule_id, 'sales_item' AS table_name, 'Completeness' AS dimension, 'Low' AS severity, 'Transactions with more than one line (0 = single-line baskets, gap)' AS description, 0 AS baseline, '> 0 expected (info)' AS expected, (SELECT COUNT(*) FROM (SELECT transaction_sk FROM sales_item GROUP BY 1 HAVING COUNT(*) > 1)) AS failed_count
  UNION ALL SELECT 'DQ-085' AS rule_id, 'sales_header' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'customer_id exists in customer_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h WHERE h.customer_id IS NULL OR NOT EXISTS (SELECT 1 FROM customer_master c WHERE c.customer_id = h.customer_id)) AS failed_count
  UNION ALL SELECT 'DQ-086' AS rule_id, 'sales_header' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'store_id exists in store_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header c LEFT JOIN store_master p ON c.store_id = p.store_code WHERE c.store_id IS NOT NULL AND p.store_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-087' AS rule_id, 'sales_header' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'country_code exists in country_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header c LEFT JOIN country_master p ON c.country_code = p.country_code WHERE c.country_code IS NOT NULL AND p.country_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-088' AS rule_id, 'sales_header' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'currency exists in currency_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header c LEFT JOIN currency_master p ON c.currency = p.currency_code WHERE c.currency IS NOT NULL AND p.currency_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-089' AS rule_id, 'sales_item' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'sku_code exists in product_sku_master' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item c LEFT JOIN product_sku_master p ON c.sku_code = p.sku_code WHERE c.sku_code IS NOT NULL AND p.sku_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-090' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'High' AS severity, 'POS requires store_id; ONLINE must have no store_id' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header WHERE channel_id NOT IN ('POS','ONLINE') OR (channel_id = 'POS' AND store_id IS NULL) OR (channel_id = 'ONLINE' AND store_id IS NOT NULL)) AS failed_count
  UNION ALL SELECT 'DQ-091' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'High' AS severity, 'POS country_code = store country_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN store_master s ON h.store_id = s.store_code WHERE h.country_code <> s.country_code) AS failed_count
  UNION ALL SELECT 'DQ-092' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'High' AS severity, 'currency = country currency_code' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN country_master c ON h.country_code = c.country_code WHERE h.currency <> c.currency_code) AS failed_count
  UNION ALL SELECT 'DQ-093' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'Sale country = customer country' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN (SELECT DISTINCT customer_id, country_code FROM customer_master) c ON h.customer_id = c.customer_id WHERE h.country_code <> c.country_code) AS failed_count
  UNION ALL SELECT 'DQ-094' AS rule_id, 'sales_item' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'category_code matches SKU hierarchy' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item i JOIN (SELECT s.sku_code, f.category_code FROM product_sku_master s JOIN product_model_master m ON s.model_code = m.model_code JOIN product_family_master f ON m.family_code = f.family_code) x ON i.sku_code = x.sku_code WHERE i.category_code <> x.category_code) AS failed_count
  UNION ALL SELECT 'DQ-095' AS rule_id, 'sales_item' AS table_name, 'Accuracy' AS dimension, 'High' AS severity, 'line_total = quantity*unit_price - discount_amount + tax_amount (+/-0.01)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item WHERE ABS(quantity * unit_price - discount_amount + tax_amount - line_total) > 0.01) AS failed_count
  UNION ALL SELECT 'DQ-096' AS rule_id, 'sales_header' AS table_name, 'Accuracy' AS dimension, 'High' AS severity, 'Header gross/discount/tax/net = sum of item lines (+/-0.01)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN (SELECT transaction_sk, SUM(quantity * unit_price) g, SUM(discount_amount) d, SUM(tax_amount) t, SUM(line_total) n FROM sales_item GROUP BY 1) i ON h.transaction_sk = i.transaction_sk WHERE ABS(h.gross_amount - i.g) > 0.01 OR ABS(h.total_discount - i.d) > 0.01 OR ABS(h.total_tax - i.t) > 0.01 OR ABS(h.net_total - i.n) > 0.01) AS failed_count
  UNION ALL SELECT 'DQ-097' AS rule_id, 'sales_header' AS table_name, 'Accuracy' AS dimension, 'High' AS severity, 'net_total = gross_amount - total_discount + total_tax (+/-0.01)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header WHERE ABS(gross_amount - total_discount + total_tax - net_total) > 0.01) AS failed_count
  UNION ALL SELECT 'DQ-098' AS rule_id, 'sales_header / sales_item' AS table_name, 'Validity' AS dimension, 'High' AS severity, 'No negative/zero amounts; discount <= gross; quantity > 0' AS description, 0 AS baseline, '= 0' AS expected, (SELECT (SELECT COUNT(*) FROM sales_header WHERE gross_amount <= 0 OR net_total <= 0 OR total_discount < 0 OR total_tax < 0 OR total_discount > gross_amount) + (SELECT COUNT(*) FROM sales_item WHERE quantity <= 0 OR unit_price <= 0 OR discount_amount > quantity * unit_price)) AS failed_count
  UNION ALL SELECT 'DQ-099' AS rule_id, 'sales_header' AS table_name, 'Accuracy' AS dimension, 'High' AS severity, 'Effective tax rate = tax_master rate for the country (+/-0.002)' AS description, 45671 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN country_master c ON h.country_code = c.country_code JOIN tax_master t ON c.tax_code = t.tax_code WHERE (h.gross_amount - h.total_discount) > 0 AND ABS(h.total_tax / (h.gross_amount - h.total_discount) - t.tax_rate) > 0.002) AS failed_count
  UNION ALL SELECT 'DQ-100' AS rule_id, 'sales_item' AS table_name, 'Timeliness' AS dimension, 'High' AS severity, 'Sale on/after SKU global_launch_date' AS description, 6737 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk JOIN product_sku_master s ON i.sku_code = s.sku_code WHERE h.transaction_timestamp::DATE < s.global_launch_date) AS failed_count
  UNION ALL SELECT 'DQ-101' AS rule_id, 'sales_item' AS table_name, 'Timeliness' AS dimension, 'High' AS severity, 'Sale on/after local_launch_date in that country' AS description, 6739 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk JOIN product_country_availability a ON a.sku_code = i.sku_code AND a.country_code = h.country_code WHERE h.transaction_timestamp::DATE < a.local_launch_date) AS failed_count
  UNION ALL SELECT 'DQ-102' AS rule_id, 'sales_item' AS table_name, 'Integrity' AS dimension, 'High' AS severity, 'SKU is available in the sale country' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk LEFT JOIN product_country_availability a ON a.sku_code = i.sku_code AND a.country_code = h.country_code WHERE a.sku_code IS NULL) AS failed_count
  UNION ALL SELECT 'DQ-103' AS rule_id, 'sales_header' AS table_name, 'Timeliness' AS dimension, 'High' AS severity, 'Sale on/after customer registration_date' AS description, 111385 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN (SELECT customer_id, MIN(registration_date) AS reg FROM customer_master GROUP BY 1) c ON h.customer_id = c.customer_id WHERE h.transaction_timestamp::DATE < c.reg) AS failed_count
  UNION ALL SELECT 'DQ-104' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'No sales by customers inactive in that year''s snapshot' AS description, 40311 AS baseline, '= 0 (review)' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN customer_master c ON c.customer_id = h.customer_id AND c.snapshot_year = YEAR(h.transaction_timestamp) WHERE LOWER(TO_VARCHAR(c.is_active)) = 'false') AS failed_count
  UNION ALL SELECT 'DQ-105' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'Low' AS severity, 'Customer present in the snapshot of the sale year' AS description, 54 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h WHERE NOT EXISTS (SELECT 1 FROM customer_master c WHERE c.customer_id = h.customer_id AND c.snapshot_year = YEAR(h.transaction_timestamp))) AS failed_count
  UNION ALL SELECT 'DQ-106' AS rule_id, 'sales_header' AS table_name, 'Validity' AS dimension, 'High' AS severity, 'No fractional amounts in zero-decimal currencies (JPY, KRW)' AS description, 66607 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN currency_master c ON h.currency = c.currency_code WHERE c.minor_unit = 0 AND h.gross_amount <> ROUND(h.gross_amount, 0)) AS failed_count
  UNION ALL SELECT 'DQ-107' AS rule_id, 'sales_header' AS table_name, 'Consistency' AS dimension, 'High' AS severity, 'Tax-inclusive countries must not add tax on top of gross' AS description, 451922 AS baseline, '= 0 (decision needed)' AS expected, (SELECT COUNT(*) FROM sales_header h JOIN country_master c ON h.country_code = c.country_code JOIN tax_master t ON c.tax_code = t.tax_code WHERE t.tax_inclusive_flag = 'Y' AND h.total_tax > 0 AND ABS(h.net_total - (h.gross_amount - h.total_discount + h.total_tax)) <= 0.01) AS failed_count
  UNION ALL SELECT 'DQ-108' AS rule_id, 'sales_header' AS table_name, 'Validity' AS dimension, 'Medium' AS severity, 'ONLINE orders not paid in Cash' AS description, 23488 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header WHERE channel_id = 'ONLINE' AND payment_method = 'Cash') AS failed_count
  UNION ALL SELECT 'DQ-109' AS rule_id, 'sales_item' AS table_name, 'Consistency' AS dimension, 'Medium' AS severity, 'SKU+currency price spread (max/min) <= 2x (count of pairs)' AS description, 7419 AS baseline, '= 0 (review)' AS expected, (SELECT COUNT(*) FROM (SELECT i.sku_code, h.currency FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk GROUP BY 1,2 HAVING MAX(i.unit_price) / NULLIF(MIN(i.unit_price),0) > 2)) AS failed_count
  UNION ALL SELECT 'DQ-110' AS rule_id, 'sales_header' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'POS transactions outside 06:00-23:59 store hours' AS description, 82824 AS baseline, '= 0 (review)' AS expected, (SELECT COUNT(*) FROM sales_header WHERE channel_id = 'POS' AND HOUR(transaction_timestamp) < 6) AS failed_count
  UNION ALL SELECT 'DQ-111' AS rule_id, 'sales_header' AS table_name, 'Timeliness' AS dimension, 'Medium' AS severity, 'No future-dated transactions' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_header WHERE transaction_timestamp > CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS failed_count
  UNION ALL SELECT 'DQ-112' AS rule_id, 'sales_item' AS table_name, 'Validity' AS dimension, 'Low' AS severity, 'quantity in expected range (1-10)' AS description, 0 AS baseline, '= 0' AS expected, (SELECT COUNT(*) FROM sales_item WHERE quantity NOT BETWEEN 1 AND 10) AS failed_count
)
SELECT r.*,
       CASE WHEN expected LIKE '> 0%' THEN IFF(failed_count > 0, 'PASS', 'GAP')
            WHEN failed_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
       failed_count - baseline AS change_vs_baseline
FROM results r
ORDER BY rule_id;


-- =====================================================================
-- DETAIL QUERIES (return failing rows for investigation)
-- =====================================================================

-- D-012 tax rows starting after the first sale
SELECT * FROM tax_master WHERE effective_start_date > (SELECT MIN(transaction_timestamp)::DATE FROM sales_header);

-- D-045 store tax jurisdictions missing from tax_master
SELECT s.tax_jurisdiction_code, COUNT(*) AS stores FROM store_master s LEFT JOIN tax_master t ON s.tax_jurisdiction_code = t.tax_code WHERE t.tax_code IS NULL GROUP BY 1 ORDER BY 2 DESC;

-- D-048 stores with POS sales before opening
SELECT s.store_code, s.store_open_date, MIN(h.transaction_timestamp)::DATE AS first_sale, COUNT_IF(h.transaction_timestamp::DATE < s.store_open_date) AS sales_before_open
FROM store_master s JOIN sales_header h ON h.store_id = s.store_code GROUP BY 1,2 HAVING sales_before_open > 0 ORDER BY sales_before_open DESC;

-- D-068 emails shared by several customers
SELECT email, COUNT(DISTINCT customer_id) AS customers FROM customer_master GROUP BY 1 HAVING customers > 1 ORDER BY 2 DESC;

-- D-099 tax rate mismatch by country
SELECT h.country_code, t.tax_rate AS master_rate, ROUND(h.total_tax / (h.gross_amount - h.total_discount), 3) AS sales_rate, COUNT(*) AS txns
FROM sales_header h JOIN country_master c ON h.country_code = c.country_code JOIN tax_master t ON c.tax_code = t.tax_code
WHERE (h.gross_amount - h.total_discount) > 0 AND ABS(h.total_tax / (h.gross_amount - h.total_discount) - t.tax_rate) > 0.002
GROUP BY 1,2,3 ORDER BY txns DESC;

-- D-100 sales before SKU launch
SELECT i.sku_code, s.global_launch_date, MIN(h.transaction_timestamp) AS first_sale, COUNT(*) AS early_sales
FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk JOIN product_sku_master s ON i.sku_code = s.sku_code
WHERE h.transaction_timestamp::DATE < s.global_launch_date GROUP BY 1,2 ORDER BY early_sales DESC;

-- D-103 sales before customer registration (by year)
SELECT YEAR(h.transaction_timestamp) AS yr, COUNT(*) AS txns FROM sales_header h
JOIN (SELECT customer_id, MIN(registration_date) AS reg FROM customer_master GROUP BY 1) c ON h.customer_id = c.customer_id
WHERE h.transaction_timestamp::DATE < c.reg GROUP BY 1 ORDER BY 1;

-- D-106 same SKU price in different currencies (currency scale check)
SELECT h.currency, MIN(i.unit_price) AS min_price, MEDIAN(i.unit_price) AS median_price, MAX(i.unit_price) AS max_price, COUNT(*) AS lines
FROM sales_item i JOIN sales_header h ON i.transaction_sk = h.transaction_sk WHERE i.sku_code = 'M44DB86LL/A' GROUP BY 1 ORDER BY 1;

-- D-CUST current customer view (latest snapshot) - use instead of raw table for counts
SELECT * FROM customer_master QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY snapshot_year DESC) = 1;
