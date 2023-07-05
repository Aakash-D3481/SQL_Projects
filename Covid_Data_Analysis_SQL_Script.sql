--select * from dbo.[Covid Deaths ];

--select * from dbo.[Covid Vaccinations];

select location, date, total_cases, new_cases, total_deaths, population
from dbo.[Covid Deaths ]
order by location, date;

-- Exploratory Data Analysis
-- Describing total cases and total deaths
-- Death_rate shows the likelihood of dying if you contract covid for India

select location, date, total_cases, total_deaths, (Convert(decimal,total_deaths)/convert(decimal,total_cases)*100)
as Death_rate
from dbo.[Covid Deaths ]
where date >= '2020-02-26 00:00:00.000' and location like '%India%'
and continent is not null
order by location, date;

-------------------------------------------------------------------------------------------------------------
-- Total Cases are what Percent of the total population in India
-- what percent of the total population contracted Covid in India

select location, date, total_cases, population, (Convert(decimal,total_cases)/convert(decimal,population)*100)
as Case_rate
from dbo.[Covid Deaths ]
where location like '%India%'
and continent is not null
order by location, date;

-- What country had the Highest Infection rate

select location, population, max(convert(integer,total_cases)) as max_cases_count
,Max((Convert(decimal,total_cases)/convert(decimal,population)*100)) as
infection_rate
from [Covid Deaths ]
where continent is not null
group by location, population
order by infection_rate desc;

-- what country had the highest death count

select location, population, max(convert(integer,total_deaths)) as max_death_count
,Max((Convert(decimal,total_deaths)/convert(decimal,population)*100)) as
death_rate
from [Covid Deaths ]
where continent is not null
group by location, population
order by max_death_count desc;
 
--Now to see highest death count by continents

select continent, max(convert(integer,total_deaths)) as max_death_count
from [Covid Deaths ]
where continent is not null
group by continent
order by max_death_count desc;

-- Global Numbers
-- we are summing up all the newcases in the entire world, and also summing up newdeaths in the world,
-- Further more calculating what percent the death is of the total infected.


select sum(cast(new_cases as bigint)) as total_infected_over_the_world,
sum(cast(new_deaths as bigint)) as total_deaths_over_the_world,
(sum(cast(new_deaths as int))/sum(new_cases)*100) as death_percentage_over_the_world
from [Covid Deaths ]
where continent is not null;

-- The vaccination table
-- Now to join deaths and vaccination table

-- Finding out the rolling vaccination total of each country over the years

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date) 
as rolling_total
from [Covid Deaths ] dea
join [Covid Vaccinations] vac 
on vac.location = dea.location and
vac.date = dea.date
where dea.continent is not null
order by dea.location, dea.date;

-- Finding the rolling total percent against the population
-- with a subquery

select e.continent, e.location, max(e.population) as max_pop, max(e.rolling_total) as max_rolling_total,
(max(e.rolling_total)/max(e.population)) * 100 as vacc_perc
from (
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date) 
	as rolling_total
	from [Covid Deaths ] dea
	join [Covid Vaccinations] vac 
	on vac.location = dea.location and
	vac.date = dea.date
	where dea.continent is not null) e
group by e.continent, e.location
order by e.location;


----------------------------------------------------------------------------------


