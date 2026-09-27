-- Databricks notebook source
--Inspecting the entire table to see what coloumns are there--
SELECT *
FROM brighttv_case_study.bright_tv.bright_tv_user_profiles limit 100;

--Finding duplicates in UserID and userid4--
SELECT *
FROM brighttv_case_study.bright_tv.bright_viewership
WHERE UserID0 IS NULL OR userid4 IS NULL;

SELECT *
FROM brighttv_case_study.bright_tv.bright_viewership
WHERE UserID0 <> userid4;--Only include rows where the value in column UserID0 is different from the value in column userid4.”

--Checking for dupilcates
SELECT COUNT(*) AS duplicate_count,
     UserID0,
     RecordDate2
FROM brighttv_case_study.bright_tv.bright_viewership
GROUP BY
    UserID0,
    RecordDate2
HAVING COUNT(*)>1
ORDER BY duplicate_count DESC;

--Converting timestamp JHB time through the use of a CTE
WITH Base_viewership AS (
    SELECT
        COALESCE(UserID0, userid4) AS User_id,
        from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS RecordDate_SAST,
        Channel2,
        `Duration 2`
    FROM brighttv_case_study.bright_tv.bright_viewership
),
Cleaned_viewership AS (
    SELECT
        User_id,
        RecordDate_SAST,
        TO_DATE(RecordDate_SAST) AS Day_name, --Convert a string into a date YYYY-MM-DD
        MONTHNAME(RecordDate_SAST) AS Month_name, -- Extarct the month name
        YEAR(RecordDate_SAST) AS Event_year, --Extract year value
        DAY(RecordDate_SAST) AS Event_day, --Extract day value
        HOUR(RecordDate_SAST) AS Hour_of_the_day, --Extract hour of the day
    CASE
        WHEN DAYNAME(RecordDate_SAST) IN ('Sat', 'Sun') THEN '02. Weekend'
        ELSE '01. Weekday'
    END AS Day_classification,

    date_format(RecordDate_SAST, 'HH:mm:ss') AS Watch_time, --Converting date format to time
    CASE
        WHEN Watch_time BETWEEN '00:00:00' AND '05:59:59' THEN '01. Midnight'
        WHEN Watch_time BETWEEN '06:00:00' AND '11:59:59' THEN '02. Morning'
        WHEN Watch_time BETWEEN '12:00:00' AND '16:59:59' THEN '03. Afternoon'
        WHEN Watch_time BETWEEN '17:00:00' AND '23:59:59' THEN '04. Evening'
    END AS Time_of_day,
   
    `Duration 2`,
    DATE_FORMAT(`Duration 2`, 'HH:mm:ss') AS Duration, --Converting duration into time format
    (
        HOUR(TO_TIMESTAMP(`Duration 2`,'HH:mm:ss')) +
        MINUTE(TO_TIMESTAMP(`Duration 2`,'HH:mm:ss')) / 60.0 + -- Converting minutes to seconds
        SECOND (TO_TIMESTAMP(`Duration 2`,'HH:mm:ss')) / 3600.0--Converting seconds to minutes
        ) AS Duration_hours,
                (
                    HOUR(TO_TIMESTAMP(`Duration 2`, 'HH:mm:ss')) * 3600 + --converting hours to seconds
            MINUTE(TO_TIMESTAMP(`Duration 2`, 'HH:mm:ss')) * 60 + ---converting minutes to seconds
            SECOND(TO_TIMESTAMP(`Duration 2`, 'HH:mm:ss'))
        ) AS Duration_seconds,   

    CASE
        WHEN Duration_seconds BETWEEN 300 AND 1800 THEN '01. Low Usage (<30 min)'
        WHEN Duration_seconds BETWEEN 1801 AND 3599 THEN '02. Medium Usage (<60 min)'
        WHEN Duration_seconds >= 3600 THEN '03. High Usage (>60 min)'
        ELSE '04. No Usage'
    END AS Screen_time_bucket,

      CASE --cleaning channel
        WHEN Channel2 IN ('SawSee','Sawsee') THEN 'SawSee'
        WHEN Channel2 IN ('SuperSport Live Events','Live on SuperSport', 'Supersport Live Events', 'DStv Events 1') THEN 'Live Events'
        ELSE Channel2
    END AS Tv_channel
FROM Base_viewership);

SELECT*
FROM Cleaned_viewership; 




