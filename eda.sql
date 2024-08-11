CREATE TABLE `financials_staging` (
  `year` int DEFAULT NULL,
  `revenue` int DEFAULT NULL,
  `cogs` int DEFAULT NULL,
  `gross_profit` int DEFAULT NULL,
  `operating_income` int DEFAULT NULL,
  `net_income` int DEFAULT NULL,
  `earnings_per_share` double DEFAULT NULL,
  `dividends_paid` double DEFAULT NULL,
  `total_assets` int DEFAULT NULL,
  `total_liabilities` int DEFAULT NULL,
  `total_equity` int DEFAULT NULL,
  `operating_expenses` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into financials_staging
select * 
from walmart_financials;

select * 
from financials_staging;

-- revenue growth 

select year ,
revenue ,
lag(revenue) over(order by year) as previous_yr_revenue ,
round((revenue - lag(revenue) over(order by year) )  / lag(revenue) over(order by year) * 100 , 1) as revenue_growth_rate
from financials_staging;

-- profitability

select year , 
(gross_profit / revenue) * 100 as gross_margin ,
(operating_income / revenue) * 100 as operating_margin ,
(net_income / revenue) * 100 as net_margin 
from financials_staging;

-- financial health 

select year , 
(total_assets / total_liabilities) as current_ratio , 
(total_liabilities / revenue )  as debt_equity_ratio
from financials_staging;

-- stock performance 

create table stocks_staging 
like walmart_historical_stocks;

insert into stocks_staging
select *
from walmart_historical_stocks;

select *
from stocks_staging;

select `Date`, 
str_to_date(`Date` , '%Y-%m-%d' )
from stocks_staging;

update stocks_staging
set `Date` = str_to_date(`Date` , '%Y-%m-%d' );

alter table stocks_staging
modify column `Date` date;

select date , 
year(date) as Year
from stocks_staging;

alter table stocks_staging
add column Year INT;

update stocks_staging
set Year = year(date) ;

delete from stocks_staging
where Year = '2024';

select year , 
round(avg(`Adj Close`) , 2) as stock_price
from stocks_staging 
group by `Year`;

create table stock_price_staging as 
select  year , 
round(avg(`Adj Close`) , 2) as stock_price
from stocks_staging 
group by year ;

select * 
from stock_price_staging;

select fs.year , 
round((sps.stock_price / fs.earnings_per_share) , 2) as price_earnings_ratio
from financials_staging fs
join stock_price_staging sps	
on fs.year = sps.year;




-- historical volatality

select * 
from stocks_staging;

with dailyreturn_cte as
(
select Date ,
year ,
`Adj Close` as sp, 
lag(`Adj Close`) over(order by Date) as pr_day_sp ,
round((`Adj Close` - lag(`Adj Close`) over( partition by year order  by Date) )  / lag(`Adj Close`) over(partition by year order by Date)* 100 , 2) as daily_return
from stocks_staging
) , 
dailyvolatility_cte as
(
select  year , 
stddev_samp(daily_return) as daily_volatility 
from dailyreturn_cte
group by year
)
select  year , 
round(daily_volatility * sqrt(252) , 2) as annual_volatility
from dailyvolatility_cte;


