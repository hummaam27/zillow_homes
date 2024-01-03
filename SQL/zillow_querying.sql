SET search_path TO zillow;


---------- Joining 3 tables ----------

SELECT *
FROM location L
JOIN year_price YP
ON L.region = YP.region
JOIN family_budget FB
on L.state = FB.state AND L.county = FB.county
LIMIT 100;




---------- Performing an aggregation ----------

SELECT state, county, year, bedrooms, round(AVG(price)) AS average_price
FROM year_price YP
JOIN location L
ON YP.region = YP.region
WHERE year = 2023
	AND state = 'MD'
	AND county = 'Anne Arundel County'
GROUP BY state, county, year, bedrooms
LIMIT 100;




-------- Using a window function to rank states on their average home price ----------

SELECT year, state, round(AVG(price)),
	RANK() OVER (PARTITION BY year ORDER BY avg(price) DESC NULLS LAST) AS price_rank
FROM year_price YP
JOIN location L
ON YP.region = L.region
WHERE year = 2023
	AND bedrooms = 3
GROUP BY state, year;




-------- Using a conditional CASE statement to categorize monthly expenditure ----------

SELECT state, county, round(AVG(total1)) AS monthly_expenditure,
	CASE	
		WHEN round(AVG(total1)) < 4000 THEN 'Low'
		WHEN round(AVG(total1)) BETWEEN 4000 AND 6000 THEN 'Medium'
		else 'High'
	END AS expense_rating
FROM family_budget
GROUP BY state, county
ORDER BY round(AVG(total1));




-------- Using a date function to see house trends for the last years ----------

SELECT L.state, L.county, YP.year, ROUND(AVG(YP.price)) AS AvgPrice
FROM location L
JOIN year_price YP ON L.region = YP.region
WHERE YP.year >= EXTRACT(YEAR FROM CURRENT_DATE) - 5
GROUP BY L.state, L.county, YP.year;




---------- Using a subquery to see where home prices are above average ----------

SELECT state, County, ROUND(AVG(price)) AS Above_average_price
FROM location L
JOIN year_price YP
ON l.region = YP.region
WHERE year = 2023
GROUP BY state, county
HAVING ROUND(AVG(price)) > (SELECT AVG(price) FROM year_price WHERE year = 2023)
ORDER BY above_Average_Price DESC;




---------- Comparing average monthly family income to average house prices ----------

SELECT L.State, ROUND(AVG(FB.median_family_income/12)) AS Avg_monthly_family_income, YP.AvgPrice
FROM family_budget FB
JOIN location L ON FB.state = L.state AND FB.county = L.county
JOIN (
    SELECT state, ROUND(AVG(price)) AS AvgPrice
    FROM location
    JOIN year_price ON location.region = year_price.region
    WHERE year = (SELECT MAX(year) FROM year_price)
    GROUP BY state
) YP ON L.state = YP.state
GROUP BY L.state, YP.AvgPrice;




-------- Using a CTE to see price idfference before and after Covid-19 ----------

WITH PriceAverages AS (
    SELECT state, county, 
    	ROUND(AVG(CASE WHEN year < 2020 THEN price ELSE NULL END)) AS avg_price_before_covid,
		ROUND(AVG(CASE WHEN year BETWEEN 2020 AND 2022 THEN price ELSE NULL END)) AS avg_price_during_covid,
    	ROUND(AVG(CASE WHEN year > 2021 THEN price ELSE NULL END)) AS avg_price_after_covid
    FROM location L
    JOIN year_price YP 
	ON L.region = YP.region
    GROUP BY state, county
)
SELECT state, county, avg_price_before_covid, avg_price_during_covid, avg_price_after_covid,
    ROUND(CASE WHEN avg_price_before_covid > 0 
		  THEN ((avg_price_after_covid - avg_price_before_covid) / avg_price_before_covid) * 100
		  ELSE NULL END) AS percent_change_before_and_after_covid
FROM PriceAverages
ORDER BY percent_change_before_and_after_covid DESC NULLS LAST;
	

































