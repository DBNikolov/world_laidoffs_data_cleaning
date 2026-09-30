/*IN THE INDUSTRY AREA WE HAD SOME BLANK ROWS WHICH MAY MESS UP THE RESULTS WHEN EXPLORING THE DATA.
    WE NEED TO FIND THE BLANK SPOTS AND SEE IF WE CAN POPULATE THEM. */

SELECT *
FROM layoffs_staging2
WHERE industry is NULL OR industry = '';

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2 tb1
JOIN layoffs_staging2 tb2
    ON tb1.company= tb2.company
    AND tb1.location= tb2.location
WHERE industry IS NULL AND industry IS NOT NULL;


UPDATE layoffs_staging2 tb1
JOIN layoffs_staging2 tb2
    ON tb1.company= tb2.company
SET tb1.industry= tb2.industry
WHERE tb1.industry IS NULL AND tb2.industry IS NOT NULL;
