-- SQL Project - Data Cleaning
-- Dataset Source: https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- Display all records from the world_layoffs.layoffs table
SELECT * 
FROM world_layoffs.layoffs;

-- Create a staging table to work on data cleaning. This helps in keeping the raw data intact in case of any issues.
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT INTO world_layoffs.layoffs_staging 
SELECT * FROM world_layoffs.layoffs;

-- Steps for data cleaning:
-- 1. Identify and remove duplicates
-- 2. Standardize data and correct errors
-- 3. Address null values appropriately
-- 4. Remove unnecessary columns and rows

-- Step 1: Remove Duplicates

-- Initial check for duplicates
SELECT * 
FROM world_layoffs.layoffs_staging;

-- Identify duplicate rows based on specific columns
SELECT company, industry, total_laid_off, `date`,
       ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`) AS row_num
FROM world_layoffs.layoffs_staging;

-- View duplicate entries
SELECT *
FROM (
    SELECT company, industry, total_laid_off, `date`,
           ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`) AS row_num
    FROM world_layoffs.layoffs_staging
) duplicates
WHERE row_num > 1;

-- Check for duplicates in specific company
SELECT * 
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda';

-- Identify true duplicates using additional columns
SELECT *
FROM (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
           ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM world_layoffs.layoffs_staging
) duplicates
WHERE row_num > 1;

-- Delete duplicate rows based on row number
WITH DELETE_CTE AS (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
           ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
    FROM DELETE_CTE
) AND row_num > 1;

-- Add a new column for row numbers to facilitate deletion
ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;

SELECT * 
FROM world_layoffs.layoffs_staging;

-- Create a new staging table with the row number column
CREATE TABLE world_layoffs.layoffs_staging2 (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` INT,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT,
    row_numbers INT
);

-- Insert data into the new staging table with row numbers
INSERT INTO world_layoffs.layoffs_staging2
SELECT `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`,
       ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

-- Delete rows with row number greater than 1
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_numbers >= 2;

-- Step 2: Standardize Data

-- Check for distinct values in the industry column
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Find rows with null or empty industry values
SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;

-- Review specific companies for data standardization
SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- Set blank industry values to NULL for easier handling
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Validate that industry column is standardized
SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;
 
-- Populate null industry values based on matching company names
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Verify remaining null values in the industry column
SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;

-- Standardize variations of 'Crypto' in the industry column
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Confirm industry standardization
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Standardize country names by removing trailing periods
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Validate country standardization
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- Correct the date column format
SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Convert date column to proper format
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change date column data type to DATE
ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Step 3: Handle Null Values

-- Null values in total_laid_off, percentage_laid_off, and funds_raised_millions are kept for EDA purposes
-- No changes needed for these null values

-- Step 4: Remove Unnecessary Columns and Rows

-- Identify rows with null total_laid_off
SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;

-- Identify rows with both total_laid_off and percentage_laid_off as null
SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Delete rows with null total_laid_off and percentage_laid_off
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Remove the row_num column as it's no longer needed
ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;

SELECT company 
FROM world_layoffs.layoffs_staging2;
