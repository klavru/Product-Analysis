-- unique users and their first events
WITH first_events AS
    (SELECT 
    DISTINCT user_pseudo_id,
    MIN (event_date) AS event_date,
    MIN (event_timestamp) AS first_event_timestamp
    FROM tc-da-1.turing_data_analytics.raw_events

    GROUP BY 
    user_pseudo_id
    /*event_date*/),

purchase_event AS -- users who have made a purchase
    (SELECT  
    DISTINCT user_pseudo_id,
    event_date, 
    purchase_revenue_in_usd,
    category,
    mobile_brand_name,
    operating_system,
    browser,
    country,
    MIN (event_timestamp) OVER (PARTITION BY user_pseudo_id ORDER BY event_date) AS purchase_timestamp 
    FROM tc-da-1.turing_data_analytics.raw_events
    WHERE event_name = 'purchase' 
    )
  

SELECT 
DISTINCT fe.user_pseudo_id,
DATE_TRUNC (PARSE_DATE('%Y%m%d', pe.event_date), DAY) AS purchase_date,
fe.first_event_timestamp,
pe.purchase_timestamp,
TIMESTAMP_MICROS(fe.first_event_timestamp) AS start_timestamp,
TIMESTAMP_MICROS(pe.purchase_timestamp) AS end_timestamp,
TIMESTAMP_DIFF(TIMESTAMP_MICROS(pe.purchase_timestamp), TIMESTAMP_MICROS(fe.first_event_timestamp), MINUTE) AS time_difference_minutes,
  CASE WHEN EXTRACT(DAYOFWEEK FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) = 1 THEN 7
    ELSE EXTRACT(DAYOFWEEK FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) - 1
  END AS day_of_week_starting_from_monday,

    CASE WHEN EXTRACT(HOUR FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) >= 0 AND EXTRACT(HOUR FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) < 6 THEN 'Night'
    WHEN EXTRACT(HOUR FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) >= 6 AND EXTRACT(HOUR FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) < 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) >= 12 AND EXTRACT(HOUR FROM TIMESTAMP_MICROS(fe.first_event_timestamp)) < 18 THEN 'Afternoon'
    ELSE 'Evening' END AS session_start_time_of_the_day,

    CASE WHEN EXTRACT(HOUR FROM TIMESTAMP_MICROS(pe.purchase_timestamp)) >= 0 AND EXTRACT(HOUR FROM TIMESTAMP_MICROS(pe.purchase_timestamp)) < 6 THEN 'Night'
    WHEN EXTRACT(HOUR FROM TIMESTAMP_MICROS(pe.purchase_timestamp)) >= 6 AND EXTRACT(HOUR FROM TIMESTAMP_MICROS(pe.purchase_timestamp)) < 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM TIMESTAMP_MICROS(pe.purchase_timestamp)) >= 12 AND EXTRACT(HOUR FROM TIMESTAMP_MICROS(pe.purchase_timestamp)) < 18 THEN 'Afternoon'
    ELSE 'Evening' END AS purchase_time_of_the_day,

pe.purchase_revenue_in_usd,
pe.category

FROM first_events AS fe
JOIN purchase_event AS pe
ON fe.user_pseudo_id = pe.user_pseudo_id AND fe.event_date = pe.event_date
