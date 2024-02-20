

--select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4

--Select data

Select Location, date, total_cases, new_cases, total_deaths, population
	From PortfolioProject..CovidDeaths
	Order by 1,2

-- Looking at TotalCases and TotalDeaths in Europe

Select location,
		continent,
		max(total_cases) as TotalCases
		,Max(Cast(total_deaths as int)) as TotalDeaths
		,(MAX(CAST(total_deaths AS int)/total_cases))*100 as DeathsPerCases
	From PortfolioProject..CovidDeaths
	where continent like '%Eu%'
	Group by location,continent
	Having Max(Cast(total_deaths as int)/total_cases)*100 is not null
	Order by TotalCases

-- Looking at TotalCases vs Population in United States
Select Location, date, total_cases, Population, (total_cases/Population)*100 as DeathPercentage
	From PortfolioProject..CovidDeaths
	where Location = 'United States'
	Order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population in 1/2021 - 4/2022
Select	Location,
		Population, 
		Max(total_cases) as HighestInfectionCount,
		Max(total_cases/Population)*100 as InfectedPerPopulation
From PortfolioProject..CovidDeaths
Group by Location, Population
Order by InfectedPerPopulation Desc

--Showing Countries with Highest Death Count per Population
Select	Location,
		Population,
		Max(cast(total_deaths as int)) as TotalDeathsCount,
		Max(cast(total_deaths as int)/Population)*100 as DeathPerPopulation
From PortfolioProject..CovidDeaths
where Location != 'World' and continent is not null
Group by Location, Population
Order by TotalDeathsCount desc

--GLOBAL NUMBERS Death/Case per day

Select
	date,
	SUM(new_cases) as TotalNewCases,
	Sum(cast(new_deaths as int)) as TotalNewDeaths,
	(Sum(cast(new_deaths as int)) / SUM(new_cases)) *100 as DeathPercentage
From PortfolioProject..CovidDeaths
	where continent is not null
	Group by date
	Having (Sum(cast(new_deaths as int)) / SUM(new_cases)) *100 is not null
	Order by 1,2

  --Showing Continent with The highest DeathCount.
Select 
		continent
		,Sum(MaxDeathCount) as TotalDeathCount
From 
	(Select continent,
			location
			,Max(Cast(Total_deaths as int)) as MaxDeathCount
		From PortfolioProject..CovidDeaths
	Group by location, continent
	) as subquery	
where continent is not null
Group by continent
order by TotalDeathCount desc

--Showing Continents with highes DeathCount per Population.
-- partition by for sum single continent 
  SELECT
  continent,
  SUM(MaxTotalDeaths) AS TotalDeath,
  SUM(MaxTotalDeaths) / SUM(Population) AS DeathPerPopulation
FROM (
-- subquery for finding the highest totaldeaths of each contry
  SELECT
    continent, location, population,
    MAX(CAST(total_deaths AS INT)) AS MaxTotalDeaths --TotalDeath each country
  FROM
    PortfolioProject..CovidDeaths
  WHERE
    continent IS NOT NULL
  GROUP BY
    continent, location,  population
) AS Subquery
-- use consequence of subquery to summarize totaldeath of continent
GROUP BY
  continent
ORDER BY
  continent;


  ------------------------------------------------------------------------------

-- Total Population vs Vaccinations

--Temp table
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric, 
RollingPeopleVaccinated numeric, 
rn numeric
)

Insert into #PercentPopulationVaccinated
Select 
		dea.continent, 
		dea.location
		,dea.date, 
		dea.population,
		vac.new_vaccinations, 
		Sum(convert(int, vac.new_vaccinations)) over
		(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
		,row_number() over (partition by dea.location order by dea.location, dea.date desc) as rn
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null

Select 
		continent, 
		location, 
		date, 
		population, 
		new_vaccinations, 
		RollingPeopleVaccinated,
        (RollingPeopleVaccinated / population) * 100 as VaccinatedPeoplePerPopulation
From #PercentPopulationVaccinated 
where rn=1 and (RollingPeopleVaccinated / population)* 100 is not null and
(RollingPeopleVaccinated / population)* 100 < 100
order by VaccinatedPeoplePerPopulation


--CTE 

With VacperPop(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated, rn)
as 
(
Select	dea.continent, dea.location, 
		dea.date, dea.population, 
		vac.new_vaccinations,
		Sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
		,row_number() over (partition by dea.location order by dea.location, dea.date desc) as rn
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select 
		continent, 
		location, date, population, new_vaccinations, 
		RollingPeopleVaccinated,
        (RollingPeopleVaccinated / population) * 100 as VaccinatedPeoplePerPopulation
from VacperPop where rn=1 and (RollingPeopleVaccinated / population)* 100 is not null and
(RollingPeopleVaccinated / population)* 100 < 100
order by VaccinatedPeoplePerPopulation



--subquery

SELECT
  continent,
  location,
  date,
  population,
  RollingPeopleVaccinate,
  (RollingPeopleVaccinate/population)*100 as VaccinatedPeoplePerPopulation
FROM 
-- subquery for calculate TotalVaccinatedPeople
(
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinate,
    ROW_NUMBER() OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date DESC) AS rn
	-- count partition rn =1 is max
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidDeaths vac ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
) AS Subquery
WHERE rn = 1
ORDER BY 2, 3


--Creating View to store data for later visualization

create view PercentPopulationVaccinated as  
SELECT
  continent,
  location,
  date,
  population,
  RollingPeopleVaccinate,
  (RollingPeopleVaccinate/population)*100 as VaccinatedPeoplePerPopulation
FROM (
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinate,
    ROW_NUMBER() OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date DESC) AS rn
	-- count partition rn =1 is max
  FROM PortfolioProject..CovidDeaths dea
  JOIN PortfolioProject..CovidDeaths vac ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
) AS Subquery
WHERE rn = 1


