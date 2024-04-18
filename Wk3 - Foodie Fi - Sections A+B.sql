-- A. write brief description about each customers onboarding journey based off 8 sample custoemers provided in the sample from subscriptions

select *
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where customer_id <= 8


-- B. DAta Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?

select
count(distinct customer_id)
from subscriptions s



--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select
date_trunc('month',start_date) as Month
,count(distinct customer_id) as trial_starts
from subscriptions s
where plan_id = 0
group by month



--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select
    plan_name
    ,count(*) "Count Of Events"
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where year(start_date) > 2020
group by plan_name

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select
count(distinct customer_id) as Churned_Customers
    ,(select count(distinct customer_id) from subscriptions) as Total_Customers
    , round(((Churned_Customers/Total_Customers)*100),1) as "% of Customers Churned"
from subscriptions
where plan_id = 4

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH CTE AS (
SELECT 
customer_id,
plan_name,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date ASC) as rn
FROM subscriptions as S
INNER JOIN plans as P on S.plan_id = P.plan_id
)
SELECT 
COUNT(DISTINCT customer_id) as churned_afer_trial_customers,
ROUND((COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100,0) as percent_churn_after_trial
FROM CTE
WHERE rn = 2
AND plan_name = 'churn';

--What is the number and percentage of customer plans after their initial free trial?

with CTE as( 
select *
,row_number() over(partition by customer_id order by start_date asc) as row_num
from subscriptions s
inner join plans p on p.plan_id = s.plan_id
) 

    select
    plan_name
    ,count(customer_id) as customer_count
    ,round((count(customer_id) / (select count(distinct customer_id) from CTE))*100,1) as customer_percent
    from CTE
    where row_num = 2
    group by plan_name



--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with CTE as( 
select *
,row_number() over(partition by customer_id order by start_date desc) as row_num
from subscriptions
where start_date <= '2020-12-31'
) 

    select
    plan_name
    ,count(customer_id) as customer_count
    ,round((count(customer_id) / (select count(distinct customer_id) from CTE))*100,1) as customer_percent
    from CTE
    inner join plans p on p.plan_id = CTE.plan_id
    where row_num = 1
    group by plan_name

--How many customers have upgraded to an annual plan in 2020?


select 
count(distinct customer_id) as upgraded_customers
from subscriptions s
inner join plans p on p.plan_id = s.plan_id
where year(start_date) = '2020'
and plan_name = 'pro annual'

--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with trial_start as (
    select
    customer_id
    ,start_date as trial_begins
    from subscriptions
    where plan_id = 0
)
    ,annual_start as (
    select 
    customer_id
    ,start_date as annual_begins
    from subscriptions
    where plan_id = 3
    )
    
    , avg_days as (
        select     
    round(avg(datediff('days',trial_begins,annual_begins)),0) as avg_annual_upgrade_days
    from trial_start as t
    inner join annual_start a on t.customer_id = a.customer_id
    ) 
    select 
    avg_annual_upgrade_days

--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with trial_start as (
    select
    customer_id
    ,start_date as trial_begins
    from subscriptions
    where plan_id = 0
)
    ,annual_start as (
    select 
    customer_id
    ,start_date as annual_begins
    from subscriptions
    where plan_id = 3
    )
    
    ,avg_days as (
    select     
    round(avg(datediff('days',trial_begins,annual_begins)),0) as avg_annual_upgrade_days
    from trial_start as t
    inner join annual_start a on t.customer_id = a.customer_id
    ) 
    
    select 
    case
        when datediff('days',trial_begins,annual_begins)<=30  then '0-30'
        when datediff('days',trial_begins,annual_begins)<=60  then '31-60'
        when datediff('days',trial_begins,annual_begins)<=90  then '61-90'
        when datediff('days',trial_begins,annual_begins)<=120  then '91-120'
        when datediff('days',trial_begins,annual_begins)<=150  then '121-150'
        when datediff('days',trial_begins,annual_begins)<=180  then '151-180'
        when datediff('days',trial_begins,annual_begins)<=210  then '181-210'
        when datediff('days',trial_begins,annual_begins)<=240  then '211-240'
        when datediff('days',trial_begins,annual_begins)<=270  then '241-270'
        when datediff('days',trial_begins,annual_begins)<=300  then '271-300'
        when datediff('days',trial_begins,annual_begins)<=330  then '301-330'
        when datediff('days',trial_begins,annual_begins)<=360  then '331-360'
end as Bins,
COUNT(T.customer_id) as customer_count
FROM trial_start as t
INNER JOIN annual_start as a on t.customer_id = a.customer_id
GROUP BY 1;


--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with pro_monthly as(
select
customer_id
,start_date as pro_month_start
from subscriptions 
where plan_id = 2
)
, basic_monthly as(
select 
customer_id
,start_date as bas_month_start
from subscriptions 
where plan_id = 1
)
select 
pro.customer_id
, pro_month_start
,bas_month_start
from pro_monthly pro
inner join basic_monthly bas on pro.customer_id = bas.customer_id
where bas_month_start > pro_month_start
and year(bas_month_start) = 2020
