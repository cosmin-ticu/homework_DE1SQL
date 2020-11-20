USE univrankings;

-- Create a temporary table in which the newly inserted university names and their respective countries will be added
DROP TABLE IF EXISTS messages;
CREATE TABLE IF NOT EXISTS messages (
    message VARCHAR(256) NOT NULL
);
TRUNCATE messages;

-- Trigger for a new university to log its addition into the messages table and add the new university to the
-- raw table which contains data on the university's country. This means that after this trigger, you should
-- rerun the final stored procedure -> get_cosminranking_comp in order to have complete views
DROP TRIGGER IF EXISTS new_uni_insert; 

DELIMITER $$

CREATE TRIGGER new_uni_insert
AFTER INSERT
ON merged_tables FOR EACH ROW
BEGIN
	
	-- log the name of the newley inserted university
	INSERT INTO messages SELECT CONCAT('new University in the ranking: ', NEW.university_name, '      from: ', NEW.country, '      added: ', NOW());

	-- archive the associated table entries to cosminranking_raw
  	INSERT INTO CosminRanking_raw
		SELECT
			m.university_name, m.country, 
            m.times_international_grade, m.times_income_grade, m.times_percent_intstudents, m.times_score,
			m.cwur_score, m.cwur_employ_rank, m.cwur_patents_rank, m.year,
			w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
		FROM 
			merged_tables m
		LEFT JOIN 
			world_bank w
				ON w.country=m.country AND w.year=m.year
		WHERE m.university_name = new.university_name;
        
END $$

DELIMITER ;

-- -----------------------------------------------------
-- If you would like to tinker with the trigger without
-- launching the event on the 4-Event.sql script, you
-- can run the insertions below and the queries
-- -----------------------------------------------------
-- insert two random entries that check whether the trigger works - check MESSAGES
INSERT INTO merged_tables VALUES('Gica Hagi University','Romania',68.7,36.6,'15%',57.7,66.8,187,58,2014);
INSERT INTO merged_tables VALUES('Puskas Ferenc University','Hungary',68.7,36.6,'15%',57.7,66.8,187,58,2014);

-- check whether they were inserted
SELECT 
    *
FROM
    messages;

SELECT 
    *
FROM
    merged_tables
WHERE
    university_name LIKE 'Gica Hagi University'
        OR university_name LIKE 'Puskas Ferenc University';

SELECT 
    *
FROM
    cosminranking_raw
WHERE
    university_name LIKE 'Gica Hagi University'
        OR university_name LIKE 'Puskas Ferenc University';

-- --------------------- clean up after yourself -----------------------------
-- delete the two random entries that check whether the trigger works - do not forget to truncate MESSAGES
DELETE FROM merged_tables 
WHERE
    university_name LIKE 'Gica Hagi University';
    
DELETE FROM merged_tables 
WHERE
    university_name LIKE 'Puskas Ferenc University';
    
DELETE FROM CosminRanking_raw 
WHERE
    university_name LIKE 'Gica Hagi University';
    
DELETE FROM CosminRanking_raw 
WHERE
    university_name LIKE 'Puskas Ferenc University';
    
-- delete the entries from the computed rank table in case you ran the final procedure with the newly-added data to cosminranking_raw
DELETE FROM CosminRanking_comp 
WHERE
    university_name LIKE 'Gica Hagi University';
    
DELETE FROM CosminRanking_comp 
WHERE
    university_name LIKE 'Puskas Ferenc University';
    
TRUNCATE messages;