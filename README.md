# Data Analytics Portfolio Project: Data Cleaning

## Project Overview

This project involves cleaning and preparing a dataset for analysis. The dataset used in this project is from Kaggle, focusing on global layoffs in 2022. The primary goal is to clean the data to ensure it is accurate, consistent, and ready for further analysis. This project showcases various data cleaning techniques, including handling duplicates, standardizing data, addressing null values, and removing unnecessary data.

## Dataset

- **Source:** [Kaggle - Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
- **Description:** The dataset contains information about company layoffs worldwide, including details such as company name, industry, total number of layoffs, date, location, and other relevant fields.

## Steps and Techniques Used

### 1. Creating a Staging Table

To ensure data integrity and to have a backup of the original dataset, a staging table was created. This staging table serves as a workspace where data cleaning operations are performed.

```sql
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT INTO world_layoffs.layoffs_staging 
SELECT * FROM world_layoffs.layoffs;
```

### 2. Removing Duplicates

Duplicates can distort analysis results. The project involves identifying and removing duplicate rows based on key columns. A common approach is using the `ROW_NUMBER()` function to assign a unique row number to each row within a partition and then removing rows with a row number greater than one.

```sql
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
```

### 3. Standardizing Data

Standardization ensures consistency in the dataset. This includes converting different representations of the same value into a single standard format. For example, different representations of the 'Crypto' industry were standardized.

```sql
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');
```

### 4. Handling Null Values

Null values can pose challenges during analysis. This project addresses null values by replacing blanks with nulls and populating nulls where possible. For instance, if a company's industry is missing in some rows but available in others, the missing values are filled based on available data.

```sql
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

### 5. Removing Unnecessary Data

Data that does not contribute to the analysis, such as rows with both `total_laid_off` and `percentage_laid_off` as null, were removed to clean the dataset further.

```sql
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
```

### 6. Finalizing Data Types

Ensuring that columns have appropriate data types is crucial for analysis. The `date` column was converted from text to a date format.

```sql
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;
```

## Conclusion

This project demonstrates essential data cleaning steps to prepare a dataset for analysis. By creating a staging table, removing duplicates, standardizing data, handling null values, and ensuring appropriate data types, the dataset is transformed into a reliable and consistent resource for analysis.

---
