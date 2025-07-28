Create database TelcoCustomerChurn;
use TelcoCustomerChurn;

CREATE TABLE Dim_customer (
    Cus_id INT PRIMARY KEY,                    -- Primary Key on Cus_id
    customerID VARCHAR(MAX) NOT NULL,           -- Alphanumeric ID
    gender VARCHAR(10) NOT NULL,                -- Gender of the customer
    SeniorCitizen VARCHAR(10) NOT NULL CHECK (SeniorCitizen IN ('Yes', 'No')),  -- CHECK constraint for SeniorCitizen
    Partner VARCHAR(10) NOT NULL CHECK (Partner IN ('Yes', 'No')),             -- CHECK constraint for Partner
    Dependents VARCHAR(10) NOT NULL CHECK (Dependents IN ('Yes', 'No'))        -- CHECK constraint for Dependents
);


-- Create Service Dimension Table
CREATE TABLE Dim_service (
    Service_id INT PRIMARY KEY,                 -- Primary Key on Service_id
    PhoneService VARCHAR(10) NOT NULL,          -- Phone Service status
    MultipleLines VARCHAR(MAX) NOT NULL,         -- Multiple Lines status
    InternetService VARCHAR(200) NOT NULL,       -- Internet Service status
    OnlineSecurity VARCHAR(200) NOT NULL,        -- Online Security status
    OnlineBackup VARCHAR(200) NOT NULL,          -- Online Backup status
    DeviceProtection VARCHAR(200) NOT NULL,      -- Device Protection status
    TechSupport VARCHAR(MAX) NOT NULL,           -- Tech Support status
    StreamingTV VARCHAR(MAX) NOT NULL,           -- Streaming TV status
    StreamingMovies VARCHAR(MAX) NOT NULL        -- Streaming Movies status
);

-- Create Contract Dimension Table
CREATE TABLE Dim_contract (
    Contract_id INT PRIMARY KEY,                -- Primary Key on Contract_id
    Contract VARCHAR(MAX) NOT NULL,              -- Contract type (e.g., Monthly, Yearly)
    PaperlessBilling VARCHAR(100) NOT NULL CHECK (PaperlessBilling IN ('Yes', 'No')),  -- CHECK constraint for PaperlessBilling
    PaymentMethod VARCHAR(MAX) NOT NULL          -- Payment Method
);
-- create churn Fact Table
CREATE TABLE Fact_churn (
    Churn_id INT PRIMARY KEY,    -- Churn_id se uniquely identify
    Cus_id INT,
    Service_id INT,
    Contract_id INT,
    tenure INT NOT NULL CHECK (tenure >= 0),
    MonthlyCharges FLOAT NOT NULL CHECK (MonthlyCharges >= 0),
    TotalCharges FLOAT NOT NULL CHECK (TotalCharges >= 0),
    num_services INT NOT NULL CHECK (num_services >= 0),
    senior_alone INT NOT NULL CHECK (senior_alone IN (0, 1)),
    avg_monthly_spend FLOAT NOT NULL CHECK (avg_monthly_spend >= 0),
    has_internet INT NOT NULL CHECK (has_internet IN (0, 1)),
    high_value_customer INT NOT NULL CHECK (high_value_customer IN (0, 1)),
    Churn VARCHAR(100) NOT NULL CHECK (Churn IN ('Yes', 'No')),
    
    -- UNIQUE constraint on composite columns
    UNIQUE (Cus_id, Service_id, Contract_id),
    
    -- Foreign Key Constraints with names
    CONSTRAINT FK_FactChurn_Customer FOREIGN KEY (Cus_id) REFERENCES Dim_customer(Cus_id) ON DELETE CASCADE,
    CONSTRAINT FK_FactChurn_Service FOREIGN KEY (Service_id) REFERENCES Dim_service(Service_id) ON DELETE CASCADE,
    CONSTRAINT FK_FactChurn_Contract FOREIGN KEY (Contract_id) REFERENCES Dim_contract(Contract_id) ON DELETE CASCADE
);

select * from Dim_customer;
select * from Dim_service;
select * from Dim_contract;
select * from Fact_churn;


--Perform joining between the tables
SELECT 
    fc.Churn_id,
    
    -- Customer details
    dc.customerID,
    dc.gender,
    dc.SeniorCitizen,
    dc.Partner,
    dc.Dependents,
    
    -- Service details
    ds.PhoneService,
    ds.MultipleLines,
    ds.InternetService,
    ds.OnlineSecurity,
    ds.OnlineBackup,
    ds.DeviceProtection,
    ds.TechSupport,
    ds.StreamingTV,
    ds.StreamingMovies,
    
    -- Contract details
    dcon.Contract,
    dcon.PaperlessBilling,
    dcon.PaymentMethod,
    
    -- Fact metrics
    fc.tenure,
    fc.MonthlyCharges,
    fc.TotalCharges,
    fc.num_services,
    fc.senior_alone,
    fc.avg_monthly_spend,
    fc.has_internet,
    fc.high_value_customer,
    fc.Churn

FROM Fact_churn fc
JOIN Dim_customer dc ON fc.Cus_id = dc.Cus_id
JOIN Dim_service ds ON fc.Service_id = ds.Service_id
JOIN Dim_contract dcon ON fc.Contract_id = dcon.Contract_id;

-- Business Problems
-- How many customers have churned and 
-- what is the overall churn rate, broken down by gender, internet service type, and contract type?"

SELECT
    dc.gender,
    ds.InternetService,
    dct.Contract,
    COUNT(fc.Cus_id) AS Total_Customers,
    SUM(CASE WHEN fc.Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND( 
        (CAST(SUM(CASE WHEN fc.Churn = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(fc.Cus_id)) * 100, 2
    ) AS Churn_Rate_Percentage
FROM Fact_churn fc
JOIN Dim_customer dc ON fc.Cus_id = dc.Cus_id
JOIN Dim_service ds ON fc.Service_id = ds.Service_id
JOIN Dim_contract dct ON fc.Contract_id = dct.Contract_id
GROUP BY dc.gender, ds.InternetService, dct.Contract
ORDER BY Churn_Rate_Percentage DESC;

-- What is the total revenue generated at each customer tenure month?

-- Monthly Revenue Analysis using tenure
SELECT 
    tenure AS Customer_Tenure_Month,
    SUM(MonthlyCharges) AS Total_Revenue
FROM Fact_churn
GROUP BY tenure
ORDER BY Customer_Tenure_Month;

-- Who are the top 10 customers based on their average monthly spend?

--Top 10 customers
SELECT 
    Cus_id,
    avg_monthly_spend,
    RANK() OVER (ORDER BY avg_monthly_spend DESC) AS Spend_Rank
FROM Fact_churn
ORDER BY Spend_Rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


-- Which type of Internet Service is most commonly used by customers?

--Internet service mostly used
SELECT 
    ds.InternetService,
    COUNT(*) AS Service_Usage_Count
FROM Fact_churn fc
JOIN Dim_service ds ON fc.Service_id = ds.Service_id
GROUP BY ds.InternetService
ORDER BY Service_Usage_Count DESC;


-- Which payment methods are most popular among customers?

-- Payment Method Analysis
SELECT 
    dcon.PaymentMethod,
    COUNT(*) AS Number_of_Customers
FROM Fact_churn fc
JOIN Dim_contract dcon ON fc.Contract_id = dcon.Contract_id
GROUP BY dcon.PaymentMethod
ORDER BY Number_of_Customers DESC;


-- What is the average tenure of customers overall?

-- Average Tenure Analysis
SELECT 
    ROUND(AVG(tenure), 2) AS Average_Tenure_Months
FROM Fact_churn;


-- How many senior citizens are living alone (no partner)?

-- Senior Citizens Living Alone
SELECT 
    COUNT(*) AS Senior_Citizens_Alone
FROM Dim_customer
WHERE 
    SeniorCitizen = 'Yes'
    AND Partner = 'No';


-- Does having internet service affect customer churn?

-- Internet Service Impact on Churn
SELECT 
    ds.InternetService,
    fc.Churn,
    COUNT(*) AS Number_of_Customers
FROM Fact_churn fc
JOIN Dim_service ds ON fc.Service_id = ds.Service_id
GROUP BY ds.InternetService, fc.Churn
ORDER BY ds.InternetService, fc.Churn;




