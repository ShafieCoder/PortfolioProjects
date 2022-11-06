/*
Cleaning Data in SQL Queries
*/

USE PortfolioProject
Go

Select *
From PortfolioProject.dbo.NashvilleHousing


---------------------------------------------------------------------------------------------------

-- Standardize Date Format
Select  SaleDateConverted , CONVERT(Date, SaleDate) as converted_sale_date
From dbo.NashvilleHousing

--this method did not work for changing the format of SaleDate from DATETIME to DATE
Update dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- We used this method instead to add new column and insert all converted data from SaleDate to this new column
ALTER TABLE dbo.NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);


------------------------------------------------------------------------------------------------------------

-- Populate Property Address data


Select *
From dbo.NashvilleHousing
--where PropertyAddress is null
order by ParcelID;

-- Since those properties that have the same parcelID have the same address, so we populate the null addresses with the address from the same parcelID
-- Let's self-join the table and go from there

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From dbo.NashvilleHousing a
Join dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null;


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From dbo.NashvilleHousing a
Join dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null;

------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From dbo.NashvilleHousing;

-- For this one we are going to use substring and charindex, ...

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as City
From dbo.NashvilleHousing;

--We are going to create two new columns and add these values to them

ALTER TABLE dbo.NashvilleHousing
Add PropertySplitAdress nvarchar(255);

Update NashvilleHousing
SET PropertySplitAdress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE dbo.NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress));


Select PropertyAddress, PropertySplitAdress, PropertySplitCity
From dbo.NashvilleHousing;

Select *
From dbo.NashvilleHousing;

-- To break out owner Address, we use Parsename() and replace() 

Select PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) as owner_Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) as owner_City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) as owner_State
From dbo.NashvilleHousing
Where OwnerAddress is not null





ALTER TABLE dbo.NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3);



ALTER TABLE dbo.NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2);



ALTER TABLE dbo.NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1);


----------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From dbo.NashvilleHousing
Group by SoldAsVacant
order by 2



Select SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From dbo.NashvilleHousing



Update NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;


---------------------------------------------------------------------------------------------------------

-- Remove Duplicates
WITH RowNumCTE 
AS
(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueID
				) row_num
From dbo.NashvilleHousing
--Order by ParcelID
)

SELECT *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;



-- Remove Duplicates
WITH RowNumCTE 
AS
(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueID
				) row_num
From dbo.NashvilleHousing
--Order by ParcelID
)

DELETE
From RowNumCTE
Where row_num > 1;



----------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN PropertyAddress, TaxDistrict, OwnerAddress

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN SaleDate;





-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO










