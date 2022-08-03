Case Study Questions
Each of the following case study questions can be answered using a single SQL statement:

1-What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) as total_amount
FROM dannys_diner.menu
JOIN dannys_diner.sales
ON menu.product_id = sales.product_id
GROUP BY customer_id
ORDER BY 1;
--2-How many days has each customer visited the restaurant?
SELECT customer_id, COUNT( DISTINCT order_date) as days_count
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id
--3-What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT
    sales.customer_id,
    RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY sales.order_date
    ) AS order_rank,
    menu.product_name
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
)
SELECT DISTINCT
  customer_id,
  product_name
FROM ordered_sales
WHERE order_rank = 1;
--4-What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name,count(sales.product_id) as item_count
FROM dannys_diner.sales join
     dannys_diner.menu
ON menu.product_id = sales.product_id
GROUP BY menu.product_name
ORDER BY item_count DESC
LIMIT 1;
--5_Which item was the most popular for each customer?
WITH popular_item as (
SELECT sales.customer_id as customer_id,COUNT(sales.product_id) as item_count, RANK() over(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) 
as item_rank, menu.product_name as product_name
FROM dannys_diner.sales Join dannys_diner.menu
ON menu.product_id = sales.product_id
GROUP BY sales.customer_id,menu.product_name
ORDER BY sales.customer_id
)
SELECT customer_id,product_name,item_count
FROM popular_item
WHERE item_rank =1;
--6-Which item was purchased first by the customer after they became a member?
WITH first_item as (
SELECT members.customer_id as customer_id, members.join_date as join_date, sales.order_date as order_date,sales.product_id as product_id ,
rank() over( PARTITION BY sales.customer_id ORDER BY order_date) as item_rank
FROM dannys_diner.sales
JOIN dannys_diner.members
ON members.customer_id=sales.customer_id
WHERE   order_date > join_date
)
SELECT customer_id,join_date,order_date,menu.product_name, item_rank
FROM dannys_diner.menu
JOIN first_item
ON menu.product_id= first_item.product_id
WHERE item_rank >= 1
ORDER BY customer_id;
--7-Which item was purchased just before the customer became a member?
WITH first_item as (
SELECT members.customer_id as customer_id, members.join_date as join_date, sales.order_date as order_date,sales.product_id as product_id ,
rank() over( PARTITION BY sales.customer_id ORDER BY order_date DESC) as item_rank
FROM dannys_diner.sales
JOIN dannys_diner.members
ON members.customer_id=sales.customer_id
WHERE   order_date < join_date
)
SELECT customer_id,join_date,order_date,menu.product_name, item_rank
FROM dannys_diner.menu
JOIN first_item
ON menu.product_id= first_item.product_id
WHERE item_rank = 1
ORDER BY customer_id;
--8-What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, sum(price) as total_amount, sum( DISTINCT sales.product_id) as total_item
FROM dannys_diner.menu
JOIN dannys_diner.sales
ON menu.product_id = sales.product_id
JOIN dannys_diner.members
ON members.customer_id = sales.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id
ORDER BY 1;
--9-If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,
sum(case when product_name ='sushi' then price*2*10
    else price*10 end) as points
FROM dannys_diner.menu
JOIN dannys_diner.sales
ON menu.product_id = sales.product_id
GROUP BY customer_id
ORDER BY customer_id;
--10-In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
SELECT sales.customer_id,
sum(case when order_date>= join_date AND order_date <= join_date +6 then price*2*10
        when product_name ='sushi' then price*2*10
        else price*10 end) as points
FROM dannys_diner.menu
JOIN dannys_diner.sales
ON menu.product_id = sales.product_id
JOIN dannys_diner.members
ON sales.customer_id = members.customer_id
WHERE order_date>= '2021-01-01' AND order_date <= '2021-01-31'
GROUP BY sales.customer_id
ORDER BY sales.customer_id;
Bonus Questions
--11-Join all the things.
SELECT sales.customer_id,sales.order_date,menu.product_name,menu.price,	
(case when order_date>= join_date  then 'Y'
        else 'N' end) as member
FROM dannys_diner.menu
JOIN dannys_diner.sales
ON menu.product_id = sales.product_id
 left JOIN dannys_diner.members
ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id,sales.order_date;
--12-Rank all the things
WITH rank_all as(
SELECT sales.customer_id as customer_id,sales.order_date as order_date,menu.product_name as product_name,menu.price as price,
(case when order_date>= join_date  then 'Y'
        else 'N' end) as member
FROM dannys_diner.menu
JOIN dannys_diner.sales
ON menu.product_id = sales.product_id
 left JOIN dannys_diner.members
ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id,sales.order_date)
SELECT customer_id,order_date,product_name,price,member,case when member = 'N' then null else
        rank()over(partition by customer_id,member order by order_date)end  ranking
FROM rank_all
GROUP BY customer_id,order_date,product_name,price,member;

