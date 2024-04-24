-- Part 1
-- Part 2a

-- 1. what is the most ordered item based on the number of times it appears in an order cart that checked out successfully?
--    you are expected to return the product_id, and product_name and num_times_in_successful_orders.

with successful_orders as (
select
	order_id
from alt_school.orders
where status = 'success'
)

-- first off, I filtered the total successful orders (2,998) from 'altschool.orders' using a cte
-- then, I used the 'order_ids' of successful orders to filter the instances (10,673) of items in line_items with a successful order.
-- I then did a count aggregate of the instances of items with successful orders by their product_id and product_name,
-- ordered by the number of occurrences in descending order, and returned the first one (the most ordered item).

select
	li.item_id as product_id,
	p.name as product_name,
	count(so.order_id) as num_times_in_successful_orders
from successful_orders so
join alt_school.line_items li on so.order_id = li.order_id
join alt_school.products p on li.item_id = p.id
group by
    product_id, 
    product_name
order by num_times_in_successful_orders desc
limit 1;

-- Answer: The most ordered item is "Apple Airpods Pro" (product_id: 7), it was successfully checked out 735 times.


-- 2. without considering currency, and without using the line_item table, find the top 5 spenders
--    you are exxpected to return the customer_id, location, total_spend


with spenders as (
	select
		e.customer_id as customer_id,
		c.location as location
	from alt_school.events e
	join alt_school.customers c on e.customer_id = c.customer_id
	where event_data ->> 'event_type' = 'checkout' and event_data ->> 'status' = 'success'
)

-- first off, I selected the customers who successfully checked out, from the events table [along with their respective locations] using a cte
-- then I did a sum aggregation of the products they bought * their unit prices

select
	s.customer_id,
	s.location,
	sum(coalesce((event_data ->> 'quantity')::int, 0) * p.price) as total_spend
from spenders s
join alt_school.events e on s.customer_id = e.customer_id 
join alt_school.products p on (e.event_data->> 'item_id')::int = p.id
group by
	s.customer_id, s.location
order by total_spend desc
limit 5;


-- Part 2b
-- 1. using the events table, Determine the most common location (country) where successful checkouts occurred. return location and checkout_count


-- Simply joined the customers table with the events table filtering customers with successful checkouts
-- then grouping by location and selecting the highest

select
	c.location as location,
--	count(o.customer_id) as checkout_count
	count(e.customer_id) as checkout_count
from alt_school.customers c 
--join alt_school.orders o on o.customer_id = c.customer_id
--where status = 'success'
join alt_school.events e on e.customer_id = c.customer_id
where
	event_data ->> 'event_type' = 'checkout' and
	event_data ->> 'status' = 'success'
group by c.location
order by checkout_count desc
limit 1;

-- Answer: Korea 17

-- 2. using the events table, identify the customers who abandoned their carts and count the number of events (excluding visits)
-- that occurred before the abandonment. return the customer_id and num_events

with ab_cart as (
	select
		customer_id,
		(event_data ->> 'timestamp')::timestamp as timestamp
	from
		alt_school.events e 
	where
		event_data ->> 'event_type' = 'checkout' and 
		event_data ->> 'status' <> 'success'
)

-- Created a cte to filter the customers who abandoned their carts along with the timestamp of the events
--  then joined it with the events table using the customer_id, filtering out the visit and checkout events.
--  counting the total number of events that occured before the abandonment.

select
	ac.customer_id,
	count(*) num_events -- excluding visits and the cart abandonment event
from ab_cart ac
join alt_school.events e on ac.customer_id = e.customer_id
where
	event_data ->> 'event_type' <> 'visit' and
	event_data ->> 'event_type' <> 'checkout' and 
	(event_data ->> 'timestamp')::timestamp < ac.timestamp
group by ac.customer_id


-- 3. Find the average number of visits per customer, considering only customers who completed a checkout! 
--    return average_visits to 2 decimal place

with co_customers as (
	select
		customer_id
	from alt_school.events e 
	where
		event_data ->> 'status' = 'success'
),

-- filtered customers who have successfully checked out before using a cte,
-- then I found the number of visits per customer, and found the average and
-- rounded it to two decimal places

visits as (
	select 
		e.customer_id,
		count(*) as visits
	from alt_school.events e 
	where
		e.customer_id in (select customer_id from co_customers) and
		event_data ->> 'event_type' = 'visit'
	group by customer_id 
)

select
	round(avg(v.visits), 2) as average_visits
from visits v

-- Answer: 4.47