USE univrankings;

-- ---------NO NEED TO RUN THIS - SIMPLE CHECK-UP QUERY------------------------------------------
-- attempt 1 at creating the large table (this is the backbone of the stored procedure) - created to explore drawbacks and inconsistencies
SELECT 
    t.university_name,
    t.country,
    t.international,
    t.income,
    t.international_students,
    t.total_score,
    c.score,
    c.alumni_employment,
    c.patents,
    c.year,
    w.gov_spend,
    w.GDP_capita,
    w.youth_unemploy,
    w.gov_women,
    w.air_pollution
FROM
    cwur c
        INNER JOIN
    times t ON t.university_name = c.university_name
        AND t.year = c.year
        LEFT JOIN
    world_bank w ON w.country = t.country
        AND w.year = c.year
WHERE
    c.year LIKE '2014';
-- ----------------------------------------------------------------------------------------------- 

-- create procedure to merge both times and cwur data 
-- fully valid only for 2012-2015 period (user defines years of interest) 
-- naive E(T)L (no actual transformations)
DROP PROCEDURE IF EXISTS Get_Merged_Tables; 
DELIMITER $$
CREATE PROCEDURE Get_Merged_Tables(
	IN year_input YEAR
)
BEGIN
	DROP TABLE IF EXISTS Merged_Tables;
    
	CREATE TABLE Merged_Tables AS
		SELECT
			t.university_name, t.country, t.international AS times_international_grade, t.income AS times_income_grade, t.international_students AS times_percent_intstudents, t.total_score AS times_score,
			c.score AS cwur_score, c.alumni_employment AS cwur_employ_rank, c.patents AS cwur_patents_rank, c.year
		FROM 
			cwur c
		INNER JOIN 
			times t
				ON t.university_name=c.university_name AND t.year=c.year
		WHERE c.year = year_input;
END $$
DELIMITER ;

CALL get_merged_tables(2014); -- result is 332 universities worldwide with partially complete statistics

SELECT 
    *
FROM
    merged_tables;
SELECT 
    COUNT(DISTINCT (country))
FROM
    merged_tables; -- check if matched countries are still the same

-- create procedure to merge all data - fully valid only for 2012-2015 period (builds up on table created by former procedure) - Naive E(T)L (no actual transformations)
DROP PROCEDURE IF EXISTS Get_CosminRanking_Raw; 
DELIMITER $$
CREATE PROCEDURE Get_CosminRanking_Raw()
BEGIN
	DROP TABLE IF EXISTS CosminRanking_raw;
    
	CREATE TABLE CosminRanking_raw AS
		SELECT
			m.university_name, m.country, 
            m.times_international_grade, m.times_income_grade, m.times_percent_intstudents, m.times_score,
			m.cwur_score, m.cwur_employ_rank, m.cwur_patents_rank, m.year,
			w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
		FROM 
			merged_tables m
		LEFT JOIN 
			world_bank w
				ON w.country=m.country AND w.year=m.year;
END $$
DELIMITER ;

CALL get_cosminranking_raw(); -- result is 332 universities worldwide with partially complete statistics

SELECT 
    *
FROM
    cosminranking_raw;
SELECT 
    COUNT(DISTINCT (country))
FROM
    cosminranking_raw; -- check if matched countries are still the same

-- -------------------------------------------------------------------------------
-- Transformation procedure to make the raw ranking into a computed one (full ETL)
-- -------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS get_cosminranking_comp; 

DELIMITER $$

CREATE PROCEDURE get_cosminranking_comp ()
BEGIN
	-- declare empty variables of interest for cursor
    DECLARE university_name VARCHAR(256) DEFAULT '';
    DECLARE times_international_grade DOUBLE DEFAULT 0;
    DECLARE times_income_grade DOUBLE DEFAULT 0;
    DECLARE times_score DOUBLE DEFAULT 0;
	DECLARE cwur_score DOUBLE DEFAULT 0;
    -- declare empty new variables for cursor and handler
    DECLARE cosmin_grade DOUBLE DEFAULT 0;
    DECLARE finished INTEGER DEFAULT 0;
	
	-- declare cursor for university
	DECLARE curUniv
		CURSOR FOR SELECT 
                    cosminranking_raw.university_name, 
                    cosminranking_raw.times_international_grade, 
                    cosminranking_raw.times_income_grade, 
                    cosminranking_raw.times_score, 
                    cosminranking_raw.cwur_score
				FROM univrankings.cosminranking_raw;

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curUniv;
	
    -- create a copy of the raw rankings table to which i add the computation column for the cosmin_grade
	DROP TABLE IF EXISTS univrankings.cosminranking_comp;
	CREATE TABLE univrankings.cosminranking_comp LIKE univrankings.cosminranking_raw;
	INSERT univrankings.cosminranking_comp SELECT * FROM univrankings.cosminranking_raw;
    ALTER TABLE univrankings.cosminranking_comp ADD cosmin_grade INTEGER DEFAULT 0;
    
    COMPUTERANK: LOOP
		FETCH curUniv INTO university_name, times_international_grade, times_income_grade, times_score, cwur_score;
		IF finished = 1 THEN LEAVE COMPUTERANK;
		END IF;
        
        IF times_score IS NOT NULL THEN
			SET cosmin_grade = (times_score+cwur_score)/2;
				UPDATE univrankings.cosminranking_comp 
					SET 
						cosminranking_comp.cosmin_grade = cosmin_grade
					WHERE 
						cosminranking_comp.university_name = university_name;
		ELSE IF times_income_grade IS NOT NULL THEN
			SET cosmin_grade = ((times_income_grade+times_international_grade)/2+cwur_score)/2;
				UPDATE univrankings.cosminranking_comp 
					SET 
						cosminranking_comp.cosmin_grade = cosmin_grade
					WHERE
						cosminranking_comp.university_name = university_name;
			ELSE 
				SET cosmin_grade = (times_international_grade-10+cwur_score)/2;
					UPDATE univrankings.cosminranking_comp 
						SET 
							cosminranking_comp.cosmin_grade = cosmin_grade
						WHERE
							cosminranking_comp.university_name = university_name;
			END IF;
		END IF;
        
	END LOOP COMPUTERANK;
	CLOSE curUniv;

END $$
DELIMITER ;

CALL get_cosminranking_comp();-- result is 332 universities worldwide with partially complete statistics

SELECT 
    *
FROM
    cosminranking_comp;
SELECT 
    COUNT(DISTINCT (country))
FROM
    cosminranking_comp; -- check if matched countries are still the same

-- ------------------------------------------------------------------------------------
-- ------------------------------- ANALYTICS PLAN -------------------------------------
-- ------------------------------------------------------------------------------------
-- This final dataset that contains the transformation for the cosmin_grade as well as
-- all the ranking and World Bank data of interest can be used for creating data marts
-- which rank universities taking into consideration factors like air quality and GDP
-- per capita. This means that the Cosmin ranking takes into consideration both the
-- individual university contributions and merits as well as the individual country
-- factors, like economic safety and gender equality.
-- Accordingly, we can proceed to ask a few questions that can guide further analysis
-- on this computed dataset of ~332 observations:
-- 1) What are the top international universities in affluent and unpolluted countries?
-- 2) How do countries compare against each other in terms of average scores?
-- 3) What is the best place to study in terms of gender equality, score and income?
-- 4) What are the best universities in terms of employment in low unemployment countries?
-- 4b) How about in countries with high youth unemployment?
-- 5) Is there a correlation between government expenditure on education and ranking?
-- 6) Do less internatioanl students come to poorer countries?
-- 7) What are the top universities for entreneurship and youth employment?
-- 8) Does a high grade of international outlook correlate with an international student body?
-- Not all of the above questions aim to be answered by the data marts computed
-- in chapter 5 (5-Views.sql).