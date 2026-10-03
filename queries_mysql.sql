-- Q1. Restaurants per Country
SELECT
    cc.Country AS country,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN r.`Aggregate rating` > 0 THEN r.`Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(r.`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants r
JOIN country_codes cc ON r.`Country Code` = cc.`Country Code`
GROUP BY cc.Country
ORDER BY restaurant_count DESC;

-- Q2. Top Cities by Restaurant Count
SELECT
    City AS city,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants
GROUP BY City
ORDER BY restaurant_count DESC
LIMIT 20;

-- Q3. Most Common Cuisines
WITH exploded AS (
    SELECT TRIM(jt.cuisine) AS cuisine
    FROM restaurants r
    CROSS JOIN JSON_TABLE(
        CONCAT('[', REPLACE(JSON_QUOTE(COALESCE(r.Cuisines, '')), ',', '","'), ']'),
        '$[*]' COLUMNS (cuisine VARCHAR(255) PATH '$')
    ) AS jt
    WHERE r.Cuisines IS NOT NULL
)
SELECT cuisine, COUNT(*) AS restaurant_count
FROM exploded
GROUP BY cuisine
ORDER BY restaurant_count DESC
LIMIT 20;

-- Q4. Highest-Rated Cuisines
WITH exploded AS (
    SELECT TRIM(jt.cuisine) AS cuisine, r.`Aggregate rating` AS rating
    FROM restaurants r
    CROSS JOIN JSON_TABLE(
        CONCAT('[', REPLACE(JSON_QUOTE(COALESCE(r.Cuisines, '')), ',', '","'), ']'),
        '$[*]' COLUMNS (cuisine VARCHAR(255) PATH '$')
    ) AS jt
    WHERE r.Cuisines IS NOT NULL AND r.`Aggregate rating` > 0
)
SELECT
    cuisine,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(rating), 2) AS avg_rating
FROM exploded
GROUP BY cuisine
HAVING COUNT(*) >= 20
ORDER BY avg_rating DESC
LIMIT 20;

-- Q5. Relationship Between Cost and Rating
WITH paired_values AS (
    SELECT
        'cost_vs_rating' AS metric,
        1.0 * `Average Cost for two` AS x,
        `Aggregate rating` AS y
    FROM restaurants
    WHERE `Aggregate rating` > 0 AND `Average Cost for two` IS NOT NULL

    UNION ALL

    SELECT
        'price_range_vs_rating' AS metric,
        1.0 * `Price range` AS x,
        `Aggregate rating` AS y
    FROM restaurants
    WHERE `Aggregate rating` > 0 AND `Price range` IS NOT NULL
),
summaries AS (
    SELECT
        metric, COUNT(*) AS n,
        SUM(x) AS sum_x, SUM(y) AS sum_y,
        SUM(x * y) AS sum_xy,
        SUM(x * x) AS sum_x2, SUM(y * y) AS sum_y2
    FROM paired_values
    GROUP BY metric
),
correlations AS (
    SELECT metric,
        (n * sum_xy - sum_x * sum_y) / NULLIF(
            SQRT(
                GREATEST(n * sum_x2 - POW(sum_x, 2), 0) *
                GREATEST(n * sum_y2 - POW(sum_y, 2), 0)
            ), 0
        ) AS correlation
    FROM summaries
)
SELECT
    ROUND(MAX(CASE WHEN metric = 'cost_vs_rating'
        THEN correlation END), 3) AS cost_vs_rating,
    ROUND(MAX(CASE WHEN metric = 'price_range_vs_rating'
        THEN correlation END), 3) AS price_range_vs_rating
FROM correlations;

-- Q6. Average Rating by Price Range
SELECT
    `Price range` AS price_range,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants
GROUP BY `Price range`
ORDER BY price_range;

-- Q7. Restaurant Rating Distribution
SELECT
    `Rating text` AS rating_text,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(`Aggregate rating`), 2) AS avg_rating
FROM restaurants
WHERE `Aggregate rating` > 0
GROUP BY `Rating text`
ORDER BY avg_rating DESC;

-- Q8. Best-Value Restaurants
SELECT
    `Restaurant Name` AS restaurant_name,
    City AS city,
    Cuisines AS cuisines,
    `Average Cost for two` AS cost_for_two,
    `Aggregate rating` AS rating,
    ROUND(`Aggregate rating` / NULLIF(`Average Cost for two`, 0) * 1000, 3) AS value_score
FROM restaurants
WHERE `Aggregate rating` >= 4.0 AND `Average Cost for two` > 0
ORDER BY value_score DESC
LIMIT 20;

-- Q9. Online Delivery and Restaurant Ratings
SELECT
    `Has Online delivery` AS has_online_delivery,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(Votes), 1) AS avg_votes
FROM restaurants
GROUP BY `Has Online delivery`;

-- Q10. Table Booking and Restaurant Ratings
SELECT
    `Has Table booking` AS has_table_booking,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants
GROUP BY `Has Table booking`;

-- Q11. List Available Cities
SELECT DISTINCT City AS city
FROM restaurants
ORDER BY city;

-- Q12. Filter Restaurants by City and Minimum Rating
SET @city = NULL;
SET @min_rating = 4.0;

SELECT
    `Restaurant Name` AS restaurant_name,
    City AS city,
    Cuisines AS cuisines,
    `Average Cost for two` AS cost_for_two,
    `Price range` AS price_range,
    `Aggregate rating` AS rating,
    Votes AS votes
FROM restaurants
WHERE (@city IS NULL OR City = @city)
  AND (@min_rating IS NULL OR `Aggregate rating` >= @min_rating)
ORDER BY rating DESC, votes DESC
LIMIT 200;
