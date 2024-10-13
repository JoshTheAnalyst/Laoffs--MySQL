# Exploratory Data Analysis (EDA) on the cleaned World layoffs dataset

SELECT *
FROM layoff_working;


UPDATE layoff_working
SET percentage_laid_off = ROUND(percentage_laid_off,1);

-- World Layoff KPI's

SELECT   MIN(`DATE`) AS Start_date, MAX(`DATE`) AS End_date,
		 COUNT(*) AS layoffs_reported,
		 SUM(total_laid_off) AS sum_total_layoff,
         ROUND(AVG(percentage_laid_off),2) AS avg_percent_laidoff,
         count(DISTINCT company) AS distinct_company,
         count(DISTINCT industry) AS distinct_industry,
         count(DISTINCT country) AS distinct_country,
         count(DISTINCT stage) AS distinct_stage
FROM layoff_working;

-- 1). What is the ranking of the total number of layoffs in each industry from 2020 to 2023? 
-- The Government needs to know which industries experienced the highest layoffs and allocate resources for recovery according to their rankings.

WITH layoff_ranking AS
			(SELECT industry, sum(total_laid_off) AS total_layoffs
			FROM layoff_working
			WHERE (`date` BETWEEN '2020-01-01' AND '2023-12-31') AND total_laid_off IS NOT NULL
			GROUP BY industry)
SELECT industry, total_layoffs, DENSE_RANK () OVER (ORDER BY total_layoffs DESC) AS ranking
FROM layoff_ranking;

-- 2). What are the individual top 5 companies with the highest average percentage of workforce layoffs in each industry?
-- Government needs to benchmark the layoff rates of top hitted companies against their industry to understand if they are outliers.

WITH company_percent_layoff AS
			(SELECT company, industry, avg(percentage_laid_off) AS percentage_laidoff
			FROM layoff_working
			GROUP BY company, industry), 
	Company_percent_rank2 AS 
			(SELECT company, industry, percentage_laidoff, DENSE_RANK () OVER (PARTITION BY industry ORDER BY percentage_laidoff DESC) AS row_percent
			FROM company_percent_layoff
			ORDER BY industry DESC, percentage_laidoff DESC)
SELECT company, industry, percentage_laidoff
FROM Company_percent_rank2
WHERE row_percent < 6
ORDER BY industry DESC;

-- 3). What is the total number of layoffs for each company level (startup, growth, mature)? 
-- The Government needs to understand weather the stage of company growth impacted vulnerability to layoffs

SELECT stage AS company_stage, sum(total_laid_off) AS total_laidoff
FROM layoff_working 
WHERE stage IS NOT NULL
GROUP BY stage
ORDER BY total_laidoff DESC;

-- 4). How did layoffs vary by percentage in industries that raised more than $250 million? 
-- The Government needs to see if the amount raised is related to how companies manage layoffs during the pandemic

SELECT industry, sum(funds_raised_millions) AS funds_raised_million, ROUND(avg(percentage_laid_off),2) AS average_percentage_laidoff
FROM layoff_working
WHERE funds_raised_millions > 250 AND industry IS NOT NULL
GROUP BY industry
ORDER BY funds_raised_million ASC;

-- 5) What is the distribution of layoffs by Month and the cumulative increase in layoffs? 
-- The Government want to see how layoffs increases gradually over the months

WITH rolling_layoff AS 
			(SELECT substring(`date`,1,7) AS `Month`, sum(total_laid_off) AS total_laidoff
			FROM layoff_working
			WHERE substring(`date`,1,7) IS NOT NULL
			GROUP BY `Month`
			ORDER BY 1 ASC)
SELECT `Month`, total_laidoff, sum(total_laidoff) OVER(ORDER BY `MONTH` ASC) AS rolling_total
FROM rolling_layoff;

-- 6). Which industries had the highest ratio of layoffs compared to amount raised?
-- This helps to evaluate if funding helped mitigate layoffs or if other factors contributed to workforce reductions.

SELECT industry, sum(funds_raised_millions) AS funds_in_million, sum(total_laid_off) AS total_laid_off, ROUND(avg(layoff_funds_ratio),1) AS funds_layoff_ratio
FROM 		(SELECT industry, total_laid_off, funds_raised_millions, (funds_raised_millions/total_laid_off) AS layoff_funds_ratio 
			FROM layoff_working
			WHERE funds_raised_millions/total_laid_off IS NOT NULL) AS layoff_ratio
WHERE layoff_funds_ratio IS NOT NULL
GROUP BY industry
ORDER BY avg(layoff_funds_ratio) DESC;

-- 7). Which companies, with less than $10 million raised had the highest layoffs, and in what industries?
-- This will help government identify companies in need of financial support and those at high risk of closure.
 
WITH Layoff_low AS 
			(SELECT company, industry, sum(total_laid_off) AS laid_off
			FROM layoff_working 
			WHERE funds_raised_millions < 10 AND total_laid_off IS NOT NULL
			GROUP BY company, industry), Layoff2 AS 
(SELECT company, industry, laid_off, DENSE_RANK () OVER (ORDER BY laid_off DESC) AS row_num
FROM Layoff_low)
SELECT company, industry, laid_off
FROM Layoff2 
WHERE row_num  < 30;

-- 8). What are the top 10 companies in the top 5 industries (with the highest layoffs) that maintained the lowest total layoff ?
-- This will help the Government identify companies that managed to sustain their workforce despite being in heavily affected industries

	SELECT company, sum(total_laid_off) AS total_laidoffs
    FROM layoff_working
    WHERE total_laid_off IS NOT NULL AND industry IN
								(SELECT industry 
								FROM 
										(SELECT industry, total_layoffs, DENSE_RANK () OVER (ORDER BY total_layoffs DESC) AS ranking
										FROM	
											(SELECT industry, sum(total_laid_off) AS total_layoffs
											FROM layoff_working
											WHERE total_laid_off IS NOT NULL
											GROUP BY industry) AS top) AS top_3
											WHERE ranking < 6)
GROUP BY company
ORDER BY total_laidoffs ASC
LIMIT 10;

-- 9). How did security industry layoff compare over the years? 
-- This will help Government know how the layoffs in the this industry vary over the years in order to further strengthen the security forces, 
-- restrategizing their options in comparison with the crime rate occurence

SELECT YEAR(`Date`) AS YEAR,  industry, sum(total_laid_off) AS total_layoffs
FROM layoff_working
WHERE total_laid_off IS NOT NULL AND `date`IS NOT NULL AND industry IS NOT NULL AND industry = 'security'
GROUP BY `Year`, industry
ORDER BY industry ASC, `Year` ASC;

-- 10). Which companies repeatedly conducted layoffs (more than once), and what are the patterns in the total layoffs, funding amounts and timing between layoffs? 
-- Government want to identify companies that may be chronically struggling, as repeated layoffs can indicate deeper structural issues

WITH company_count AS 
			(SELECT company, industry, SUM(total_laid_off) AS total_laidoff, SUM(funds_raised_millions) AS funds_in_millions, COUNT(*) AS layoffs_reported
			FROM layoff_working
			GROUP BY company, industry)
SELECT company, industry, total_laidoff, funds_in_millions, layoffs_reported
FROM company_count
WHERE layoffs_reported > 1
ORDER BY layoffs_reported DESC;
