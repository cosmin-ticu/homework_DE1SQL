USE univrankings;

-- Turn on
SET GLOBAL event_scheduler = ON;

-- Create a temporary table in which the newly inserted university names and their respective countries will be added
-- this is a reiteration of the messages table from the trigger, but it only acts for logging the time of the addition
DROP TABLE IF EXISTS event_log;
CREATE TABLE IF NOT EXISTS event_log (
    message VARCHAR(256) NOT NULL
);
TRUNCATE event_log;

-- -----------------------------------------------------------------------------
-- Event for creation of new random universities in the merged table of rankings
-- -----------------------------------------------------------------------------
DROP EVENT IF EXISTS insert_new_uni_store;

DELIMITER $$

CREATE EVENT insert_new_uni_store
ON SCHEDULE EVERY 15 SECOND
STARTS CURRENT_TIMESTAMP
ENDS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE -- this should create 5 new entries for Kukus University
DO
	BEGIN
    
    DECLARE uni_temp VARCHAR(256) DEFAULT 'Birdstrikes University';
		SET uni_temp = CONCAT(uni_temp,' ',FLOOR(RAND()*(10000-30+1))+30);
		
	INSERT INTO event_log SELECT CONCAT('insertion at: ',NOW());
	
    INSERT INTO merged_tables VALUES(uni_temp,'Romania',68.7,36.6,'15%',57.7,66.8,187,58,2014);
	
    END$$
DELIMITER ;

-- check whether event went through and check the log(s)
-- ideally only messages table should be used, as it also
-- contains the timestamp of insertion.
-- log table was conceptualized in case trigger would
-- not want to be run and the even would run idependently
SHOW EVENTS; -- to see if event ran

SELECT 
    *
FROM
    event_log;
    
SELECT 
    *
FROM
    messages;-- if trigger was initiated
    
SELECT 
    *
FROM
    merged_tables
WHERE
    university_name LIKE 'Birdstrikes University%';
    
SELECT 
    *
FROM
    cosminranking_raw
WHERE
    university_name LIKE 'Birdstrikes University%';

-- clean up after your mess (same reasoning as per 3-Trigger.sql - last section)
DELETE FROM merged_tables 
WHERE
    university_name LIKE 'Birdstrikes University%';
    
DELETE FROM cosminranking_raw 
WHERE
    university_name LIKE 'Birdstrikes University%';
    
TRUNCATE messages;

TRUNCATE event_log;