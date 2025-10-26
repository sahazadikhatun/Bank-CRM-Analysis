use bank_crm_project;
-- Subjective Q_1
select 
	case
		when Tenure > 4 then "Long-Term"
        else "New"
    end  as CustomerType,
    count(CustomerID) as NoOfCustomer,
    round(avg(Balance),2) as AvgBalance,
    round(avg(NumOfProducts),2) as AvgProducts,
    round(avg(CreditScore),2) as AvgCreditScore
from bank_churn
group by CustomerType
order by CustomerType;

-- Subjective Q_2
with ProductCombination as(select  
	CustomerID,
    NumOfProducts,
    case
		when NumOfProducts=1 then "SavingsAccount"
        when NumOfProducts = 2 then "SavingsAccount,CreditCard"
        when NumOfProducts = 3 then "SavingsAccount,CreditCard,Loan"
        when NumOfProducts >=4 then "SavingsAccount,CreditCard,Loan,InvestmentAccount"
    end as ProductsName
from bank_churn),
CustCount as (
select 
	ProductsName,
    count(CustomerID) as customer_count
from ProductCombination
group by ProductsName)

select 
	ProductsName,
    customer_count,
    round((100*customer_count/(select count(CustomerID) from bank_churn)),2) as product_percent
from CustCount;


-- Subjective Q_3
with cust_count_region as(
select 
    t1.GeographyID,
    t3.GeographyLocation,
    count(t1.CustomerID) as ChurnedCustomerCount
from customerinfo t1
join bank_churn t2
on t1.CustomerID= t2.CustomerID
join geography t3 
on t1.GeographyID=t3.GeographyID
where ExitID =1
group by   t1.GeographyID,t3.GeographyLocation),

cust_C as(
select GeographyID,count(t2.CustomerID) as c
from customerinfo t1
join bank_churn t2
on t1.CustomerID= t2.CustomerID
group by GeographyID)


select 
	t1.GeographyID,
    GeographyLocation,
    ChurnedCustomerCount,
    round((100*ChurnedCustomerCount/c),2) as churn_percent
from cust_count_region t1
join cust_C t2
on t1.GeographyID=t2.GeographyID;


-- Subjective Q_4

SELECT 
  g.GeographyLocation,
  AVG(bc.CreditScore) AS AvgCreditScore,
  SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS NumChurned,
  COUNT(*) AS TotalCustomers,
  ROUND(100.0 * SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / COUNT(*), 2) AS ChurnRate
FROM CustomerInfo ci
JOIN Bank_Churn bc ON ci.CustomerID = bc.CustomerID
JOIN Geography g ON ci.GeographyID = g.GeographyID
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY g.GeographyLocation;

SELECT 
  gen.GenderCategory,
  AVG(bc.CreditScore) AS AvgCreditScore,
  ROUND(100.0 * SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / COUNT(*), 2) AS ChurnRate
FROM CustomerInfo ci
JOIN Bank_Churn bc ON ci.CustomerID = bc.CustomerID
JOIN Gender gen ON ci.GenderID = gen.GenderID
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY gen.GenderCategory;


-- Subjective Q_5
SELECT 
    ci.CustomerID,
    ci.Age,
    ci.EstimatedSalary,
    geo.GeographyLocation,
    bc.CreditScore,
    bc.Tenure,
    bc.Balance,
    bc.NumOfProducts,
    cc.Category AS CreditCardCategory,
    ac.ActiveCategory,
    ec.ExitCategory,
    ROUND(DATEDIFF(CURDATE(), ci.Bank_DOJ) / 365, 2) AS CurrentTenureYears,
    CASE WHEN ec.ExitCategory = 'Yes' THEN 1 ELSE 0 END AS IsChurned
FROM CustomerInfo ci
JOIN Geography geo ON ci.GeographyID = geo.GeographyID
JOIN Bank_Churn bc ON ci.CustomerID = bc.CustomerID
LEFT JOIN CreditCard cc ON bc.CreditID = cc.CreditID
LEFT JOIN ActiveCustomer ac ON bc.ActiveID = ac.ActiveID
LEFT JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
limit 10;

-- Subjective Q_7
-- Churn Rate by Geography
SELECT 
  g.GeographyLocation,
  ROUND(100.0 * SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / COUNT(*), 2) AS ChurnRate
FROM CustomerInfo ci
JOIN Bank_Churn bc ON ci.CustomerID = bc.CustomerID
JOIN Geography g ON ci.GeographyID = g.GeographyID
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY g.GeographyLocation;

-- Credit Score vs Exit Category
SELECT 
  CASE 
    WHEN bc.CreditScore < 500 THEN 'Low (<500)'
    WHEN bc.CreditScore BETWEEN 500 AND 700 THEN 'Medium (500-700)'
    ELSE 'High (>700)'
  END AS CreditBand,
  ROUND(100.0 * SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / COUNT(*), 2) AS ChurnRate
FROM Bank_Churn bc
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY CreditBand;

-- Tenure & Churn
SELECT 
  CASE 
    WHEN bc.Tenure < 3 THEN 'Short (<3 yrs)'
    WHEN bc.Tenure BETWEEN 3 AND 7 THEN 'Medium (3–7 yrs)'
    ELSE 'Long (>7 yrs)'
  END AS TenureGroup,
  ROUND(100.0 * SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / COUNT(*), 2) AS ChurnRate
FROM Bank_Churn bc
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY TenureGroup;

-- Product Count and Churn
SELECT 
  bc.NumOfProducts,
  ROUND(100.0 * SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / COUNT(*), 2) AS ChurnRate
FROM Bank_Churn bc
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY bc.NumOfProducts;

-- Subjective Q_9

-- By Age Group
SELECT 
  CASE 
    WHEN ci.Age < 30 THEN 'Young (<30)'
    WHEN ci.Age BETWEEN 30 AND 50 THEN 'Middle Age (30–50)'
    ELSE 'Senior (>50)'
  END AS AgeGroup,
  COUNT(*) AS TotalCustomers
FROM CustomerInfo ci
GROUP BY AgeGroup
ORDER BY TotalCustomers DESC;

-- By Geography and Gender
SELECT 
  g.GeographyLocation,
  gen.GenderCategory,
  COUNT(*) AS NumCustomers
FROM CustomerInfo ci
JOIN Geography g ON ci.GeographyID = g.GeographyID
JOIN Gender gen ON ci.GenderID = gen.GenderID
GROUP BY g.GeographyLocation, gen.GenderCategory
ORDER BY g.GeographyLocation;

-- By Number of Products
SELECT 
  bc.NumOfProducts,
  COUNT(*) AS TotalCustomers
FROM Bank_Churn bc
GROUP BY bc.NumOfProducts
ORDER BY bc.NumOfProducts;
 -- By Tenure Group
 SELECT 
  CASE 
    WHEN bc.Tenure < 3 THEN 'New (<3 yrs)'
    WHEN bc.Tenure BETWEEN 3 AND 7 THEN 'Established (3–7 yrs)'
    ELSE 'Loyal (>7 yrs)'
  END AS TenureSegment,
  COUNT(*) AS TotalCustomers
FROM Bank_Churn bc
GROUP BY TenureSegment
ORDER BY TotalCustomers DESC;
-- By Activity and Churn Status
SELECT 
  ac.ActiveCategory,
  ec.ExitCategory,
  COUNT(*) AS NumCustomers
FROM Bank_Churn bc
JOIN ActiveCustomer ac ON bc.ActiveID = ac.ActiveID
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY ac.ActiveCategory, ec.ExitCategory;

-- Combine Demographic + Account Segmentation
SELECT 
  g.GeographyLocation,
  CASE 
    WHEN ci.Age < 30 THEN 'Young (<30)'
    WHEN ci.Age BETWEEN 30 AND 50 THEN 'Middle Age (30–50)'
    ELSE 'Senior (>50)'
  END AS AgeGroup,
  bc.NumOfProducts,
  ac.ActiveCategory,
  COUNT(*) AS SegmentCount
FROM CustomerInfo ci
JOIN Bank_Churn bc ON ci.CustomerID = bc.CustomerID
JOIN Geography g ON ci.GeographyID = g.GeographyID
JOIN ActiveCustomer ac ON bc.ActiveID = ac.ActiveID
GROUP BY g.GeographyLocation, AgeGroup, bc.NumOfProducts, ac.ActiveCategory
ORDER BY g.GeographyLocation, AgeGroup;


-- Subjective Q_10
SELECT 
    c.CustomerID,
    c.Surname,
    g.GenderCategory AS Gender,
    geo.GeographyLocation AS Geography,
    b.CreditScore,
    CASE
        WHEN b.CreditScore < 500 THEN 'High Risk'
        WHEN b.CreditScore BETWEEN 500 AND 700 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS CreditScoreCategory,
    
    b.Tenure,
    CASE
        WHEN b.Tenure >= 3 THEN 'Loyal'
        ELSE 'Potential Churn Risk'
    END AS TenureCategory,
    
    b.Balance,
    CASE
        WHEN b.Balance < 30000 THEN 'Financially Vulnerable'
        WHEN b.Balance BETWEEN 30001 AND 80000 THEN 'Moderate Risk'
        ELSE 'Financially Secure'
    END AS BalanceCategory,
    
    b.NumOfProducts,
    cc.Category AS CreditCardType,
    ac.ActiveCategory AS ActiveStatus,
    ec.ExitCategory AS ExitStatus
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerID = b.CustomerID
JOIN Gender g ON c.GenderID = g.GenderID
JOIN Geography geo ON c.GeographyID = geo.GeographyID
JOIN CreditCard cc ON b.CreditID = cc.CreditID
JOIN ActiveCustomer ac ON b.ActiveID = ac.ActiveID
JOIN ExitCustomer ec ON b.ExitID = ec.ExitID;


-- Subjective_Q11
-- Query for Yearly Churn Rate
SELECT 
    YEAR(ci.Bank_DOJ) AS YearJoined,
    COUNT(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 END) AS ChurnedCustomers,
    COUNT(*) AS TotalCustomers,
    ROUND(100.0 * COUNT(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 END) / COUNT(*), 2) AS ChurnRatePercent
FROM CustomerInfo ci
JOIN Bank_Churn bc ON ci.CustomerID = bc.CustomerID
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY YEAR(ci.Bank_DOJ)
ORDER BY YearJoined;

-- Query for Overall Churn Rate
SELECT 
    COUNT(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 END) AS TotalChurned,
    COUNT(*) AS TotalCustomers,
    ROUND(100.0 * COUNT(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 END) / COUNT(*), 2) AS OverallChurnRate
FROM Bank_Churn bc
JOIN ExitCustomer ec ON bc.ExitID = ec.ExitID;


-- Subjective_Q12







ALTER TABLE Bank_Churn
RENAME COLUMN CreditID TO Has_creditcard;
select * from Bank_Churn;
