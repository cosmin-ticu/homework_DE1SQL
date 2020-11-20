USE univrankings;

-- Always call the final stored procedure to make sure you are working with the most up-to-date data
CALL get_cosminranking_comp();

-- -------------------------------------------------------------------
-- self-updating VIEWS (data marts) - but these are slow because they rebuild the table from scratch
-- -------------------------------------------------------------------

-- What are the top 50 universities worldwide according to the computed cosmin grade?
DROP VIEW IF EXISTS Top_50_Worldwide;

CREATE VIEW `Top_50_Worldwide` AS
    SELECT 
        university_name, country, year, cosmin_grade
    FROM
        cosminranking_comp
    ORDER BY - cosmin_grade
    LIMIT 50;

SELECT 
    *
FROM
    Top_50_Worldwide; -- run the view

-- How many universities per country and what is the country's average cosmin grade?
-- naturally the countries that only have a few universities might be at a large advantage
-- thus, some arbitrary "weights" are added
DROP VIEW IF EXISTS Grade_Per_Country;

CREATE VIEW `Grade_Per_Country` AS
    SELECT 
        COUNT(university_name) AS num_univs,
        country,
        CASE
            WHEN COUNT(university_name) <= 4 THEN (AVG(cosmin_grade) - 5.0)
            WHEN COUNT(university_name) <= 6 THEN (AVG(cosmin_grade) - 2.0)
            ELSE AVG(cosmin_grade)
        END AS computed_avg_cosmin_grade
    FROM
        cosminranking_comp
    GROUP BY country
    ORDER BY - computed_avg_cosmin_grade;

SELECT 
    *
FROM
    Grade_Per_Country; -- run the view

-- How many universities does this dataset contain for each economic level (country-wide values)?
DROP VIEW IF EXISTS grades_econ_levels;

CREATE VIEW `grades_econ_levels` AS
    SELECT 
        AVG(cosmin_grade) AS average_grade,
        CASE
            WHEN gdp_capita <= 10000 THEN 'Poor country'
            WHEN gdp_capita <= 25000 THEN 'Developing country'
            WHEN gdp_capita <= 35000 THEN 'Lower middle income country'
            WHEN gdp_capita <= 50000 THEN 'Middle income country'
            WHEN gdp_capita <= 65000 THEN 'Upper income country'
            ELSE 'Top income country'
        END AS econ_rating
    FROM
        cosminranking_comp
    GROUP BY econ_rating
    ORDER BY - AVG(cosmin_grade);

SELECT 
    *
FROM
    grades_econ_levels; -- run the view

-- Example depth question:
-- "I am interested in studying at top (50/100) universities for internationality,
-- I want to know their world rank (cosmin_grade), air quality matters for me,
-- and I would like to live in a country where women have a say in parliament."
DROP VIEW IF EXISTS air_international_women;

CREATE VIEW air_international_women AS
    SELECT 
        university_name,
        country,
        times_international_grade,
        times_percent_intstudents,
        cosmin_grade,
        CASE
            WHEN air_pollution = NULL THEN 'unknown air pollution level'
            WHEN air_pollution <= 8 THEN 'low air pollution'
            WHEN air_pollution <= 15 THEN 'medium air pollution'
            WHEN air_pollution <= 50 THEN 'high air pollution'
            ELSE 'very high air pollution'
        END AS air_pollution_rating,
        CASE
            WHEN gov_women = NULL THEN 'unknown ratio of women in parliament'
            WHEN gov_women <= 15 THEN 'low ratio of women in parliament'
            WHEN gov_women <= 25 THEN 'lower medium ratio of women in parliament'
            WHEN gov_women <= 35 THEN 'upper medium ratio of women in parliament'
            ELSE 'high ratio of women in parliament'
        END AS women_in_parliament
    FROM
        cosminranking_comp
    ORDER BY - times_international_grade
    LIMIT 100;

SELECT 
    *
FROM
    air_international_women; -- run the view

-- Example depth question:
-- "I am interested in studying at top (50/100) universities for employment opportunities,
-- but I am also interested in entrepreneurship and patenting my work. I want to
-- know their world rank (cosmin_grade) and to know whether the country as a whole
-- having a good employment market for young people."
DROP VIEW IF EXISTS employment_patent_grade;

CREATE VIEW employment_patent_grade AS
    SELECT 
        university_name,
        cwur_employ_rank AS employment_rank,
        cwur_patents_rank AS patents_rank,
        country,
        CASE
            WHEN youth_unemploy = NULL THEN 'unknown youth unemployment rate'
            WHEN youth_unemploy <= 10 THEN 'low youth unemployment'
            WHEN youth_unemploy <= 15 THEN 'medium youth unemployment'
            WHEN youth_unemploy <= 20 THEN 'upper medium youth unemployment'
            WHEN youth_unemploy <= 35 THEN 'high youth unemployment'
            ELSE 'very high youth unemployment'
        END AS youth_unemployment
    FROM
        cosminranking_comp
    ORDER BY cwur_employ_rank
    LIMIT 100;

SELECT 
    *
FROM
    employment_patent_grade; -- run the view