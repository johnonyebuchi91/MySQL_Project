-- MySQL Data Cleaning and Transformation – Layoffs Dataset

-- 1. Creating a Temporary Table for Data Processing
DROP TABLE IF EXISTS layoffs_1;
CREATE TABLE layoffs_1 LIKE world_layoffs;

INSERT INTO layoffs_1
SELECT * FROM world_layoffs;

SELECT * FROM layoffs_1;

-- 2. Identifying Duplicate Records
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
ORDER BY company) AS Row_Num
FROM layoffs_1;

WITH duplicate_cte AS (
    SELECT *, 
    ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
    ORDER BY company) AS Row_Num
    FROM layoffs_1
)
SELECT * FROM duplicate_cte WHERE Row_Num > 1;

-- 3. Creating a New Clean Table
CREATE TABLE layoffs_2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off TEXT,
    percentage_laid_off TEXT,
    date TEXT,
    stage TEXT,
    country TEXT,
    funds_raised INT DEFAULT NULL,
    Row_Num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Inserting Data with Row Number for Deduplication
INSERT INTO layoffs_2
SELECT *, ROW_NUMBER() OVER(
PARTITION BY company, location, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised) AS Row_Num
FROM layoffs_1;

SELECT * FROM layoffs_2;

-- 5. Removing Duplicate Entries
DELETE FROM layoffs_2 WHERE Row_Num > 1;

SELECT * FROM layoffs_2;

-- 6. Cleaning Company Names
SELECT company, TRIM(company) FROM layoffs_2;
UPDATE layoffs_2 SET company = TRIM(company);

-- 7. Extracting Unique Industry and Country Names
SELECT DISTINCT (industry) FROM layoffs_2 ORDER BY 1;
SELECT DISTINCT (country) FROM layoffs_2 ORDER BY 1;

-- 8. Formatting the Date Column
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y') FROM layoffs_2;
UPDATE layoffs_2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
ALTER TABLE layoffs_2 MODIFY COLUMN `date` DATE;
SELECT `date` FROM layoffs_2;

-- 9. Identifying and Handling Missing Values
SELECT COUNT(percentage_laid_off) AS Null_Percentage FROM layoffs_2 WHERE percentage_laid_off IS NULL;
SELECT COUNT(total_laid_off) AS Null_Total FROM layoffs_2 WHERE total_laid_off IS NULL;

SELECT DISTINCT percentage_laid_off, total_laid_off FROM layoffs_2;
SELECT COUNT(percentage_laid_off) FROM layoffs_2 WHERE percentage_laid_off = '';
SELECT COUNT(total_laid_off) FROM layoffs_2 WHERE total_laid_off = '';
SELECT * FROM layoffs_2 WHERE percentage_laid_off = '' AND total_laid_off = '';

-- 10. Handling Missing Industry Values
SELECT COUNT(industry) FROM layoffs_2 WHERE industry IS NULL;
UPDATE layoffs_2 SET industry = NULL WHERE industry = '';
SELECT DISTINCT company, industry FROM layoffs_2 WHERE industry = '' OR industry IS NULL;

-- 11. Validating Data Integrity
SELECT * FROM layoffs_2 WHERE company = 'Appsmith';
SELECT * FROM layoffs_2 WHERE total_laid_off = '' AND percentage_laid_off = '';

-- 12. Handling Null Values in Layoff Columns
UPDATE layoffs_2 SET total_laid_off = NULL WHERE total_laid_off = '';
UPDATE layoffs_2 SET percentage_laid_off = NULL WHERE percentage_laid_off = '';
SELECT DISTINCT(company), percentage_laid_off, total_laid_off FROM layoffs_2 
WHERE percentage_laid_off IS NULL AND total_laid_off IS NULL;
DELETE FROM layoffs_2 WHERE percentage_laid_off IS NULL AND total_laid_off IS NULL;

-- 13. Final Cleanup - Dropping Unnecessary Columns
ALTER TABLE layoffs_2 DROP COLUMN Row_Num;

-- 14. Reviewing Final Cleaned Dataset
SELECT * FROM layoffs_2;
