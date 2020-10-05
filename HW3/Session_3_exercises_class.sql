-- Exercise 1 - If speed is NULL or speed < 100 create a "LOW SPEED" category, otherwise, mark as "HIGH SPEED"
select aircraft, airline, speed,
if (speed < 100 or speed is NULL, 'low speed','high speed')
as speed_category
from birdstrikes
order by speed_category;

-- Exercise 2 - How many distinct 'aircraft' we have in the database?
select count(distinct(aircraft)) from birdstrikes;
select distinct(aircraft) from birdstrikes; -- this is just to check the distinct types; one is empty (not null), though
-- 3

-- Exercise 3 - What was the lowest speed of aircrafts starting with 'H'
select min(speed) as lowest_speed from birdstrikes where aircraft like 'H%';
-- 9

-- Exercise 4 - Which phase_of_flight has the least of incidents?
select phase_of_flight, count(*) as incidents from birdstrikes group by phase_of_flight order by incidents;
-- Taxi

-- Exercise 5 - What is the rounded highest average cost by phase_of_flight?
select phase_of_flight, (avg(cost)) as avg_cost from birdstrikes group by phase_of_flight order by avg_cost desc;
-- ~54673 for the Climb phase of flight

-- Exercise 6 - What the highest AVG speed of the states with names less than 5 characters?
select state, avg(speed) as avg_speed from birdstrikes group by state having length(state) < 5 order by avg_speed desc limit 1;
-- 2862.5 for Iowa (out of all the states with names less than 5 characters)