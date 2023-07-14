--This data contains information about covid deaths and vaccinations in the period 2020-2021
--In this file we'r putting in practice basic commands in Microsoft SQL Server 

--We start just checking the info
Select *
FROM nuevo..dead


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM nuevo..dead
order by 1, 2

--Let's make some questions 
--¿What was the ratio of deaths over total cases?
--At the begining we couldn't do the operation because total_cases and total_deaths were nvarchar type, so we had to change them to numeric

ALTER TABLE nuevo..dead
ALTER COLUMN total_cases numeric


SELECT location, date, total_cases, total_deaths, total_deaths/total_cases*100 as "Rdeadthxcases"
FROM nuevo..dead
order by 1;

-- now for South America

SELECT location, continent, date, total_cases, total_deaths, total_deaths/total_cases*100 as "deadthxcases"
FROM nuevo..dead
WHERE continent = 'South America'
order by 1

--Now for Peru, but finding the dates when there were the most deaths

SELECT location, date, MAX(total_deaths)
FROM nuevo.dbo.dead
WHERE location='Peru'
Group by location, date
Order by MAX(total_deaths) DESC

--Now let's see the ratio of the population that got covid

SELECT location, population, total_cases, (total_cases/population)*100 as "%infected"
FROM nuevo..dead
where continent like '%America'
order by 1

--Now let's check highest rate infected over population in America (continent)

SELECT location, population, total_cases, MAX(total_cases/population)*100 as "%infected"
FROM nuevo..dead
where continent like '%America'
GROUP BY location, population, total_cases
order by MAX(total_cases/population)*100 DESC

--highest rate infected over population in the world:

SELECT location, population, total_cases, MAX(total_cases/population)*100 as "%infected"
FROM nuevo..dead
GROUP BY location, population, total_cases
order by MAX(total_cases/population)*100 DESC

--Countries with most infected people:

SELECT location, population, MAX(total_cases) as HighestInfected
FROM nuevo..dead
Group by location, population
order by 1, 2

--Let's check the total death count

Select location, MAX(total_deaths)
FROM nuevo..dead
WHERE continent is not null
Group by location 
order by MAX(total_deaths) DESC

--Let's see how it is by continent

SELECT continent, MAX(total_deaths)
FROM nuevo..dead
WHERE continent is not null
GROUP BY continent
order by MAX(total_deaths) DESC



--GLOBAL NUMBERS
--Ratio of deaths per new cases per date
SELECT date, SUM(NEW_CASES) AS "NEW_CASES", SUM(NEW_DEATHS) AS "NEW_DEATHS", SUM(NEW_DEATHS)/SUM(NEW_CASES)*100 AS "%DEATHXNCASES"
FROM nuevo..dead
WHERE CONTINENT IS NOT NULL
GROUP BY DATE

--Ratio of deaths global
SELECT  SUM(NEW_CASES) AS "NEW_CASES", SUM(NEW_DEATHS) AS "NEW_DEATHS", SUM(NEW_DEATHS)/SUM(NEW_CASES)*100 AS "%DEATHXNCASES"
FROM nuevo..dead
WHERE CONTINENT IS NOT NULL



-- Let's use the vaccination info

--First, we gotta use a join to check with the other table
SELECT A.location, A.population, A.new_vaccinations
FROM nuevo..vac A, nuevo..dead B
WHERE A.location=B.location AND A.continent is not null

--Let's see how the number of infected people have been increasing
-- We're gonna see it using OVER PARTITION
SELECT A.continent, A.location, A.population, B.new_vaccinations, A.date, 
SUM(CAST(B.new_vaccinations AS int)) OVER (PARTITION BY A.LOCATION order by A.location, A.date) as ROLLINGVAC
FROM nuevo..dead A, nuevo..vac B
WHERE A.location=B.location AND A.date=B.date AND A.continent is not null

--Now let's see the rate os the increasing of infected people over the population USING A CTE

WITH POPVSVAC (continente, location, population, new_vaccinations, date, ROLLINGVAC)
as
(
SELECT A.continent, A.location, A.population, B.new_vaccinations, A.date, 
SUM(CAST(B.new_vaccinations AS int)) OVER (PARTITION BY A.LOCATION order by A.location, A.date) as ROLLINGVAC
FROM nuevo..dead A, nuevo..vac B
WHERE A.location=B.location AND A.date=B.date AND A.continent is not null
)
Select *, (ROLLINGVAC/population)*100 as "rollingratio"
FROM POPVSVAC


--OR creating a new table
DROP table if exists POPvsVAC
Create table POPvsVAC
(
continent nvarchar (255),
location nvarchar (255),
population numeric,
new_vaccinations numeric,
date datetime,
ROLLINGVAC numeric
)
SELECT *
FROM POPvsVAC

INSERT INTO POPvsVAC (continent, location, population, new_vaccinations, date, ROLLINGVAC)
SELECT A.continent, A.location, A.population, B.new_vaccinations, A.date, 
SUM(CAST(B.new_vaccinations AS bigint)) OVER (PARTITION BY A.LOCATION order by A.location, A.date) as ROLLINGVAC
FROM nuevo..dead A, nuevo..vac B
WHERE A.location=B.location AND A.date=B.date; 

--AND A.continent is not null

Select *, (ROLLINGVAC/population)*100 as "rollingratio"
FROM POPvsVAC

