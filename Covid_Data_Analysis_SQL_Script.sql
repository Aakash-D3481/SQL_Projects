--select * from dbo.[Covid Deaths ];

--select * from dbo.[Covid Vaccinations];

select location, date, total_cases, new_cases, total_deaths, population
from dbo.[Covid Deaths ]
order by location, date;

-- Exploratory Data Analysis
-- Describing total cases and total deaths
-- Death_rate shows the likelihood of dying if you contract covid
-- For location = India

select location, date, total_cases, total_deaths, (Convert(decimal,total_deaths)/convert(decimal,total_cases)*100)
as Death_rate
from dbo.[Covid Deaths ]
where date >= '2020-02-26 00:00:00.000' and location = 'India'
and continent is not null
order by location, date;

-------------------------------------------------------------------------------------------------------------
-- Total Cases are what Percent of the total population in India
-- what percent of the total population contracted Covid in India

select location, date, population, total_cases, (Convert(decimal,total_cases)/convert(decimal,population)*100)
as Case_rate
from dbo.[Covid Deaths ]
where location = 'India'
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

---------------------------------------------------------------------------------------------------

-- what country had the highest death count

create or alter view Death_Count_Country_wise 
as
select location as Country, population as Country_Population, 
max(convert(integer,total_deaths)) as Total_Death_Count
,Max((Convert(decimal,total_deaths)/convert(decimal,population)*100)) as
Rate_of_Death
from [Covid Deaths ]
where continent is not null
group by location, population
having max(convert(integer,total_deaths)) is not null
--order by Total_Death_Count desc;

select * from Death_Count_Country_wise;
---------------------------------------------------------------------------------------------------

--Now to see highest death count by continents

Create view Death_count_by_continents
as
select continent as Continent, max(convert(integer,total_deaths)) as Total_Death_Count
from [Covid Deaths ]
where continent is not null
group by continent
-- order by Total_Death_Count desc;

select * from Death_count_by_continents;

---------------------------------------------------------------------------------------------------

-- Global Numbers
-- we are summing up all the newcases in the entire world, and also summing up newdeaths in the world,
-- Further more calculating what  the death percent is over the world

Create view Covid_19_Infection_and_Death_Stats
as
select sum(cast(new_cases as bigint)) as Total_No_Of_Infected,
sum(cast(new_deaths as bigint)) as Total_Deaths_over_The_World,
round((sum(cast(new_deaths as int))/sum(new_cases)*100),2) as Death_Percentage
from [Covid Deaths ]
where continent is not null;

select * from Covid_19_Infection_and_Death_Stats;

---------------------------------------------------------------------------------------------------

-- The vaccination table Analysis

-- Finding out the rolling vaccination total of each country over the years

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date) 
as rolling_total
from [Covid Deaths ] dea
join [Covid Vaccinations] vac 
on vac.location = dea.location and
vac.date = dea.date
where dea.continent is not null
and dea.location = 'Australia'
order by dea.location, dea.date;


-- Finding the Total Vaccination Percentage against the population for different Countries 
--( Looks Wrong )


select e.continent as Continent, e.location as Country, max(e.population) as Total_Population, max(e.rolling_total) as Total_Vaccinations,
round((max(e.rolling_total)/max(e.population)) * 100,2) as Vaccination_Percentage
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
having max(e.rolling_total) is not null
order by e.location;


----------------------------------------------------------------------------------

-- Total Tests conducted over different Countries
Create view Country_Test_Count
as
select location as Country, max(cast(total_tests as bigint)) as No_of_tests_Conducted
from [Covid Vaccinations]
where continent is not null 
group by location
having max(cast(total_tests as bigint)) is not null
--order by No_of_tests_Conducted desc;

Select * from Country_Test_Count;

---------------------------------------------------------------------------------------------------

-- Trend in testing over the period of 3 years across different countries

Create view Yearly_Country_Testing_Count
as
select Year(date) as Years, location as Country, sum(cast(new_tests as bigint)) as Total_Tests_Count
from [Covid Vaccinations]
--where location = 'United States' 
where continent is not null
group by year(date), location
having sum(cast(new_tests as bigint)) is not null
--order by year(date)

Select * from Yearly_Country_Testing_Count;

---------------------------------------------------------------------------------------------------

-- No. of people who tested positive out of the total_tests_conducted in India throughout the 3 Years

select date, location, total_tests, new_tests, positive_rate,
round(((cast(positive_rate as float)) * total_tests),0)  as no_of_positives
from [Covid Vaccinations]
where location = 'India'
order by date, location;	

---------------------------------------------------------------------------------------------------

-- Comparison of rate at testing as Covid Positive by different countries out of the \
-- total tests conducted,\
-- Throughout different years

create view Yearly_Country_COVID19_Positive_Rate
as
select year(date) as Year, location as Country, 
round(max(positive_rate),4) as Testing_as_Covid_Positive_Rate
from [Covid Vaccinations]
-- where location = 'United States'
group by year(date), location
having max(positive_rate) is not null
--order by year(date), location;	

select * from Yearly_Country_COVID19_Positive_Rate;

---------------------------------------------------------------------------------------------------

-- Testing Intensity

-- Here Tests_per_person is a measure of testing intensity and indicates the average number of tests performed on individuals 
-- relative to the total population size. And everything is grouped by different countries

create or alter view Testing_intensity 
as
Select e.location as Country, e.No_of_tests_Conducted, e.pop as Total_Population, 
round((e.No_of_tests_Conducted/e.pop),2) as Avg_Tests_Per_Person
from (
	select dea.location, max(cast(vac.total_tests as bigint)) as No_of_tests_Conducted,
	max(dea.population) as pop
	from [Covid Vaccinations] vac
	join [Covid Deaths ] dea on 
	dea.date = vac.date and
	dea.location = vac.location
	where dea.continent is not null 
	group by dea.location) as e
where No_of_tests_Conducted is not null
--Order by e.No_of_tests_Conducted Desc

select * from Testing_intensity;

---------------------------------------------------------------------------------------------------

-- To analyse the Hospitilization rate across continents 

Create view Hosipitalization_Over_Continents
as
select  continent as Continent, location as Country , 
sum(cast(hosp_patients as int)) as Total_Hospitalized_Patients,
max(population) as Total_Population,
round((sum(cast(hosp_patients as int))/max(population))*100,2) as Hospitalization_Rate
from [Covid Deaths ]
where continent is not null
-- and continent = 'North America'
group by continent, location
having sum(cast(hosp_patients as int)) is not null
--order by Hosp_rate Desc

select * from Hosipitalization_Over_Continents;

---------------------------------------------------------------------------------------------------

--The "GDP per capita" is a measure of economic prosperity and represents the Gross Domestic Product (GDP) 
--of a country divided by its population. 
--It provides an estimate of the average economic output per person in a given country.
--

select location, gdp_per_capita
from [Covid Vaccinations] 
where continent is not null
and location = 'United States'


--Vaccination Check

select dea.continent, dea.location, dea.population, 
max(vac.people_fully_vaccinated) as Total_People_Vaccinated,
(max(vac.people_fully_vaccinated)/dea.population)*100 as Vaccination_Percentage
from [Covid Deaths ] dea
join [Covid Vaccinations] vac 
on vac.location = dea.location and
vac.date = dea.date
where dea.continent is not null
group by dea.continent, dea.location, dea.population
having max(vac.people_fully_vaccinated) is not null
order by Vaccination_Percentage Desc;


