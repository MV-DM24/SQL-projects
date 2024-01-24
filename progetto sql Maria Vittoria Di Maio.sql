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