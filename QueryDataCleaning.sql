-- Cleaning Data in SQL Queries

SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------


-- Standarize Date Format

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM ProjectPortfolio.dbo.NashvilleHousing
ORDER BY SaleDateConverted

/* The code below doesn't properly work for some reason so I end up creating a new column for it. 
UPDATE ProjectPortfolio.dbo.NashvilleHousing
Set SaleDate = CONVERT(Date,SaleDate)
*/

ALTER TABLE projectportfolio.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE projectportfolio.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,saleDate)

--------------------------------------------------------------------------------------------------------------------------


/* Populate Property Address Data
The PropertyAddress Column has some nulls that can be filled using parcelID. The parcel ID has duplicate
numbers and sometimes some of the addresses are full with one parcel ID address. so I check if parcelID
has another parcelID and if the second parcelID's Property Address is null then it duplicates the 
property address from the one that has the address.
*/


SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing
WHERE PropertyAddress is null


-- This query works so I implement it to update the column
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolio.dbo.NashvilleHousing a
JOIN ProjectPortfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Query that updates the column
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolio.dbo.NashvilleHousing a
JOIN ProjectPortfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------

/* 
Breaking out Address Into individual Columns (Address, City, State). I do this to make the data more
organized and easier to use in the future.
*/


SELECT PropertyAddress
FROM ProjectPortfolio.dbo.NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address

FROM ProjectPortfolio.dbo.NashvilleHousing

-- Making 2 new columns to fit this split address. 

-- Column Created: PropertySplitAddress: created to put in first half of address.
ALTER TABLE projectportfolio.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE projectportfolio.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

--Column created: PropertySplitCity: created to put in the second half of address which is the city
ALTER TABLE projectportfolio.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE projectportfolio.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 


/* 
Also Breaking out Address Into individual Columns for the OwnerAdress using a different method of 
accomplishing the same result.
*/


SELECT OwnerAddress
FROM ProjectPortfolio.dbo.NashvilleHousing


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM ProjectPortfolio.dbo.NashvilleHousing

-- Now I update my new columns.

-- Column Created: OwnerSplitAddress: contains first part
ALTER TABLE projectportfolio.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE projectportfolio.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- Column Created: OwnerSplitCity: contains middle part(City)
ALTER TABLE projectportfolio.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE projectportfolio.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- Column Created: OwnerSplitState: contains end part(State)
ALTER TABLE projectportfolio.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE projectportfolio.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 


--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT DISTINCT(SoldASVacant), COUNT(SoldAsVacant)
FROM ProjectPortfolio.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldASVacant
,CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM ProjectPortfolio.dbo.NashvilleHousing

-- Update Column with new values
UPDATE ProjectPortfolio.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


--------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates Using CTE


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
					
FROM ProjectPortfolio.dbo.NashvilleHousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


--------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing

ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate