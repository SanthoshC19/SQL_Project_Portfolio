/*
Import Credit_Card_Transaction data
Right click on database
Click Tasks and further click Import
Data Source : Excel
Browse to the file location and select
Choose the destination
Preview the table and load
*/

/* Explore Dataset*/
SELECT TOP 10* FROM credit_card_transactions;


/* To find data types for each columns*/
SELECT COLUMN_NAME,DATA_TYPE,IS_NULLABLE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'credit_card_transactions';

/* Number of records */
SELECT COUNT(*) FROM credit_card_transactions;

/* Number of Distinct records */
SELECT COUNT(*) FROM (SELECT DISTINCT * FROM credit_card_transactions) AS A;

/* Range of transaction date*/
SELECT MIN(transaction_date), MAX(transaction_date) FROM credit_card_transactions;

/* Type of cards*/
SELECT DISTINCT card_type FROM credit_card_transactions;

/*Type of expenses*/
SELECT DISTINCT exp_type FROM credit_card_transactions;

/* Print top 5 cities with highest spends and their percentage contribution of total credit card spends */
WITH T1 AS (
SELECT city,SUM(amount) AS city_spend
FROM credit_card_transactions
GROUP BY city)

SELECT TOP 5 city,city_spend, SUM(city_spend) OVER () AS tot_spend, ROUND(100*city_spend/SUM(city_spend) OVER (),2) AS per_contribution
FROM T1
ORDER BY city_spend DESC;

/*print highest spend month and amount spent in that month for each card type*/

WITH T1 AS (SELECT card_type,DATEPART(MM,transaction_date) AS mnth, DATEPART(YY,transaction_date) AS yr,SUM(amount) AS tot_amt
FROM credit_card_transactions
GROUP BY card_type, DATEPART(MM,transaction_date), DATEPART(YY,transaction_date)),

T2 AS (SELECT * ,RANK() OVER (PARTITION BY card_type ORDER BY tot_amt DESC) AS rn
FROM T1)

SELECT * FROM T2
WHERE rn=1

/*print the transaction details(all columns from the table) for each card type 
when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/

WITH T1 AS (SELECT *, SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS running_total
FROM credit_card_transactions),

T2 AS (SELECT *, RANK() OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS rn
FROM T1
WHERE running_total >= 1000000)

SELECT * FROM T2 WHERE rn=1;

/*find city which had lowest percentage spend for gold card type*/
WITH T1 AS (SELECT city,card_type, SUM(amount) AS t_amt, SUM(case when card_type='Gold' then amount end) AS g_amt
FROM credit_card_transactions
GROUP BY city,card_type)

SELECT TOP 1 city, 100*SUM(g_amt)/SUM(t_amt) AS l_per
FROM T1
GROUP BY city
HAVING SUM(g_amt) IS NOT NULL
ORDER BY l_per;

/*print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)*/

WITH T1 AS (SELECT city, exp_type, SUM(amount) AS expense
FROM credit_card_transactions
GROUP BY city,exp_type)

SELECT DISTINCT city, FIRST_VALUE(exp_type) OVER (PARTITION BY city ORDER BY expense DESC) AS highest_expense_type
,FIRST_VALUE(exp_type) OVER (PARTITION BY city ORDER BY expense) AS lowest_expense_type
FROM T1;

/*percentage contribution of spends by females for each expense type*/

WITH T1 AS (SELECT *, SUM(amount) OVER (PARTITION BY exp_type) as tot
FROM credit_card_transactions)

SELECT exp_type, 100*SUM(amount)/tot AS pct
FROM T1
WHERE gender = 'F'
GROUP BY exp_type,tot;


/*which card and expense type combination saw highest month over month growth % in Jan-2014*/

WITH T1 AS (SELECT card_type,exp_type,SUM(amount) AS tot_sum, DATEPART(MM,transaction_date) AS mnt,DATEPART(YY,transaction_date) AS yr
FROM credit_card_transactions
GROUP BY card_type,exp_type,DATEPART(MM,transaction_date),DATEPART(YY,transaction_date)),

T2 AS (SELECT *,LAG(tot_sum,1) OVER (PARTITION BY card_type,exp_type ORDER BY yr,mnt) AS pre
FROM T1)

SELECT TOP 1 *, 100*(tot_sum-pre)/pre AS mom
FROM T2
WHERE mnt=1 AND yr=2014
ORDER BY mom DESC

/*during weekends which city has highest total spend to total no of transcations ratio*/

SELECT TOP 1 city, SUM(amount)/COUNT(transaction_id) AS ratio
FROM credit_card_transactions
WHERE DATEPART(WEEKDAY, transaction_date) IN (7,1)
GROUP BY city
ORDER BY ratio DESC;

/*which city took least number of days to reach its 500th transaction after the first transaction in that city*/

WITH T1 AS (SELECT city, transaction_id,transaction_date,COUNT(transaction_id) OVER (PARTITION BY city ) AS cnt,
ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date) AS rn
FROM credit_card_transactions),

T2 AS (SELECT city, transaction_id, transaction_date,rn, LAG(transaction_date,1) OVER(PARTITION BY city ORDER BY rn) AS pre
FROM T1
WHERE cnt>500 AND rn IN (1,500))

SELECT TOP 1 city, DATEDIFF(D,pre, transaction_date) AS no_of_days
FROM T2
WHERE pre IS NOT NULL
ORDER BY no_of_days;

