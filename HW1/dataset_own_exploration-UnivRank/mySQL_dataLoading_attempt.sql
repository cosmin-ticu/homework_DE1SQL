-- Loading all the data into MySQL Workbench - preliminary stage
-- a lot of the varchar variables should actually be doubles, but they need a through data cleaning for missing values
create schema UnivRankings;
use UnivRankings;

-- Create table for Shanghai university rankings
create table shanghai
(world_rank varchar (256) not null,
university_name varchar (256) not null,
national_rank varchar (256),
total_score varchar (256),
alumni double,
award double,
hici double,
ns varchar (256),
pub double,
pcp double,
year year, primary key(university_name));

describe shanghai;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/shanghaiData.csv'
into table shanghai
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 4398 rows; -- this is done to only keep 2015 data

select * from shanghai;

-- Create table for Times university rankings
use univrankings;
create table times
(world_rank varchar (256) not null,
university_name varchar (256) not null,
country varchar (256) not null,
teaching double,
international double,
research double,
citations double,
income varchar (256),
total_score varchar (256),
num_students varchar(256),
student_staff_ratio varchar (256),
international_students varchar (256),
female_male_ratio varchar (256),
year year, primary key(university_name));

describe times;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/timesData.csv'
into table times
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1804 rows; -- this is done to only keep the 2016 data

select * from times;

-- Create table for Center for World University Rankings
use univrankings;
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
year year, primary key(university_name));

describe cwur;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cwurData.csv'
into table cwur
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1201 rows; -- this is done to only keep the 2015 data

select * from cwur;

-- Create table for universities and their respective countries (useful for checking rankings validity)
use univrankings;
create table school_country
(school_name varchar (256) not null,
country varchar (256) not null,
primary key (school_name));

describe school_country;

load data infile 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/school_and_country_table.csv'
into table school_country
fields terminated by ','
enclosed by '"'
lines terminated by '\n';

select * from school_country;

-- What remains to be done (for further analysis) would be to include the other 2 tables on World Bank indicators for certain countries