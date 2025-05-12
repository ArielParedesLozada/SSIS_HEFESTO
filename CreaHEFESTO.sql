CREATE TABLE DimOrdenes (
	IDOrder INT PRIMARY KEY,
	Estado TINYINT NOT NULL
);

CREATE TABLE DimProductos (
	IDProducto INT PRIMARY KEY,
	Nombre NVARCHAR(50) NOT NULL,
	CompradoFlag BIT NOT NULL,
	PrecioLista MONEY NOT NULL
);

CREATE TABLE DimPais (
	IDPais NVARCHAR(3) PRIMARY KEY,
	Nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE DimEstado (
	IDEstado INT PRIMARY KEY,
	EstadoCode NCHAR(3) NOT NULL,
	Nombre NVARCHAR(50) NOT NULL,
	PaisID NVARCHAR(3) FOREIGN KEY REFERENCES DimPais(IDPais)
);

CREATE TABLE DimCiudad (
	IDCiudad INT PRIMARY KEY,
	Nombre NVARCHAR(30) NOT NULL,
	CodigoPostal NVARCHAR(15) NOT NULL,
	EstadoID INT FOREIGN KEY REFERENCES DimEstado(IDEstado)
);

CREATE TABLE DimVendedor (
	IDVendedor INT PRIMARY KEY,
	Nombre NVARCHAR(50) NOT NULL,
	Apellido NVARCHAR(50) NOT NULL,
	CiudadID INT FOREIGN KEY REFERENCES DimCiudad(IDCiudad)
);

CREATE TABLE FactOrdenesDetails (
	IDVenta INT PRIMARY KEY,
	PrecioLista MONEY NOT NULL,
	PrecioUnitario MONEY NOT NULL,
	DiferenciaPrecios MONEY NOT NULL,
	VendedorID INT FOREIGN KEY REFERENCES DimVendedor(IDVendedor),
	ProductoID INT FOREIGN KEY REFERENCES DimProductos(IDProducto),
	OrdenID INT FOREIGN KEY REFERENCES DimOrdenes(IDOrder)
);

DELETE FROM FactOrdenesDetails;
DELETE FROM DimOrdenes;
DELETE FROM DimProductos;
DELETE FROM DimVendedor;
DELETE FROM DimCiudad;
DELETE FROM DimEstado;
DELETE FROM DimPais;

SELECT
	soh.SalesOrderID AS IDOrder,
	soh.Status AS Estado
FROM AdventureWorks2022.Sales.SalesOrderHeader soh,
	AdventureWorks2022.Sales.SalesOrderDetail sod
WHERE soh.SalesOrderID = sod.SalesOrderID
;

SELECT
	DISTINCT soh.SalesOrderID AS IDOrder,
	soh.Status AS Estado
FROM AdventureWorks2022.Sales.SalesOrderHeader soh,
	AdventureWorks2022.Sales.SalesOrderDetail sod
WHERE soh.SalesOrderID = sod.SalesOrderID
;

SELECT 
	DISTINCT pp.ProductID AS IDProducto,
	pp.MakeFlag AS CompradoFlag,
	pp.ListPrice AS PrecioLista,
	pp.Name AS Nombre
FROM AdventureWorks2022.Production.Product pp,
	AdventureWorks2022.Sales.SalesOrderDetail sod
WHERE pp.ProductID = sod.ProductID
;

SELECT 
	CountryRegionCode AS IDPais,
	Name AS Nombre
FROM AdventureWorks2022.Person.CountryRegion;

SELECT
	StateProvinceID AS IDEstado,
	StateProvinceCode AS EstadoCode,
	Name AS Nombre,
	CountryRegionCode AS PaisID
FROM AdventureWorks2022.Person.StateProvince
;

SELECT 
	pa.AddressID AS IDCiudad,
	pa.PostalCode AS CodigoPostal,
	pa.StateProvinceID AS EstadoID,
	pa.City AS Nombre
FROM AdventureWorks2022.Person.Address pa,
	AdventureWorks2022.Person.BusinessEntity pbe,
	AdventureWorks2022.Person.BusinessEntityAddress pbea,
	AdventureWorks2022.HumanResources.Employee hre
WHERE pa.AddressID = pbea.AddressID AND 
	pbe.BusinessEntityID = pbea.BusinessEntityID AND
	pbe.BusinessEntityID = hre.BusinessEntityID
;

SELECT 
	DISTINCT hre.BusinessEntityID AS IDVendedor,
	pp.FirstName AS Nombre,
	pp.LastName AS Apellido,
	pbea.AddressID AS CiudadID
FROM AdventureWorks2022.Person.BusinessEntity pbe,
	AdventureWorks2022.HumanResources.Employee hre,
	AdventureWorks2022.Person.BusinessEntityAddress pbea,
	AdventureWorks2022.Person.Person pp,
	AdventureWorks2022.Sales.SalesOrderHeader soh
WHERE hre.BusinessEntityID = pbe.BusinessEntityID
	AND pbe.BusinessEntityID = pbea.BusinessEntityID
	AND pbe.BusinessEntityID = pp.BusinessEntityID
	AND hre.BusinessEntityID = soh.SalesPersonID
;

SELECT
	sod.SalesOrderDetailID AS IDVenta,
	sod.UnitPrice AS PrecioUnitario,
	dp.PrecioLista AS PrecioLista,
	dp.PrecioLista - sod.UnitPrice AS DiferenciaPrecios,
	dp.IDProducto AS ProductoID,
	do.IDOrder AS OrdenID,
	dv.IDVendedor AS VendedorID
FROM AdventureWorks2022.Sales.SalesOrderDetail sod,
	AdventureWorks2022.Sales.SalesOrderHeader soh,
	HEFESTO.dbo.DimProductos dp,
	HEFESTO.dbo.DimVendedor dv,
	HEFESTO.dbo.DimOrdenes do
WHERE sod.SalesOrderID = do.IDOrder AND
	soh.SalesPersonID = dv.IDVendedor AND 
	sod.ProductID = dp.IDProducto AND
	sod.SalesOrderID = soh.SalesOrderID
;