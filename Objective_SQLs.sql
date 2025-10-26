use bank_crm_project;
--  the distribution of account balances across different regions
select 
	t3.GeographyLocation,
	sum(Balance) as TotalBalance,
    avg(Balance) as AvgBalanece,
    count(*) as CountCustomer
from bank_churn t1
join customerinfo t2
on t1.CustomerID=t2.CustomerID 
join geography t3
on t2.GeographyID=t3.GeographyID
group by t3.GeographyLocation;


-- the top 5 customers with the highest Estimated Salary in the last quarter of the year.
select 
	CustomerID,Surname,Bank_DOJ,
    EstimatedSalary
from customerinfo
activecustomer
where month(Bank_DOJ) in (10,11,12)
order by EstimatedSalary desc
limit 5;

-- Calculate the average number of products used by customers who have a credit card.
select Round(avg(NumOfProducts),2) as AvgNumOfProducts
from bank_churn 	
where CreditID = 1;

-- Determine the churn rate by gender for the most recent year in the dataset.

with most_recent_year as(
select max(year(Bank_DOJ)) as  latest_year from customerinfo),

churn_data as(select 
    GenderCategory,
    sum(case when t1.ExitID = 1 then 1 else 0 end) as ExitCustomerCount,
    count(*) as TotalCustomerCount    
from bank_churn t1 
join customerinfo t2
on t1.CustomerID = t2.CustomerID
join exitcustomer t3
on t1.ExitID = t3.ExitID
join gender t4
on t2.GenderID = t4.GenderID
where year(Bank_DOJ) = (select latest_year from most_recent_year)
group by GenderCategory)
select 
	GenderCategory,
	ExitCustomerCount,
    TotalCustomerCount,
    round((100*ExitCustomerCount/TotalCustomerCount),2) as Churn_Rate
from churn_data
group by GenderCategory;

-- Compare the average credit score of customers who have exited and those who remain.

select t1.ExitID,ExitCategory,
	avg(CreditScore)  as AvgCreditScore
from bank_churn t1 
join customerinfo t2
on t1.CustomerID = t2.CustomerID
join exitcustomer t3
on t1.ExitID = t3.ExitID
group by ExitID,ExitCategory;

-- Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?
select 
	t1.GenderID,
	GenderCategory,
    round(avg(EstimatedSalary),2) as AvgEstimatedSalary,
    count(case when t4.ActiveID = 1 then 1 end) as ActiveAccountsCount
from customerinfo t1
join gender t2
on t1.GenderID = t2.GenderID 
join bank_churn t3
on t1.CustomerID=t3.CustomerID
join activecustomer t4
on t3.ActiveID = t4.ActiveID
group by t1.GenderID,GenderCategory;

-- Segment the customers based on their credit score and identify the segment with the highest exit rate.
-- Exceptional: 800 to 850
-- Very good: 740 to 799
-- Good: 670 to 739
-- Fair: 580 to 669
-- Poor: 300 to 579
select 
	Segment,
	sum(case when ExitID = 1 then 1 else 0 end) as exitcustcount,
    count(*) as total_cust_count,
    round((100*sum(case when ExitID = 1 then 1 else 0 end)/count(*)),2) as exit_rate
from(
select 
	CustomerID,
    ExitID,
    case
		when CreditScore between 800 and 850 then "Exceptional"
        when CreditScore between 740 and 799 then "Very Good"
        when CreditScore between 670 and 739 then "Good"
        when CreditScore between 580 and 669 then "Fair"
        when CreditScore between 300 and 579 then "Poor"
    end as Segment
from bank_churn)p1
group by Segment
order by exit_rate desc;

-- Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.

select 
    t1.GeographyID,
    t3.GeographyLocation,
    count(t1.CustomerID) as ActiveCustomerCount
from customerinfo t1
join bank_churn t2
on t1.CustomerID= t2.CustomerID
join geography t3 
on t1.GeographyID=t3.GeographyID
where ActiveID = 1 and t2.Tenure > 5
group by t1.GeographyID,GeographyLocation
order by ActiveCustomerCount desc;


-- What is the impact of having a credit card on customer churn, based on the available data?
select
	t2.Category,
    count(*) as TotalCustomer,
    sum(case when ExitID = 1 then 1 else 0 end) as ExitCustomer,
    round((100*sum(case when ExitID = 1 then 1 else 0 end)/count(*)),2) as chrun_rate
from bank_churn t1 
join creditcard t2
on t1.CreditID = t2.CreditID
group by t2.Category
order by chrun_rate desc;

-- For customers who have exited, what is the most common number of products they have used?
select 
	NumOfProducts,
    count(*) as CommonProductsCustomerCount
from bank_churn
where ExitID = 1
group by NumOfProducts
order by CommonProductsCustomerCount desc;

-- Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). 
-- Prepare the data through SQL and then visualize it.
select
	year(Bank_DOJ) as Year,
    count(CustomerID) as YearlyJoinedCust
from customerinfo
group by year(Bank_DOJ)
order by Year;

select
	month(Bank_DOJ) as Month,
    monthname(Bank_DOJ) as MonthName,
    count(CustomerID) as MonthlyJoinedCust
from customerinfo
group by month(Bank_DOJ),monthname(Bank_DOJ)
order by Month;

-- Analyze the relationship between the number of products and the account balance for customers who have exited.

select 
	NumOfProducts,
    count(*) as CommonProductsCustomerCount,
     Avg(Balance) as AvgAccountBalance,
      sum(Balance) as TotalAccountBalance
from bank_churn t1
where ExitID = 1
group by NumOfProducts
order by AvgAccountBalance desc;

-- Identify any potential outliers in terms of balance among customers who have remained with the bank.
with Final as (
select 
	CustomerID,
    Balance,
	row_number() over(order by Balance) as rn,
    count(*) over() as n
from bank_churn
where ActiveID = 1
),
First_Quartile as(
select 
	CustomerID,
    Balance,
    rn as First_Q
from final
where rn = (n+1)/4),
Third_Quartile as(
select 
	CustomerID,
    Balance,
    rn as Third_Q
from final
where rn = (3*(n+1)/4)),

InterQuartileRange as(
select Balance-(select Balance from First_Quartile) as IQR
from Third_Quartile),
Lower_Limit as(
select 
	Balance - 
		(1.5*(select IQR from InterQuartileRange)) as low
from First_Quartile),
Upper_Limit as(
select 
	Balance +
		(1.5*(select IQR from InterQuartileRange)) as up
from Third_Quartile)
select CustomerID,Balance
from final
where Balance not between (select low from Lower_Limit) and (select up from Upper_Limit);

-- Using SQL, write a query to find out the gender-wise average income of males and
-- females in each geography id. Also, rank the gender according to the average value
select 
	t1.GenderID,
    t2.GenderCategory,
    t1.GeographyID,
    t3.GeographyLocation,
    t1.AvgIncome,
    rank() over(partition by GenderCategory order by AvgIncome desc) as rnk
from(
select 
	GenderID,
    GeographyID,
    Round(avg(EstimatedSalary),2) as AvgIncome
from customerinfo
group by GenderID,GeographyID) t1
join Gender t2
on t1.GenderID = t2.GenderID
join Geography t3
on t1.GeographyID= t3.GeographyID
order by AvgIncome desc;

-- Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
select 
	age_bracket,
    Avg(Tenure) as AvgTenure
from(
select 
	t1.CustomerID,
	Age,
    Tenure,
    (case
		when Age between 18 and 30 then "18-30"
        when Age between 31 and 50 then "31-50"
        when Age >50 then "50+"
    end) as age_bracket
from bank_churn t1
join customerinfo t2
on t1.CustomerID = t2.CustomerID
where ExitID = 1)p
group by age_bracket
order by age_bracket;

-- Is there any direct correlation between salary and the balance of the customers? 
-- And is it different for people who have exited or not?

SELECT
	t1.CustomerID,
    t2.Surname as CustomerName,
    EstimatedSalary AS CustomerSalary,
    Balance AS CustomerBalance,
    t3.ExitCategory
from bank_churn t1
join customerinfo t2
on t1.CustomerID = t2.CustomerID
join exitcustomer t3
on t1.ExitID = t3.ExitID
where t1.ExitID = 1
order by CustomerBalance desc
limit 5 ;

SELECT
	t1.CustomerID,
    t2.Surname as CustomerName,
    EstimatedSalary AS CustomerSalary,
    Balance AS CustomerBalance,
	t3.ExitCategory
from bank_churn t1
join customerinfo t2
on t1.CustomerID = t2.CustomerID
join exitcustomer t3
on t1.ExitID = t3.ExitID
where t1.ExitID = 0
order by CustomerBalance desc
limit 5;


-- Is there any correlation between the salary and the Credit score of customers?

SELECT
	t1.CustomerID,
    t2.Surname as CustomerName,
    EstimatedSalary AS CustomerSalary,
    CreditScore,
	Category
from bank_churn t1
join customerinfo t2
on t1.CustomerID = t2.CustomerID
join creditcard t3
on t1.CreditID = t3.CreditID
order by CustomerSalary desc;

-- Rank each bucket of credit  score as per the number of customers who have churned the bank.
select *,
		rank() over(order by ChurnedCustomerCount) as ChurnedRank
from(
select 
	Segment,
    count(*) as ChurnedCustomerCount
from(
select 
	CustomerID,
    case
		when CreditScore between 800 and 850 then "Exceptional"
        when CreditScore between 740 and 799 then "Very Good"
        when CreditScore between 670 and 739 then "Good"
        when CreditScore between 580 and 669 then "Fair"
        when CreditScore between 300 and 579 then "Poor"
    end as Segment
from bank_churn
where  ExitID = 1)p
group by Segment) o
order by ChurnedRank;


-- The age buckets find the number of customers who have a credit card.
-- retrieve those buckets that have lesser than average number of credit cards per bucket.
with final as(select 
	age_bracket,
    count(CustomerID) as cust_count
from(
select 
	t1.CustomerID,
	Age,
    Tenure,
    (case
		when Age between 18 and 30 then "18-30"
        when Age between 31 and 50 then "31-50"
        when Age >50 then "50+"
    end) as age_bracket
from bank_churn t1
join customerinfo t2
on t1.CustomerID = t2.CustomerID
where t1.CreditID = 1)l
group by age_bracket)
select age_bracket, cust_count
from final
where cust_count<(select avg(cust_count) from final);

-- Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
with final as(select 
	t2.GeographyID,
	t3.GeographyLocation,
    count(*) as NoOfCustomer,
    avg(t1.Balance) as AvgBalance
from bank_churn t1
join customerinfo t2
on t1.CustomerID = t2.CustomerID
join Geography t3
on t2.GeographyID = t3.GeographyID
where ExitID = 1
group by t2.GeographyID,t3.GeographyLocation)

select 
	GeographyID,
    GeographyLocation,
    NoOfCustomer,
    dense_rank() over(order by NoOfCustomer desc) as cust_rank,
    AvgBalance,
    dense_rank() over(order by AvgBalance desc) as balance_rank
from final;

-- 
SELECT 
    CustomerID,
    Surname,
    CONCAT(CustomerID, '_', Surname) AS CustomerKey
FROM CustomerInfo
limit 10;

-- Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table?
select 
	CustomerID,
    Balance,
    ExitID,
    (select ExitCategory from exitcustomer where ExitID = t1.ExitID) as ExitCategory
from bank_churn t1
order by Balance desc
limit 10;


-- Missing Values
SELECT *
FROM customerinfo
WHERE CustomerID IS NULL
   OR Surname IS NULL
   OR Age IS NULL
   OR GenderID IS NULL
   OR EstimatedSalary IS NULL
   OR GeographyID IS NULL
   OR Bank_DOJ IS NULL;

SELECT *
FROM bank_churn
WHERE CustomerID IS NULL
   OR CreditScore IS NULL
   OR Tenure IS NULL
   OR Balance IS NULL
   OR NumOfProducts IS NULL
   OR CreditID IS NULL
   OR ActiveID IS NULL
   OR ExitID IS NULL;

-- get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
select 
	t1.CustomerID,
    Surname,
    ActiveCategory
from customerinfo t1
join bank_churn t2
on t1.CustomerID = t2.CustomerID
join activecustomer t3
on t2.ActiveID=t3.ActiveID
where t2.ActiveID in (0,1)
	and Surname like "%on"
    limit 10;

-- 
select * from bank_churn
where ActiveID = 1 and ExitID = 1;
SELECT 
    COUNT(*) AS Total_Discrepancies
FROM bank_churn
WHERE ExitID = 1 AND ActiveID = 1;

