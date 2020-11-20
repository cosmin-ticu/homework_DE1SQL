# University Rankings Term Project - Data Engineering 1 SQL
The data for this term project was chosen out of personal interest for university rankings and with the goal of getting a better understanding of how and why we pick the universities that we do. In my opionion, the score of the actual university is not the only aspect that matters, but rather the country's attributes are highly important.
The following run-through is a shortened version of the [SQL scripts](https://github.com/cosmin-ticu/homework_DE1SQL/tree/master/Term/Scripts) provided. A detailed run-through is available within the scripts after each query, procedure and function.
## [Chapter 1 - Loading-cleaning-structuring](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/1-Loading_cleaning_structuring.sql)
Times World Rankings -> <https://www.timeshighereducation.com/>
Center for World University Rankings -> <https://cwur.org/>
The two university ([CWUR](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Data/cwurData.csv) & [Times](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Data/timesData.csv)) ranking datasets were imported into MySQL Workbench using table creation code and then uploading loading the respective CSVs.
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
The [World Bank data](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Data/world_bank_data.csv) was procured from the [World Bank repository](https://databank.worldbank.org/home.aspx) by choosing tabular data, getting the measures of interest and attributing them to columns and rows respectively. The same table creation and import was done for the World Bank data. A few cleaning of variables was also done to get the numeric measures to be correctly handled by MySQL.
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
## [Chapter 2 - ETL-Stored Procedures-Analytical Layer](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/2-ETL.sql)
The stored procedure function was used in MySQL to merge all the datasets together in order to build the following table (data store - analytical layer), representing facts and dimensions.

Class | Measure
:------------- | :-------------
Fact  | University
Fact  | Country
Fact  | Year
Dimension  | CWUR – Grade
Dimension  | CWUR – Employment Rank
Dimension  | CWUR – Patents Rank
Dimension  | Times – Percentage of international students
Dimension  | Times – Income
Dimension  | Times – Grade
Dimension  | World Bank – Expenditure on education (% of GDP)
Dimension  | World Bank – GDP per capita (PPP)
Dimension  | World Bank – Unemployment youth (% total labor force)
Dimension  | World Bank – Proportion of seats by women in parliament
Dimension  | World Bank – PM2.5 air pollution (annual exposure)
Dimension (computed)  | Cosmin Grade

An iterative approach was taken. Thus,
1. The first procedure (get_merged_tables) creates a merger between the two rankings datasets.
2. The second procedure (get_cosminranking_raw) merges the two rankings datasets to the World Bank data, adding all the chosen measures to each country.
3. The final procedure (get_cosminranking_comp) takes the data store and adds a new computed column to round off the ETL (Extract - Transform - Load). The cosmin_grade was computed based on all the measures of interest from the two rankings datasets. The computation snippet as part of the larger stored procedure (get_cosminranking_comp) can be seen in the code below.
```
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
```
### Analytics Plan
This final dataset that contains the transformation for the cosmin_grade as well as all the ranking and World Bank data of interest can be used for creating data marts which rank universities taking into consideration factors like air quality and GDP per capita. This means that the Cosmin ranking takes into consideration both the individual university contributions and merits as well as the individual country factors, like economic safety and gender equality.
Accordingly, we can proceed to ask a few questions that can guide further analysis on this computed dataset (of ~332 observations for the year 2014):
1. What are the top international universities in affluent and unpolluted countries?
2. How do countries compare against each other in terms of average scores?
3. What is the best place to study in terms of gender equality, score and income?
4. What are the best universities in terms of employment in low unemployment countries?
	* How about in countries with high youth unemployment?
5. Is there a correlation between government expenditure on education and ranking?
6. Do less internatioanl students come to poorer countries?
7. What are the top universities for entreneurship and youth employment?
8. Does a high grade of international outlook correlate with an international student body?
Not all of the above questions aim to be answered by the data marts computed in chapter 5 ([5-Views.sql](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/5-Views.sql)).

### Final ERR diagram of dataset (without intermediary cosminranking_raw)
![picture alt](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Diagrams/ERR_final_data.png)
## [Chapter 3 - Trigger-Changes upon insertion of new data](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/3-Trigger.sql)
The SQL Trigger was added so that newly-inserted data would be automatically logged in the intermediary cosminranking_raw table. The *messages* table was created in order to log each new entry (university - alongside all the other dimensions), the country the university is from and the exact timestamp of when it was added. The code for logging the new entries looks like this:
```
INSERT INTO messages SELECT CONCAT('new University in the ranking: ', NEW.university_name, ' from: ', NEW.country, ' added: ', NOW());
```
With the trigger in place, two random entries were made in the dataset to check whether runs. This can be checked by querying the messages table and the cosminranking_raw table for the newly-added data.
```
INSERT INTO merged_tables VALUES('Gica Hagi University','Romania',68.7,36.6,'15%',57.7,66.8,187,58,2014);
INSERT INTO merged_tables VALUES('Puskas Ferenc University','Hungary',68.7,36.6,'15%',57.7,66.8,187,58,2014);
```
After the insertion of the two new values, there is added script in the [3rd chapter](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/3-Trigger.sql) for cleaning up the new entries. Alternatively, if the entries want to be kept, the final procedure (get_cosminranking_comp) needs to be rerun (no input parameters needed). The command for rerunning the final procedure is on the first line of the final chapter ([5-Views.sql](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/5-Views.sql)).
## [Chapter 4 - Event-Create random inserts of new data](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/4-Event.sql)
The event was created pertaining to the same table that the trigger was defined on so that they could run together. Thus, with every new addition from the event, the trigger will automatically archive the new data in the merged_tables and will log their insertion. The following code is the main snippet of the event:
```
DECLARE uni_temp VARCHAR(256) DEFAULT 'Birdstrikes University';
		SET uni_temp = CONCAT(uni_temp,' ',FLOOR(RAND()*(10000-30+1))+30);
		
	INSERT INTO event_log SELECT CONCAT('insertion at: ',NOW());
	
    INSERT INTO merged_tables VALUES(uni_temp,'Romania',68.7,36.6,'15%',57.7,66.8,187,58,2014);
```
As such, the messages table acts as the main log for the event as well. However, if the trigger were not set up or initiated, the event_log table acts as an intermediary. This represents the end of our ETL and other data manipulation procedures. The final chapter covers data marts which can be later used to accomplish the analytics plan.
## [Chapter 5 - Views-Data Marts](https://github.com/cosmin-ticu/homework_DE1SQL/blob/master/Term/Scripts/5-Views.sql)
The 5 views covers the following 5 questions:
1. What are the top 50 universities worldwide according to the computed cosmin grade?
2. How many universities per country and what is the country's average cosmin grade? Naturally the countries that only have a few universities might be at a large advantage. Thus, some arbitrary "weights" are added.
3. How many universities does this dataset contain for each economic level (country-wide values)?
4. Example depth question: "I am interested in studying at top (50/100) universities for internationality, I want to know their world rank (cosmin_grade), air quality matters for me, and I would like to live in a country where women have a say in parliament."
5. Example depth question: "I am interested in studying at top (50/100) universities for employment opportunities, but I am also interested in entrepreneurship and patenting my work. I want to know their world rank (cosmin_grade) and to know whether the country as a whole having a good employment market for young people."
### Sample of code used to categorize numeric measures (usage of CASE statement)
```
CASE
            WHEN youth_unemploy = NULL THEN 'unknown youth unemployment rate'
            WHEN youth_unemploy <= 10 THEN 'low youth unemployment'
            WHEN youth_unemploy <= 15 THEN 'medium youth unemployment'
            WHEN youth_unemploy <= 20 THEN 'upper medium youth unemployment'
            WHEN youth_unemploy <= 35 THEN 'high youth unemployment'
            ELSE 'very high youth unemployment'
        END AS youth_unemployment
```

## Concluding remarks
This project has made use of data loading, cleaning, ETL, stored procedures, triggers, events and views as functions of SQL in MySQL Workbench. The entire projects represents a runthrough of the BI Architecture. This project's scope can be easily enhanced by conducting even more data enrichment with more country-wide measures or even city-centric measures. The Cosmin Ranking is, thus, a work in progress.
