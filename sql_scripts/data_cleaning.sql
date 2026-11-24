-- =====================================================================
-- Проект: Очистка и стандартизация данных интернет-магазина (E-commerce)
-- Инструмент: SQL (диалект PostgreSQL / MySQL)
-- =====================================================================

-- 1. УДАЛЕНИЕ ДУБЛИКАТОВ
-- Используем CTE (общие табличные выражения) и оконную функцию ROW_NUMBER().
-- Это классический подход, который ищут на собеседованиях.
WITH numbered_rows AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY Order_ID, Customer_ID -- ищем дубликаты по ID заказа и клиента
               ORDER BY Order_Date
           ) as row_num
    FROM raw_transactions
)
DELETE FROM numbered_rows 
WHERE row_num > 1;

-- 2. СТАНДАРТИЗАЦИЯ СПОСОБА ОПЛАТЫ (Payment_Method)
-- Приводим к единому виду с помощью LOWER (нижний регистр) и TRIM (удаление пробелов).
UPDATE raw_transactions
SET Payment_Method = CASE
    WHEN LOWER(TRIM(Payment_Method)) IN ('netbanking', 'net banking') THEN 'Net Banking'
    WHEN LOWER(TRIM(Payment_Method)) IN ('debit card', 'debit_card') THEN 'Debit Card'
    WHEN LOWER(TRIM(Payment_Method)) IN ('credit card', 'credit_card') THEN 'Credit Card'
    WHEN LOWER(TRIM(Payment_Method)) IN ('cod', 'cash on delivery') THEN 'Cash on Delivery'
    WHEN LOWER(TRIM(Payment_Method)) = 'paypal' THEN 'PayPal'
    ELSE Payment_Method -- если значение не подошло, оставляем как есть
END;

-- 3. СТАНДАРТИЗАЦИЯ СТРАН (Country)
-- Избавляемся от сокращений (U.K., CA, DE) и неправильного регистра (germany).
UPDATE raw_transactions
SET Country = CASE
    WHEN UPPER(TRIM(Country)) IN ('U.K.', 'U.K', 'UK') THEN 'United Kingdom'
    WHEN UPPER(TRIM(Country)) IN ('USA', 'U.S.A', 'US') THEN 'United States'
    WHEN UPPER(TRIM(Country)) IN ('CA', 'CANADA') THEN 'Canada'
    WHEN UPPER(TRIM(Country)) IN ('DE', 'GERMANY') THEN 'Germany'
    WHEN UPPER(TRIM(Country)) IN ('AU', 'AUSTRALIA') THEN 'Australia'
    ELSE Country
END;

-- 4. ОБРАБОТКА ПРОПУЩЕННЫХ ЗНАЧЕНИЙ (Discount_Percent)
-- Если скидка пустая, считаем, что её не было (ставим 0). 
-- Это нужно, чтобы при подсчете средней скидки не возникало ошибок.
UPDATE raw_transactions
SET Discount_Percent = 0
WHERE Discount_Percent IS NULL OR TRIM(Discount_Percent) = '';

-- 5. ОБРАБОТКА ДАТ (Order_Date) 
-- В данных встречаются форматы: 2026-04-03, 10-15-2024, 17 Jun 2024.
-- В реальной базе (например, в PostgreSQL) это делается так:
-- UPDATE raw_transactions
-- SET Order_Date = TO_DATE(Order_Date, 'YYYY-MM-DD')
-- WHERE Order_Date ~ '^\d{4}-\d{2}-\d{2}$';
