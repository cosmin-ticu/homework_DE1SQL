use univrankings;

-- ---------NO NEED TO RUN THIS - SIMPLE CHECK-UP QUERY------------------------------------------
-- attempt 1 at creating the large table (this is the backbone of the stored procedure) - created to explore drawbacks and inconsistencies
select
	t.university_name, t.country, t.international, t.income, t.international_students, t.total_score,
    c.score, c.alumni_employment, c.patents, c.year,
    w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
from 
	cwur c
inner join 
	times t
		on t.university_name=c.university_name and t.year=c.year
left join -- reasoning for keeping this as a left join is because Taiwan is also present within the rankings, but the World Bank does not have separate data on Taiwan as a country (rather included within China's data)
			-- we can thus keep Taiwan in this case, as it can still receive a cosmin_grade, but it will not show up for any of the data marts that are based on World Bank parameters
            -- this means that years 2014 and 2015 each have an extra country in their count as opposed to what the queries in chapter 1 say (as those were inner joins)
	world_bank w
		on w.country=t.country and w.year=c.year
where c.year like '2014';

-- create procedure to merge both times and cwur data - fully valid only for 2012-2015 period (user defines years of interest) - Naive E(T)L (no actual transformations)
DROP PROCEDURE IF EXISTS Get_Merged_Tables; 
DELIMITER $$
CREATE PROCEDURE Get_Merged_Tables(
	in year_input year
)
BEGIN
	drop table if exists Merged_Tables;
    
	create table Merged_Tables as
		select
			t.university_name, t.country, t.international as times_international_grade, t.income as times_income_grade, t.international_students as times_percent_intstudents, t.total_score as times_score,
			c.score as cwur_score, c.alumni_employment as cwur_employ_rank, c.patents as cwur_patents_rank, c.year
		from 
			cwur c
		inner join 
			times t
				on t.university_name=c.university_name and t.year=c.year
		where c.year = year_input;
END $$
delimiter ;

call get_merged_tables(2014);
select * from merged_tables;
select count(distinct(country)) from merged_tables;

-- create procedure to merge all data - fully valid only for 2012-2015 period (builds up on table created by former procedure) - Naive E(T)L (no actual transformations)
DROP PROCEDURE IF EXISTS Get_CosminRanking_Raw; 
DELIMITER $$
CREATE PROCEDURE Get_CosminRanking_Raw()
BEGIN
	drop table if exists CosminRanking_raw;
    
	create table CosminRanking_raw as
		select
			m.university_name, m.country, 
            m.times_international_grade, m.times_income_grade, m.times_percent_intstudents, m.times_score,
			m.cwur_score, m.cwur_employ_rank, m.cwur_patents_rank, m.year,
			w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
		from 
			merged_tables m
		left join 
			world_bank w
				on w.country=m.country and w.year=m.year;
END $$
delimiter ;

call get_cosminranking_raw(); -- result is 332 universities worldwide with partially complete statistics

-- check result and check whether number of countries was preserved
select * from cosminranking_raw;
select count(distinct(country)) from cosminranking_raw;


-- Transformation procedure to make the raw ranking into a computed one (full ETL)
DROP PROCEDURE IF EXISTS get_cosminranking_comp; 

DELIMITER $$

CREATE PROCEDURE get_cosminranking_comp ()
BEGIN
    declare university_name varchar(256) default '';
    declare times_international_grade double DEFAULT 0;
    declare times_income_grade double DEFAULT 0;
    declare times_score double DEFAULT 0;
	declare cwur_score double DEFAULT 0;
    
    DECLARE cosmin_grade DOUBLE DEFAULT 0;
    DECLARE finished INTEGER DEFAULT 0;
	
	-- declare cursor for university
	DECLARE curUniv
		CURSOR FOR 
            		SELECT cosminranking_raw.university_name, cosminranking_raw.times_international_grade, cosminranking_raw.times_income_grade, cosminranking_raw.times_score, cosminranking_raw.cwur_score
				FROM univrankings.cosminranking_raw;

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curUniv;
	
    -- create a copy of the raw rankings table to which i add the computation column for the cosmin_grade
	DROP TABLE IF EXISTS univrankings.cosminranking_comp;
	CREATE TABLE univrankings.cosminranking_comp LIKE univrankings.cosminranking_raw;
	INSERT univrankings.cosminranking_comp SELECT * FROM univrankings.cosminranking_raw;
    alter table univrankings.cosminranking_comp add cosmin_grade integer default 0;
    
    computeRank: LOOP
		FETCH curUniv INTO university_name, times_international_grade, times_income_grade, times_score, cwur_score;
		IF finished = 1 THEN LEAVE computeRank;
		END IF;
        
        if times_score is not NULL then
			set cosmin_grade = (times_score+cwur_score)/2;
			UPDATE univrankings.cosminranking_comp 
				SET cosminranking_comp.cosmin_grade = cosmin_grade
					where cosminranking_comp.university_name = university_name;
			ELSE if times_income_grade is not null then
				set cosmin_grade = ((times_income_grade+times_international_grade)/2+cwur_score)/2;
				UPDATE univrankings.cosminranking_comp 
					SET cosminranking_comp.cosmin_grade = cosmin_grade
						where cosminranking_comp.university_name = university_name;
				else set cosmin_grade = (times_international_grade-10+cwur_score)/2;
				UPDATE univrankings.cosminranking_comp 
					SET cosminranking_comp.cosmin_grade = cosmin_grade
						where cosminranking_comp.university_name = university_name;
				end if;
		END if;
        
	END LOOP computeRank;
	CLOSE curUniv;

END $$
DELIMITER ;

call get_cosminranking_comp(); -- result is 332 universities worldwide with partially complete statistics

-- check result and check whether number of countries was preserved
select * from cosminranking_comp;
select count(distinct(country)) from cosminranking_comp;