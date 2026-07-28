-- Databricks notebook source
-------------------------------------------------------------------------------
--Viewership Table
-------------------------------------------------------------------------------
SELECT *
FROM retail.default.bright_tv_viewership
LIMIT 10;

SELECT COUNT(*) AS num_rows,
       COUNT(COALESCE(UserID0,userid4)) AS  subs,
       COUNT(DISTINCT COALESCE(UserID0,userid4) ) AS active_subs
FROM retail.default.bright_tv_viewership
WHERE UserID0 IS NOT NULL ;

SELECT DISTINCT Channel2
FROM retail.default.bright_tv_viewership;

SELECT DISTINCT
    CASE
      WHEN Channel2 IN ('Sawsee', 'SawSee') THEN 'SawSee'
      WHEN Channel2 IN ('Supersport Live Events', 'Live on SuperSport','SuperSport Live Events') THEN 'Live Events'
ELSE Channel2
END AS tv_channels
FROM retail.default.bright_tv_viewership;



WITH base AS(
SELECT COALESCE(UserID0,userid4) AS userid
FROM retail.default.bright_tv_viewership
),
processing AS (
SELECT
 COALESCE(UserID0,userid4) AS userid,
   DAYNAME(TO_DATE(RecordDate2)) AS day_name,
   TO_CHAR(RecordDate2, 'yyyyMM') AS month_id,
   TO_DATE(RecordDate2) AS watch_date,
   --TIME(RecordDate2) AS watch_time,
   TO_CHAR(RecordDate2, 'DD') AS day_of_week,

   CASE
      WHEN day_name IN ('Sat' , 'Sun') THEN 'weekend'
      ELSE 'weekday'
      END AS day_classification,

   MONTHNAME(RecordDate2) AS month_name,
  CASE
   WHEN  watch_time BETWEEN '00:00:00' AND '05:59:59' THEN '01.Midnight'
   WHEN  watch_time BETWEEN '06:00:00' AND '11:59:59' THEN '02.Morning'
   WHEN  watch_time BETWEEN '12:00:00' AND '17:59:59' THEN '03.Afternoon'
   WHEN  watch_time BETWEEN '18:00:00' AND '21:59:59' THEN '04.Evening'
   WHEN  watch_time BETWEEN '22:00:00' AND '23:59:59' THEN '05.Night'
END AS time_of_day,
   CASE
      WHEN Channel2 IN ('Sawsee', 'SawSee') THEN 'SawSee'
      WHEN Channel2 IN ('Supersport Live Events', 'Live on SuperSport','SuperSport Live Events') THEN 'Live Events'
ELSE Channel2
END AS tv_channels,
DATE_FORMAT(RecordDate2, 'HH:mm:ss') AS time_part,
HOUR(RecordDate2) AS hour_of_day,

DATE_FORMAT(`Duration 2`, 'HH:mm:ss') AS duration,
CASE
   WHEN duration  BETWEEN '00:00:00' AND '00:30:00' THEN 'Low Usage'
   WHEN duration  BETWEEN '00:30:01' AND '00:59:59' THEN 'Med Usage'
   WHEN duration > '00:59:59' THEN  'High Usage'
END AS screen_time_bucket

FROM retail.default.bright_tv_viewership
),
