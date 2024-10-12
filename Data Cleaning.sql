# World Layoffs' Project on Data Cleaning and Data Exploration
-- This dataset present the details of layoffs by company during the Covid pandemic.

# Data Cleaning
-- Create a Working Data Layoffs' Table
-- Remove Duplicate Rows
-- Data Standardisation
-- Check for Value Correctness and Text Consistency
-- Work on NULL and BLANK Values
-- Remove Unnecessary Column(s) from the Layoffs' Dataset

# Create a Working Data Layoffs' Table
-- Another Layoffs' dataset table will be created so as not to tamper with the original Layoffs' Dataset table.
SELECT * 
FROM layoffs;

CREATE TABLE Layoff_raw 
LIKE layoffs;

INSERT layoff_raw
SELECT *
FROM layoffs;

SELECT *
FROM layoff_raw;

# Removing Duplicates
-- Duplicate rows will be removed for proper data analysis and consistency
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoff_raw ;

-- In order for us to filter by row number we make use of the CTE (Common Table Expressions) to check for duplicate rows
WITH Layoff_duplicates AS
			(SELECT *,
			ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
			FROM layoff_raw)
SELECT *
FROM Layoff_duplicates 
WHERE row_num > 1;

-- To remove duplicate, we have to create another table then delete row_num > 2 as CTEs doesn't allow for any update such as the DELETE Function
CREATE TABLE `layoff_working` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoff_working;

-- Remove Duplicates
DELETE
FROM layoff_working
WHERE row_num > 1;

SELECT *
FROM layoff_working
WHERE row_num > 1;    

-- DONE WITH REMOVING DUPLICATES
-- ALL DUPLICATES REMOVED

# Data Standardisation
-- This is done to ensure data accuracy and consistency. Important columns will be checked.
SELECT *
FROM layoff_working;

-- Company Column Standardisation
SELECT company, trim(company)
FROM layoff_working;

UPDATE layoff_working
SET company = trim(company);

-- Country Column Standardisation
SELECT DISTINCT country
FROM layoff_working
ORDER BY country DESC;

UPDATE layoff_working
SET country = trim(TRAILING '.' FROM country);

-- Industry Column Standardisation
SELECT DISTINCT industry
FROM layoff_working
ORDER BY industry ASC;

UPDATE layoff_working
SET industry = 'crypto'
WHERE industry LIKE 'Crypto%';

-- Location Column Standardisation
SELECT DISTINCT location
FROM layoff_working 
ORDER BY location DESC;

-- Date Column Standardisation
-- The date column will be converted to a date 
SELECT date 
FROM layoff_working;

UPDATE layoff_working
SET `date` = str_to_date (DATE,'%m/%d/%Y');
-- Covert the data type to a date
ALTER TABLE layoff_working
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoff_working;

# Handling NULL and BLANK Spaces
DELETE 
FROM layoff_working
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT company, industry, total_laid_off, percentage_laid_off
FROM layoff_working
WHERE industry IS NULL OR industry = '';
UPDATE layoff_working
SET industry = NULL
WHERE industry = '';

SELECT lw1.industry, lw2.industry
FROM layoff_working lw1
JOIN layoff_working lw2
	 ON lw1.company = lw2.company
     AND lw1.location = lw2.location
WHERE (lw1.industry IS NULL OR lw1.industry = '')
AND lw2.industry IS NOT NULL;

UPDATE layoff_working lw1
JOIN layoff_working lw2
	ON lw1.company = lw2.company
SET lw1.industry = lw2.industry
WHERE lw1.industry IS NULL
AND lw2.industry IS NOT NULL;

SELECT *
FROM layoff_working
order by company desc;

SELECT company, ROW_NUMBER

# Drop Column
ALTER TABLE layoff_working
DROP COLUMN row_num;

SELECT *
FROM layoff_working; 

-- Data Cleaning Project Completed, We dive next to EDA (Exploratory Data Analysis) 
 
UPDATE layoff_working
SET percentage_laid_off = percentage_laid_off * 100;























































