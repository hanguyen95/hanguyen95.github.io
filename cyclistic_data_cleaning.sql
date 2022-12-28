use bike_share
# 1. Change data type
---information of table
exec sp_help [202112-divvy-tripdata]
exec sp_help merge_data
---change data type
alter table [202209-divvy-tripdata]
alter column end_station_id nvarchar (510)
---create view merge_data
create view merge_data as
select * from
(
	select * from [202112-divvy-tripdata]
	union
	select * from [202201-divvy-tripdata]
	union
	select * from [202202-divvy-tripdata]
	union
	select * from [202203-divvy-tripdata]
	union
	select * from [202204-divvy-tripdata]
	union
	select * from [202205-divvy-tripdata]
	union
	select * from [202206-divvy-tripdata]
	union
	select * from [202207-divvy-tripdata]
	union
	select * from [202208-divvy-tripdata]
	union
	select * from [202209-divvy-tripdata]
	union
	select * from [202210-divvy-tripdata]
	union
	select * from [202211-divvy-tripdata]
) as b
---create table merge_table from merge_data
select * into merge_table
from merge_data
---delete merge_data since no need anymore
drop view merge_data

# 2. Missing value
---create table station_info include start station and end station
with cte_station (station_name, station_id) as
(select start_station_name as station_name, start_station_id as station_id
group by start_station_name, start_station_id
union
select end_station_name as station_name, end_station_id as station_id
from merge_table
group by end_station_name, end_station_id)

select * into station_info
from cte_station
group by station_name, station_id

---update merge_table: start_station_id
---there are 854844 null values in start_station_name, 1814065 null values in start_station_id, null value in both columns are 854844 values
UPDATE merge_table
SET start_station_id = p.station_id
FROM station_info AS p
WHERE start_station_name = p.station_name
AND start_station_id IS NULL
AND p.station_id IS NOT NULL;
GO
---check null value of end station
---there are 915082 null values in end_station_name, 1391798 null values in end_station_id, null value in both columns are 915082 values
select end_station_name, count(*)
from merge_table
where end_station_name is null
group by end_station_name


---update merge_table: end_station_id, 467174 value was updated
UPDATE merge_table
SET end_station_id = p.station_id
FROM station_info AS p
WHERE end_station_name = p.station_name
AND end_station_id IS NULL
AND p.station_id IS NOT NULL;
GO

---double check:
---remain 915082 null value in both end station name and end station id, 542 null value in end station id
---remain 854844 null value in both start station name and start station id, 516 null value in start station id
select start_station_name, start_station_id, count(*)
from merge_table
group by start_station_id, start_station_name
order by 2


---check lat and lng to fill null value of name and id
---cannot using this method because there are cases that has the same coordinate but different station id and name
select start_station_id, start_station_name, left(start_lat,5) as lat, left(start_lng,6) as lng, count(*)
from merge_table
group by start_station_id, start_station_name, left(start_lat,5), left(start_lng,6)
order by 3,4

# 3. Wrong data
---check number of values having ride length <= 0: 70784 values
select count(*)
from
(
select datediff(minute, started_at, ended_at) as ride_length_minute
from merge_table
) as a
where ride_length_minute <= 0
---then drop those value
delete from merge_table where datediff(minute, started_at, ended_at) <= 0






