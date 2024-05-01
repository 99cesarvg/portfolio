SELECT *
FROM ProjectPortfolio..CovidDeaths$
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM ProjectPortfolio..CovidVaccinations$
--order by 3,4

-- Select Data that we are going to be using. isnt needed comment

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ProjectPortfolio..CovidDeaths$
WHERE Location LIKE '%states%'
OR Location LIKE '%mexico%'
AND continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid.
SELECT Location, date, Population, total_cases,  (total_cases/Population)*100 AS InfectedPopulation
FROM ProjectPortfolio..CovidDeaths$
WHERE Location LIKE '%states%'
OR Location LIKE '%mexico%'
ORDER BY 1,2

-- Looking at Countries with Highest infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  MAX(total_cases/Population)*100 AS PercentPopulationInfected
FROM ProjectPortfolio..CovidDeaths$
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
-- SELECT Location, Population, MAX(total_deaths) as TotalDead,  MAX(total_deaths/Population)*100 AS PercentageDead
FROM ProjectPortfolio..CovidDeaths$
GROUP BY Location, Population
ORDER BY PercentageDead DESC

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProjectPortfolio..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
-- same but by continent not countries
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProjectPortfolio..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS


SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM ProjectPortfolio..CovidDeaths$
--Where location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM ProjectPortfolio..CovidDeaths$
--Where location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio..CovidDeaths$ dea
JOIN ProjectPortfolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio..CovidDeaths$ dea
JOIN ProjectPortfolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--Order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Using SubQueries to calculate (RollingPeopleVaccinated/population)*100 in select.

SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    RollingVaccinations,
    (CAST(RollingVaccinations AS FLOAT) / dea.population) * 100 AS VaccinationPercentage
FROM 
    ProjectPortfolio..CovidDeaths$ dea
JOIN 
    (
        SELECT 
            location,
            date,
            SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY location ORDER BY date) AS RollingVaccinations
        FROM 
            ProjectPortfolio..CovidVaccinations$
    ) vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
ORDER BY 
    dea.location, 
    dea.date;



-- Creating View to store data for later vizualizations 

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order By dea.location, dea.date) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM ProjectPortfolio..CovidDeaths$ dea
JOIN ProjectPortfolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--Order by 2,3

SELECT *
FROM PercentPopulationVaccinated