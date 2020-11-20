-- Loading all the data into MySQL Workbench 
-- a lot of the varchar variables should actually be doubles, but they need a thorough data cleaning for missing values first
DROP SCHEMA IF EXISTS univrankings;
CREATE SCHEMA univrankings;
USE univrankings;

-- Create table for Times university rankings (Western world-centric)
-- all rank-measuring variables should be numeric, but some need to be cleaned
-- the rank variables can range from 1 to 100, representing a grade (with some null values too)
USE univrankings;
DROP TABLE IF EXISTS times;
CREATE TABLE times (
    world_rank VARCHAR(256) NOT NULL,
    university_name VARCHAR(256) NOT NULL,
    country VARCHAR(256) NOT NULL,
    teaching DOUBLE,
    international VARCHAR(256),
    research DOUBLE,
    citations DOUBLE,
    income VARCHAR(256),
    total_score VARCHAR(256),
    num_students VARCHAR(256),
    student_staff_ratio VARCHAR(256),
    international_students VARCHAR(256),
    female_male_ratio VARCHAR(256),
    year YEAR,
    PRIMARY KEY (university_name , year , country)
);

DESCRIBE times;

LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/timesData.csv'
INTO TABLE times
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT 
    *
FROM
    times;

-- label missing values for all columns
UPDATE times 
SET 
    total_score = NULL
WHERE
    total_score = '-';

UPDATE times 
SET 
    international = NULL
WHERE
    international = '-';

UPDATE times 
SET 
    income = NULL
WHERE
    income = '-';

UPDATE times 
SET 
    num_students = NULL
WHERE
    num_students = '';

UPDATE times 
SET 
    student_staff_ratio = NULL
WHERE
    student_staff_ratio = '';

UPDATE times 
SET 
    international_students = NULL
WHERE
    international_students = '';

UPDATE times 
SET 
    female_male_ratio = NULL
WHERE
    female_male_ratio = '';

-- convert measures to numeric for later computations
ALTER TABLE times
MODIFY COLUMN international DOUBLE;

ALTER TABLE times
MODIFY COLUMN total_score DOUBLE;

ALTER TABLE times
MODIFY COLUMN income DOUBLE;

-- turn num_students into numeric
UPDATE times 
SET 
    num_students = REPLACE(num_students, ',', '');
ALTER TABLE times
MODIFY COLUMN num_students DOUBLE;

-- Create table for Center for World University Rankings (Middle East-centric)
-- all rank-measuring variables should be numeric, but some need to be cleaned
-- the rank variables can range from 1 until 1000 (with some null values too)
-- the only measure out of 100 is the score, giving the universities a total weighted grade
USE univrankings;
DROP TABLE IF EXISTS cwur;
CREATE TABLE cwur (
    world_rank DOUBLE NOT NULL,
    university_name VARCHAR(256) NOT NULL,
    country VARCHAR(256) NOT NULL,
    national_rank DOUBLE,
    quality_of_education DOUBLE,
    alumni_employment DOUBLE,
    quality_of_faculty DOUBLE,
    publications DOUBLE,
    influence DOUBLE,
    citations DOUBLE,
    broad_impact VARCHAR(256),
    patents DOUBLE,
    score DOUBLE,
    year YEAR,
    PRIMARY KEY (university_name , year , country)
);

DESCRIBE cwur;

LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cwurData.csv'
INTO TABLE cwur
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- label NULL values appropriately
UPDATE cwur 
SET 
    broad_impact = NULL
WHERE
    broad_impact = '';

-- change measures to numeric for later computations
ALTER TABLE cwur
MODIFY COLUMN broad_impact DOUBLE;

-- --------QUERY---------
-- check final contents of cwur
SELECT 
    *
FROM
    cwur;

-- --------QUERY---------
-- check country coverage between the two rankings
SELECT DISTINCT
    (country)
FROM
    cwur;
SELECT DISTINCT
    (country)
FROM
    times;

-- --------QUERY---------
-- All the countries match each other from the two tables - i.e. no duplicates or mislabeled countries
SELECT DISTINCT
    (country)
FROM
    cwur
        LEFT JOIN
    times USING (country);

-- Create table of countries with various measures from the World Bank
USE univrankings;
DROP TABLE IF EXISTS world_bank;
CREATE TABLE world_bank (
    year YEAR NOT NULL,
    country VARCHAR(256) NOT NULL,
    gov_spend VARCHAR(256),
    GDP_capita VARCHAR(256),
    youth_unemploy VARCHAR(256),
    gov_women VARCHAR(256),
    air_pollution VARCHAR(256),
    temp VARCHAR(256),
    PRIMARY KEY (country , year)
);

DESCRIBE world_bank;

LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/world_bank_data.csv'
INTO TABLE world_bank
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- label missing values accordingly
-- the NULL observation comes in handy for later manipulation of variables into numeric
UPDATE world_bank 
SET 
    gov_spend = NULL
WHERE
    gov_spend = '..';

UPDATE world_bank 
SET 
    gdp_capita = NULL
WHERE
    gdp_capita = '..';

UPDATE world_bank 
SET 
    youth_unemploy = NULL
WHERE
    youth_unemploy = '..';

UPDATE world_bank 
SET 
    gov_women = NULL
WHERE
    gov_women = '..';

UPDATE world_bank 
SET 
    air_pollution = NULL
WHERE
    air_pollution = '';

-- change measures to numeric
ALTER TABLE world_bank
MODIFY COLUMN gov_spend DOUBLE;

ALTER TABLE world_bank
MODIFY COLUMN gdp_capita DOUBLE;

ALTER TABLE world_bank
MODIFY COLUMN youth_unemploy DOUBLE;

ALTER TABLE world_bank
MODIFY COLUMN gov_women DOUBLE;

ALTER TABLE world_bank
MODIFY COLUMN air_pollution DOUBLE;

ALTER TABLE world_bank
DROP COLUMN temp;-- removing the intermediary variable because now all values can be read by MySQL

-- ----------------------------------------------------------------------------------------------
-- ---------NO NEED TO RUN THESE - SIMPLE CHECK-UP QUERIES---------------------------------------
-- ----------------------------------------------------------------------------------------------

-- Checks to see how many distinct countries there are between the datasets
SELECT COUNT(DISTINCT (country)) FROM cwur;-- 59 coutries; average coverage
SELECT COUNT(DISTINCT (country)) FROM times; -- 72 countries; good coverage

SELECT DISTINCT
    (year)
FROM
    cwur
        INNER JOIN
    times USING (year);

SELECT DISTINCT
    (year)
FROM
    cwur
        INNER JOIN
    world_bank USING (year);

SELECT DISTINCT
    (year)
FROM
    times
        INNER JOIN
    world_bank USING (year);

SELECT DISTINCT
    c.country,
    w.gov_spend,
    w.GDP_capita,
    w.youth_unemploy,
    w.gov_women,
    w.air_pollution
FROM
    cwur c
        INNER JOIN
    times ON times.country = c.country AND times.year = c.year
        INNER JOIN
    world_bank w ON times.country = w.country AND times.year = w.year
WHERE
    w.year = 2015;

-- check how many countries are available between the two datasets of rankings and world bank data
SELECT 
    COUNT(DISTINCT (times.country)) AS num_countries,
    COUNT(DISTINCT (times.university_name)) AS num_universities,
    times.year
FROM
    cwur
        INNER JOIN
    times ON times.country = cwur.country
        AND times.year = cwur.year
        INNER JOIN
    world_bank ON times.country = world_bank.country
        AND times.year = world_bank.year
WHERE
    times.year = 2015;
-- 16 countries for 2012
-- 18 countries for 2013
-- 37 countries for 2014
-- 36 countries for 2015
-- If analysis should be done on a specific year, pick 2014 or 2015, as they have the most countries available