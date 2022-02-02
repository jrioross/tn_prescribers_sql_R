/* 

1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
   Report the npi and the total number of claims.
   
   b. Repeat the above, but this time report the 
   nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
   
*/

-- a

SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescriber
NATURAL JOIN prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 3;

-- prescriber npi 1881634483 with 99,707 claims

-- b

SELECT npi, 
	nppes_provider_first_name, 
	nppes_provider_last_org_name,  
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
NATURAL JOIN prescription
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
ORDER BY total_claims DESC
LIMIT 3;

-- it's Bruce with that 99,707

---------------------------------------------------------------------------------------------- 2

/*

2. a. Which specialty had the most total number of claims (totaled over all drugs)?

    b. Which specialty had the most total number of claims for opioids?

    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
   
*/

-- a

SELECT specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
NATURAL JOIN prescription
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 3;

-- Family Practice with 9,752,347 claims

-- b

SELECT specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
INNER JOIN drug
	USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 3;

-- Nurse Practitioner with 900,845 (This is terrifying.)

-- c



-- d


---------------------------------------------------------------------------------------------- 3

/*

3. a. Which drug (generic_name) had the highest total drug cost?

    b. Which drug (generic_name) has the hightest total cost per day? 
	**Bonus: Round your cost per day column to 2 decimal places. 
	Google ROUND to see how this works.
	
*/

-- a

SELECT generic_name, total_drug_cost
FROM drug
NATURAL JOIN prescription
ORDER BY total_drug_cost DESC;

-- PIRFENIDONE at $2,829,174.30 !!!

-- b

SELECT generic_name, 
	total_drug_cost, 
	total_day_supply,
	ROUND(total_drug_cost/total_day_supply, 2)::money AS cost_per_day
FROM drug
NATURAL JOIN prescription
ORDER BY cost_per_day DESC;

-- IMMUN GLOB G(IGG)/GLY/IGA OV50 at $7,141.11 per day

---------------------------------------------------------------------------------------------- 4

/*

4. a. For each drug in the drug table, return the drug name and then a column named
   'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
   says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
   and says 'neither' for all other drugs.

    b. Building off of the query you wrote for part a, 
	determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
	Hint: Format the total costs as MONEY for easier comparision.
	
*/

-- a

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug

-- b

WITH drug_class AS (
	SELECT drug_name,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE 'neither' END AS drug_type
	FROM drug
)
SELECT drug_type,
	SUM(total_drug_cost)::money AS total_spent
FROM drug_class
NATURAL JOIN prescription
WHERE drug_type <> 'neither'
GROUP BY drug_type
ORDER BY total_spent DESC;

-- About 3x more was spent on opioids

---------------------------------------------------------------------------------------------- 5

/*

5. a. How many CBSAs are in Tennessee? 
   **Warning:** The cbsa table contains information for all states, not just Tennessee.

    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
	
*/

-- a

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN';

-- There are 10 distinct CBSAs in TN

-- b

SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population
	USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC
LIMIT 5;

-- Nashville-Davidson--Murfreesboro--Franklin, TN has a total population of 1,830,410

-- c

SELECT county, population
FROM fips_county
INNER JOIN population
	USING (fipscounty)
WHERE county NOT IN
	(
	SELECT county
	FROM fips_county
	INNER JOIN cbsa
		USING (fipscounty)
	)
ORDER BY population DESC
LIMIT 3;

-- Sevier county is the highest-populated county not in a CBSA: 95,523

---------------------------------------------------------------------------------------------- 6

/*

6. 
    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

*/

-- a

SELECT drug_name, total_claim_count
FROM prescription
INNER JOIN drug
	USING (drug_name)
WHERE total_claim_count >= 3000;

-- b

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug
	USING (drug_name)
WHERE total_claim_count >= 3000;

-- c

SELECT drug_name, 
	total_claim_count, 
	opioid_drug_flag,
	nppes_provider_first_name,
	nppes_provider_last_org_name
FROM prescription
INNER JOIN drug
	USING (drug_name)
LEFT JOIN prescriber
	USING(npi)
WHERE total_claim_count >= 3000;

-- David and Bruce, man

---------------------------------------------------------------------------------------------- 7

/*

7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') 
	in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
	where the drug is an opioid (opiod_drug_flag = 'Y'). 
	**Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.

    b. Next, report the number of claims per drug per prescriber. 
	Be sure to include all combinations, whether or not the prescriber had any claims. 
	You should report the npi, the drug name, and the number of claims (total_claim_count).
    
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
	
*/

-- a

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'

-- b

SELECT
	prescriber.npi,
	nppes_provider_first_name, 
	nppes_provider_last_org_name,  
	drug_name, 
	total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY nppes_provider_last_org_name, nppes_provider_first_name
	

-- c

SELECT
	prescriber.npi,
	nppes_provider_first_name, 
	nppes_provider_last_org_name,  
	drug_name, 
	COALESCE(total_claim_count, 0) AS total_claim_count_filled
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY nppes_provider_last_org_name, nppes_provider_first_name