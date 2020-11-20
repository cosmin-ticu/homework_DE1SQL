use univrankings;

drop table messages;
CREATE TABLE IF NOT EXISTS messages (message varchar(256) NOT NULL);
truncate messages;

DROP TRIGGER IF EXISTS new_uni_insert; 

DELIMITER $$

CREATE TRIGGER new_uni_insert
AFTER INSERT
ON merged_tables FOR EACH ROW
BEGIN
	
	-- log the name of the newley inserted university
	INSERT INTO messages SELECT CONCAT('new University in the ranking: ', NEW.university_name, '      from: ', NEW.country, '      added: ', NOW());

	-- archive the order and assosiated table entries to cosmin_ranking_raw
  	insert into CosminRanking_raw
		select
			m.university_name, m.country, 
            m.times_international_grade, m.times_income_grade, m.times_percent_intstudents, m.times_score,
			m.cwur_score, m.cwur_employ_rank, m.cwur_patents_rank, m.year,
			w.gov_spend, w.GDP_capita, w.youth_unemploy, w.gov_women, w.air_pollution
		from 
			merged_tables m
		left join 
			world_bank w
				on w.country=m.country and w.year=m.year
		where m.university_name = new.university_name;
        
END $$

DELIMITER ;

-- insert two random entries that check whether the trigger works - check MESSAGES
insert into merged_tables values('Gica Hagi University','Romania',68.7,36.6,'15%',57.7,66.8,187,58,2014);
insert into merged_tables values('Puskas Ferenc University','Hungary',68.7,36.6,'15%',57.7,66.8,187,58,2014);

-- delete the two random entries that check whether the trigger works - do not forget to truncate MESSAGES
delete from merged_tables where university_name like 'Gica Hagi University';
delete from merged_tables where university_name like 'Puskas Ferenc University';
delete from CosminRanking_raw where university_name like 'Gica Hagi University';
delete from CosminRanking_raw where university_name like 'Puskas Ferenc University';
-- delete the entries from the computed rank table in case you ran the final procedure with the newly-added data to cosminranking_raw
delete from CosminRanking_comp where university_name like 'Gica Hagi University';
delete from CosminRanking_comp where university_name like 'Puskas Ferenc University';