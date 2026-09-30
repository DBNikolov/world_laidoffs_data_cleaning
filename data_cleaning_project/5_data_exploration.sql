-- FOR THIS ONE THERE NO SPECIFIC TARGET OR QUESTION TO ANSWER AND WE ARE JUST GOING TO FIND SOME INTERESTING FACTS ABOUT THE DATASET.

-- FIRST I WANT TO DETERMINE THE TIME PERIOD OF THE DATASET

SELECT MAX(date), 
    MIN (date)
FROM layoffs_staging2;

--NEXT I WANT TO KNOW THE  COMPANIES THAT LAID OFF ALL OF THEIR STAFF AND WHICH OF THEM HAD THE BIGGEST LAID OFF.

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off= '1'
    AND total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC;

-- NEXT WE ARE GOING TO FIND THE COMPANIES THAT HAD THE MOST FUNDING AND LAID OFF ALL OF THEIR STAFF.

    -- WE NEED TO CHANGE THE TYPE OF COLUMN (FUNDS_RAISED_MILLIONS) AS IT IS TEXT RIGHT NOW AND WE NEED IT TO BE NUMERIC VALUES.

ALTER TABLE layoffs_staging2
ALTER COLUMN funds_raised_millions TYPE NUMERIC 
USING funds_raised_millions::NUMERIC;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = '1'
    AND funds_raised_millions IS NOT NULL
ORDER BY funds_raised_millions DESC;

--NEXT I AM GOING TO SEE WHICH COMPANIES AND INDUSTRIES HAVE THE MOST PEOPLE LAID OF IN GENEREAL IN THE WHOLE PERIOD.

SELECT company, 
    SUM (total_laid_off) AS total
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY SUM (total_laid_off) DESC;

SELECT industry, 
    SUM (total_laid_off) AS total
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY SUM (total_laid_off) DESC;

-- LET'S FIND HOW MANY LAID OFFS THERE WERE IN EACH YEAR IN THAT PERIOD.

SELECT EXTRACT(YEAR FROM date) AS year, 
    SUM (total_laid_off) AS total
FROM layoffs_staging2
GROUP BY year
ORDER BY total DESC;

-- NEXT I WANT TO SEE HOW MANY LAID OFFS THERE WERE IN EACH MONTH OF EVERY.

SELECT 
    SUBSTRING(date::text,1,7) as month,
    SUM(total_laid_off) as total_off
FROM layoffs_staging2
WHERE date IS NOT NULL  
GROUP BY month
ORDER BY month;

-- NOW WE ARE GOING TO ADD EACH MONTH ON TOP OF THE NEXT FOR THE WHOLE PERIOD.

WITH rolling_total AS (
SELECT 
    SUBSTRING(date::text,1,7) as month,
    SUM(total_laid_off) as total_off
FROM layoffs_staging2
WHERE date IS NOT NULL  
GROUP BY month
ORDER BY month ) 

SELECT month,
     total_off,
     SUM (total_off) OVER (ORDER BY month) as sum_total
FROM rolling_total;

-- I ALSO WANT TO SEE WHICH COMPANY LAID THE MOST PEOPLE OFF AND IN WHICH YEAR.

SELECT 
    company, 
    EXTRACT(YEAR FROM date) as year,
    SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off is NOT NULL
GROUP BY company, year
ORDER BY SUM(total_laid_off) DESC;

-- NEXT TASK IS GOING TO RANK FOR EACH YEAR WHICH WAS THE COMPANY WITH MOST LAID OFFS.

WITH company_year AS (
    SELECT 
    company, 
    EXTRACT(YEAR FROM date) as year,
    SUM(total_laid_off) AS total
    FROM layoffs_staging2
    WHERE total_laid_off is NOT NULL
    GROUP BY company, year
    ORDER BY SUM(total_laid_off) DESC
)

SELECT *,
    DENSE_RANK () OVER (PARTITION BY year ORDER BY total DESC) AS ranking
FROM company_year
WHERE year IS NOT NULL
ORDER BY ranking, year;

