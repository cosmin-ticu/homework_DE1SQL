# University Rankings Term Project - Data Engineering 1 SQL
## Chapter 1 - Loading-cleaning-structuring
The two university ranking datasets were imported into MySQL Workbench using table creation code and then uploading loading the respective CSVs.
### Sample table creation
```
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
```
### Sample table import
```
LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/timesData.csv'
INTO TABLE times
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```
The World Bank data was procured from the [World Bank repository](https://databank.worldbank.org/home.aspx) by choosing tabular data, getting the measures of interest and attributing them to columns and rows respectively. The same table creation and import was done for the World Bank data. A few cleaning of variables was also done to get the numeric measures to be correctly handled by MySQL.
### Sample data cleaning
```
UPDATE world_bank 
SET 
    gov_spend = NULL
WHERE
    gov_spend = '..';

ALTER TABLE world_bank
MODIFY COLUMN gov_spend DOUBLE;
```
### ERR diagram of initial data (relations are manually added between datasets)
The functionality of MySQL Workbench of designing ERR models was used. Foreign keys, primary keys and non-identifying relationships were created.

![picture alt](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Diagrams/ERR_initial_data.png)
### Entity-relation diagram (defining entities)
This diagram was made using the [Live Mermaid Editor](https://mermaid-js.github.io/mermaid-live-editor/) for Entity-Relation diagrams.

![picture alt](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Diagrams/entity-relation_diagram.png)

After running all the data cleaning, it is worthwhile to inspect how many countries are available between the datasets. This can be done with a simple query to make sure that we are working with the same number of countries throughout the analysis.
### Sample query:
```
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
```

Class | Measure
------------- | -------------
Fact  | University
Fact  | Country
Fact  | Year
Dimension  | CWUR – Grade
Dimension  | CWUR – Employment Rank
Dimension  | CWUR – Patents Rank
Dimension  | Times – Percentage of international students
Dimension  | Times – Income
Dimension  | Times – Grade
Dimension  | Expenditure on education (% of GDP)
Dimension  | GDP per capita (PPP)
Dimension  | Unemployment youth (% total labor force)
Dimension  | Proportion of seats by women in parliament
Dimension  | PM2.5 air pollution (annual exposure)
Dimension (computed)  | Cosmin Grade
