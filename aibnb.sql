/* Practice on SQL using MySQL database

*/

-- create table 
CREATE TABLE AirbnbListings ( 
    id INT,
    name VARCHAR(255),
    host_id INT,
    room_type VARCHAR(50),
    price DECIMAL(10, 2),
    number_of_reviews INT,
    last_review DATE,
    reviews_per_month DECIMAL(3, 1),
    availability_365 INT
);

-- import data
-- Data sourced from Inside Airbnb (https://insideairbnb.com/get-the-data/)
LOAD DATA INFILE 'Airbnb_rental_listings.csv'
INTO TABLE AirbnbListings
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- Query to find all listings with more than 50 reviews
SELECT *
FROM AirbnbListings
WHERE number_of_reviews > 50;

-- Query to find all listings available for more than 300 days a year
SELECT *
FROM AirbnbListings
WHERE availability_365 > 300;

-- Calculate the average price of listings in each neighbourhood
SELECT neighbourhood, AVG(price) AS average_price
FROM AirbnbListings
GROUP BY neighbourhood;

-- Count the total number of listings per host and find the top 5 hosts by the number of listings
SELECT host_id, COUNT(*) AS total_listings
FROM AirbnbListings
GROUP BY host_id
ORDER BY total_listings DESC 
LIMIT 5;

/* Find listings that are categorized as "Entire home/apt" 
and priced below the average price of all entire homes/apts in the dataset */
SELECT * FROM AirbnbListings
WHERE room_type = 'Entire home/apt' AND price < (
    SELECT AVG(price)
    FROM AirbnbListings
    WHERE room_type = 'Entire home/apt'
);

-- List all properties that have not been reviewed since a certain date, for example, since 2020
SELECT *
FROM AirbnbListings
WHERE last_review < '2020-01-01' OR last_review IS NULL; -- date condition

/* Subqueries and Nested Queries:
Find neighbourhoods where the average number of reviews per 
listing is higher than the overall average across all neighbourhoods */
SELECT neighbourhood, AVG(number_of_reviews) AS avg_reviews FROM AirbnbListings
GROUP BY neighbourhood
HAVING AVG(number_of_reviews) > ( -- higher than avg_reviews across all neigh.
    SELECT AVG(number_of_reviews) FROM AirbnbListings
);

/* Analyze the seasonal availability of properties:
Calculate the average availability of properties by month to identify peak and off-peak seasons.
THIS SECTION WON'T BE APPLIED, REQUIRE MORE DETAILED INFO FROM ACTUAL DATA*/
/* 
SELECT  -- Calculate the average number of days booked per month
    MONTH(date_start) AS month, 
    AVG(DATEDIFF(date_end, date_start) + 1) AS avg_days_booked
FROM Booking
GROUP BY MONTH(date_start);
*/

/* Geospatial Queries:
Find listings within a certain distance from a popular landmark or center 
(using Haversine Formula to compute distances)
*/
WITH DistanceCalc AS ( -- use CTE (Common table expression), temporary result
    SELECT *,
        (6371 * acos(
            cos(radians(40.6892)) * cos(radians(latitude)) * 
            cos(radians(longitude) - radians(-74.0445)) +
            sin(radians(40.6892)) * sin(radians(latitude)) -- Haversine Formula
        )) AS distance_km 
    FROM AirbnbListings
)
SELECT * FROM DistanceCalc
WHERE distance_km < 10
ORDER BY distance_km;


/* Correlation Analysis:
Explore potential correlations between price and other factors
( number of reviews, availability, or minimum nights) . (This could involve 
complex joins or subqueries to calculate averages and compare across categories). */

-- Correlation between Price and Number of Reviews
SELECT 
    CASE 
        WHEN number_of_reviews BETWEEN 0 AND 10 THEN '0-10'
        WHEN number_of_reviews BETWEEN 11 AND 50 THEN '11-50'
        WHEN number_of_reviews BETWEEN 51 AND 100 THEN '51-100'
        ELSE '100+' 
    END AS review_category,
    AVG(price) AS average_price,
    COUNT(*) AS listings_count
FROM AirbnbListings
GROUP BY review_category;

-- Correlation between Price and Availability
SELECT 
    CASE 
        WHEN availability_365 BETWEEN 0 AND 120 THEN 'Low availability'
        WHEN availability_365 BETWEEN 121 AND 240 THEN 'Medium availability'
        ELSE 'High availability'
    END AS availability_category,
    AVG(price) AS average_price,
    COUNT(*) AS listings_count
FROM AirbnbListings
GROUP BY availability_category;

-- Correlation between Price and Minimum Nights
SELECT 
    CASE 
        WHEN minimum_nights <= 3 THEN 'Short stays'
        WHEN minimum_nights BETWEEN 4 AND 7 THEN 'Medium stays'
        ELSE 'Long stays'
    END AS stay_length,
    AVG(price) AS average_price,
    COUNT(*) AS listings_count
FROM AirbnbListings
GROUP BY stay_length;

/* Use SQL window functions to rank listings within each neighbourhood by price 
or by number of reviews. Identify the top 3 most expensive or most reviewed 
properties in each neighbourhood. */

-- Ranking Listings by Price
WITH RankedPrices AS (
    SELECT  
        id,
        name,
        neighbourhood,
        price,
        RANK() OVER (PARTITION BY neighbourhood ORDER BY price DESC) AS price_rank
    FROM 
        AirbnbListings
)
SELECT * FROM RankedPrices WHERE price_rank <= 3 ;

-- Ranking Listings by Number of Reviews
WITH RankedReviews AS (
    SELECT 
        id,
        name,
        neighbourhood,
        number_of_reviews,
        DENSE_RANK() OVER (PARTITION BY neighbourhood ORDER BY number_of_reviews DESC) AS review_rank
    FROM  
        AirbnbListings
)
SELECT * FROM RankedReviews WHERE review_rank <= 3;

