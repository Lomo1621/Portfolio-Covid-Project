
-- The date data type is set to TEXT and is impossible to change to a DATETIME data type, because it is not in the right format. I tried changing it in Excel, but it would not save the format when
-- saving it as a CSV file. MySQL only accepts CSV files to be imported. 
-- Exploring Data Data that we are going to use

SELECT *
FROM coviddeaths
WHERE continent != ''
-- Empty values did not transfer over from CSV file as NULL values, but just as empty
-- Filters out locations that counted as a whole continent

-- Looking at Total Cases vs Total Deaths
-- Shows the chances of dying in a country after contracting covid

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent != ''
-- WHERE location = 


-- Looking at Total cases vs Population

SELECT location, date, total_cases, population, (total_cases / population) * 100 AS InfectionPercentage
FROM coviddeaths
WHERE continent !=
-- WHERE location = 'Faeroe Islands'


-- Countries with Highest Infection Rate per Population

SELECT location, population, MAX(total_cases) AS MaxInfectionCount, MAX((total_cases / population) * 100) AS InfectionPercentage
FROM Coviddeaths
WHERE continent != ''
GROUP BY location, population
ORDER BY InfectionPercentage DESC

-- Countries with Highest Death Count per population


SELECT location, MAX((total_deaths / population) * 100) AS MaxDeathPercentage
FROM Coviddeaths
WHERE continent != ''
GROUP BY location
ORDER BY MaxDeathPercentage DESC

-- Continents/Areas with Highest Infection Rate

SELECT location, MAX((total_cases / population) * 100) AS InfectionPercentage
FROM coviddeaths
WHERE continent = ''
GROUP BY location
ORDER BY InfectionPercentage DESC

-- Continents/Areas with Highest Death Rates

SELECT location, MAX((total_deaths / population) * 100) AS MaxDeathPercentage
FROM Coviddeaths
WHERE continent = ''
GROUP BY location
ORDER BY MaxDeathPercentage DESC


-- Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent != ''
GROUP BY date

-- Total Population vs Vaccination
-- SUBSTR(dea.date, -2, 2) = Year
-- SUBSTR(dea.date, 2, 1), SUBSTR(dea.date, 1, 1) = Month
-- The vaccinations get added by month and not during the days, I can not figure out how to correctly make it sort my date yet
-- If the date column would be in DATETIME data type or all in the same format, i.e. (mm/dd/yy) I would be able to sort it correctly,
-- but since the day in the given format can be in the 3rd through 5th spot in the string, it makes it very difficult to sort it correctly


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, SUBSTR(dea.date, -2, 2), SUBSTR(dea.date, 2, 1), 
		SUBSTR(dea.date, 1, 1))  AS VacCount
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY dea.location




-- Create Temp table to get be able to use the newly created VacCount column in another calculation

-- Drop statement if needed after 
DROP TEMPORARY TABLE VaccinationPercentage

CREATE TEMPORARY TABLE VaccinationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, SUBSTR(dea.date, -2, 2), SUBSTR(dea.date, 2, 1), 
		SUBSTR(dea.date, 1, 1))  AS VacCount
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''

-- Query from Temp table
SELECT *, (VacCount / population) * 100 AS VacPercentage
FROM VaccinationPercentage




-- Creating View to save data for visualization

CREATE VIEW VacPercentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, SUBSTR(dea.date, -2, 2), SUBSTR(dea.date, 2, 1), 
		SUBSTR(dea.date, 1, 1))  AS VacCount
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''


-- Queries I use to create Visualizations in Tableau

-- 1. Calculating the total cases, deaths, death percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
	SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent != ''

-- 2. Find the numbers for the specific locations, excluding regions European Union, High Income, International, and Low Income to
-- avoid double counting and stay consistent. For some reason Asia is excluded in the location column, so I need to use the Union statement.

(SELECT location, SUM(new_deaths) AS total_deaths
FROM coviddeaths
WHERE continent = ''
	AND location NOT IN ('European Union', 'High Income', 'International', 'Low Income')
GROUP BY location)
UNION
(SELECT continent, SUM(new_deaths) AS total_deaths
FROM coviddeaths
WHERE continent = 'Asia'
GROUP BY continent )
ORDER BY total_deaths DESC

-- 3. Calculating the percentage of infected people in each country


SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopInfected
FROM coviddeaths
WHERE continent != ''
GROUP BY location, population
ORDER BY PercentPopInfected DESC

-- 4. Calculate the Infection rate per day per location

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopInfected
FROM coviddeaths
GROUP BY location, population, date
ORDER BY PercentPopInfected DESC 
