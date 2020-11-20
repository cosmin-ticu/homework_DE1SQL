-- Loading all the data into MySQL Workbench 
-- a lot of the varchar variables should actually be doubles, but they need a thorough data cleaning for missing values first
drop schema if exists univrankings;
create schema univrankings;
use univrankings;

-- Create table for Times university rankings (Western world-centric)
-- all rank-measuring variables should be numeric, but some need to be cleaned
-- the rank variables can range from 1 to 100, representing a grade (with some null values too)
use univrankings;
drop table if exists times;
create table times
(world_rank varchar (256) not null,
university_name varchar (256) not null,
country varchar (256) not null,
teaching double,
international varchar (256),
research double,
citations double,
income varchar (256),
total_score varchar (256),
num_students varchar(256),
student_staff_ratio varchar (256),
international_students varchar (256),
female_male_ratio varchar (256),
year year, 
primary key(university_name, year, country));

describe times;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/timesData.csv'
into table times
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from times;

-- label missing values for all columns
UPDATE times 
SET total_score = NULL 
WHERE total_score = '-';

UPDATE times 
SET international = NULL 
WHERE international = '-';

UPDATE times 
SET income = NULL 
WHERE income = '-';

UPDATE times 
SET num_students = NULL 
WHERE num_students = '';

UPDATE times 
SET student_staff_ratio = NULL 
WHERE student_staff_ratio = '';

UPDATE times 
SET international_students = NULL 
WHERE international_students = '';

UPDATE times 
SET female_male_ratio = NULL 
WHERE female_male_ratio = '';

-- convert measures to numeric for later computations
alter table times
modify column international double;

alter table times
modify column total_score double;

alter table times
modify column income double;

-- turn num_students into numeric
update times
set num_students = replace(num_students,',','');
alter table times
modify column num_students double;

-- Create table for Center for World University Rankings (Middle East-centric)
-- all rank-measuring variables should be numeric, but some need to be cleaned
-- the rank variables can range from 1 until 1000 (with some null values too)
-- the only measure out of 100 is the score, giving the universities a total weighted grade
use univrankings;
drop table if exists cwur;
create table cwur
(world_rank double not null,
university_name varchar (256) not null,
country varchar (256) not null,
national_rank double,
quality_of_education double,
alumni_employment double,
quality_of_faculty double,
publications double,
influence double,
citations double,
broad_impact varchar (256),
patents double,
score double,
year year, 
primary key(university_name, year, country));

describe cwur;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cwurData.csv'
into table cwur
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- label NULL values appropriately
UPDATE cwur 
SET broad_impact = NULL 
WHERE broad_impact = '';

-- change measures to numeric for later computations
alter table cwur
modify column broad_impact double;

-- --------QUERY---------
-- check final contents of cwur
select * from cwur;

-- --------QUERY---------
-- check country coverage between the two rankings
select distinct(country) from cwur;
select distinct(country) from times;

-- --------QUERY---------
-- All the countries match each other from the two tables - i.e. no duplicates or mislabeled countries
select distinct(country) from cwur
left join times
using (country);

-- Create table of countries with various measures from the World Bank
use univrankings;
drop table if exists world_bank;
create table world_bank
(year year not null,
country varchar (256) not null,
gov_spend varchar (256),
GDP_capita varchar (256),
youth_unemploy varchar (256),
gov_women varchar (256),
air_pollution varchar (256),
temp varchar (256), -- adding intermediary variable at the end because otherwise MySQL does not interpret air_pollution as having data (easy workaround)
primary key(country, year));

describe world_bank;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/world_bank_data.csv'
into table world_bank
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 lines;

-- label missing values accordingly
-- the NULL observation comes in handy for later manipulation of variables into numeric
UPDATE world_bank 
SET gov_spend = NULL 
WHERE gov_spend = '..';

UPDATE world_bank 
SET gdp_capita = NULL 
WHERE gdp_capita = '..';

UPDATE world_bank 
SET youth_unemploy = NULL 
WHERE youth_unemploy = '..';

UPDATE world_bank 
SET gov_women = NULL 
WHERE gov_women = '..';

UPDATE world_bank 
SET air_pollution = NULL 
WHERE air_pollution = '';

-- change measures to numeric
alter table world_bank
modify column gov_spend double;

alter table world_bank
modify column gdp_capita double;

alter table world_bank
modify column youth_unemploy double;

alter table world_bank
modify column gov_women double;

alter table world_bank
modify column air_pollution double;

alter table world_bank
drop column temp; -- removing the intermediary variable because now all values can be read by MySQL


-- ------------------------------------------------------------------------
-- -- -- These are just queries to check data quality and coverage -- -- --
-- ------------------------------------------------------------------------

-- find the years that all datasets have in common
select distinct(year) from cwur
inner join times
using (year);

select distinct(year) from cwur
inner join world_bank
using (year);

select distinct(year) from times
inner join world_bank
using (year);

-- this refuses to run; query might be too complex
		-- select distinct(year) from world_bank
		-- inner join times
		-- using (year)
		-- inner join cwur
		-- using (year);

-- check for missing values within the world bank measures for each country for a year in common
select distinct(c.country), w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution from cwur c
left join times
on times.country=c.country and times.year=c.year
inner join world_bank w
on times.country=w.country and times.year=w.year
where w.year=2015;

-- check how many countries are available between the two datasets of rankings
select count(distinct(times.country)) as num_countries, count(distinct(times.university_name)) as num_universities, times.year from cwur
inner join times
on times.country=cwur.country and times.year=cwur.year
inner join world_bank
on times.country=world_bank.country and times.year=world_bank.year
where times.year=2015;
-- 16 countries for 2012
-- 18 countries for 2013
-- 37 countries for 2014
-- 36 countries for 2015
-- If analysis should be done on a specific year, pick 2014 or 2015, as they have the most countries available

select count(distinct(country)) from cwur; -- 59 coutries; average coverage
select count(distinct(country)) from times; -- 72 countries; good coverage