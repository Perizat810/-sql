#ЗАДАЧА 1
WITH months AS (
    SELECT '2015-06-01' AS month
    UNION SELECT '2015-07-01'
    UNION SELECT '2015-08-01'
    UNION SELECT '2015-09-01'
    UNION SELECT '2015-10-01'
    UNION SELECT '2015-11-01'
    UNION SELECT '2015-12-01'
    UNION SELECT '2016-01-01'
    UNION SELECT '2016-02-01'
    UNION SELECT '2016-03-01'
    UNION SELECT '2016-04-01'
    UNION SELECT '2016-05-01'
    UNION SELECT '2016-06-01'
),
client_transactions AS (
    SELECT c.ID_client,
           m.month,
           COUNT(t.Id_check) AS total_operations,
           SUM(t.Sum_payment) AS total_amount_spent,
           AVG(t.Sum_payment / t.Count_products) AS avg_check
    FROM customer_info c
    LEFT JOIN months m ON 1=1  -- Соединяем каждого клиента с каждым месяцем
    LEFT JOIN transactions_info t ON c.ID_client = t.ID_client
                                      AND EXTRACT(YEAR_MONTH FROM t.date_new) = EXTRACT(YEAR_MONTH FROM m.month)
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY c.ID_client, m.month
),
client_summary AS (
    SELECT ID_client,
           COUNT(DISTINCT month) AS active_months,  -- Считаем количество месяцев с транзакциями
           AVG(total_amount_spent) AS avg_monthly_spending,  -- Средняя сумма покупок в месяц
           SUM(total_operations) AS total_operations,  -- Общее количество операций
           AVG(avg_check) AS avg_check  -- Средний чек за весь период
    FROM client_transactions
    GROUP BY ID_client
)
SELECT cs.ID_client,
       cs.avg_check,
       cs.avg_monthly_spending,
       cs.total_operations,
       cs.active_months
FROM client_summary cs
ORDER BY cs.ID_client;

#ЗАДАЧА 2
WITH months AS (
    SELECT '2015-06-01' AS month
    UNION SELECT '2015-07-01'
    UNION SELECT '2015-08-01'
    UNION SELECT '2015-09-01'
    UNION SELECT '2015-10-01'
    UNION SELECT '2015-11-01'
    UNION SELECT '2015-12-01'
    UNION SELECT '2016-01-01'
    UNION SELECT '2016-02-01'
    UNION SELECT '2016-03-01'
    UNION SELECT '2016-04-01'
    UNION SELECT '2016-05-01'
    UNION SELECT '2016-06-01'
),
client_transactions AS (
    SELECT c.ID_client,
           m.month,
           COUNT(t.Id_check) AS total_operations,
           SUM(t.Sum_payment) AS total_amount_spent,
           AVG(t.Sum_payment / t.Count_products) AS avg_check,
           c.Gender
    FROM customer_info c
    LEFT JOIN months m ON 1=1  -- Соединяем каждого клиента с каждым месяцем
    LEFT JOIN transactions_info t ON c.ID_client = t.ID_client
                                      AND EXTRACT(YEAR_MONTH FROM t.date_new) = EXTRACT(YEAR_MONTH FROM m.month)
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY c.ID_client, m.month, c.Gender
),
monthly_summary AS (
    SELECT month,
           AVG(total_amount_spent) AS avg_monthly_spending,  -- Средняя сумма покупок в месяц
           AVG(total_operations) AS avg_operations_per_month,  -- Среднее количество операций в месяц
           COUNT(DISTINCT ID_client) AS avg_clients_per_month,  -- Среднее количество клиентов, совершавших операции в месяц
           SUM(total_operations) AS total_operations_year,  -- Общее количество операций за год
           SUM(total_amount_spent) AS total_amount_year  -- Общая сумма за год
    FROM client_transactions
    GROUP BY month
),
gender_summary AS (
    SELECT month,
           SUM(CASE WHEN Gender = 'M' THEN total_amount_spent ELSE 0 END) AS male_spending,
           SUM(CASE WHEN Gender = 'F' THEN total_amount_spent ELSE 0 END) AS female_spending,
           SUM(CASE WHEN Gender IS NULL THEN total_amount_spent ELSE 0 END) AS na_spending,
           SUM(total_amount_spent) AS total_spending
    FROM client_transactions
    GROUP BY month
)
SELECT m.month,
       ms.avg_monthly_spending,
       ms.avg_operations_per_month,
       ms.avg_clients_per_month,
       ms.total_operations_year,
       ms.total_amount_year,
       (ms.total_operations_year / (SELECT SUM(total_operations_year) FROM monthly_summary)) * 100 AS operations_percentage,
       (ms.total_amount_year / (SELECT SUM(total_amount_year) FROM monthly_summary)) * 100 AS amount_percentage,
       gs.male_spending / gs.total_spending * 100 AS male_percentage,
       gs.female_spending / gs.total_spending * 100 AS female_percentage,
       gs.na_spending / gs.total_spending * 100 AS na_percentage
FROM months m
JOIN monthly_summary ms ON m.month = ms.month
JOIN gender_summary gs ON m.month = gs.month
ORDER BY m.month;

#ЗАДАЧА 3
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN c.Age IS NULL THEN 'Unknown'
            WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
            WHEN c.Age >= 80 THEN '80+'
        END AS age_group,
        c.ID_client,
        t.Id_check,
        t.Sum_payment,
        t.date_new
    FROM customer_info c
    LEFT JOIN transactions_info t ON c.ID_client = t.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
quarterly_data AS (
    SELECT 
        age_group,
        QUARTER(t.date_new) AS quarter,
        YEAR(t.date_new) AS year,
        COUNT(t.Id_check) AS total_operations,
        SUM(t.Sum_payment) AS total_amount
    FROM age_groups t
    GROUP BY age_group, QUARTER(t.date_new), YEAR(t.date_new)
),
annual_data AS (
    SELECT 
        age_group,
        COUNT(t.Id_check) AS total_operations_year,
        SUM(t.Sum_payment) AS total_amount_year
    FROM age_groups t
    GROUP BY age_group
)
SELECT 
    q.age_group,
    q.year,
    q.quarter,
    q.total_operations AS operations_in_quarter,
    q.total_amount AS amount_in_quarter,
    ROUND(q.total_operations / a.total_operations_year * 100, 2) AS operations_percentage_of_year,
    ROUND(q.total_amount / a.total_amount_year * 100, 2) AS amount_percentage_of_year,
    ROUND(q.total_operations / 3, 2) AS avg_operations_per_month,  -- среднее количество операций в месяц за квартал
    ROUND(q.total_amount / 3, 2) AS avg_amount_per_month  -- средняя сумма за месяц за квартал
FROM quarterly_data q
JOIN annual_data a ON q.age_group = a.age_group
ORDER BY q.age_group, q.year, q.quarter;

