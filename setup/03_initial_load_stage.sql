-- Initial load: upload source CSVs from __initial_load/ into an internal stage in SALES_DEV.BRONZE.
-- Folder structure is mirrored in the stage. customer-master and sales-transaction: 2019 only;
-- all other folders loaded entirely.
-- Run with a client that supports PUT (e.g. snow sql -c coco_cli_user -f setup/03_initial_load_stage.sql).
-- For speed the PUTs were executed concurrently (8 at a time) from the shell; each PUT also uses
-- PARALLEL = 99 (max upload threads) and AUTO_COMPRESS (gzip). Files are stored as .csv.gz.
-- PUT requires absolute file:// paths - adjust the local path below if the repo moves.

-- ---------- STAGE ----------
CREATE STAGE IF NOT EXISTS SALES_DEV.BRONZE.INITIAL_LOAD_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Initial load of CSV source files';

-- ---------- CUSTOMER-MASTER (2019, one folder per country) ----------
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/AE/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/AE/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/AT/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/AT/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/AU/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/AU/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/BE/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/BE/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/BR/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/BR/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/CA/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/CA/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/CH/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/CH/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/CN/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/CN/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/DE/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/DE/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/DK/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/DK/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/ES/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/ES/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/FI/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/FI/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/FR/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/FR/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/HK/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/HK/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/IE/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/IE/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/IL/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/IL/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/IN/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/IN/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/IT/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/IT/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/JP/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/JP/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/KR/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/KR/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/MX/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/MX/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/MY/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/MY/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/NL/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/NL/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/NO/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/NO/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/NZ/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/NZ/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/PL/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/PL/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/SA/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/SA/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/SE/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/SE/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/SG/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/SG/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/TH/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/TH/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/TR/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/TR/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/TW/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/TW/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/UK/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/UK/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/US/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/US/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/customer-master/2019/ZA/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/customer-master/2019/ZA/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ---------- SALES-TRANSACTION (2019) ----------
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/sales-transaction/2019/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/sales-transaction/2019/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ---------- MASTER DATA (all files) ----------
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/country-master/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/country-master/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/product-master/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/product-master/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
PUT 'file:///Users/naren/Documents/Snowflake cortex udemy/cli_learning/cortex_cli_learning_git/__initial_load/store-master/*.csv' @SALES_DEV.BRONZE.INITIAL_LOAD_STAGE/store-master/ PARALLEL = 99 AUTO_COMPRESS = TRUE OVERWRITE = TRUE;

-- ---------- REFRESH DIRECTORY TABLE & VERIFY ----------
ALTER STAGE SALES_DEV.BRONZE.INITIAL_LOAD_STAGE REFRESH;

SELECT SPLIT_PART(relative_path, '/', 1) AS folder,
       COUNT(*)                          AS files,
       ROUND(SUM(size) / 1024 / 1024, 2) AS mb
FROM DIRECTORY(@SALES_DEV.BRONZE.INITIAL_LOAD_STAGE)
GROUP BY 1
ORDER BY 1;
