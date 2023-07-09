-- For table Referencing

select * from [Nashville Housing Data];

-- Data Cleaning with SQL queries

-- 1. To Convert DateTime format to Regular Date Format

select SaleDate
from [Nashville Housing Data]

Alter table [Nashville Housing Data]
add Sale_Date_Converted date;

update [Nashville Housing Data]
set Sale_Date_Converted = Convert(date, SaleDate);

Select Sale_Date_Converted
from [Nashville Housing Data];

-----------------------------------------------------------------------

-- 2. Populate null entries in Property Address Data
-- In the table there are entries where there are duplicate parcel_ids with\ 
-- different Unique Id, so there is an address present for one of the parcel_id\
-- but the same parcel Id is missing for its duplicate, So I am attempting to fill the\
-- address of one parcel_id to its duplicate.

-- Checking to see the null values and cross checking with self join

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
, isnull(a.PropertyAddress, b.PropertyAddress) as To_fill_in_Aproperty_address
from [Nashville Housing Data] a
join [Nashville Housing Data] b 
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- So here I am attempting to fill the Property address with its duplicate

update a
set a.PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
from [Nashville Housing Data] a
join [Nashville Housing Data] b 
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-------------------------------------------------------------------------

-- 3. Splitting the Address column into individual columns

select PropertyAddress
from [Nashville Housing Data];

-- Attempt to extract the character after the delimiter, as my "city", the delimiter here is a ","

select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as address,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress)) as city 
from [Nashville Housing Data]

alter table [Nashville Housing Data]
add Property_Split_Address Nvarchar(255)

alter table [Nashville Housing Data]
add Property_Split_city Nvarchar(255)

update [Nashville Housing Data]
set Property_Split_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

update [Nashville Housing Data]
set Property_Split_City = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress));

select Property_Split_Address, Property_Split_City
from [Nashville Housing Data];

-------------------------------------------------------------------------------------------------

-- 4. Change "y" and "n" to Yes and No in the SoldAsVacant Column

select distinct(SoldAsVacant), count(SoldAsVacant) as Total_Entries
from [Nashville Housing Data]
group by SoldAsVacant
order by 2;

-- Converting the y and n to Yes and No

select SoldAsVacant,
Case when SoldAsVacant = 'Y' Then 'Yes'
	when SoldAsVacant = 'N' Then 'No'
	else SoldAsVacant
end
from [Nashville Housing Data]

update [Nashville Housing Data]
set SoldAsVacant = Case when SoldAsVacant = 'Y' Then 'Yes'
	when SoldAsVacant = 'N' Then 'No'
	else SoldAsVacant
	end

select distinct(SoldAsVacant)
from [Nashville Housing Data]

----------------------------------------------------------------------------

-- 5. To remove Duplicates

select *,
ROW_NUMBER() over(Partition by ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference order by UniqueID) as row_num
from [Nashville Housing Data]

--- Now to identify the rows where the row_num is greater than 1, to identify the duplicates

with row_num_cte as(
select *,
	ROW_NUMBER() over(
	Partition by ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference 
				order by UniqueID) as row_num
from [Nashville Housing Data]) 

select * from row_num_cte
where row_num > 1;

-- now to remove the duplicates

with row_num_cte as(
select *,
	ROW_NUMBER() over(
	Partition by ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference 
				order by UniqueID) as row_num
from [Nashville Housing Data]) 

Delete
from row_num_cte
where row_num > 1;

-------------------------------------------------------------------------

-- 6. To delete the columns from the table that are not useful for analysis

alter table [Nashville Housing Data]
drop column OwnerAddress, TaxDistrict, SaleDate;

---------------------------------------------------------------------------
-- With this the data is good to go for further analysis and visualizations in other softwares

Select * from [Nashville Housing Data];

--========================================================================================================================