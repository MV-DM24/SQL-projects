/*inizio con il creare una tabella per inserire i dati*/
CREATE TABLE world_data (
    Country VARCHAR(255),
    Density TEXT,
    Abbreviation VARCHAR(2),
    Agricultural_Land TEXT,
    Land_Area TEXT,
    Armed_Forces_Size TEXT,
    Birth_Rate TEXT,
    Calling_Code INT,
    Capital_Major_City VARCHAR(255),
    Co2_Emissions TEXT,
    CPI TEXT,
    CPI_Change TEXT,
    Currency_Code VARCHAR(3),
    Fertility_Rate TEXT,
    Forested_Area TEXT,
    Gasoline_Price TEXT,
    GDP VARCHAR(255), 
    Gross_Primary_Education_Enrollment TEXT,
    Gross_Tertiary_Education_Enrollment TEXT,
    Infant_Mortality TEXT,
    Largest_City VARCHAR(255),
    Life_Expectancy TEXT,
    Maternal_Mortality_Ratio TEXT,
    Minimum_Wage TEXT,
    Official_Language VARCHAR(255),
    Out_of_Pocket_Health_Expenditure TEXT,
    Physicians_Per_Thousand TEXT,
    Population TEXT,
    Population_Labor_Force_Participation TEXT,
    Tax_Revenue TEXT,
    Total_Tax_Rate TEXT,
    Unemployment_Rate TEXT,
    Urban_Population TEXT,
    Latitude DECIMAL(9, 6),
    Longitude DECIMAL(9, 6)
);

/*importo i dati dal file csv con il comando \copy e man mano pulisco e modifico i dati usando le funzioni UPDATE e ALTER TABLE per renderli numerici
ex.: ALTER TABLE world_data ALTER COLUMN life_expectancy TYPE NUMERIC USING life_expectancy::numeric;

UPDATE world_data
SET GDP = CAST(REPLACE(REPLACE(REPLACE(GDP, '"', ''), '$', ''), ',', '') AS numeric)
WHERE GDP IS NOT NULL
  AND GDP NOT LIKE '%[^0-9]%';
ALTER TABLE world_data
ALTER COLUMN GDP TYPE numeric USING GDP::numeric;*/

SELECT AVG(Life_Expectancy) FROM world_data; --72 anni, ma ora voglio vedere come questa aspettativa cambia nei Paesi con un GDP sopra la media
WITH average_gdp (avg_gdp) AS 
  ((SELECT AVG(GDP) FROM world_data)) 
  SELECT AVG(Life_Expectancy) FROM world_data, average_gdp WHERE GDP>avg_gdp; --circa 79 anni
WITH average_gdp (avg_gdp) AS
  ((SELECT AVG(gdp) FROM world_data))
  SELECT AVG(Life_Expectancy) FROM world_data, average_gdp WHERE GDP<avg_gdp; --circa 71 anni

SELECT CORR(Life_Expectancy, Out_of_Pocket_Health_Expenditure) AS correlation_coefficient FROM world_data; -- -0.33 è il coefficiente di correlazione tra l'aspettativa di vita e le spese medice out of pocket

/*trovo la distribuzione dell'aspettative di vita usando la mediana e i quartili della distribuzione*/
SELECT
    MIN(life_expectancy) AS min_life_expectancy, --52.8
    MAX(life_expectancy) AS max_life_expectancy, --85.4
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY life_expectancy) as q1_life_expectancy, --67
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Life_Expectancy) as median_life_expectancy, --73.2
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Life_Expectancy) as q3_life_expectancy --77.5
FROM world_data;
SELECT country FROM world_data WHERE Life_Expectancy IS NOT NULL ORDER BY life_expectancy DESC LIMIT 5; --trovo i 5 Paesi con l'aspettativa di vita più alta

SELECT CORR(GDP, Gross_Primary_Education_Enrollment) AS correlation_coefficient FROM world_data; --0,00 la correlazione tra queste due variabili è pressoché inesistente
SELECT CORR(GDP, Gross_Tertiary_Education_Enrollment) as correlation_coefficient from world_data; --0.21

/*comincio ad unire le 2 tabelle world_data e sustainability_data per un'analisi dei dati sulla sostenibilità*/

WITH average_renewable_use AS (
    SELECT 
        entity,
        year,
        AVG(gdp_percapita) AS avg_gdp_percapita,
        AVG(renewable_energy_share_in_consumption) AS avg_renewable_energy_share
    FROM 
        sustainability_data
    GROUP BY 
        entity, 
        year
)
SELECT 
    corr(avg_gdp_percapita, avg_renewable_energy_share) AS correlation_coefficient
FROM (
    SELECT 
        wd.country,
        aru.year,
        aru.avg_renewable_energy_share,
        aru.avg_gdp_percapita
    FROM 
        world_data wd
    LEFT JOIN 
        average_renewable_use aru ON wd.country = aru.entity
) AS combined_data;
/*questa query mi permette di analizzare il rapporto tra percentuale di energia rinnovabile consumata nel tempo e gdp procapite dei paesi
-0.34, questo significa che all'aumentare del gdp procapite la percentuale di energia rinnovabile consumata diminuisce, anche se la correlazione è debole*/

WITH world_sustainability AS (
    SELECT wd.country,
           wd.GDP,
           sd.year,
           sd.CO2_Emissions,
           sd.gdp_percapita
    FROM world_data wd
    LEFT JOIN sustainability_data sd ON wd.country = sd.entity 
)
SELECT 
    CORR(GDP, CO2_Emissions) AS correlation_gdp_co2,
    CORR(GDP, gdp_percapita) AS correlation_gdp_gdp_percapita,
    CORR(CO2_Emissions, gdp_percapita) AS correlation_co2_gdp_percapita
FROM 
    world_sustainability;

/*uso questa query per unire le due tabelle con cui sto lavorando e calcolare la correlazione tra gdp ed emissioni di co2, gdp e gdp procapite, emissioni e gdp procapite
La prima risulta molto forte e positiva con un valore di 0.93. La seconda e la terza sono sempre positive ma deboli.*/

/*Infine creo un indice di performance ambientale (EPI) e faccio un ranking dei paesi in base a quello*/
--normalizzo i dati delle due tabelle creando due CTEs
WITH normalized_data AS (
    SELECT
        entity AS country,
        (CO2_Emissions - MIN(CO2_Emissions) OVER ()) / NULLIF((MAX(CO2_Emissions) OVER () - MIN(CO2_Emissions) OVER ()), 0) AS normalized_co2_emissions,
        (access_to_electricity - MIN(access_to_electricity) OVER ()) / NULLIF((MAX(access_to_electricity) OVER () - MIN(access_to_electricity) OVER ()), 0) AS normalized_access_to_electricity,
        (access_to_cleanfuels - MIN(access_to_cleanfuels) OVER ()) / NULLIF((MAX(access_to_cleanfuels) OVER () - MIN(access_to_cleanfuels) OVER ()), 0) AS normalized_access_to_cleanfuels,
        (percentage_renewables - MIN(percentage_renewables) OVER ()) / NULLIF((MAX(percentage_renewables) OVER () - MIN(percentage_renewables) OVER ()), 0) AS normalized_percentage_renewables,
        (density - MIN(density) OVER ()) / NULLIF((MAX(density) OVER () - MIN(density) OVER ()), 0) AS normalized_density
    FROM
        sustainability_data
),
world_data_normalized AS (
    SELECT
        country,
        (GDP - MIN(GDP) OVER ()) / NULLIF((MAX(GDP) OVER () - MIN(GDP) OVER ()), 0) AS normalized_gdp,
        (agricultural_land - MIN(agricultural_land) OVER ()) / NULLIF((MAX(agricultural_land) OVER () - MIN(agricultural_land) OVER ()), 0) AS normalized_agricultural_land,
        (land_area - MIN(land_area) OVER ()) / NULLIF((MAX(land_area) OVER () - MIN(land_area) OVER ()), 0) AS normalized_land_area,
        (population - MIN(population) OVER ()) / NULLIF((MAX(population) OVER () - MIN(population) OVER ()), 0) AS normalized_population,
        (gasoline_price - MIN(gasoline_price) OVER ()) / NULLIF((MAX(gasoline_price) OVER () - MIN(gasoline_price) OVER ()), 0) AS normalized_gasoline_price
    FROM
        world_data
),
--e sempre con una CTE assegno dei pesi specifici alle variabili escludendo i valori nulli
weighted_scores AS (
    SELECT
        nd.country,
        (0.2 * nd.normalized_co2_emissions) AS co2_score,
        (0.1 * nd.normalized_access_to_electricity) AS access_to_electricity_score,
        (0.1 * nd.normalized_access_to_cleanfuels) AS access_to_cleanfuels_score,
        (0.1 * nd.normalized_percentage_renewables) AS percentage_renewables_score,
        (0.05 * nd.normalized_density) AS density_score,
        (0.1 * wdn.normalized_gdp) AS gdp_score,
        (0.1 * wdn.normalized_agricultural_land) AS agricultural_land_score,
        (0.05 * wdn.normalized_land_area) AS land_area_score,
        (0.1 * wdn.normalized_population) AS population_score,
        (0.1 * wdn.normalized_gasoline_price) AS gasoline_price_score
    FROM
        normalized_data nd
    JOIN
        world_data_normalized wdn ON nd.country = wdn.country
    WHERE
        normalized_co2_emissions IS NOT NULL
        AND normalized_access_to_electricity IS NOT NULL
        AND normalized_access_to_cleanfuels IS NOT NULL
        AND normalized_percentage_renewables IS NOT NULL
        AND normalized_density IS NOT NULL
        AND normalized_GDP IS NOT NULL
        AND normalized_agricultural_land IS NOT NULL
        AND normalized_land_area IS NOT NULL
        AND normalized_population IS NOT NULL
        AND normalized_gasoline_price IS NOT NULL
)
-- colcolo gli epi score generali
SELECT
    country,
    MAX((co2_score + access_to_electricity_score + access_to_cleanfuels_score + percentage_renewables_score + density_score +
     gdp_score + agricultural_land_score + land_area_score + population_score + gasoline_price_score)) AS epi_score
FROM
    weighted_scores
GROUP BY weighted_scores.country
ORDER BY
    epi_score DESC;
