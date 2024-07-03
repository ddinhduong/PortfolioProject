--SELECT * FROM PortfolioProject..CovidDeaths 
--ORDER BY 3,4

--SELECT * FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--SELECT DATA IS GOING TO BE USED
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths 
ORDER BY 1,2 


--RATIO BETWEEN TOTALCASES AND TOTALDEATHS.

--World
DROP TABLE IF EXISTS #TotalInTheWorld
CREATE TABLE #TotalInTheWorld
(
location nvarchar (255),
TotalCases numeric,
TotalDeaths numeric
)

INSERT INTO #TotalInTheWorld
SELECT 'WorldWide', MAX(total_cases) as TotalCases, MAX(CAST(total_deaths as int)) as TotalDeaths 
	FROM PortfolioProject..CovidDeaths
WHERE location NOT IN ('North America', 'South America', 'Europe');

SELECT *, (TotalDeaths/TotalCases)*100 AS DeathPercentage FROM #TotalInTheWorld

--PER COUNTRY
SELECT location, population, TotalCases, TotalDeaths, (TotalDeaths/TotalCases) as DeathPercentage
FROM 
	(
		SELECT location, population, MAX(total_cases) as TotalCases, MAX(CAST(total_deaths as int)) as TotalDeaths
		FROM PortfolioProject..CovidDeaths
		GROUP BY location, population
		) AS SubQuery




--FINDING CASERATE (RATIO BETWEEN TOTALCASES AND POPULATION)

--World
SELECT  location, population, date, HighestInfectionCount, CaseRate
FROM
(	SELECT
	location, date, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as CaseRate
	FROM PortfolioProject..CovidDeaths
	GROUP BY location, population, date
) AS Subquery
WHERE population is not null and HighestInfectionCount is not null

--Country
SELECT location, population, HighestInfectionCount, CaseRate
FROM
(	SELECT
	location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as CaseRate
	FROM PortfolioProject..CovidDeaths
	GROUP BY location, population
) AS Subquery
WHERE population is not null and HighestInfectionCount is not null

--FINDING DEATHRATE (RATIO BETWEEN TOTALDEATHS AND POPULATION)

--WORLD
SELECT 
		SUM(Population) AS TotalPopulation,
		SUM(TotalDeath) AS TotalDeaths,
		(SUM(TotalDeath)/SUM(Population)) *100 as DeathRate
FROM	
(
		SELECT continent, 
				SUM(population) as Population, 
				SUM(MaxDeathPerCountry) as TotalDeath
		FROM
		(
			SELECT continent, 
					population,
					MAX(CAST(total_deaths as int)) AS MaxDeathPerCountry 
			FROM PortfolioProject..CovidDeaths
			WHERE continent is not null
			GROUP BY continent, population
		) AS SubQuery1 
		GROUP BY continent
) as SubQuery2


--PER COUNTRY
SELECT location, population, TotalDeathCount, (TotalDeathCount/population) * 100 as DeathRate
FROM 
		(SELECT location, population, MAX(CAST(Total_deaths as int)) as TotalDeathCount FROM
		PortfolioProject..CovidDeaths
		GROUP BY location, population) 
AS SubQuery
ORDER BY DeathRate desc

--PER CONTINENT
SELECT	continent, 
		TotalPopulation,
		TotalDeath,
		(TotalDeath/TotalPopulation) *100 as DeathRate
FROM	
(
		SELECT continent, 
				SUM(population) as TotalPopulation, 
				SUM(MaxDeathPerCountry) as TotalDeath
		FROM
		(
			SELECT continent, 
					population,
					MAX(CAST(total_deaths as int)) AS MaxDeathPerCountry 
			FROM PortfolioProject..CovidDeaths
			GROUP BY continent, population
		) AS SubQuery1 
		GROUP BY continent
) as SubQuery2
WHERE continent is not NULL
ORDER BY DeathRate desc

--FINDING VACCINATIONSRATE (RATIO BETWEEN TOTALVACCINATIONS AND POPULATION)

--PER COUNTRY
SELECT location, continent, population, TotalCase, TotalVaccinations,
		TotalVaccinations/ population * 100 as VaccinationRate
FROM
(	
		SELECT dea.location, dea.continent, dea.population,
				MAX(CAST(dea.total_cases as int)) as TotalCase, 
				SUM(CAST(vac.new_vaccinations as int)) as TotalVaccinations
		FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
		WHERE vac.new_vaccinations IS NOT NULL
			AND dea.continent IS NOT NULL
		GROUP BY dea.location, dea.continent, dea.population
) as SubQuery
WHERE TotalCase IS NOT NULL
ORDER BY location, continent

--CTE Ratio between TotalPopulation and TotalVaccinations Per Country
WITH SubQuery AS
(	
		SELECT dea.location, dea.continent, dea.population, 
				MAX(CAST(dea.total_cases as int)) as TotalCase, 
				SUM(CAST(vac.new_vaccinations as int)) as TotalVaccinations
		FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
		WHERE vac.new_vaccinations IS NOT NULL
			AND dea.continent IS NOT NULL
		GROUP BY dea.location, dea.continent, dea.population
)
SELECT location, continent, population, TotalCase, TotalVaccinations,
		TotalVaccinations/ population * 100 as VaccinationRate
FROM SubQuery
WHERE TotalCase IS NOT NULL
ORDER BY location, continent

--TEMP TABLE Ratio between TotalPopulation and TotalVaccinations Per Country
DROP TABLE IF EXISTS #RatioTotalPopulationandTotalVaccinations
CREATE TABLE #RatioTotalPopulationandTotalVaccinations
(
continent nvarchar(255),
location nvarchar(255),
population numeric,
TotalCase numeric,
TotalVaccinations numeric
)

INSERT INTO #RatioTotalPopulationandTotalVaccinations (continent, location, population, TotalCase, TotalVaccinations)
SELECT continent, location, population, TotalCase, TotalVaccinations
FROM
(	
		SELECT dea.location, dea.continent, dea.population, 
				MAX(CAST(dea.total_cases as int)) as TotalCase, 
				SUM(CAST(vac.new_vaccinations as int)) as TotalVaccinations
		FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
		WHERE vac.new_vaccinations IS NOT NULL
			AND dea.continent IS NOT NULL
		GROUP BY dea.location, dea.continent, dea.population
) as SubQuery
WHERE TotalCase IS NOT NULL

SELECT *, TotalVaccinations/ population * 100 as VaccinationRate
FROM #RatioTotalPopulationandTotalVaccinations
ORDER BY 1,2 

--CREATE VIEW STORE DATA

DROP VIEW IF EXISTS RatioTotalPopulationandTotalVaccinations
CREATE VIEW RatioTotalPopulationandTotalVaccinations AS 
SELECT continent, location, population, TotalCase, TotalVaccinations
FROM
(	
		SELECT dea.location, dea.continent, dea.population, 
				MAX(CAST(dea.total_cases as int)) as TotalCase, 
				SUM(CAST(vac.new_vaccinations as int)) as TotalVaccinations
		FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
		WHERE vac.new_vaccinations IS NOT NULL
			AND dea.continent IS NOT NULL
		GROUP BY dea.location, dea.continent, dea.population
) as SubQuery
WHERE TotalCase IS NOT NULL
ORDER BY location, continent
