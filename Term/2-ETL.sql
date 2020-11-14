-- attempt 1 at creating the large table
select
	t.university_name, t.country, t.international, t.income, t.international_students, t.total_score,
    c.score, c.alumni_employment, c.patents, c.year,
    w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
from 
	cwur c
inner join 
	times t
		on t.university_name=c.university_name and t.year=c.year
inner join 
	world_bank w
		on w.country=t.country and w.year=c.year
where c.year like '2014';

-- create procedure to merge all data - fully valid only for 2012-2015 period (user defines years of interest)
DROP PROCEDURE IF EXISTS Get_CosminRanking_Raw; 
drop table if exists CosminRanking_raw;
DELIMITER $$
CREATE PROCEDURE Get_CosminRanking_Raw(
	in year_input year
)
BEGIN
	create table CosminRanking_raw as
		select
			t.university_name, t.country, t.international, t.income, t.international_students, t.total_score,
			c.score, c.alumni_employment, c.patents, c.year,
			w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
		from 
			cwur c
		inner join 
			times t
				on t.university_name=c.university_name and t.year=c.year
		inner join 
			world_bank w
				on w.country=t.country and w.year=c.year
		where c.year = year_input;
END $$
delimiter ;

call get_cosminranking_raw(2012);
select * from cosminranking_raw;