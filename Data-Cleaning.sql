-- DATA CLEANING

SELECT * FROM layoffs;

-- 1. REMOVE DUPLICATES
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove Any Columns 



-- 1. REMOVE DUPLICATES


-- Öncelikle asıl tablomuzdaki verilerimizi kaybetmemek için yeni bir tablo oluşturup verilerimizi yeni tabloya ekliyoruz.
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging;

-- Satırları numaralandırarak, her birindeki yinelenenleri belirliyoruz.

SELECT *,
ROW_NUMBER() OVER ( 
PARTITION BY company ,location , industry , total_laid_off , percentage_laid_off ,
 'date' , stage , country , funds_raised_millions)  AS row_num
 FROM layoffs_staging;


WITH duplicates_cts AS
(SELECT *,
ROW_NUMBER() OVER ( 
PARTITION BY company ,location , industry , total_laid_off , percentage_laid_off ,
 'date' , stage , country , funds_raised_millions)  AS row_num
 FROM layoffs_staging)
 SELECT *
 FROM duplicates_cts
 WHERE row_num > 1;
 
 SELECT * FROM layoffs_staging
 WHERE company = 'Yahoo';


-- row_num kolonu ile beraber işlem yapabilmek için yeni bir tablo oluşturuyoruz.

CREATE TABLE `layoffs_staging2` (
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

SELECT * FROM layoffs_staging2;

-- Oluşturulan tabloya layoffs_staging tablosundaki verileri row_num kolonu ile beraber aktarıyoruz.

INSERT layoffs_staging2
(SELECT *,
ROW_NUMBER() OVER ( 
PARTITION BY company ,location , industry , total_laid_off , percentage_laid_off ,
 'date' , stage , country , funds_raised_millions)  AS row_num
 FROM layoffs_staging);
 
 SELECT * FROM layoffs_staging2
 WHERE row_num > 1;

-- Yinelenenleri silme işlemi yapıyoruz.
 DELETE FROM layoffs_staging2
 WHERE row_num > 1 ;

 SELECT * FROM layoffs_staging2
 WHERE company = 'Yahoo';


-- 2. Standardize the Data

-- Şirket isimlerindeki gereksiz boşlukları kaldırıyoruz.
SELECT company , TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY industry;

-- Aynı anlamda ancak farklı olarak yazılmış Endüstri kategorilerini standartlaştırıyoruz.
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
 
 
SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- Ülke adlarını standartlaştırıyoruz.
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Tarih sütununun veri tipini DATE olarak değiştiriyoruz.
SELECT `date` , 	
STR_TO_DATE(`date` , '%m/%d/%Y')
FROM layoffs_staging2;


UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date` , '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE ;


-- 3. Null Values or blank values

-- NULL veya boş değerlere sahip satırları kontrol ediyoruz.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

UPDATE layoffs_staging2
SET industry  = NULL 
WHERE industry ='';

SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT t1.industry , t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
WHERE (t1.industry IS NULL 
OR t1.industry = '') AND t2.industry IS NOT NULL;

-- İşlenmemiş endüstri verilerini düzeltiyoruz.
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- 4. Remove Any Columns 

SELECT * 
FROM layoffs_staging2;

-- Artık ihtiyacımızın olmadığı row_num sütununu kaldırıyoruz.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM layoffs_staging2;
