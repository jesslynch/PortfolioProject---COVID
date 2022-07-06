-- DELETING DUPLICATE DATA
Select * from PortfolioProject..CovidDeaths$

-- 1. See which data has duplicate and the number of duplicates
Select continent, location, date, population, total_cases, new_cases,
total_deaths, new_deaths, Count(*) as DupCount
From PortfolioProject..CovidDeaths$
Group by continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths
Having Count(*) > 1

--2. Delete duplicates
Delete from PortfolioProject..CovidDeaths$ where ID not in (
Select MAX(ID) from PortfolioProject..CovidDeaths$
Group by continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths)


Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
Order by 1,2 

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where Location like '%states%'
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
Select Location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
From PortfolioProject..CovidDeaths$
Where Location like '%states%'
Order by 1,2

-- Looking at countries with highest infection rate compared to population
Select Location, Population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as HighestInfectionRate
From PortfolioProject..CovidDeaths$
Group by Location, Population
Order by HighestInfectionRate desc

-- Showing countries with highest death count
Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
Where continent is not null
Group by Location
Order by TotalDeathCount desc

-- Showing continents with highest death count
Select location, max(cast(total_deaths as int)) as TotalDeathCountContinent
From PortfolioProject..CovidDeaths$
Where continent is null
Group by location
Order by TotalDeathCountContinent desc

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
Where continent is not null
Group by continent
Order by TotalDeathCount desc 

-- GLOBAL NUMBERS

-- Numbers of new cases, deaths, and death percentage globally per day
Select date, SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as NewDeaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
where continent is not null
Group by date
Order by 1,2

-- Numbers of new cases, deaths, and death percentage globally from 1/1/2020 till this report
Select SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as NewDeaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
where continent is not null
Order by 1,2


-- JOIN COVID VACCINATION DATA

Select *
From PortfolioProject..CovidVaccinations$
Order by 3,4

Select continent, location, date, new_tests, total_tests, Count(*) as DupCount
From PortfolioProject..CovidVaccinations$
Group by continent, location, date, new_tests, total_tests
Having Count(*) > 1

Select *
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Total of people that have been vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location
Order by dea.location, dea.date) as VaccinationAccumulated
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

-- USE CTE

With PopvsVac(continent, location, date, population, new_vaccinations, VaccinationAccumulated)
as (
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location
	Order by dea.location, dea.date) as VaccinationAccumulated
	From PortfolioProject..CovidDeaths$ dea
	Join PortfolioProject..CovidVaccinations$ vac
		On dea.location = vac.location
		and dea.date = vac.date
	Where dea.continent is not null)
Select *, (VaccinationAccumulated/population)*100 as PercentageVaxAcc
From PopvsVac

-- USE TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
VaccinationAccumulated numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location
	Order by dea.location, dea.date) as VaccinationAccumulated
	From PortfolioProject..CovidDeaths$ dea
	Join PortfolioProject..CovidVaccinations$ vac
		On dea.location = vac.location
		and dea.date = vac.date
	Where dea.continent is not null

Select *, (VaccinationAccumulated/population)*100 as PercentageVaxAcc
From #PercentPopulationVaccinated


-- CREATING VIEW TO SORE DATA FOR LATER VISUALIZATIONS

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location
	Order by dea.location, dea.date) as VaccinationAccumulated
	From PortfolioProject..CovidDeaths$ dea
	Join PortfolioProject..CovidVaccinations$ vac
		On dea.location = vac.location
		and dea.date = vac.date
	Where dea.continent is not null
