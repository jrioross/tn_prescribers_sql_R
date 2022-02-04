/* 

1. How many npi numbers appear in the prescriber table but not in the prescription table?
  
*/

SELECT COUNT(*)
FROM 
	(SELECT npi
	FROM prescriber
	EXCEPT
	SELECT npi
	FROM prescription) as s;

-- 4,458

---------------------------------------------------------------------------------------------- 2

/*

2.
    a. Find the top five drugs (generic_name) prescribed by prescribers 
	with the specialty of Family Practice.

    b. Find the top five drugs (generic_name) prescribed by prescribers 
	with the specialty of Cardiology.

    c. Which drugs appear in the top five prescribed for both 
	Family Practice prescribers and Cardiologists?
	Combine what you did for parts a and b into a single query to answer this question.
	

*/

-- a

SELECT 
	generic_name, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
NATURAL JOIN prescription
NATURAL JOIN drug
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- Chris

SELECT 
	generic_name, 
	SUM(total_claim_count) AS tcc
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE npi IN
	(
		SELECT npi
		FROM prescriber
		WHERE specialty_description = 'Family Practice'
	)
GROUP BY generic_name
ORDER BY tcc DESC
LIMIT 5;


-- b

SELECT 
	generic_name, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
NATURAL JOIN prescription
NATURAL JOIN drug
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

-- c

-- Drugs in both top 5s

(SELECT 
	generic_name
FROM prescriber
NATURAL JOIN prescription
NATURAL JOIN drug
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
INTERSECT
(SELECT 
	generic_name
FROM prescriber
NATURAL JOIN prescription
NATURAL JOIN drug
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)

-- Alternate interpretation

SELECT 
	generic_name, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
NATURAL JOIN prescription
NATURAL JOIN drug
WHERE specialty_description IN ('Family Practice', 'Cardiology')
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

---------------------------------------------------------------------------------------------- 3

/*

3. Your goal in this question is to generate a list of 
   the top prescribers in each of the major metropolitan areas of Tennessee.
   
    a. First, write a query that finds the top 5 prescribers in Nashville 
	in terms of the total number of claims (total_claim_count) across all drugs. 
	Report the npi, the total number of claims, and include a column showing the city.
	
    b. Now, report the same for Memphis.
	
    c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
	
*/

-- a

SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- b

SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- c

(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
ORDER BY nppes_provider_city, total_claims DESC;

---------------------------------------------------------------------------------------------- 4

/*

4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017. 
   Report the county name and number of overdose deaths.
   
*/

SELECT county, overdose_deaths
FROM overdose_deaths
INNER JOIN fips_county
	USING (fipscounty)
WHERE year = 2017
AND overdose_deaths > (SELECT AVG(overdose_deaths) 
						 FROM overdose_deaths
						 WHERE year = 2017
						 GROUP BY year);

---------------------------------------------------------------------------------------------- 5

/*

5.
    a. Write a query that finds the total population of Tennessee.
	
    b. Build off of the query that you wrote in part a 
	to write a query that returns for each county that county's 
	name, its population, and the percentage of the total population of Tennessee 
	that is contained in that county.
	
*/

-- a

SELECT SUM(population)
FROM population

-- 6,597,381

-- b

SELECT
	county,
	ROUND(100*population/SUM(population) OVER(), 2) AS with_window,
	ROUND(100*population/(SELECT SUM(population) FROM population), 2) AS with_subquery
FROM population
INNER JOIN fips_county
USING (fipscounty)


