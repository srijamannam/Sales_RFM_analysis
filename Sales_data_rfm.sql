/*Inspecting data*/ 
SELECT * FROM sales_data_rfm.sales_data_sample; 

/*checking unique values*/
SELECT DISTINCT YEAR_ID FROM sales_data_rfm.sales_data_sample;
SELECT DISTINCT PRODUCTLINE FROM sales_data_rfm.sales_data_sample;
SELECT DISTINCT DEALSIZE FROM sales_data_rfm.sales_data_sample;
SELECT DISTINCT COUNTRY FROM sales_data_rfm.sales_data_sample;
SELECT DISTINCT TERRITORY FROM sales_data_rfm.sales_data_sample;

select distinct MONTH_ID from sales_data_rfm.sales_data_sample
where year_id = 2003


/*ANALYSIS*/

select PRODUCTLINE, sum(sales) AS Revenue
from sales_data_rfm.sales_data_sample
group by PRODUCTLINE
order by 2 desc;

select YEAR_ID, sum(sales) Revenue
from sales_data_rfm.sales_data_sample
group by YEAR_ID
order by 2 desc;

select distinct MONTH_ID from sales_data_rfm.sales_data_sample
where year_id = 2005
/*IN 2005 They only operated for 5 months ,hence the low revenue */

select DEALSIZE, sum(sales) Revenue
from sales_data_rfm.sales_data_sample
group by DEALSIZE
order by 2 desc;

/*Since 2004 was the most profitable year , we try and find out which month had the most sales */

SELECT MONTH_ID ,SUM(SALES) REVENUE,COUNT(ORDERNUMBER)
FROM Sales_data_rfm.sales_data_sample
WHERE YEAR_ID=2004
GROUP BY MONTH_ID
ORDER BY 2 DESC;

/*Novemeber is when most of the revenue is genearted , we then try and find out whuch product is sold the most during this time */

select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
from Sales_data_rfm.sales_data_sample
where YEAR_ID = 2004 and MONTH_ID = 11 
group by  MONTH_ID, PRODUCTLINE
order by 3 desc;

/* As expected it was classic cars that was sold the most and contributed to the revenue the most */

/* who is the best customer */

DROP TABLE IF EXISTS #rfmtemp
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from sales_data_sample) max_order_date,
		DATEDIFF((select max(ORDERDATE) from sales_data_sample), MAX(ORDERDATE)) Recency
	from sales_data_rfm.sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)

select c.*,
	rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell, 
    cast(rfm_recency as char) + cast(rfm_frequency as char) + cast(rfm_monetary  as char)rfm_cell_string
	into #rfm 
from rfm_calc c;


select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  -- lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' -- (Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm


# Which products are sold together 

select distinct OrderNumber, stuff(
	(select ',' + PRODUCTCODE
	from sales_data_rfm.sales_data_sample p
	where ORDERNUMBER in 
		(
			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_rfm.sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER)
		for xml path ('')), 1, 1, '') ProductCodes
from sales_data_rfm.sales_data_sample s
order by 2 desc



-- What city has the highest number of sales in a specific country
select city, sum(sales) Revenue
from sales_data_rfm.sales_data_sample
where country = 'UK'
group by city
order by 2 desc;



--- What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data_rfm.sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc;