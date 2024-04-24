-- How many unique nodes are there on the Data Bank system?
select count(distinct node_id) as unique_nodes
from customer_nodes

-- What is the number of nodes per region?
select 
region_name
,count(distinct node_id) as nodes
from customer_nodes cn
join regions r on cn.region_id = r.region_id
group by region_name


-- How many customers are allocated to each region?
select 
region_name
,count(distinct customer_id) as total_nodes
from customer_nodes cn
join regions r on cn.region_id = r.region_id
group by region_name

-- How many days on average are customers reallocated to a different node?
with days_in_node as (
select 
customer_id
,node_id
,sum(datediff('days',start_date,end_date)) as days_in_node
from customer_nodes
where end_date <> '9999-12-31'
group by customer_id
,node_id
)
select 
round(avg(days_in_node),0) as avg_days_in_node
from days_in_node

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with days_in_node as (
    select 
        region_name
        ,customer_id
        ,node_id
        ,sum(datediff('days',start_date,end_date)) as days_in_node
    from customer_nodes cn
        inner join regions r on cn.region_id = r.region_id
    where end_date <> '9999-12-31'
    group by region_name 
            ,customer_id
            ,node_id
)
select
region_name
,round(avg(days_in_node), 0) as avg_days_in_node
,round(median(days_in_node),0) as med_days_in_node
,round(percentile_cont(0.80) within group (order by days_in_node),0) as pc80_days_in_node
,round(percentile_cont(0.95) within group (order by days_in_node),0) as pc95_days_in_node
from days_in_node
group by region_name