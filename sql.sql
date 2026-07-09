use flight_analysis;
select * from airport_project_data;

# 1.Analyze total passenger traffic per route and over time. 
select 
year, QUARTER, ORIGIN_CITY_NAME, DEST_CITY_NAME, sum(PASSENGERS) as total_passengers
from airport_project_data
group by 1,2,3,4
order by year, QUARTER;

#2.Top 5 routes which are the busiest routes having huge passenger trafic.
select 
year, ORIGIN_CITY_NAME, DEST_CITY_NAME, SUM(PASSENGERS) as total_passengers
from airport_project_data
group by 1,2,3
order by total_passengers desc
limit 5;

#3. Least busiest routes.
select 
year, ORIGIN_CITY_NAME, DEST_CITY_NAME, SUM(PASSENGERS) as total_passengers
from airport_project_data
group by 1,2,3
having sum(PASSENGERS)>0
order by total_passengers
limit 5;

#4. Determine average passengers per flight for various routes and airport.
# for routes.
select 
year, ORIGIN_CITY_NAME, DEST_CITY_NAME, avg(PASSENGERS) as avg_passengers
from airport_project_data
group by 1,2,3
order by avg_passengers desc;

# for airport. (outhoing)
select 
ORIGIN_AIRPORT_ID, avg (PASSENGERS) as avg_passengers
from airport_project_data
group by 1
order by avg_passengers desc;

# (incoming)
select 
DEST_AIRPORT_ID, avg(PASSENGERS) as avg_passengers
from airport_project_data
group by 1 
order by avg_passengers desc;

WITH outgoing_passengers AS (
    SELECT
        ORIGIN_AIRPORT_ID,
        AVG(PASSENGERS) AS avg_passengers
    FROM airport_project_data
    GROUP BY ORIGIN_AIRPORT_ID
),

incoming_passengers AS (
    SELECT
        DEST_AIRPORT_ID,
        AVG(PASSENGERS) AS avg_passengers
    FROM airport_project_data
    GROUP BY DEST_AIRPORT_ID
),

all_airport AS (
    SELECT 
    DISTINCT ORIGIN_AIRPORT_ID AS airport_id
    FROM airport_project_data

    UNION

    SELECT DISTINCT DEST_AIRPORT_ID AS airport_id
    FROM airport_project_data
)

SELECT
    aa.airport_id,
    COALESCE(op.avg_passengers,0) + COALESCE(ip.avg_passengers,0)
        AS total_passengers_travelling
FROM all_airport aa
LEFT JOIN outgoing_passengers op
    ON aa.airport_id = op.ORIGIN_AIRPORT_ID
LEFT JOIN incoming_passengers ip
    ON aa.airport_id = ip.DEST_AIRPORT_ID
ORDER BY total_passengers_travelling DESC;

#5. Assess flight frequency and identify high traffic corridors.
select 
ORIGIN_CITY_NAME, DEST_CITY_NAME, count(AIRLINE_ID) as total_flights
from airport_project_data
group by 1,2
order by total_flights desc
limit 10;

#6. Evaluate available seat capacity to understand seat utilization for each airline.
with seating_capacity AS 
(select 
AIRLINE_ID, max(PASSENGERS) as seat_capacity
from airport_project_data
group by AIRLINE_ID
having max(passengers)>0),

seat_utilization as 
(select 
ad.AIRLINE_ID, ad.PASSENGERS*100.00/sc.seat_capacity as seat_utilization 
from airport_project_data ad join seating_capacity sc on ad.AIRLINE_ID = SC.AIRLINE_ID
order by seat_utilization desc)

select 
AIRLINE_ID, avg(seat_utilization) as avg_seat_utilization
from seat_utilization
group by 1 
order by avg_seat_utilization desc;

#7. Identify popular destination airport based on inbound passenger counts.

select 
DEST_AIRPORT_ID, DEST_CITY_NAME, sum(PASSENGERS) as inbound_passengers
from airport_project_data
group by DEST_AIRPORT_ID, DEST_CITY_NAME
order by inbound_passengers desc 
limit 10;   #fortop10.

#8. Examin the relationship between city poulation & airport passenger trafic.
select*from all_city_pop;

with outgoing_passengers as 
(select 
ORIGIN_AIRPORT_ID, sum(PASSENGERS) as tot_passengers
from airport_project_data
group by 1),

incoming_passengers as
(select 
DEST_AIRPORT_ID, sum(PASSENGERS) as tot_passengers
from airport_project_data
group by 1),

all_airport as 
(select 
distinct ORIGIN_AIRPORT_ID as airport_id, 
ORIGIN_CITY_NAME as city_name 
from airport_project_data
union 
select distinct DEST_AIRPORT_ID as airport_id,
DEST_CITY_NAME as city_name
from airport_project_data),

passenger_traffic AS (
    SELECT
        SUBSTRING_INDEX(aa.city_name, ',', 1) AS city_name,
        COALESCE(op.tot_passengers,0) +
        COALESCE(ip.tot_passengers,0) AS total_passenger_travelling
    FROM all_airport aa
    LEFT JOIN outgoing_passengers op
        ON aa.airport_id = op.ORIGIN_AIRPORT_ID
    LEFT JOIN incoming_passengers ip
        ON aa.airport_id = ip.DEST_AIRPORT_ID
)

select cp.city_name, cp.population, pt.total_passenger_travelling
from passenger_traffic pt 
join all_city_pop cp 
on pt.city_name = cp.city_name
where CP.population is not null 
and total_passenger_travelling is not null
and population <>0
order by population asc;
