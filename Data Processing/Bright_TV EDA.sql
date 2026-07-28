-- Databricks notebook source
--Want to see what colomns the table has before I start doing any analysis on it.
SELECT*
FROM retail.default.bright_tv_user_profiles
LIMIT 10;

--Checking for duplicates in my data.
SELECT UserID,
COUNT(*) AS  duplicates_count
FROM retail.default.bright_tv_user_profiles
GROUP BY UserID
HAVING COUNT(*) > 1;

--How big is this data(size of the data), how many rows are there.
SELECT COUNT(*) AS number_of_rows,
       COUNT(DISTINCT UserID) AS number_subs
FROM retail.default.bright_tv_user_profiles;

--Are the any rows where userID is NULL.
SELECT COUNT(*)
FROM retail.default.bright_tv_user_profiles
WHERE UserID IS NULL;

------------------------------------------------------------------
--Gender checks
------------------------------------------------------------------

SELECT DISTINCT Gender
FROM retail.default.bright_tv_user_profiles;

--Checking for empty spaces on gender
SELECT COUNT(*)
FROM retail.default.bright_tv_user_profiles
WHERE Gender=' ';

SELECT 
      COUNT(DISTINCT UserID) AS subs,
    CASE
       WHEN Gender=' ' THEN 'None'
       ELSE Gender
       END AS Gender
FROM retail.default.bright_tv_user_profiles
GROUP BY Gender;

---------------------------------------------------------
--Race checks
---------------------------------------------------------
SELECT DISTINCT race
FROM retail.default.bright_tv_user_profiles;

SELECT COUNT(*) AS num_rows
FROM retail.default.bright_tv_user_profiles
WHERE Race IS NULL;

SELECT DISTINCT
    CASE 
      WHEN Race = 'other' THEN 'None'
      WHEN Race = ' ' THEN 'None'
ELSE Race
END AS Race
FROM retail.default.bright_tv_user_profiles;

--------------------------------------------------------
--Province checks
--------------------------------------------------------
SELECT DISTINCT Province
FROM retail.default.bright_tv_user_profiles;

SELECT DISTINCT
    CASE
        WHEN Province = ' ' THEN 'Uncategorized'
        WHEN Province = 'None' THEN 'Uncategorized'
ELSE Province
END AS Province
FROM retail.default.bright_tv_user_profiles;

-------------------------------------------------------------
--Age Checks
-------------------------------------------------------------
SELECT MIN(Age) AS min_age,
      MAX(Age) AS max_age
FROM retail.default.bright_tv_user_profiles;

SELECT COUNT(*)
FROM retail.default.bright_tv_user_profiles
WHERE Age IS NULL;

SELECT COUNT(DISTINCT UserID) AS subs,
     CASE 
        WHEN Age = 0 THEN 'Infants'
        WHEN Age BETWEEN 1 AND 12 THEN 'Kids'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teenager'
        WHEN Age BETWEEN 20 AND 35 THEN 'Youth'
        WHEN Age BETWEEN 36 AND 50 THEN 'Adult'
        WHEN Age BETWEEN 51 AND 65 THEN 'Elder'
        WHEN Age >65 THEN 'Senior'
  END AS  age_groups
  FROM retail.default.bright_tv_user_profiles
  GROUP BY age_groups;
  -----------------------------------------------------------------
--Combining Everything together
-------------------------------------------------------------------
CREATE OR REPLACE TABLE retail.default.final_data AS
WITH user_profiles AS (
  SELECT UserID,
     CASE
        WHEN Province = ' ' THEN 'Uncategorized'
        WHEN Province = 'None' THEN 'Uncategorized'
ELSE Province
END AS Region,

Age,
  CASE 
        WHEN Age = 0 THEN 'Infants'
        WHEN Age BETWEEN 1 AND 12 THEN 'Kids'
        WHEN Age BETWEEN 13 AND 19 THEN 'Teenager'
        WHEN Age BETWEEN 20 AND 35 THEN 'Youth'
        WHEN Age BETWEEN 36 AND 50 THEN 'Adult'
        WHEN Age BETWEEN 51 AND 65 THEN 'Elder'
        WHEN Age >65 THEN 'Senior'
  END AS  age_groups,

  CASE
     WHEN (Email IS NULL) OR (Email != ' ') OR (Email NOT IN('None')) THEN 1
     ELSE 0
     END AS email_flag,

  CASE
    WHEN (`Social Media Handle` IS NOT NULL) OR (`Social Media Handle`!= ' ') OR (`Social Media Handle` NOT IN ('None')) THEN 1
    ELSE 0
    END AS sm_flag,
  
 CASE 
      WHEN Race = 'other' THEN 'None'
      WHEN Race = ' ' THEN 'None'
ELSE Race
END AS Race,

CASE
       WHEN Gender=' ' THEN 'None'
       ELSE Gender
END AS Gender
FROM retail.default.bright_tv_user_profiles
),
viewership AS (
SELECT
 COALESCE(UserID0,userid4) AS userid,
   DAYNAME(RecordDate2) AS day_name,
   TO_CHAR(RecordDate2, 'yyyyMM') AS month_id,
   TO_DATE(RecordDate2) AS watch_date,
   --TIME(RecordDate2) AS watch_time,
   TO_CHAR(RecordDate2, 'DD') AS day_of_week,
   MONTHNAME(RecordDate2) AS month_name,
   CASE
      WHEN day_name IN ('Sat' , 'Sun') THEN 'weekend'
      ELSE 'weekday'
      END AS day_classification,

   CASE
      WHEN Channel2 IN ('Sawsee', 'SawSee') THEN 'SawSee'
      WHEN Channel2 IN ('Supersport Live Events', 'Live on SuperSport','SuperSport Live Events') THEN 'Live Events'
ELSE Channel2
END AS tv_channels,
date_format(RecordDate2, 'HH:mm:ss') AS watch_time,
CASE
   WHEN  watch_time BETWEEN '00:00:00' AND '05:59:59' THEN '01.Midnight'
   WHEN  watch_time BETWEEN '06:00:00' AND '11:59:59' THEN '02.Morning'
   WHEN  watch_time BETWEEN '12:00:00' AND '17:59:59' THEN '03.Afternoon'
   WHEN  watch_time BETWEEN '18:00:00' AND '21:59:59' THEN '04.Evening'
   WHEN  watch_time BETWEEN '22:00:00' AND '23:59:59' THEN '05.Night'
END AS time_of_day,
HOUR(RecordDate2) AS hour_of_day,
date_format(`Duration 2`, 'HH:mm:ss') AS duration,
ROUND((HOUR(`Duration 2`) * 60 + minute(`Duration 2`) + second(`Duration 2`) /60), 2) AS duration_minute,
CASE
   WHEN duration  BETWEEN '00:00:00' AND '00:30:00' THEN 'Low Usage'
   WHEN duration  BETWEEN '00:30:01' AND '00:59:59' THEN 'Med Usage'
   WHEN duration > '00:59:59' THEN  'High Usage'
   ELSE 'No Usage'
END AS screen_time_bucket

FROM retail.default.bright_tv_viewership
)

SELECT COALESCE(A.userid, B.userid) AS sub_id,
      month_id,
      watch_date,
      day_of_week,
      day_name,
      day_classification,
      month_name,
      tv_channels,
      time_of_day,
      hour_of_day,
      screen_time_bucket,
      duration,
      duration_minute,
      Region,
      age_groups,
      email_flag,
      sm_flag,
      Race,
      Gender
FROM viewership AS A
LEFT JOIN user_profiles AS B
ON A.userid=B.userid
GROUP BY ALL;


SELECT COUNT(*) FROM retail.default.final_data;

-------------------------------------------------------------------
--Total watch time by TV channel
-------------------------------------------------------------------
SELECT tv_channels,
       ROUND(
         SUM( CAST(SPLIT(duration, ':')[0] AS INT)*3600
            + CAST(SPLIT(duration, ':')[1] AS INT)*60
            + CAST(SPLIT(duration, ':')[2] AS INT) ) / 3600.0
       , 2) AS total_watch_hours
FROM retail.default.final_data
GROUP BY tv_channels
ORDER BY total_watch_hours DESC;

-------------------------------------------------------------------
--Average watch duration by channel
-------------------------------------------------------------------
SELECT tv_channels,
       ROUND(
         AVG( CAST(SPLIT(duration, ':')[0] AS INT)*3600
            + CAST(SPLIT(duration, ':')[1] AS INT)*60
            + CAST(SPLIT(duration, ':')[2] AS INT) ) / 60.0
       , 2) AS avg_watch_minutes
FROM retail.default.final_data
GROUP BY tv_channels
ORDER BY avg_watch_minutes DESC;

-------------------------------------------------------------------
--Viewership trend by month
-------------------------------------------------------------------
SELECT month_id,
       month_name,
       COUNT(*) AS viewing_records,
       ROUND(
         SUM( CAST(SPLIT(duration, ':')[0] AS INT)*3600
            + CAST(SPLIT(duration, ':')[1] AS INT)*60
            + CAST(SPLIT(duration, ':')[2] AS INT) ) / 3600.0
       , 2) AS total_watch_hours
FROM retail.default.final_data
GROUP BY month_id, month_name
ORDER BY month_id;

--------------------------------------------------------------------
--Top 5 most watched TV channels
-------------------------------------------------------------------
SELECT tv_channels,
       COUNT(*) AS viewing_records,
       ROUND(
         SUM( CAST(SPLIT(duration, ':')[0] AS INT)*3600
            + CAST(SPLIT(duration, ':')[1] AS INT)*60
            + CAST(SPLIT(duration, ':')[2] AS INT) ) / 3600.0
       , 2) AS total_watch_hours
FROM retail.default.final_data
GROUP BY tv_channels
ORDER BY viewing_records DESC
LIMIT 5;

