-- Homework 5: Continue the last script: complete the US local phones to international using the city code

DROP TABLE IF EXISTS area_codes;
CREATE TABLE area_codes (city VARCHAR(50), AreaCode VARCHAR(3));
LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/HW5_area-codes.csv' 
INTO TABLE area_codes
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

DROP PROCEDURE IF EXISTS FixUSPhones; 

DELIMITER $$

CREATE PROCEDURE FixUSPhones ()
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE phone varchar(50) DEFAULT "x";
	DECLARE customerNumber INT DEFAULT 0;
	DECLARE country varchar(50) DEFAULT "";
	DECLARE area_code varchar(3) DEFAULT "";
	DECLARE city varchar(50) DEFAULT "x";

	-- declare cursor for customer
	DECLARE curPhone
		CURSOR FOR 
            		SELECT customers.customerNumber, customers.phone, customers.country, customers.city 
				FROM classicmodels.customers;

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curPhone;
    
    	-- create a copy of the customer table 
	DROP TABLE IF EXISTS classicmodels.fixed_customers;
	CREATE TABLE classicmodels.fixed_customers LIKE classicmodels.customers;
	INSERT fixed_customers SELECT * FROM classicmodels.customers;

	fixPhone: LOOP
		FETCH curPhone INTO customerNumber, phone, country, city;
		IF finished = 1 THEN 
			LEAVE fixPhone;
		END IF;
		 
		-- concatenate complete US number with +1 and incomplete phone numbers with area codes & +1
         
		IF country = 'USA'  THEN
			IF phone NOT LIKE '+%' THEN
				IF LENGTH(phone) = 10 THEN 
							SET  phone = CONCAT('+1',phone);
                            UPDATE classicmodels.fixed_customers 
                            SET fixed_customers.phone=phone 
										WHERE fixed_customers.customerNumber = customerNumber;
                        ELSEIF length(phone) = 7 THEN
							SET area_code = (select area_codes.AreaCode from area_codes where area_codes.city = city);
							SET phone = CONCAT('+1',area_code,phone);
								UPDATE classicmodels.fixed_customers 
									SET fixed_customers.phone=phone 
										WHERE fixed_customers.customerNumber = customerNumber;
				END IF;    
			END IF;
		END IF;

	END LOOP fixPhone;
	CLOSE curPhone;

END$$
DELIMITER ;

CALL FixUSPhones();
SELECT * FROM fixed_customers where country = 'USA';