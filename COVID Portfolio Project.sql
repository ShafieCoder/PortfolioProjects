Use PortfolioProject
Go

Select *
From dbo.CovidDeath
Where continent is not null
order By 3,4;

--Select *
--From dbo.CovidVacsinations
--order By 3,4;

-- Select Data that we are going to be using:

Select location, date, total_cases, new_cases, total_deaths, population
From dbo.CovidDeath
Where continent is not null
order by 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows the liklihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From dbo.CovidDeath
Where location = 'Canada'
AND continent is not null
order by 1,2;

-- Looking at the total cases vs the population
-- Shows what percentage of the population infected by Covid
Select location, date, population, total_cases, (total_cases/population)*100 as Infection_rate_percentage
From dbo.CovidDeath
--Where location = 'Canada'
Where continent is not null
order by 1,2;


-- Loooking at countries with highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as Infection_rate_percentage
From dbo.CovidDeath
Where continent is not null
Group by location, population
order by Infection_rate_percentage desc;

-- Showing the countries with the highest death count per population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From dbo.CovidDeath
Where continent is not null
Group by location
order by TotalDeathCount desc;


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with highest deathcount per population

Select continent ,MAX(cast(total_deaths as int)) as TotalDeathCount
From dbo.CovidDeath
Where continent is not null
Group by continent
order by TotalDeathCount desc;


-- GLOBAL NUMBERS

-- Shows the likelihood of dying if you contract covid in your country
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From dbo.CovidDeath
-- location = 'Canada'
Where continent is not null
--Group by date
--order by 1,2;



--  Looking at Total Population vs vaccination

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
From dbo.CovidDeath dea
Join dbo.CovidVacsinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
order by 2,3;
 

 -- USE CTE
 with PopvsVac (Continent, Location, Date, Population, New_Vaccination,RollingPeopleVaccinated )
 as 
 (
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
From dbo.CovidDeath dea
Join dbo.CovidVacsinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--order by 2,3
 )
 Select *,(RollingPeopleVaccinated/Population)*100 as New_Vaccinated_Percentage
 From PopvsVac;

 -- TEMP TABLE
 Drop Table if exists #PercentPopulationVaccinated
 Create Table #PercentPopulationVaccinated
 (
 Continent nvarchar(255),
 Location nvarchar(255),
 Date datetime,
 Population numeric,
 New_Vaccinations numeric,
 RollingPeopleVaccinated numeric,
 )
 Insert into #PercentPopulationVaccinated
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
From dbo.CovidDeath dea
Join dbo.CovidVacsinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null

 Select *,(RollingPeopleVaccinated/Population)*100 as New_Vaccinated_Percentage
 From #PercentPopulationVaccinated;



 --Creating View to store data for visulaization

 Create View PercentPopulationVaccinated
 as
  Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
From dbo.CovidDeath dea
Join dbo.CovidVacsinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null


Select *
From PercentPopulationVaccinated