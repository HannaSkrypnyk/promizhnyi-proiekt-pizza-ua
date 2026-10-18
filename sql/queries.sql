-- =====================================================================
-- Проміжний проєкт: продажі піцерії (Pizza Place Sales, Kaggle)
-- Deutsche Tech Akademie · Data Analytics
-- СУБД: SQLite Online
-- Таблиці: orders, order_details, pizzas, pizza_types
-- =====================================================================
 
 
-- =====================================================================
-- 0 Перевірка імпорту
-- =====================================================================
 
-- 0.1а Структура: чи став перший рядок назвами колонок? Які типи даних?
PRAGMA table_info(orders);
PRAGMA table_info(order_details);
PRAGMA table_info(pizzas);
PRAGMA table_info(pizza_types);
 
-- 0.1b Перші рядки кожної таблиці
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_details LIMIT 5;
SELECT * FROM pizzas LIMIT 5;
SELECT * FROM pizza_types LIMIT 5;
 
-- 0.2 Кількість рядків у кожній таблиці
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_details' AS table_name, COUNT(*) AS row_count FROM order_details
UNION ALL
SELECT 'pizzas' AS table_name, COUNT(*) AS row_count FROM pizzas
UNION ALL
SELECT 'pizza_types' AS table_name, COUNT(*) AS row_count FROM pizza_types;
 
-- 0.3 Пропуски: NULL або порожній рядок у кожній колонці
SELECT
    COUNT(*) AS row_count,
    SUM(CASE WHEN order_id IS NULL OR TRIM(order_id) = '' THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN date     IS NULL OR TRIM(date)     = '' THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN time     IS NULL OR TRIM(time)     = '' THEN 1 ELSE 0 END) AS missing_time
FROM orders;
 
SELECT
    COUNT(*) AS row_count,
    SUM(CASE WHEN order_details_id IS NULL OR TRIM(order_details_id) = '' THEN 1 ELSE 0 END) AS missing_order_details_id,
    SUM(CASE WHEN order_id  IS NULL OR TRIM(order_id)  = '' THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN pizza_id  IS NULL OR TRIM(pizza_id)  = '' THEN 1 ELSE 0 END) AS missing_pizza_id,
    SUM(CASE WHEN quantity  IS NULL OR TRIM(quantity)  = '' THEN 1 ELSE 0 END) AS missing_quantity
FROM order_details;
 
SELECT
    COUNT(*) AS row_count,
    SUM(CASE WHEN pizza_id      IS NULL OR TRIM(pizza_id)      = '' THEN 1 ELSE 0 END) AS missing_pizza_id,
    SUM(CASE WHEN pizza_type_id IS NULL OR TRIM(pizza_type_id) = '' THEN 1 ELSE 0 END) AS missing_pizza_type_id,
    SUM(CASE WHEN size          IS NULL OR TRIM(size)          = '' THEN 1 ELSE 0 END) AS missing_size,
    SUM(CASE WHEN price         IS NULL OR TRIM(price)         = '' THEN 1 ELSE 0 END) AS missing_price
FROM pizzas;
 
SELECT
    COUNT(*) AS row_count,
    SUM(CASE WHEN pizza_type_id IS NULL OR TRIM(pizza_type_id) = '' THEN 1 ELSE 0 END) AS missing_pizza_type_id,
    SUM(CASE WHEN name          IS NULL OR TRIM(name)          = '' THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN category      IS NULL OR TRIM(category)      = '' THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN ingredients   IS NULL OR TRIM(ingredients)   = '' THEN 1 ELSE 0 END) AS missing_ingredients
FROM pizza_types;
 
-- 0.4 Унікальність ключів: чи кожен ID трапляється лише один раз?
SELECT 'orders.order_id' AS key_name,
       COUNT(*) AS row_count, 
       COUNT(DISTINCT order_id) AS distinct_count
FROM orders
UNION ALL
SELECT 'order_details.order_details_id',
       COUNT(*), 
       COUNT(DISTINCT order_details_id) 
FROM order_details
UNION ALL
SELECT 'pizzas.pizza_id',
       COUNT(*), 
       COUNT(DISTINCT pizza_id) 
FROM pizzas
UNION ALL
SELECT 'pizza_types.pizza_type_id',
       COUNT(*), 
       COUNT(DISTINCT pizza_type_id) 
FROM pizza_types;
 
-- 0.5 Зв'язки: чи є посилання без відповідного запису?
-- Позиції без замовлення
SELECT COUNT(*) AS details_without_order
FROM order_details AS od
LEFT JOIN orders AS o USING(order_id)
WHERE o.order_id IS NULL;
 
-- Позиції без піци
SELECT COUNT(*) AS details_without_pizza
FROM order_details AS od
LEFT JOIN pizzas AS p USING(pizza_id)
WHERE p.pizza_id IS NULL;
 
-- Піци без типу піци
SELECT COUNT(*) AS pizzas_without_type
FROM pizzas AS p
LEFT JOIN pizza_types AS pt USING(pizza_type_id)
WHERE pt.pizza_type_id IS NULL;
 
-- Замовлення без жодної позиції
SELECT COUNT(*) AS orders_without_details
FROM orders AS o
LEFT JOIN order_details AS od USING(order_id)
WHERE od.order_id IS NULL;
 
-- 0.6 Тип даних числових колонок: текст чи число?
SELECT typeof(price) AS data_type, COUNT(*) AS row_count
FROM pizzas
GROUP BY typeof(price);
 
SELECT typeof(quantity) AS data_type, COUNT(*) AS row_count
FROM order_details
GROUP BY typeof(quantity);
 
-- 0.7 Формат дати й часу: чи розуміє їх strftime?
SELECT
    MIN(date) AS first_date,
    MAX(date) AS last_date,
    SUM(CASE WHEN strftime('%Y-%m-%d', date) IS NULL THEN 1 ELSE 0 END) AS invalid_date,
    SUM(CASE WHEN strftime('%H:%M:%S', time) IS NULL THEN 1 ELSE 0 END) AS invalid_time
FROM orders;
 
 
-- =====================================================================
-- Питання 1: Загальні показники за 2015 рік
-- Виручка, кількість замовлень, продані піци, середній чек, середня кількість піц у замовленні. 
-- Піци рахуємо з урахуванням quantity.
-- price (REAL) і quantity (INTEGER) вже є числами (перевірено typeof у 0.6).
-- =====================================================================
SELECT
    ROUND(SUM(p.price * od.quantity)) AS revenue,
    COUNT(DISTINCT od.order_id) AS orders,
    SUM(od.quantity) AS pizzas_sold,
    ROUND(SUM(p.price * od.quantity)
          / COUNT(DISTINCT od.order_id), 2) AS avg_order_value,

    -- CAST потрібен (ціле / ціле) в SQLite відкидає дробову частину
    ROUND(CAST(SUM(od.quantity) AS REAL)
          / COUNT(DISTINCT od.order_id), 2) AS avg_pizzas_per_order
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id);
 
 
-- =====================================================================
-- Питання 2: Виручка і замовлення по місяцях
-- Який місяць найсильніший, а який найслабший?
-- =====================================================================
SELECT
    strftime('%m', o.date) AS month,
    ROUND(SUM(p.price * od.quantity)) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders AS o
JOIN order_details AS od USING(order_id)
JOIN pizzas AS p USING(pizza_id)
GROUP BY month
ORDER BY month;
 
-- Питання 2 ★: Зміна до попереднього місяця у відсотках (LAG)
WITH monthly_values AS (
    SELECT
        strftime('%m', o.date) AS month,
        SUM(p.price * od.quantity) AS revenue,
        COUNT(DISTINCT o.order_id) AS orders
    FROM orders AS o
    JOIN order_details AS od USING(order_id)
    JOIN pizzas AS p USING(pizza_id)
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue) AS revenue,
    orders,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
          / LAG(revenue) OVER (ORDER BY month), 1) AS revenue_mom_pct,
    ROUND((orders - LAG(orders) OVER (ORDER BY month)) * 100.0
          / LAG(orders) OVER (ORDER BY month), 1) AS orders_mom_pct
FROM monthly_values
ORDER BY month;
 
 
-- =====================================================================
-- Питання 3a: Замовлення за днями тижня
-- Скільки замовлень у середньому надходить за один понеділок, вівторок і т. д.
-- strftime('%w') повертає 0 = неділя … 6 = субота
-- sort_nr: понеділок = 0 … неділя = 6
-- =====================================================================
SELECT
    (CAST(strftime('%w', date) AS INTEGER) + 6) % 7 AS sort_nr,
    CASE strftime('%w', date)
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
        WHEN '0' THEN 'Sunday'
    END AS weekday,
    COUNT(*) AS orders,
    COUNT(DISTINCT date) AS days_count,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT date), 1) AS orders_per_day
FROM orders
GROUP BY weekday
ORDER BY sort_nr;
 
-- =====================================================================
-- Питання 3b: Замовлення за годинами
-- Коли пік, а коли тихо?
-- Середнє на день = замовлення / кількість усіх днів із замовленнями
-- (підзапит, а не COUNT(DISTINCT date) у групі, інакше рідкісні години виглядали б завантаженими)
-- =====================================================================
SELECT
    strftime('%H', time) AS hour,
    COUNT(*) AS orders,
    ROUND(COUNT(*) * 1.0 / (SELECT COUNT(DISTINCT date) FROM orders), 1) AS orders_per_day
FROM orders
GROUP BY hour
ORDER BY hour;
 
 
-- =====================================================================
-- Питання 4a: Топ-5 піц за виручкою (на рівні назви, усі розміри разом)
-- =====================================================================
SELECT
    pt.name AS pizza_name,
    ROUND(SUM(p.price * od.quantity)) AS revenue,
    SUM(od.quantity) AS quantity
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
GROUP BY pt.pizza_type_id, pt.name
ORDER BY SUM(p.price * od.quantity) DESC
LIMIT 5;
 
-- =====================================================================
-- Питання 4b: Останні 5 піц за виручкою
-- =====================================================================
SELECT
    pt.name AS pizza_name,
    ROUND(SUM(p.price * od.quantity)) AS revenue,
    SUM(od.quantity) AS quantity
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
GROUP BY pt.pizza_type_id, pt.name
ORDER BY SUM(p.price * od.quantity) ASC
LIMIT 5;
 
-- =====================================================================
-- Питання 4c: Топ-5 піц за кількістю
-- =====================================================================
SELECT
    pt.name AS pizza_name,
    SUM(od.quantity) AS quantity,
    ROUND(SUM(p.price * od.quantity)) AS revenue
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
GROUP BY pt.pizza_type_id, pt.name
ORDER BY SUM(od.quantity) DESC
LIMIT 5;
 
-- =====================================================================
-- Питання 4d: Останні 5 піц за кількістю
-- =====================================================================
SELECT
    pt.name AS pizza_name,
    SUM(od.quantity) AS quantity,
    ROUND(SUM(p.price * od.quantity)) AS revenue
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
GROUP BY pt.pizza_type_id, pt.name
ORDER BY SUM(od.quantity) ASC
LIMIT 5;

-- =====================================================================
-- Питання 5a: Частка виручки кожної категорії
-- Частка = виручка категорії / загальна виручка (через підзапит)
-- =====================================================================
SELECT
      pt.category AS category,
      ROUND(SUM(p.price * od.quantity)) AS revenue,
      SUM(od.quantity) AS quantity,
      ROUND(SUM(p.price * od.quantity) * 100.0
            / (
               SELECT SUM(p2.price * od2.quantity)
               FROM order_details od2
               JOIN pizzas AS p2 USING(pizza_id)
              ), 
            1) AS revenue_share_pct
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
GROUP BY pt.category
ORDER BY SUM(p.price * od.quantity) DESC;

-- =====================================================================
-- Питання 5b ★: Частка виручки та продажі за розмірами
-- Які розміри продаються найкраще?
-- Загальна виручка через віконну функцію SUM() OVER ()
-- =====================================================================
SELECT
    p.size AS size,
    ROUND(SUM(p.price * od.quantity)) AS revenue,
    SUM(od.quantity) AS quantity,
    ROUND(SUM(p.price * od.quantity) * 100.0
          / SUM(SUM(p.price * od.quantity)) OVER (), 1) AS revenue_share_pct,
    ROUND(SUM(od.quantity) * 100.0
          / SUM(SUM(od.quantity)) OVER (), 1)  AS quantity_share_pct
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
GROUP BY p.size
ORDER BY revenue DESC;

-- =====================================================================
-- Питання 6a: Кандидати на вилучення з меню
-- Піци (усі розміри разом) з часткою виручки < 2 %
-- CASE: чи низькі також продажі (частка кількості < 2 %)
-- Поріг 2 %: середня частка однієї піци = 100 % / 32 ≈ 3,1 %
-- =====================================================================
SELECT
      pt.name AS pizza_name,
      ROUND(SUM(p.price * od.quantity)) AS revenue,
      SUM(od.quantity) AS quantity,
      ROUND(SUM(p.price * od.quantity) * 100.0
            / (SELECT SUM(p2.price * od2.quantity)
               FROM order_details od2
               JOIN pizzas AS p2 USING(pizza_id)), 2) AS revenue_share_pct,
      ROUND(SUM(od.quantity) * 100.0
            / (SELECT SUM(quantity) 
               FROM order_details), 2) AS quantity_share_pct,
      CASE
          WHEN SUM(od.quantity) * 100.0
               / (SELECT SUM(quantity) 
                  FROM order_details) < 2.0
          THEN 'low revenue + low sales'
          ELSE 'low revenue only'
      END AS assessment
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
GROUP BY pt.pizza_type_id, pt.name
HAVING SUM(p.price * od.quantity) * 100.0
       / (SELECT SUM(p2.price * od2.quantity)
          FROM order_details od2
          JOIN pizzas AS p2 USING(pizza_id)) < 2.0
ORDER BY SUM(p.price * od.quantity) ASC;

-- =====================================================================
-- Питання 6b ★: Накопичувальна частка виручки (знизу вгору)
-- Скільки виручки зачепить вилучення 1, 2, 3 … найслабших піц
-- =====================================================================
WITH pizza_revenue AS (
    SELECT
          pt.name AS pizza_name,
          SUM(p.price * od.quantity) AS revenue,
          SUM(od.quantity) AS quantity
    FROM order_details AS od
    JOIN pizzas AS p USING(pizza_id)
    JOIN pizza_types AS pt USING(pizza_type_id)
    GROUP BY pt.pizza_type_id, pt.name
)
SELECT
      RANK() OVER (ORDER BY revenue ASC) AS rank_from_bottom,
      pizza_name,
      ROUND(revenue) AS revenue,
      quantity,
      ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2) AS revenue_share_pct,
      ROUND(SUM(revenue) OVER (ORDER BY revenue ASC)
            * 100.0 / SUM(revenue) OVER (), 2) AS cumulative_share_pct
FROM pizza_revenue
ORDER BY revenue ASC
LIMIT 10;

-- =====================================================================
-- Питання 6c: Інгредієнти кандидатів, яких немає в жодній іншій піці
-- Рядок ingredients ("Tomatoes, Garlic, …") розбивається
-- на окремі інгредієнти рекурсивним CTE
-- =====================================================================
WITH RECURSIVE split AS (
    -- стартовий рядок: ще нічого не відрізано, до залишку додано кому
    SELECT pizza_type_id,
           name,
           '' AS ingredient,
           ingredients || ',' AS rest
    FROM pizza_types
    UNION ALL
    -- кожен крок: відрізати текст до першої коми
    SELECT pizza_type_id,
           name,
           TRIM(SUBSTR(rest, 1, INSTR(rest, ',') - 1)),
           SUBSTR(rest, INSTR(rest, ',') + 1)
    FROM split
    WHERE rest <> ''
),
ingredient_list AS (
    -- один рядок = одна піца + один інгредієнт
    SELECT pizza_type_id, name, ingredient
    FROM split
    WHERE ingredient <> ''
),
ingredient_usage AS (
    -- у скількох піцах трапляється кожен інгредієнт
    SELECT ingredient,
           COUNT(DISTINCT pizza_type_id) AS pizzas_using
    FROM ingredient_list
    GROUP BY ingredient
)
SELECT
    il.name AS pizza_name,
    il.ingredient AS ingredient,
    iu.pizzas_using AS pizzas_using
FROM ingredient_list AS il
JOIN ingredient_usage AS iu USING(ingredient)
WHERE iu.pizzas_using = 1
  AND il.name IN ('The Brie Carre Pizza',
                  'The Green Garden Pizza',
                  'The Spinach Supreme Pizza',
                  'The Mediterranean Pizza',
                  'The Spinach Pesto Pizza',
                  'The Calabrese Pizza',
                  'The Italian Vegetables Pizza')
ORDER BY il.name;

-- =====================================================================
-- Питання 6d: Скільки виручки зачепить вилучення обраних піц
-- Обрано: Brie Carre, Calabrese, Mediterranean
-- (низькі виручка і продажі + 9 власних інгредієнтів)
-- =====================================================================
SELECT
    COUNT(DISTINCT pt.pizza_type_id) AS pizzas_removed,
    ROUND(SUM(p.price * od.quantity)) AS revenue_affected,
    SUM(od.quantity) AS quantity_affected,
    ROUND(SUM(p.price * od.quantity) * 100.0
          / (SELECT SUM(p2.price * od2.quantity)
             FROM order_details AS od2
             JOIN pizzas AS p2 USING(pizza_id)), 2) AS revenue_share_pct
FROM order_details AS od
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id)
WHERE pt.name IN ('The Brie Carre Pizza',
                  'The Calabrese Pizza',
                  'The Mediterranean Pizza');

-- =====================================================================
-- Питання 7: Великі замовлення (4+ піц у замовленні)
-- Частка замовлень і виручки; CTE на рівні замовлення
-- =====================================================================
WITH order_totals AS (
    SELECT
          od.order_id,
          SUM(od.quantity) AS pizzas_in_order,
          SUM(p.price * od.quantity) AS order_revenue
    FROM order_details AS od
    JOIN pizzas AS p USING(pizza_id)
    GROUP BY od.order_id
)
SELECT
      CASE
          WHEN pizzas_in_order >= 4 THEN '4+ pizzas'
          ELSE '1-3 pizzas'
      END AS order_size,
      COUNT(*) AS orders,
      ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS orders_share_pct,
      ROUND(SUM(order_revenue)) AS revenue,
      ROUND(SUM(order_revenue) * 100.0 / SUM(SUM(order_revenue)) OVER (), 1) AS revenue_share_pct,
      ROUND(SUM(order_revenue) / COUNT(*), 2) AS avg_order_value
FROM order_totals
GROUP BY order_size;

-- =====================================================================
-- Питання 8a: Середня виручка за день у кожному вікні
-- «день тижня × часовий слот» — пошук слабких вікон
-- (поєднання питань 3 і 5)
-- =====================================================================
WITH lines AS (
    SELECT
          o.date,
          strftime('%w', o.date) AS wd,
          strftime('%H', o.time) AS hr,
          o.order_id,
          p.price * od.quantity AS revenue
    FROM orders AS o
    JOIN order_details AS od USING(order_id)
    JOIN pizzas AS p USING(pizza_id)
)
SELECT
    (CAST(wd AS INTEGER) + 6) % 7 AS sort_nr,
    CASE wd
        WHEN '1' THEN 'Monday'    WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday' WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'    WHEN '6' THEN 'Saturday'
        WHEN '0' THEN 'Sunday'
    END AS weekday,
    CASE
        WHEN hr <= '11' THEN '1: 09-12'
        WHEN hr <= '13' THEN '2: 12-14 lunch'
        WHEN hr <= '16' THEN '3: 14-17'
        WHEN hr <= '19' THEN '4: 17-20 evening'
        ELSE '5: 20-24'
    END AS time_slot,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(revenue)) AS revenue,
    ROUND(SUM(revenue)
          / (SELECT COUNT(DISTINCT o2.date)
             FROM orders AS o2
             WHERE strftime('%w', o2.date) = wd)) AS revenue_per_day
FROM lines
GROUP BY wd, time_slot
ORDER BY sort_nr, time_slot;

-- =====================================================================
-- Питання 8b: Потенціал акції «Weekend-Lunch» (сб + нд, 12:00–14:00)
-- Поточна виручка у вікні, ефект +10 %, частка розміру L у вікні
-- =====================================================================
WITH lines AS (
    SELECT
          o.date,
          strftime('%w', o.date) AS wd,
          strftime('%H', o.time) AS hr,
          o.order_id,
          p.size,
          p.price * od.quantity AS revenue
    FROM orders AS o
    JOIN order_details AS od USING(order_id)
    JOIN pizzas AS p USING(pizza_id)
)
SELECT
      COUNT(DISTINCT order_id) AS window_orders,
      ROUND(SUM(revenue)) AS window_revenue,
      ROUND(SUM(revenue)
            / (SELECT COUNT(DISTINCT date) 
               FROM orders
               WHERE strftime('%w', date) IN ('0', '6'))) AS revenue_per_day,
      ROUND(SUM(revenue) * 0.10) AS uplift_10pct,
      ROUND(SUM(revenue) * 1.10) AS revenue_with_uplift,
      ROUND(SUM(revenue) * 0.10 * 100.0
            / (SELECT SUM(p2.price * od2.quantity)
               FROM order_details AS od2
               JOIN pizzas AS p2 USING(pizza_id)), 2) AS uplift_share_of_total_pct,
      ROUND(SUM(CASE WHEN size = 'L' THEN revenue ELSE 0 END)
            * 100.0 / SUM(revenue), 1) AS l_share_in_window_pct
FROM lines
WHERE wd IN ('0', '6')
  AND hr BETWEEN '12' AND '13';

-- =====================================================================
-- КРОК 5. Вибірка sales_lines для Tableau (оформлена як VIEW)
-- Один рядок = одна позиція замовлення; JOIN усіх чотирьох таблиць
-- CAST — згідно із завданням (типи вже коректні, перевірено в 3.6)
-- =====================================================================

DROP VIEW IF EXISTS sales_lines;

CREATE VIEW sales_lines AS
SELECT
    o.order_id AS order_id,
    o.date AS order_date,
    o.time AS order_time,
    strftime('%m', o.date) AS month,
    CASE strftime('%w', o.date)
        WHEN '1' THEN 'Monday'    
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday' 
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'    
        WHEN '6' THEN 'Saturday'
        WHEN '0' THEN 'Sunday'
    END AS weekday,
    strftime('%H', o.time) AS hour,
    pt.name AS pizza_name,
    pt.category AS category,
    p.size AS size,
    CAST(p.price AS REAL) AS unit_price,
    CAST(od.quantity AS INTEGER) AS quantity,
    CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER) AS revenue
FROM order_details AS od
JOIN orders AS o USING(order_id)
JOIN pizzas AS p USING(pizza_id)
JOIN pizza_types AS pt USING(pizza_type_id);

-- Контроль: кількість рядків sales_lines = кількість рядків order_details,
-- загальна виручка = результат питання 1
SELECT COUNT(*) AS sales_lines_rows
FROM sales_lines;
SELECT COUNT(*) AS order_details_rows
FROM order_details;
SELECT ROUND(SUM(revenue), 2) AS total_revenue
FROM sales_lines; 

-- Вивантаження в CSV (exports/sales_lines.csv)
SELECT * FROM sales_lines;

-- =====================================================================
-- ДОДАТКОВІ РОЗРАХУНКИ ДЛЯ ВИСНОВКІВ
-- Числа з висновків (дашборд, презентація, README), які не виводяться
-- напряму запитами 1–8. Позначення Д1–Д9 використано в README.
-- =====================================================================
 
-- Д1: Відхилення виручки кожного місяця від середнього місяця («±7 %»)
-- AVG() OVER () — середня виручка місяця, однакова в кожному рядку
WITH monthly AS (
    SELECT
        strftime('%m', o.date)         AS month,
        SUM(p.price * od.quantity)     AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id  = od.order_id
    JOIN pizzas p         ON od.pizza_id = p.pizza_id
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue)                                              AS revenue,
    ROUND(AVG(revenue) OVER ())                                 AS avg_month_revenue,
    ROUND((revenue - AVG(revenue) OVER ()) * 100.0
          / AVG(revenue) OVER (), 1)                            AS deviation_pct
FROM monthly
ORDER BY month;
 
-- Д2: Наскільки найсильніший місяць вищий за найслабший («≈ 13 %»)
WITH monthly AS (
    SELECT
        strftime('%m', o.date)         AS month,
        SUM(p.price * od.quantity)     AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id  = od.order_id
    JOIN pizzas p         ON od.pizza_id = p.pizza_id
    GROUP BY month
)
SELECT
    ROUND(MAX(revenue))                                         AS max_month_revenue,
    ROUND(MIN(revenue))                                         AS min_month_revenue,
    ROUND(MAX(revenue) * 100.0 / MIN(revenue) - 100, 1)         AS max_vs_min_pct
FROM monthly;