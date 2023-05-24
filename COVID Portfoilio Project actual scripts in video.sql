/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From PortfoilioProject..CovidDeaths$
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population_density
From PortfoilioProject..CovidDeaths$
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths


SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS float)/CAST(total_cases AS float)*100 as DeathPercentage
FROM PortfoilioProject..CovidDeaths$
WHERE LOCATION LIKE '%states%'
and continent is not null
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, population_density,total_cases, (total_cases/population_density)*100 as PerecentPopulationInfected
From PortfoilioProject..CovidDeaths$
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population_Density, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population_density))*100 as PercentPopulationInfected
From PortfoilioProject..CovidDeaths$
--Where location like '%states%'
Group by Location, population_density
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfoilioProject..CovidDeaths$
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfoilioProject..CovidDeaths$
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select date, SUM(new_cases), SUM(cast(new_deaths as int))--, total_deaths (total_deaths/total_cases)*100 as DeathPercentage
From PortfoilioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null 
Group By date
order by 1,2


Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfoilioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations

SELECT *
FROM PortfoilioProject..CovidDeaths$ dea
Join PortfoilioProject..CovidVaccination$ vac
  on dea.location = vac.location
  and dea.date = vac.date


-- Shows Percentage of Population that has recieved at least one Covid Vaccine


Select dea.continent, dea.location, dea.date, dea.population_density, vac.total_vaccinations
, SUM(CONVERT(bigint,vac.total_vaccinations))  OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfoilioProject..CovidDeaths$ dea
Join PortfoilioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, population_density, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.Location, dea.Date, dea.population_density, vac.total_vaccinations
, SUM(CONVERT(bigint,vac.total_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfoilioProject..CovidDeaths$ dea
Join PortfoilioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/population_density)*100
From PopvsVac


--Temp Table

Create table #percentpopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population_density numeric,
Total_vaccinations numeric,
RollingPeopleVacctionations numeric
)

Insert into #percentpopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population_density, vac.total_vaccinations
, SUM(CONVERT(int,vac.total_vaccinations)) OVER (Partition by dea.Location Order by dea.location,
  dea.Date) as RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/population)*100
  From PortfoilioProject..CovidDeaths$ dea
  Join PortfoilioProject..CovidVaccination$ vac
      On dea.location = vac.location
	  and dea.date = vac.date
	  WHERE dea.continent is not null
	  --order by 2,3


	  SELECT *, (RollingPeopleVacctionations/Population_density)*100
	  FROM #PercentPopulationVaccinated


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population_density numeric,
total_vaccinations numeric,
RollingPeopleVacctionations numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population_density, vac.total_vaccinations
, SUM(CONVERT(bigint,vac.total_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVacctionations
--, (RollingPeopleVaccinated/population_density)*100
From PortfoilioProject..CovidDeaths$ dea
Join PortfoilioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
 -- Where dea.continent is not null 
 --order by 2,3

 SELECT *, SUM(cast(RollingPeopleVacctionations as bigint))/NULLIF(Population_density, 0)*100 
 FROM #PercentPopulationVaccinated
 Group by continent, location, date,Population_density, total_vaccinations, RollingPeopleVacctionations, Population_density



 -- Creating View to store data for later visualizations

Create View PercentPopulationVacc as
Select dea.continent, dea.location, dea.date, dea.population_density, vac.total_vaccinations
, SUM(CONVERT(int,vac.total_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfoilioProject..CovidDeaths$ dea
Join PortfoilioProject..CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3


Select *
From PercentPopulationVacc 
