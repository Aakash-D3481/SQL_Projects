--For quick Reference of Tables

--select * from dbo.[Covid Deaths ];
--select * from dbo.[Covid Vaccinations];


-- Exploratory Data Analysis

-- Describing total cases and total deaths
-- For all Countries


select location, date, total_cases, total_deaths, (Convert(decimal,total_deaths)/convert(decimal,total_cases)*100)
as Death_rate
from dbo.[Covid Deaths ]
where continent is not null
and location is not null
order by location, date;

-------------------------------------------------------------------------------------------------------------

-- What percent of the total population contracted Covid in India throughout the data?

select location, date, population, total_cases, (Convert(decimal,total_cases)/convert(decimal,population)*100)
as Case_rate
from dbo.[Covid Deaths ]
where location = 'India'
and continent is not null
order by location, date;

------------------------------------------------------------------------

-- What country had the Highest Infection rate?

select location, population, max(convert(integer,total_cases)) as max_cases_count
,Max((Convert(decimal,total_cases)/convert(decimal,population)*100)) as
infection_rate
from [Covid Deaths ]
where continent is not null
group by location, population
order by infection_rate desc;

---------------------------------------------------------------------------------------------------

-- What country had the highest death count?

select location as Country, population as Country_Population, 
max(convert(integer,total_deaths)) as Total_Death_Count
,Max((Convert(decimal,total_deaths)/convert(decimal,population)*100)) as
Rate_of_Death
from [Covid Deaths ]
where continent is not null
group by location, population
having max(convert(integer,total_deaths)) is not null
order by Total_Death_Count desc;

---------------------------------------------------------------------------------------------------

--Highest death count by continents

select continent as Continent, max(convert(integer,total_deaths)) as Total_Death_Count
from [Covid Deaths ]
where continent is not null
group by continent
order by Total_Death_Count desc;

---------------------------------------------------------------------------------------------------

-- Global Figures of The Covid-19 Pandemic
-- Summing up all the newcases in the entire world, and also summing up newdeaths in the world,
-- Further more calculating what the death percent is over the world


select sum(cast(new_cases as bigint)) as Total_No_Of_Infected,
sum(cast(new_deaths as bigint)) as Total_Deaths_over_The_World,
round((sum(cast(new_deaths as int))/sum(new_cases)*100),2) as Death_Percentage
from [Covid Deaths ]
where continent is not null;


---------------------------------------------------------------------------------------------------


-- Finding out the rolling vaccination total of each country over the years

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date) 
as rolling_total
from [Covid Deaths ] dea
join [Covid Vaccinations] vac 
on vac.location = dea.location and
vac.date = dea.date
where dea.continent is not null
and dea.location is not null
order by dea.location, dea.date;

--------------------------------------------------------------------------------

-- Total Tests conducted over different Countries

select location as Country, max(cast(total_tests as bigint)) as No_of_tests_Conducted
from [Covid Vaccinations]
where continent is not null 
group by location
having max(cast(total_tests as bigint)) is not null
order by No_of_tests_Conducted desc;


---------------------------------------------------------------------------------------------------

-- Trend in testing over the period of 3 years across different countries
-- Here it is a trend of India


select Year(date) as Years, location as Country, sum(cast(new_tests as bigint)) as Total_Tests_Count
from [Covid Vaccinations]
where location = 'India' 
and continent is not null
group by year(date), location
having sum(cast(new_tests as bigint)) is not null
order by year(date)


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
-- For this case, it is for India


select year(date) as Year, location as Country, 
round(max(positive_rate),4) as Testing_as_Covid_Positive_Rate
from [Covid Vaccinations]
where location = 'India'
group by year(date), location
having max(positive_rate) is not null
order by year(date), location;	

---------------------------------------------------------------------------------------------------

-- Testing Intensity

-- Here Tests_per_person is a measure of testing intensity and indicates the average number of tests performed on individuals 
-- relative to the total population size. And everything is grouped by different countries

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
Order by e.No_of_tests_Conducted Desc

---------------------------------------------------------------------------------------------------

-- To analyse the Hospitilization rate across continents 

select  continent as Continent, location as Country , 
sum(cast(hosp_patients as int)) as Total_Hospitalized_Patients,
max(population) as Total_Population,
round((sum(cast(hosp_patients as int))/max(population))*100,2) as Hospitalization_Rate
from [Covid Deaths ]
where continent is not null
group by continent, location
having sum(cast(hosp_patients as int)) is not null
order by Hospitalization_Rate Desc

---------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

-- Creation of Views for making a Dashboard in PowerBI

--1. COVID-19 Infection Statistics ( Global Figures )

Create or alter view Covid_19_Infection_and_Death_Stats
as
select sum(cast(new_cases as bigint)) as Total_No_Of_Infected,
sum(cast(new_deaths as bigint)) as Total_Deaths_over_The_World,
round((sum(cast(new_deaths as int))/sum(new_cases)*100),2) as Death_Percentage
from [Covid Deaths ]
where continent is not null
and location not in ('World', 'European Union', 'International');

select * from Covid_19_Infection_and_Death_Stats;

-- 2. The Mortality Count Country wise

create or alter view Death_Count_Country_wise 
as
select continent as Continent, location as Country, population as Country_Population, 
max(convert(integer,total_deaths)) as Total_Death_Count
,Max((Convert(decimal,total_deaths)/convert(decimal,population)*100)) as
Rate_of_Death
from [Covid Deaths ]
where continent is not null
group by continent, location, population
having max(convert(integer,total_deaths)) is not null
--order by Total_Death_Count desc;

select * from Death_Count_Country_wise;

-- 3. Total Infected Country Wise

create view Total_Infected_Country_wise
as
select continent as Continent, location as Country, 
sum(cast(new_cases as bigint)) as Total_Infected
from [Covid Deaths ] 
where continent is not null
group by continent, location
having sum(cast(new_cases as bigint)) is not null
--order by total_infected desc

Select * from Total_Infected_Country_wise;


-- 4. Testing Statistics

Create or alter view Testing_intensity
as
Select e.continent as Continent, e.location as Country, e.No_of_tests_Conducted, e.pop as Total_Population, 
round((e.No_of_tests_Conducted/e.pop),2) as Avg_Tests_Per_Person
from (
	select dea.continent, dea.location, max(cast(vac.total_tests as bigint)) as No_of_tests_Conducted,
	max(dea.population) as pop
	from [Covid Vaccinations] vac
	join [Covid Deaths ] dea on 
	dea.date = vac.date and
	dea.location = vac.location
	where dea.continent is not null 
	group by dea.continent, dea.location) as e
where No_of_tests_Conducted is not null
-- Order by e.No_of_tests_Conducted Desc

select * from Testing_intensity;


-- 5. Strain on Healthcare Systems of the Country

create view Strain_On_Healthcare_Systems
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

select * from Strain_On_Healthcare_Systems;


--========================================================================



