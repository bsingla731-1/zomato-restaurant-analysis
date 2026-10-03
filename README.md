# zomato-restaurant-analysis
Zomato Restaurant Data Analysis Using MySQL

## Overview

This project explores restaurant data using MySQL queries and a dashboard image. It focuses on restaurant locations, cuisine popularity, pricing, customer ratings, online delivery, and table booking. This README documents the objectives, dataset, schema, business questions, and SQL solutions.

## Objectives

- Analyse the distribution of restaurants across countries and cities.
- Identify common and highly rated cuisines.
- Explore the relationship between pricing and restaurant ratings.
- Compare restaurant ratings across delivery and booking options.
- Identify highly rated restaurants and apply city and rating filters.
- Present the analysis through a dashboard image.

## Dataset

The dataset was downloaded from Kaggle:

- **Dataset link:** [Zomato Restaurants Data](https://www.kaggle.com/datasets/shrutimehta/zomato-restaurants-data)
- **Restaurant data:** `zomato.csv`.
- **Country lookup:** `Country-Code.xlsx`.

The source project reports 9,551 restaurants and 21 restaurant-data columns. Results should be interpreted within the coverage of this dataset rather than as a complete or current view of the restaurant market.

## Tools Used

- **MySQL 8.0 or later** for database tables and analytical queries.
- **SQL** for joins, common table expressions, aggregations, and filtering.
- **Dashboard image** for visual presentation of the results.

## Repository Contents

| File | Description |
| --- | --- |
| SQL queries file | Numbered analytical queries, Q1–Q12. |
| Schema file | MySQL definitions for the restaurant and country lookup tables. |
| Dashboard image | A visual summary of the analysis. |

## Schema

The `restaurants` and `country_codes` tables join on `Country Code`. Column names are preserved from the source dataset.

```sql
CREATE TABLE restaurants (
    `Restaurant ID` BIGINT,
    `Restaurant Name` VARCHAR(255),
    `Country Code` BIGINT,
    `City` VARCHAR(255),
    `Address` TEXT,
    `Locality` VARCHAR(255),
    `Locality Verbose` TEXT,
    `Longitude` DOUBLE,
    `Latitude` DOUBLE,
    `Cuisines` TEXT,
    `Average Cost for two` BIGINT,
    `Currency` VARCHAR(255),
    `Has Table booking` VARCHAR(255),
    `Has Online delivery` VARCHAR(255),
    `Is delivering now` VARCHAR(255),
    `Switch to order menu` VARCHAR(255),
    `Price range` BIGINT,
    `Aggregate rating` DOUBLE,
    `Rating color` VARCHAR(255),
    `Rating text` VARCHAR(255),
    `Votes` BIGINT
) DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE country_codes (
    `Country Code` BIGINT,
    `Country` VARCHAR(255)
) DEFAULT CHARACTER SET utf8mb4;
```

## Business Problems and Solutions

### Q1. Restaurants per Country

```sql
SELECT
    cc.Country AS country,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN r.`Aggregate rating` > 0 THEN r.`Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(r.`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants r
JOIN country_codes cc ON r.`Country Code` = cc.`Country Code`
GROUP BY cc.Country
ORDER BY restaurant_count DESC;
```

**Objective:** Count restaurants in each country and compare their average ratings and costs. Unrated restaurants are excluded from the average rating.

### Q2. Top Cities by Restaurant Count

```sql
SELECT
    City AS city,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants
GROUP BY City
ORDER BY restaurant_count DESC
LIMIT 20;
```

**Objective:** Identify the 20 cities with the highest restaurant counts.

### Q3. Most Common Cuisines

```sql
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
```

**Objective:** Split comma-separated cuisine lists and count the number of restaurant entries for each cuisine.

### Q4. Highest-Rated Cuisines

```sql
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
```

**Objective:** Rank cuisines by average rating, considering only rated restaurants and cuisines with at least 20 restaurant entries.

### Q5. Relationship Between Cost and Rating

```sql
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
```

**Objective:** Calculate Pearson correlations for cost versus rating and price range versus rating. The formula is expressed through MySQL aggregates.

### Q6. Average Rating by Price Range

```sql
SELECT
    `Price range` AS price_range,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants
GROUP BY `Price range`
ORDER BY price_range;
```

**Objective:** Compare restaurant counts, average ratings, and costs across the dataset's price ranges.

### Q7. Restaurant Rating Distribution

```sql
SELECT
    `Rating text` AS rating_text,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(`Aggregate rating`), 2) AS avg_rating
FROM restaurants
WHERE `Aggregate rating` > 0
GROUP BY `Rating text`
ORDER BY avg_rating DESC;
```

**Objective:** Summarise rated restaurants by their rating categories.

### Q8. Best-Value Restaurants

```sql
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
```

**Objective:** Find restaurants rated at least 4.0 and rank them using rating divided by cost. Compare the scores within the same currency before interpreting value.

### Q9. Online Delivery and Restaurant Ratings

```sql
SELECT
    `Has Online delivery` AS has_online_delivery,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(Votes), 1) AS avg_votes
FROM restaurants
GROUP BY `Has Online delivery`;
```

**Objective:** Compare average ratings and votes between restaurants with and without online delivery.

### Q10. Table Booking and Restaurant Ratings

```sql
SELECT
    `Has Table booking` AS has_table_booking,
    COUNT(*) AS restaurant_count,
    ROUND(AVG(CASE WHEN `Aggregate rating` > 0 THEN `Aggregate rating` END), 2) AS avg_rating,
    ROUND(AVG(`Average Cost for two`), 2) AS avg_cost_for_two
FROM restaurants
GROUP BY `Has Table booking`;
```

**Objective:** Compare average ratings and costs between restaurants with and without table booking.

### Q11. List Available Cities

```sql
SELECT DISTINCT City AS city
FROM restaurants
ORDER BY city;
```

**Objective:** Retrieve distinct city names that can be used as filter options.

### Q12. Filter Restaurants by City and Minimum Rating

```sql
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
```

**Objective:** Retrieve up to 200 restaurants using optional city and rating filters. Set @city or @min_rating to NULL to disable that filter.

## Dashboard

The uploaded dashboard image provides a visual overview of the restaurant analysis. Open the image in this repository to inspect it alongside the SQL results.

## How to Use

1. Download the dataset from Kaggle.
2. Create or select a database in MySQL 8.0 or later.
3. Run the schema file to create the tables.
4. Import `zomato.csv` into `restaurants`. Export the country lookup from Excel to CSV before importing it into `country_codes`.
5. Run the numbered SQL queries. For Q12, update the city and minimum-rating variables as needed.
6. Review the query outputs alongside the dashboard image.

## Findings and Conclusion

The queries support analysis of restaurant concentration, cuisine popularity, rating patterns, pricing, and service options. Conclusions should be based on the actual query outputs and dashboard values; no numerical findings are claimed here without those results.

When interpreting the analysis:

- A rating of `0` represents an unrated restaurant and is excluded from rating summaries where appropriate.
- A restaurant can serve multiple cuisines, so cuisine counts may exceed the number of restaurants.
- Compare costs and value scores within the same currency.
- Differences between delivery or booking groups show associations, not proof that those services cause higher ratings.

Together, the SQL queries and dashboard provide a structured way to explore the dataset and develop recommendations supported by the results.
