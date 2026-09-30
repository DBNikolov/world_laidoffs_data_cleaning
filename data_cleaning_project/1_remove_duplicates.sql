--FIRST THING WE DO IS CREATE COPY TABLE OF THE RAW DATA SO IF WE MAKE ANY MISTAKES, THE RAW DATA STAYS INTACT.

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

--SINCE WE DON'T HAVE ID COLUMN WE ARE GOING TO USE ROW NUMBER TO SORT THE ROWS.

SELECT *,
ROW_NUMBER () OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions)
FROM layoffs_staging;

WITH duplicates_cte AS (
    SELECT *,
    ROW_NUMBER () OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- NOW WE HAVE THE DUPLICATES AND WE HAVE TO DELETE THEM

CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT,
    percentage_laid_off TEXT,
    date TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT,
    row_num INT
);

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off,percentage_laid_off, 
    date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;