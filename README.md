# Introduction
In this project we are going to work with dataset about laid offs for a variety of companies.
The focus will be on cleaning the data and making it standartized to work with.
At the end we are going to do some tasks to find some information about the dataset.

🔍 Here are the SQL queries for this project! Check them out here: [data_cleaning_project](./data_cleaning_project/).

# Background 
The purpose is to get used to looking at data and fixing it more effectively. This project is meant to explore different ways of fixing the issues with our data.

Data hails from Alex The Analyst SQL Course. 

### The tasks I wanted to accomplish through my SQL queries were:
1. Remove the duplicates.
2. Standartize the data.
3. Look and fix the null values and blank rows.
4. Remove unnecessary columns.
5. Do some data exploration.
# Tools Used 
To dive into the data analyst job market, I deployed several key tools:
- **SQL:** The backbone of my analysis, allowing me to query the database and get critical insights.
- **PostgreSQL:** The chosen database management system, ideal for handling the job posting data.
- **Visual Studio Code:** My go-to for database management and executing SQL queries.
- **Git & GitHub:** Essential for version control and sharing my SQL scripts and analysis.


### 1. Removing the duplicate values.

First thing we do is create a copy table of the raw data so if we make any mistakes, the raw data stays intact.
```sql
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;
```

Since we don't have ID column we are going to use (Row Numnber) function to sort the rows.
```sql
SELECT *,
ROW_NUMBER () OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions)
FROM layoffs_staging;
```
```sql
WITH duplicates_cte AS (
    SELECT *,
    ROW_NUMBER () OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;
```
Now we all the rows numbered as 1 and the duplicates will be numbered as 2. We have to delete them and for that we are going to cleate new table.
```sql
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
```

```sql
INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off,percentage_laid_off, 
    date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;
```
All we have to do now is to delete the rows where the row_num is bigger than 1 and that is going to delete the rows where the duplicates are.
```sql
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;
```

### 2. Standartize the data.

We are going to look for some strange things in the columns and try to remove some mistakes.

In case we have some blank spaces before and after the company names I want to remove them.
```sql
SELECT DISTINCT company,
    TRIM (company)
FROM layoffs_staging2;
```

```sql
UPDATE layoffs_staging2
SET company= TRIM(company);
```
Now we are going to look at the industry column and see if we have some similar values.
```sql
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;
```
![Industry identicals](assets\Crypto.png)

- From this we can see that there are 3 different variations of Crypto and I want to change that because that may be an issue for the future analysis of the data.

We are going to set them all to be 'Crypto'.

```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
Next we are going to take a look at the countries list and try to see if everything is fine there.

```sql
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;
```
![Countries](assets\Countries.png)

- We can see that some of the rows with United States have a dot at the end so that needs to be changes.
```sql
UPDATE layoffs_staging2
SET industry = 'UNITED STATES'
WHERE industry LIKE 'UNITED STATES%';
```

In this dataset the date column is in text function and the format need to be changed as well.

First we are going to change the date format.
```sql
SELECT TO_DATE(date, 'MM/DD/YYYY')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = TO_DATE(date, 'MM/DD/YYYY')
WHERE date IS NOT NULL 
  AND date != 'NULL';
```
Now we are going to change the type of the column from text to date.
```sql
ALTER TABLE layoffs_staging2
ALTER COLUMN date TYPE DATE
USING TO_DATE(date, 'MM/DD/YYYY');
```
### 3. NULL and blank values.

In the industry column we had some blank rows which may mess up the results when exploring the data.

We need to find the blank spots and see if we can populate them based on the info in the table.
```sql
SELECT *
FROM layoffs_staging2
WHERE industry is NULL OR industry = '';
```
![Industry null or blanks](assets\blanks.png)
- We have couple of null or blank spots as we can see from the photo.

I'd like to set all the blank spots to be NULL values because that will help me manage the data better.
```sql
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
```
To populate them we first going to join the table on itself on company and location to be sure we are selecting the right companies.

This query performs a Self-Join on the layoffs_staging2 table to identify rows where a company has a missing (NULL) industry value, but another row for the same company (at the same location) already has a known industry.

Tb1 represents records with missing industry data and tb2 represents reference records containing valid industry data.

ON tb1.company = tb2.company AND tb1.location = tb2.location: Matches rows that belong to the exact same company and location.

WHERE tb1.industry IS NULL AND tb2.industry IS NOT NULL: Filters the results so you only see pairs where tb1 lacks an industry value while tb2 provides a valid one to copy from.
```sql
SELECT *
FROM layoffs_staging2 tb1
JOIN layoffs_staging2 tb2
    ON tb1.company= tb2.company
    AND tb1.location= tb2.location
WHERE tb1.industry IS NULL AND tb2.industry IS NOT NULL;
```
Next we uptade with a Self-Join to copy the valid industry string from tb2 directly into the NULL industry column of tb1.
```sql
UPDATE layoffs_staging2 tb1
JOIN layoffs_staging2 tb2
    ON tb1.company= tb2.company
SET tb1.industry= tb2.industry
WHERE tb1.industry IS NULL AND tb2.industry IS NOT NULL;
```

### 4. Removing unnecessary columns.

In some of the columns like (total_laid_off) and (percentage_laid_off) both of the values are NULL.

If both of those values are NULL, they are useless for us since the dataset is about laid offs and that is the info we work with.

First we are going to find those columns.
```sql
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
    AND percentage_laid_off IS NULL;
```
And now just perform DELETE function on those rows.
```sql
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
    AND percentage_laid_off IS NULL;
```

We still have the row_num columns from earlier but it is not needed anymore so we can delete it as well.
```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

### 5. Data exploration.

For this one there are no specific targets or questions to answer and we are just going to find some interesting facts about the dataset.

First I want to determine the time period of the dataset.
```sql
SELECT MAX(date), 
    MIN (date)
FROM layoffs_staging2;
```
![Time_period](assets\Time_period.png)

- The period of the dataset as we can see is a three-year period and it is after COVID.

Next I want to know the companies that laid off all of their staff and which of them had the biggest laid of.
```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off= '1'
    AND total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC;
```

![Most_laid_offs](assets\Most_laid_offs.png)

- Companies like Katerra and Butler Hospitality have the biggest single laid offs and are way ahead of the rest in the list.

Next we are going to find the companies that had the most funding and laid off all of their staff.

*We need to change the type of column(funds_raised_millions) as it is text and we need it to be numeric values.*

```sql
ALTER TABLE layoffs_staging2
ALTER COLUMN funds_raised_millions TYPE NUMERIC 
USING funds_raised_millions::NUMERIC;
```
```sql
SELECT company,
    percentage_laid_off,
    funds_raised_millions
FROM layoffs_staging2
WHERE percentage_laid_off = '1'
    AND funds_raised_millions IS NOT NULL
ORDER BY funds_raised_millions DESC;
```
![Most_funding](assets\Most_funding.png)

- Here we can see that the companies that have most funding and fired all of their people.

- The top 5 companies with most funding are way ahead of the rest in terms of how much money they have raised.

- Also Kattera is in this list as well.

Next I am going to see which companies and industries have the most people laid of in general in the whole period.

```sql
SELECT company, 
    SUM (total_laid_off) AS total
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY SUM (total_laid_off) DESC;
```
![Company_most_laidoff](assets\Company_most_laidoff.png)
- From this table we can see that most of the companies with highest total sum of laid offs are tech companies and some of them are also in the hospitability area.
```sql
SELECT industry, 
    SUM (total_laid_off) AS total
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY SUM (total_laid_off) DESC;
```
![Industry_most_laidoffs](assets\Ind_most_laidoff.png)
- Based on the industry we can see that the consumer and retail industries had the most people laid off which could be tied to the pandemic and post pandemic situation around those years.

Let's find how many laid offs there were in each year in that period.

```sql
SELECT EXTRACT(YEAR FROM date) AS year, 
    SUM (total_laid_off) AS total
FROM layoffs_staging2
GROUP BY year
ORDER BY total DESC;
```
![Year_laidoff](assets\Year_laidoffs.png)

- This data shows that years 22 and 23 have the most laid offs which is basically around the end of the COVID.

Next I want to see how many laid offs there were in each month of every year and see which months had the most.

```sql
SELECT 
    SUBSTRING(date::text,1,7) as month,
    SUM(total_laid_off) as total_off
FROM layoffs_staging2
WHERE date IS NOT NULL  
GROUP BY month
ORDER BY total_off DESC;
```

![Month_laidoff](assets\Month_laidoff.png)

- This table shows the hardest period was at the end of 2022 and the start of 2023 as those months have much more laid offs than the rest.

Now we are going to add each month on top of the next for the whole period and see how gradually the laid off number changes.

```sql
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
```
![Added_laidoffs](assets\Added_laidoffs.png)

- This table confirms how numbers start growing around the middle of 2022 and keep raising towards the new year.

I also want to see which company laid the most peopl off and in which year.

```sql
SELECT 
    company, 
    EXTRACT(YEAR FROM date) as year,
    SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off is NOT NULL
GROUP BY company, year
ORDER BY SUM(total_laid_off) DESC;
```
![Company_year_laidoff](assets\Company_year_laidoff.png)

-This table just confirms that those 2 years were very bad for business and that the biggest laid offs happened either in 2022 or 2023.

Next task is goint to rank for each year which was the company with he most laid offs.

```sql
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
```
![Year_company_laidoff](assets\Year_company_laidoff.png)

- There is a big surge in the volume of layoffs. In 2020 and 2021, the top companies (e.g., Uber with 7,525 and ByteDance with 3,600) experienced significantly lower total numbers compared to 2022 and 2023, where single Big Tech firms (Google, Meta, Amazon, Microsoft) laid off over 10,000 employees each.
- In 2020 layoffs were concentrated in travel and mobility companies (Uber and Booking.com) due to global travel restrictions.

- In 2022–2023 layoffs shifted entirely to Big Tech giants (Meta, Amazon, Google, Microsoft), that may be based on over-hiring during the pandemic boom and subsequent post-pandemic market recalibration.