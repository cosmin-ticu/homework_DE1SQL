# University Rankings Term Project - Data Engineering 1 SQL
## Chapter 1 - Loading-cleaning-structuring
The two university ranking datasets were imported into MySQL Workbench using table creation code and then uploading loading the respective CSVs.
### Sample table creation:
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
### Sample table import:
```
LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/timesData.csv'
INTO TABLE times
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
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
