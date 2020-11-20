use univrankings;

-- Turn on
SET GLOBAL event_scheduler = ON;

-- Create a temporary table in which the newly inserted university names and their respective countries will be added
-- this is a reiteration of the messages table from the trigger, but it only acts for logging the time of the addition
drop table event_log;
CREATE TABLE IF NOT EXISTS event_log (message varchar(256) NOT NULL);
truncate event_log;

-- -----------------------------------------------------------------------------
-- Event for creation of new random universities in the merged table of rankings
-- -----------------------------------------------------------------------------
drop event if exists insert_new_uni_store;

DELIMITER $$

CREATE EVENT insert_new_uni_store
ON SCHEDULE EVERY 15 SECOND
STARTS CURRENT_TIMESTAMP
ENDS CURRENT_TIMESTAMP + INTERVAL 1 minute -- this should create 5 new entries for Kukus University
DO
	BEGIN
    declare uni_temp varchar(256) default 'Birdstrikes University';
		set uni_temp = concat(uni_temp,' ',FLOOR(RAND()*(10000-30+1))+30);
		INSERT INTO event_log SELECT CONCAT('insertion at: ',NOW());
		insert into merged_tables values(uni_temp,'Romania',68.7,36.6,'15%',57.7,66.8,187,58,2014);
	END$$
DELIMITER ;

-- check whether event went through and check the log(s)
-- ideally only messages table should be used, as it also
-- contains the timestamp of insertion.
-- log table was conceptualized in case trigger would
-- not want to be run and the even would run idependently
show events;
select * from event_log;
select * from messages; -- if trigger was initiated
select * from merged_tables where university_name like 'Birdstrikes University%';
select * from cosminranking_raw where university_name like 'Birdstrikes University%';

-- clean up after your mess
delete from merged_tables where university_name like 'Birdstrikes University%';
delete from cosminranking_raw where university_name like 'Birdstrikes University%';
truncate messages;
truncate event_log;