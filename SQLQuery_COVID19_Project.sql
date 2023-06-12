/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM covid_portfolio_project.dbo.CovidDeaths
WHERE continent is not NULL

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
ORDER BY 1,2

-- Looking at the total cases vs total deaths 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
where location like '%united kingdom%'
ORDER BY 1,2

-- Looking at total cases vs population

SELECT location, date, total_cases, total_deaths, population, (total_cases/population)*100 as CasePercentage
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
where location like '%united kingdom%'
ORDER BY 1,2

-- Highest infection rates

SELECT location, population, max(total_cases) as Highestinfectioncount, (MAX(total_cases)/population)*100 as Prevelance%
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
GROUP BY location, population
ORDER BY Prevelance DESC

-- Showing countries with highest death count

SELECT location, MAX(cast(total_deaths as INT)) as totaldeathcount 
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY LOCATION
ORDER BY totaldeathcount DESC

-- BREAK THINGS DOWN BY CONTINENT 
-- Filtering on the continent entries in the location column i.e. the continent column is NULL (this gives correct figures)
---- SELECT location, MAX(cast(total_deaths as INT)) as totaldeathcount 
---- FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
---- WHERE continent is NULL
---- GROUP BY location
---- ORDER BY totaldeathcount DESC

SELECT continent, MAX(cast(total_deaths as INT)) as totaldeathcount 
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY continent 
ORDER BY totaldeathcount DESC

-- Global numbers

SELECT date, SUM(new_cases) as totalcases, SUM(new_deaths) as totaldeaths, (SUM(new_deaths)/SUM(new_cases))*100 as Deathpercentage -- sums new cases for each date (i.e. per day) and the new deaths to give totals
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

-- Total cases for the world

SELECT SUM(new_cases) as totalcases, SUM(new_deaths) as totaldeaths, (SUM(new_deaths)/SUM(new_cases))*100 as Deathpercentage 
FROM COVID_PORTFOLIO_PROJECT.dbo.CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

-- Looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(vac.new_vaccinations) OVER (PARTITION by dea.location order by dea.LOCATION, dea.date) as rollingpeoplevaccinated
FROM covid_portfolio_project.dbo.CovidDeaths as dea JOIN covid_portfolio_project.dbo.CovidVaccinations as vac
    ON dea.LOCATION = vac.location
    and dea.DATE = vac.date
    WHERE dea.continent is not NULL
order by 2,3

-- Use CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_portfolio_project..CovidDeaths dea
Join covid_portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Temp Table

DROP TABLE if exists #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
(
continent nvarchar(255),
Location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric, 
rollingpeoplevaccinated numeric
)

INSERT INTO #percentpopulationvaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_portfolio_project..CovidDeaths dea
Join covid_portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *, (rollingpeoplevaccinated/population)*100 as percentofpeoplevaccinated
FROM #percentpopulationvaccinated

-- Creating View to Store Data for Later Visualisation

CREATE View percentofpeoplevaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_portfolio_project..CovidDeaths dea
Join covid_portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
