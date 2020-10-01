-- Exercises_Cosmin --

-- Exercise 1
SELECT * FROM birdstrikes LIMIT 144,1;
-- Tennessee

-- Exercise 2
SELECT * FROM birdstrikes ORDER BY flight_date DESC;
-- 2000-04-18

-- Exercise 3
select distinct cost from birdstrikes where damage = 'Caused damage' order by cost DESC limit 49,1;
-- 1336

-- Exercise 4 (two different results depending on the interpretation)
-- this is where we acknowledge fields that contain an actual blank space
select * from birdstrikes where state is NOT NULL and bird_size is not NULL limit 1,1;
-- ''

-- this is where we only acknowledge fields that have any sort of writing in them
select * from birdstrikes where state is NOT NULL and state != '' and bird_size is not NULL and bird_size != '' limit 1,1;
-- Colorado

-- Exercise 5 (i left the iterative code-building here to check whether my logic makes sense)
select *, datediff(reported_date, flight_date) from birdstrikes;
select *, weekofyear(flight_date) from birdstrikes where state = 'Colorado';
select *, weekofyear(flight_date) from birdstrikes where state = 'Colorado' and weekofyear(flight_date) = 52;
select *, weekofyear(flight_date), datediff(now(), flight_date) from birdstrikes where state = 'Colorado' and weekofyear(flight_date) = 52;
select *, datediff(now(), flight_date) from birdstrikes where state = 'Colorado' and weekofyear(flight_date) = 52;
select datediff(now(), flight_date) from birdstrikes where state = 'Colorado' and weekofyear(flight_date) = 52;

select datediff(now(), flight_date)
from birdstrikes
where
	state = 'Colorado'
    and
    weekofyear(flight_date) = 52;
-- 7579 days