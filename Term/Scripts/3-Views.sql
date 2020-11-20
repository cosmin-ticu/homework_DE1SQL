use univrankings;

-- -------------------------------------------------------------------
-- self-updating VIEWS (data marts) - but these are slow because they rebuild the table from scratch
-- -------------------------------------------------------------------

-- What are the top 50 universities worldwide according to the computed cosmin grade?
DROP VIEW IF EXISTS Top_50_Worldwide;

CREATE VIEW `Top_50_Worldwide` AS
select 
	university_name, country, year, cosmin_grade from cosminranking_comp
order by -cosmin_grade
limit 50;

select * from Top_50_Worldwide;

-- How many universities per country and what is the country's average cosmin grade?
-- naturally the countries that only have a few universities might be at a large advantage
-- thus, some arbitrary "weights" are added
drop view if exists Grade_Per_Country;

create view `Grade_Per_Country` as
select 
	count(university_name) as num_univs, country, 
case
	when count(university_name) <= 4 then (avg(cosmin_grade)-5.0)
    when count(university_name) <= 6 then (avg(cosmin_grade)-2.0)
    else avg(cosmin_grade)
end as computed_avg_cosmin_grade
from cosminranking_comp
group by country
order by -computed_avg_cosmin_grade;

select * from Grade_Per_Country;

-- How many universities does this dataset contain for each economic level (country-wide values)?
drop view if exists grades_econ_levels;

create view `grades_econ_levels` as
select 
	avg(cosmin_grade) as average_grade,
case
	when gdp_capita <= 10000 then 'Poor country'
    when gdp_capita <= 25000 then 'Developing country'
    when gdp_capita <= 35000 then 'Lower middle income country'
    when gdp_capita <= 50000 then 'Middle income country'
    when gdp_capita <= 65000 then 'Upper income country'
    else 'Top income country'
end as econ_rating
from cosminranking_comp
group by econ_rating
order by -avg(cosmin_grade);

select * from grades_econ_levels;

-- Example depth question:
-- "I am interested in studying at top (50/100) universities for internationality,
-- I want to know their world rank (cosmin_grade), air quality matters for me,
-- and I would like to live in a country where women have a say in parliament."
drop view if exists air_international_women;

create view air_international_women as
select 
	university_name, 
    country, 
    times_international_grade, 
    times_percent_intstudents,
    cosmin_grade,
case
	when air_pollution = NULL then 'unknown air pollution level'
    when air_pollution <= 8 then 'low air pollution'
    when air_pollution <= 15 then 'medium air pollution'
    when air_pollution <= 50 then 'high air pollution'
    else 'very high air pollution'
end as air_pollution_rating,
case
	when gov_women = NULL then 'unknown ratio of women in parliament'
	when gov_women <= 15 then 'low ratio of women in parliament'
    when gov_women <= 25 then 'lower medium ratio of women in parliament'
    when gov_women <= 35 then 'upper medium ratio of women in parliament'
    else 'high ratio of women in parliament'
end as women_in_parliament
from cosminranking_comp
order by -times_international_grade
limit 100;

select * from air_international_women;

-- Example depth question:
-- "I am interested in studying at top (50/100) universities for employment opportunities,
-- but I am also interested in entrepreneurship and patenting my work. I want to
-- know their world rank (cosmin_grade) and to know whether the country as a whole
-- having a good employment market for young people."
drop view if exists employment_patent_grade;

create view employment_patent_grade as
select 
	university_name,
    cwur_employ_rank as employment_rank,
    cwur_patents_rank as patents_rank,
    country,
case
	when youth_unemploy = NULL then 'unknown youth unemployment rate'
    when youth_unemploy <= 10 then 'low youth unemployment'
    when youth_unemploy <= 15 then 'medium youth unemployment'
    when youth_unemploy <= 20 then 'upper medium youth unemployment'
    when youth_unemploy <= 35 then 'high youth unemployment'
    else 'very high youth unemployment'
end as youth_unemployment
from cosminranking_comp
order by cwur_employ_rank
limit 100;

select * from employment_patent_grade;