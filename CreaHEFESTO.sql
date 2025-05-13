--Crea base de datos
CREATE DATABASE HEFESTO;

CREATE TABLE HEFESTO.dbo.DimTerritorio (
	IdTerritorio INT PRIMARY KEY,
	TerritorioNombre NVARCHAR(50) NOT NULL,
	GrupoTerritorio NVARCHAR(50) NOT NULL
);

CREATE TABLE HEFESTO.dbo.DimPais (
	IDPais NVARCHAR(3) PRIMARY KEY,
	Nombre NVARCHAR(50) NOT NULL
);

CREATE TABLE HEFESTO.dbo.DimEstado (
	IDEstado INT PRIMARY KEY,
	EstadoCode NCHAR(3) NOT NULL,
	Nombre NVARCHAR(50) NOT NULL,
	PaisID NVARCHAR(3) FOREIGN KEY REFERENCES HEFESTO.dbo.DimPais(IDPais)
);

CREATE TABLE HEFESTO.dbo.DimCiudad (
	IDCiudad INT PRIMARY KEY,
	Nombre NVARCHAR(30) NOT NULL,
	CodigoPostal NVARCHAR(15) NOT NULL,
	EstadoID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimEstado(IDEstado)
);

CREATE TABLE HEFESTO.dbo.DimEmpleados (
	IDVendedor INT PRIMARY KEY,
	Nombre NVARCHAR(50) NOT NULL,
	Apellido NVARCHAR(50) NOT NULL,
	CiudadID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimCiudad(IDCiudad),
	EsAsalariado BIT NOT NULL,
	Puesto NVARCHAR(50) NOT NULL,
	TerritorioVentaID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimTerritorio(IdTerritorio)
);

CREATE TABLE HEFESTO.dbo.DimTiempo (
    ClaveFecha INT PRIMARY KEY,         -- YYYYMMDD
    FechaCompleta DATE,
    Año INT,
    Semestre INT,                       -- 1 o 2
    Trimestre NVARCHAR(10),             -- '1ro', '2do', etc.
    NumeroMes INT,                      -- 1 a 12
    NombreMes NVARCHAR(20),             -- 'Enero', 'Febrero', etc.
    Día INT                             -- Día del mes
);

CREATE TABLE HEFESTO.dbo.DimMoneda (
	IdMoneda INT PRIMARY KEY,
	Moneda NVARCHAR(50) NOT NULL,
	TasaPromedio MONEY 
);

CREATE TABLE HEFESTO.dbo.DimOrdenes (
	IDOrder INT PRIMARY KEY,
	TotalPagado MONEY NOT NULL,
	ClaveFechaEnvio INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimTiempo(ClaveFecha),
	MonedaID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimMoneda(IdMoneda),
	Estado TINYINT NOT NULL
);

CREATE TABLE HEFESTO.dbo.DimProductos (
	IDProducto INT PRIMARY KEY,
	Nombre NVARCHAR(50) NOT NULL,
	CompradoFlag BIT NOT NULL,
	PrecioLista MONEY NOT NULL
);

CREATE TABLE HEFESTO.dbo.FactOrdenesDetails (
	IDVenta INT PRIMARY KEY,
	PrecioLista MONEY NOT NULL,
	PrecioUnitario MONEY NOT NULL,
	DiferenciaPrecios MONEY NOT NULL,
	TotalVentaMoneda MONEY NOT NULL,
	Cantidad SMALLINT NOT NULL,
	VendedorID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimEmpleados(IDVendedor),
	ProductoID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimProductos(IDProducto),
	OrdenID INT FOREIGN KEY REFERENCES HEFESTO.dbo.DimOrdenes(IDOrder)
);

DELETE FROM HEFESTO.dbo.FactOrdenesDetails;
DELETE FROM HEFESTO.dbo.DimOrdenes;
DELETE FROM HEFESTO.dbo.DimProductos;
DELETE FROM HEFESTO.dbo.DimEmpleados;
DELETE FROM HEFESTO.dbo.DimCiudad;
DELETE FROM HEFESTO.dbo.DimEstado;
DELETE FROM HEFESTO.dbo.DimPais;
DELETE FROM HEFESTO.dbo.DimTerritorio;
DELETE FROM HEFESTO.dbo.DimTiempo;
DELETE FROM HEFESTO.dbo.DimMoneda;

--DimProductos
SELECT 
	DISTINCT pp.ProductID AS IDProducto,
	pp.MakeFlag AS CompradoFlag,
	pp.ListPrice AS PrecioLista,
	pp.Name AS Nombre
FROM AdventureWorks2022.Production.Product pp,
	AdventureWorks2022.Sales.SalesOrderDetail sod
WHERE pp.ProductID = sod.ProductID
;

--DimPais
SELECT 
	CountryRegionCode AS IDPais,
	Name AS Nombre
FROM AdventureWorks2022.Person.CountryRegion;

--DimEstado
SELECT
	StateProvinceID AS IDEstado,
	StateProvinceCode AS EstadoCode,
	Name AS Nombre,
	CountryRegionCode AS PaisID
FROM AdventureWorks2022.Person.StateProvince
;

--DimMoneda
SELECT
    ROW_NUMBER() OVER (ORDER BY c.CurrencyCode) AS IdMoneda,
    c.Name AS Moneda,
    c.CurrencyCode AS CodigoMoneda,
    cr.AverageRate AS TasaPromedio
FROM AdventureWorks2022.Sales.Currency c
LEFT JOIN AdventureWorks2022.Sales.CurrencyRate cr
    ON c.CurrencyCode = cr.ToCurrencyCode
;

--DimCiudad
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

--DimTerritorio
SELECT
    TerritoryID AS IdTerritorio,
    [Name] AS TerritorioNombre,
    [Group] AS GrupoTerritorio
FROM AdventureWorks2022.Sales.SalesTerritory;

--DimEmpleado -DimVendedor
SELECT DISTINCT
    hre.BusinessEntityID AS IDVendedor,
    pp.FirstName AS Nombre,
    pp.LastName AS Apellido,
    pbea.AddressID AS CiudadID, 
    hre.SalariedFlag AS EsAsalariado,
    hre.JobTitle AS Puesto,
    sst.TerritoryID AS TerritorioVenta 
FROM
    AdventureWorks2022.HumanResources.Employee hre
INNER JOIN
    AdventureWorks2022.Person.Person pp ON hre.BusinessEntityID = pp.BusinessEntityID
LEFT JOIN
    AdventureWorks2022.Person.BusinessEntityAddress pbea ON hre.BusinessEntityID = pbea.BusinessEntityID
LEFT JOIN
    AdventureWorks2022.Sales.SalesPerson ssp ON hre.BusinessEntityID = ssp.BusinessEntityID
LEFT JOIN
    AdventureWorks2022.Sales.SalesTerritory sst ON ssp.TerritoryID = sst.TerritoryID
WHERE
    hre.BusinessEntityID IN (SELECT DISTINCT SalesPersonID FROM AdventureWorks2022.Sales.SalesOrderHeader WHERE SalesPersonID IS NOT NULL);

--DimOrdenes (Sales.SalesOrderHeader)
SELECT
	soh.SalesOrderID AS IDOrder,
	soh.TotalDue AS TotalPagado,
	CONVERT(INT, FORMAT(soh.OrderDate, 'yyyyMMdd')) AS ClaveFechaEnvio,
	soh.CurrencyRateID AS MonedaID,
	soh.Status AS Estado
FROM AdventureWorks2022.Sales.SalesOrderHeader soh
;

--Tabla de hechos
SELECT
	sod.SalesOrderDetailID AS IDVenta,
	sod.UnitPrice AS PrecioUnitario,
	dp.PrecioLista AS PrecioLista,
	dp.PrecioLista - sod.UnitPrice AS DiferenciaPrecios,
	sod.UnitPrice * sod.OrderQty * scr.AverageRate AS TotalVentaMoneda,
	dp.IDProducto AS ProductoID,
	do.IDOrder AS OrdenID,
	dv.IDVendedor AS VendedorID,
	sod.OrderQty AS Cantidad
FROM AdventureWorks2022.Sales.SalesOrderDetail sod,
	AdventureWorks2022.Sales.SalesOrderHeader soh,
	AdventureWorks2022.Sales.CurrencyRate scr,
	HEFESTO.dbo.DimProductos dp,
	HEFESTO.dbo.DimEmpleados dv,
	HEFESTO.dbo.DimOrdenes do
WHERE sod.SalesOrderID = do.IDOrder AND
	soh.SalesPersonID = dv.IDVendedor AND 
	sod.ProductID = dp.IDProducto AND
	sod.SalesOrderID = soh.SalesOrderID AND
	soh.CurrencyRateID = scr.CurrencyRateID
;

